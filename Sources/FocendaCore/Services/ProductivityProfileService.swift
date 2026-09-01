import Foundation

#if os(macOS)
import AppKit
import ApplicationServices
#endif

public enum ProductivityWindowArrangementResult: Equatable, Sendable {
    case arranged
    case applicationNotRunning
    case noWindow
    case accessibilityDenied
    case failed
}

/// The outcome of activating a profile, suitable for user-facing status text
/// and deterministic unit tests without requiring real applications to launch.
public struct ProductivityProfileActivationResult: Equatable, Sendable {
    public let profileName: String
    public let launchedApplicationNames: [String]
    public let arrangedApplicationNames: [String]
    public let failedApplicationNames: [String]
    public let requiresAccessibilityPermission: Bool

    public init(
        profileName: String,
        launchedApplicationNames: [String] = [],
        arrangedApplicationNames: [String] = [],
        failedApplicationNames: [String] = [],
        requiresAccessibilityPermission: Bool = false
    ) {
        self.profileName = profileName
        self.launchedApplicationNames = launchedApplicationNames
        self.arrangedApplicationNames = arrangedApplicationNames
        self.failedApplicationNames = failedApplicationNames
        self.requiresAccessibilityPermission = requiresAccessibilityPermission
    }

    public var succeeded: Bool {
        failedApplicationNames.isEmpty
    }

    public var summary: String {
        if failedApplicationNames.isEmpty {
            if arrangedApplicationNames.isEmpty {
                return "Profile \"\(profileName)\" has no applications configured yet."
            }
            return "Profile \"\(profileName)\" activated with \(arrangedApplicationNames.count) organized app\(arrangedApplicationNames.count == 1 ? "" : "s")."
        }

        let failed = failedApplicationNames.joined(separator: ", ")
        if requiresAccessibilityPermission {
            return "Give Focenda Accessibility access to organize: \(failed)."
        }
        return "Profile activated partially. Could not organize: \(failed)."
    }
}

public protocol ProductivityWindowManagerProtocol: AnyObject {
    var isAccessibilityTrusted: Bool { get }

    func requestAccessibilityAccess()
    func availableScreens() -> [ProductivityScreenDescriptor]
    func defaultWindowLayout() -> ProductivityWindowLayout
    func isApplicationRunning(_ application: ProductivityProfileApplication) -> Bool
    func launch(application: ProductivityProfileApplication) async -> Bool
    func arrange(application: ProductivityProfileApplication, layout: ProductivityWindowLayout) async -> ProductivityWindowArrangementResult
    func captureWindowLayout(for application: ProductivityProfileApplication) -> ProductivityWindowLayout?
}

public protocol ProductivityProfileActivationServiceProtocol: AnyObject {
    func activate(_ profile: ProductivityProfile) async -> ProductivityProfileActivationResult
}

/// Opens every application in a profile and applies its saved window layout.
public final class ProductivityProfileActivationService: ProductivityProfileActivationServiceProtocol {
    private let windowManager: ProductivityWindowManagerProtocol

    public init(windowManager: ProductivityWindowManagerProtocol = AccessibilityWindowManager()) {
        self.windowManager = windowManager
    }

    public func activate(_ profile: ProductivityProfile) async -> ProductivityProfileActivationResult {
        var launchedNames: [String] = []
        var arrangedNames: [String] = []
        var failedNames: [String] = []
        var requiresAccessibilityPermission = false

        if !windowManager.isAccessibilityTrusted {
            windowManager.requestAccessibilityAccess()
        }

        for application in profile.applications {
            let wasRunning = windowManager.isApplicationRunning(application)
            if !wasRunning {
                guard await windowManager.launch(application: application) else {
                    failedNames.append(application.name)
                    continue
                }
                launchedNames.append(application.name)
            }

            switch await windowManager.arrange(application: application, layout: application.windowLayout) {
            case .arranged:
                arrangedNames.append(application.name)
            case .accessibilityDenied:
                requiresAccessibilityPermission = true
                failedNames.append(application.name)
            case .applicationNotRunning, .noWindow, .failed:
                failedNames.append(application.name)
            }
        }

        return ProductivityProfileActivationResult(
            profileName: profile.displayName,
            launchedApplicationNames: launchedNames,
            arrangedApplicationNames: arrangedNames,
            failedApplicationNames: failedNames,
            requiresAccessibilityPermission: requiresAccessibilityPermission
        )
    }
}

#if os(macOS)
/// Native macOS implementation backed by NSWorkspace and the Accessibility API.
public final class AccessibilityWindowManager: ProductivityWindowManagerProtocol {
    private static let launchAttemptCount = 50
    private static let arrangementAttemptCount = 25
    private static let arrangementRetryDelayNanoseconds: UInt64 = 100_000_000
    private static let frameVerificationTolerance: CGFloat = 2

    public init() {}

    public var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    public func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public func availableScreens() -> [ProductivityScreenDescriptor] {
        NSScreen.screens.map { screen in
            ProductivityScreenDescriptor(id: Self.displayIdentifier(for: screen), name: screen.localizedName)
        }
    }

    public func defaultWindowLayout() -> ProductivityWindowLayout {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return ProductivityWindowLayout(position: .center)
        }

        let visibleFrame = screen.visibleFrame
        let width = min(900, max(ProductivityWindowLayout.minimumWidth, visibleFrame.width - 120))
        let height = min(700, max(ProductivityWindowLayout.minimumHeight, visibleFrame.height - 120))
        return ProductivityWindowLayout(
            x: 60,
            y: 60,
            width: width,
            height: height,
            screenID: Self.displayIdentifier(for: screen),
            screenName: screen.localizedName,
            position: .center
        )
    }

    public func isApplicationRunning(_ application: ProductivityProfileApplication) -> Bool {
        runningApplication(for: application) != nil
    }

    public func launch(application: ProductivityProfileApplication) async -> Bool {
        if let runningApplication = runningApplication(for: application), !runningApplication.isTerminated {
            return true
        }

        guard let resolvedApplication = applicationURL(for: application) else {
            return false
        }
        let applicationURL = resolvedApplication.url
        defer {
            if resolvedApplication.didStartAccessingSecurityScopedResource {
                applicationURL.stopAccessingSecurityScopedResource()
            }
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        let launched = await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) { application, _ in
                continuation.resume(returning: application != nil)
            }
        }

        guard launched else { return false }

        // NSWorkspace reports success just before the app has necessarily
        // created its first window. Wait for the process here; arrangement has
        // its own retry loop for the window and its geometry becoming ready.
        for _ in 0..<Self.launchAttemptCount {
            if let runningApplication = runningApplication(for: application), !runningApplication.isTerminated {
                return true
            }
            try? await Task.sleep(for: .milliseconds(100))
        }

        return runningApplication(for: application) != nil
    }

    public func arrange(
        application: ProductivityProfileApplication,
        layout: ProductivityWindowLayout
    ) async -> ProductivityWindowArrangementResult {
        var sawRunningApplication = false
        var sawWindow = false

        for attempt in 0..<Self.arrangementAttemptCount {
            guard isAccessibilityTrusted else { return .accessibilityDenied }

            guard let runningApplication = runningApplication(for: application) else {
                await waitBeforeArrangementRetry(ifNeeded: attempt)
                continue
            }
            sawRunningApplication = true

            // Existing applications are not necessarily frontmost or unhidden.
            // Bringing them forward before querying AX makes their main window
            // available consistently, especially immediately after launch.
            _ = runningApplication.unhide()
            if attempt == 0 {
                _ = runningApplication.activate(options: [])
            }

            let appElement = AXUIElementCreateApplication(runningApplication.processIdentifier)
            guard let window = firstWindow(for: appElement) else {
                await waitBeforeArrangementRetry(ifNeeded: attempt)
                continue
            }
            sawWindow = true

            guard let screen = screen(for: layout) else {
                return .failed
            }

            let targetFrame = layout.sanitized.appKitFrame(in: screen.visibleFrame)
            if apply(targetFrame: targetFrame, to: window) {
                return .arranged
            }

            await waitBeforeArrangementRetry(ifNeeded: attempt)
        }

        if !sawRunningApplication {
            return .applicationNotRunning
        }
        return sawWindow ? .failed : .noWindow
    }

    public func captureWindowLayout(for application: ProductivityProfileApplication) -> ProductivityWindowLayout? {
        guard isAccessibilityTrusted,
              let runningApplication = runningApplication(for: application) else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(runningApplication.processIdentifier)
        guard let window = firstWindow(for: appElement),
              let windowFrame = frame(of: window),
              let screen = screen(containing: windowFrame.center) ?? NSScreen.main ?? NSScreen.screens.first else {
            return nil
        }

        let visibleFrame = screen.visibleFrame
        return ProductivityWindowLayout(
            x: windowFrame.minX - visibleFrame.minX,
            y: windowFrame.minY - visibleFrame.minY,
            width: windowFrame.width,
            height: windowFrame.height,
            screenID: Self.displayIdentifier(for: screen),
            screenName: screen.localizedName,
            position: ProductivityWindowPosition.nearest(to: windowFrame, in: visibleFrame)
        )
    }

    public static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func runningApplication(for application: ProductivityProfileApplication) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first {
            guard !$0.isTerminated else { return false }
            return $0.bundleIdentifier == application.bundleIdentifier
        }
    }

    private func applicationURL(for application: ProductivityProfileApplication) -> (url: URL, didStartAccessingSecurityScopedResource: Bool)? {
        if let bookmarkData = application.applicationBookmarkData {
            var isStale = false
            if let bookmarkedURL = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                return (bookmarkedURL, bookmarkedURL.startAccessingSecurityScopedResource())
            }
        }

        if !application.applicationPath.isEmpty,
           FileManager.default.fileExists(atPath: application.applicationPath) {
            return (URL(fileURLWithPath: application.applicationPath), false)
        }

        guard !application.bundleIdentifier.isEmpty else { return nil }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: application.bundleIdentifier) else {
            return nil
        }
        return (url, false)
    }

    private func firstWindow(for appElement: AXUIElement) -> AXUIElement? {
        var windowsValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsValue
        ) == .success,
        let windows = windowsValue as? [AXUIElement] else {
            return nil
        }

        let standardWindows = windows.filter { window in
            var roleValue: CFTypeRef?
            return AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleValue) == .success
                && (roleValue as? String) == (kAXWindowRole as String)
        }

        var mainWindowValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            appElement,
            kAXMainWindowAttribute as CFString,
            &mainWindowValue
        ) == .success,
           let mainWindowValue,
           CFGetTypeID(mainWindowValue) == AXUIElementGetTypeID() {
            let mainWindow = mainWindowValue as! AXUIElement
            if isGeometrySettable(mainWindow) {
                return mainWindow
            }
        }

        // Prefer a standard window whose geometry attributes are writable.
        // Some applications expose sheets, tool windows, or transient launch
        // windows before their actual workspace window.
        if let writableWindow = standardWindows.first(where: isGeometrySettable) {
            return writableWindow
        }
        return standardWindows.first ?? windows.first
    }

    private func isGeometrySettable(_ window: AXUIElement) -> Bool {
        var positionSettable = DarwinBoolean(false)
        var sizeSettable = DarwinBoolean(false)
        let positionError = AXUIElementIsAttributeSettable(
            window,
            kAXPositionAttribute as CFString,
            &positionSettable
        )
        let sizeError = AXUIElementIsAttributeSettable(
            window,
            kAXSizeAttribute as CFString,
            &sizeSettable
        )
        return positionError == .success
            && sizeError == .success
            && positionSettable.boolValue
            && sizeSettable.boolValue
    }

    private func apply(targetFrame: CGRect, to window: AXUIElement) -> Bool {
        var position = accessibilityPosition(for: targetFrame)
        var size = targetFrame.size

        guard let positionValue = AXValueCreate(.cgPoint, &position),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return false
        }

        if frame(of: window).map({ matches($0, targetFrame) }) == true {
            return true
        }

        _ = AXUIElementSetAttributeValue(
            window,
            kAXMinimizedAttribute as CFString,
            kCFBooleanFalse
        )
        _ = AXUIElementPerformAction(window, kAXRaiseAction as CFString)

        // Different window frameworks commit geometry in different orders. Try
        // both common orders and verify the resulting frame instead of treating
        // an accepted AX message as proof that the window moved.
        let sizeThenPosition = AXUIElementSetAttributeValue(
            window,
            kAXSizeAttribute as CFString,
            sizeValue
        ) == .success
            && AXUIElementSetAttributeValue(
                window,
                kAXPositionAttribute as CFString,
                positionValue
            ) == .success

        if sizeThenPosition, frame(of: window).map({ matches($0, targetFrame) }) == true {
            return true
        }

        let positionThenSize = AXUIElementSetAttributeValue(
            window,
            kAXPositionAttribute as CFString,
            positionValue
        ) == .success
            && AXUIElementSetAttributeValue(
                window,
                kAXSizeAttribute as CFString,
                sizeValue
            ) == .success

        return positionThenSize && frame(of: window).map({ matches($0, targetFrame) }) == true
    }

    private func matches(_ actualFrame: CGRect, _ targetFrame: CGRect) -> Bool {
        abs(actualFrame.minX - targetFrame.minX) <= Self.frameVerificationTolerance
            && abs(actualFrame.minY - targetFrame.minY) <= Self.frameVerificationTolerance
            && abs(actualFrame.width - targetFrame.width) <= Self.frameVerificationTolerance
            && abs(actualFrame.height - targetFrame.height) <= Self.frameVerificationTolerance
    }

    private func waitBeforeArrangementRetry(ifNeeded attempt: Int) async {
        guard attempt < Self.arrangementAttemptCount - 1 else { return }
        try? await Task.sleep(nanoseconds: Self.arrangementRetryDelayNanoseconds)
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionValue,
              let sizeValue else {
            return nil
        }

        guard CFGetTypeID(positionValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeValue) == AXValueGetTypeID() else {
            return nil
        }

        var accessibilityPosition = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &accessibilityPosition),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else {
            return nil
        }

        let primaryScreenMaxY = primaryScreen?.frame.maxY ?? 0
        let appKitOrigin = CGPoint(
            x: accessibilityPosition.x,
            y: primaryScreenMaxY - accessibilityPosition.y - size.height
        )
        return CGRect(origin: appKitOrigin, size: size)
    }

    private func screen(for layout: ProductivityWindowLayout) -> NSScreen? {
        if let screenID = layout.screenID,
           let matchingScreen = NSScreen.screens.first(where: { Self.displayIdentifier(for: $0) == screenID }) {
            return matchingScreen
        }

        let requestedName = layout.screenName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !requestedName.isEmpty,
           let matchingScreen = NSScreen.screens.first(where: { $0.localizedName == requestedName }) {
            return matchingScreen
        }

        return NSScreen.main ?? NSScreen.screens.first
    }

    private func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) }
    }

    private var primaryScreen: NSScreen? {
        NSScreen.screens.first(where: { Self.displayIdentifier(for: $0) == CGMainDisplayID() })
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    private func accessibilityPosition(for appKitFrame: CGRect) -> CGPoint {
        let primaryScreenMaxY = primaryScreen?.frame.maxY ?? 0
        return CGPoint(
            x: appKitFrame.minX,
            y: primaryScreenMaxY - appKitFrame.maxY
        )
    }

    private static func displayIdentifier(for screen: NSScreen) -> UInt32 {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}

private extension ProductivityWindowLayout {
    func appKitFrame(in visibleFrame: CGRect) -> CGRect {
        let safeLayout = sanitized
        let width = min(safeLayout.width, visibleFrame.width)
        let height = min(safeLayout.height, visibleFrame.height)
        let maxX = max(visibleFrame.minX, visibleFrame.maxX - width)
        let maxY = max(visibleFrame.minY, visibleFrame.maxY - height)
        let origin: CGPoint
        if let position = safeLayout.position {
            origin = position.origin(
                in: visibleFrame,
                windowSize: CGSize(width: width, height: height)
            )
        } else {
            // Keep applying coordinates for layouts written before semantic
            // positions were introduced.
            origin = CGPoint(
                x: min(max(visibleFrame.minX + safeLayout.x, visibleFrame.minX), maxX),
                y: min(max(visibleFrame.minY + safeLayout.y, visibleFrame.minY), maxY)
            )
        }
        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
#endif
