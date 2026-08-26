import Foundation
import UserNotifications

/// Protocol defining notification operations for focus sessions
public protocol NotificationManagerProtocol: AnyObject {
    func requestAuthorization(completion: ((Bool, Error?) -> Void)?)
    func notifySessionCompleted(mode: FocusMode)
}

/// Service managing native macOS system notifications for Focenda focus sessions and breaks
public final class NotificationManager: NotificationManagerProtocol {
    public static let shared = NotificationManager()

    private let center: UNUserNotificationCenter?
    public private(set) var lastNotifiedMode: FocusMode?

    public init(center: UNUserNotificationCenter? = nil) {
        if let center = center {
            self.center = center
        } else if Self.isNotificationAvailable {
            self.center = UNUserNotificationCenter.current()
        } else {
            self.center = nil
        }
    }

    private static var isNotificationAvailable: Bool {
        guard NSClassFromString("XCTestCase") == nil,
              NSClassFromString("XCTest") == nil,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
              ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil,
              !ProcessInfo.processInfo.arguments.contains(where: { $0.contains("xctest") || $0.contains("test") }),
              let bundleId = Bundle.main.bundleIdentifier,
              bundleId != "com.apple.dt.xctest.tool",
              bundleId != "FocendaPackageTests",
              !bundleId.isEmpty else {
            return false
        }
        return true
    }

    /// Requests authorization to display native macOS banners, sounds, and badges
    public func requestAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
        guard let center = center else {
            completion?(false, nil)
            return
        }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion?(granted, error)
        }
    }

    /// Async variant for requesting authorization
    @discardableResult
    public func requestAuthorization() async throws -> Bool {
        guard let center = center else {
            return false
        }
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Friendly English notification title for a given focus mode completion
    public static func notificationTitle(for mode: FocusMode) -> String {
        switch mode {
        case .work:
            return "Focus Session Completed! 🎯"
        case .shortBreak:
            return "Short Break Finished! ⚡"
        case .longBreak:
            return "Long Break Ended! 🚀"
        }
    }

    /// Friendly English notification body copy for a given focus mode completion
    public static func notificationBody(for mode: FocusMode) -> String {
        switch mode {
        case .work:
            return "Great job! Time to take a well-deserved break."
        case .shortBreak:
            return "Ready to jump back into deep focus?"
        case .longBreak:
            return "Feeling refreshed? Let's get back to work!"
        }
    }

    /// Posts a native macOS banner alert and sound when a focus session or break completes
    public func notifySessionCompleted(mode: FocusMode) {
        self.lastNotifiedMode = mode

        guard let center = center else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = Self.notificationTitle(for: mode)
        content.body = Self.notificationBody(for: mode)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
}
