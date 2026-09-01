import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(Carbon)
import Carbon.HIToolbox
#endif

public extension Notification.Name {
    static let focusShortcutTriggered = Notification.Name("FocendaFocusShortcutTriggeredNotification")
    static let productivityProfileShortcutTriggered = Notification.Name("FocendaProductivityProfileShortcutTriggeredNotification")
}

/// Protocol defining global shortcut management operations
public protocol GlobalShortcutManagerProtocol: AnyObject {
    var isEnabled: Bool { get }
    var preset: GlobalShortcutPreset { get }
    var registeredCombinations: [ShortcutKeyCombination] { get }
    var lastTriggeredAction: FocusShortcutAction? { get }
    var lastTriggeredProfileID: UUID? { get }
    func setup(timerVM: FocusTimerViewModel, appState: AppState?)
    func setProductivityProfileShortcuts(_ profiles: [ProductivityProfile])
    func registerAll()
    func unregisterAll()
    func triggerAction(_ action: FocusShortcutAction)
    func triggerProductivityProfile(_ profileID: UUID)
}

#if canImport(Carbon) && canImport(AppKit)
/// Global C-compatible event handler function for Carbon HotKeys
private func focendaHotKeyCallback(
    nextHandler: EventHandlerCallRef?,
    theEvent: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let theEvent = theEvent else { return noErr }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        theEvent,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return noErr }

    if let action = FocusShortcutAction.from(numericId: hotKeyID.id) {
        DispatchQueue.main.async {
            GlobalShortcutManager.shared.triggerAction(action)
        }
    } else {
        DispatchQueue.main.async {
            GlobalShortcutManager.shared.triggerProductivityProfile(forNumericID: hotKeyID.id)
        }
    }
    return noErr
}
#endif

/// Service managing system-wide Carbon HotKeys and local shortcut event dispatchers for focus control
public final class GlobalShortcutManager: GlobalShortcutManagerProtocol {
    public static let shared = GlobalShortcutManager()

    public private(set) var isEnabled: Bool = true
    public private(set) var preset: GlobalShortcutPreset = .standard
    public private(set) var registeredCombinations: [ShortcutKeyCombination] = []
    public private(set) var lastTriggeredAction: FocusShortcutAction?
    public private(set) var lastTriggeredProfileID: UUID?

    public var onActionTriggered: ((FocusShortcutAction) -> Void)?

    private weak var timerVM: FocusTimerViewModel?
    private weak var appState: AppState?
    private var hasBeenSetup = false
    private var productivityProfileShortcuts: [(profileID: UUID, shortcut: ProductivityProfileShortcut)] = []
    private var registeredProfileHotKeyIDs: [UInt32: UUID] = [:]

    private static let profileHotKeyBaseID: UInt32 = 20_000

    #if canImport(Carbon) && canImport(AppKit)
    private var eventHandlerRef: EventHandlerRef?
    private var registeredHotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    #endif

    public init() {
        self.registeredCombinations = ShortcutKeyCombination.defaultCombinations(for: .standard)
    }

    deinit {
        unregisterAll()
    }

    /// Connects the shortcut manager to view models and state
    public func setup(timerVM: FocusTimerViewModel, appState: AppState? = nil) {
        self.timerVM = timerVM
        self.appState = appState
        self.hasBeenSetup = true

        if let state = appState {
            self.isEnabled = state.globalShortcutsEnabled
            self.preset = state.shortcutPreset
            self.registeredCombinations = ShortcutKeyCombination.defaultCombinations(for: state.shortcutPreset)
        }

        if isEnabled {
            registerAll()
        } else {
            unregisterAll()
        }
    }

    /// Sets whether global shortcuts are enabled
    public func setEnabled(_ enabled: Bool) {
        guard self.isEnabled != enabled else { return }
        self.isEnabled = enabled
        if enabled && hasBeenSetup {
            registerAll()
        } else {
            unregisterAll()
        }
    }

    /// Updates the active preset scheme
    public func setPreset(_ newPreset: GlobalShortcutPreset) {
        self.preset = newPreset
        self.registeredCombinations = ShortcutKeyCombination.defaultCombinations(for: newPreset)
        if isEnabled && hasBeenSetup {
            registerAll()
        }
    }

    /// Updates the profile shortcuts registered alongside the built-in focus shortcuts.
    public func setProductivityProfileShortcuts(_ profiles: [ProductivityProfile]) {
        productivityProfileShortcuts = ProductivityProfilesFeature.isEnabled ? profiles.compactMap { profile in
            guard let shortcut = profile.globalShortcut, shortcut.isUsable else { return nil }
            return (profileID: profile.id, shortcut: shortcut)
        } : []

        if isEnabled && hasBeenSetup {
            registerAll()
        }
    }

    // MARK: - Carbon HotKey Registration

    /// Registers all global hotkeys with macOS Carbon Event Manager
    public func registerAll() {
        unregisterAll()
        guard isEnabled else { return }

        #if canImport(Carbon) && canImport(AppKit)
        guard !Self.isHeadlessTestEnvironment else { return }

        // Install event handler if not already installed
        if eventHandlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            let status = InstallEventHandler(
                GetEventDispatcherTarget(),
                focendaHotKeyCallback,
                1,
                &eventType,
                nil,
                &eventHandlerRef
            )

            if status != noErr {
                print("⚠️ [GlobalShortcutManager] Failed to install Carbon event handler: \(status)")
            }
        }

        let signature = OSType(0x464F434E) // 'FOCN'
        for combo in registeredCombinations {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: signature, id: combo.action.numericId)

            let status = RegisterEventHotKey(
                combo.keyCode,
                combo.carbonModifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr, let ref = hotKeyRef {
                registeredHotKeyRefs[combo.action.numericId] = ref
            } else {
                print("⚠️ [GlobalShortcutManager] Failed to register HotKey for \(combo.action.rawValue): \(status)")
            }
        }

        for (index, profileShortcut) in productivityProfileShortcuts.enumerated() {
            let numericID = Self.profileHotKeyBaseID + UInt32(index)
            registeredProfileHotKeyIDs[numericID] = profileShortcut.profileID

            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: signature, id: numericID)
            let status = RegisterEventHotKey(
                profileShortcut.shortcut.keyCode,
                profileShortcut.shortcut.carbonModifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr, let ref = hotKeyRef {
                registeredHotKeyRefs[numericID] = ref
            } else {
                print("⚠️ [GlobalShortcutManager] Failed to register profile HotKey for \(profileShortcut.profileID): \(status)")
            }
        }
        #endif
    }

    /// Unregisters all registered Carbon HotKeys
    public func unregisterAll() {
        #if canImport(Carbon) && canImport(AppKit)
        for (_, ref) in registeredHotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        registeredHotKeyRefs.removeAll()
        registeredProfileHotKeyIDs.removeAll()

        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
        #endif
    }

    // MARK: - Action Execution

    /// Triggers an action directly, updating timer state and broadcasting events
    public func triggerAction(_ action: FocusShortcutAction) {
        self.lastTriggeredAction = action

        guard let timer = timerVM else {
            notifyTriggered(action: action)
            onActionTriggered?(action)
            return
        }

        switch action {
        case .toggleFocus:
            if timer.status == .running {
                timer.pause()
            } else {
                timer.start()
            }

        case .startWork:
            timer.switchMode(to: .work)
            timer.start()

        case .startShortBreak:
            timer.switchMode(to: .shortBreak)
            timer.start()

        case .startLongBreak:
            timer.switchMode(to: .longBreak)
            timer.start()

        case .resetTimer:
            timer.reset()

        case .skipSession:
            timer.skip()
        }

        notifyTriggered(action: action)
        onActionTriggered?(action)
    }

    /// Activates a productivity profile shortcut and publishes it for the app layer.
    public func triggerProductivityProfile(_ profileID: UUID) {
        lastTriggeredProfileID = profileID
        NotificationCenter.default.post(
            name: .productivityProfileShortcutTriggered,
            object: self,
            userInfo: ["profileID": profileID]
        )

        #if canImport(AppKit)
        if let appState = appState, appState.showShortcutFeedback {
            NotificationManager.shared.playRichAlertChime(soundName: "Ping")
        }
        #endif
    }

    fileprivate func triggerProductivityProfile(forNumericID numericID: UInt32) {
        guard let profileID = registeredProfileHotKeyIDs[numericID] else { return }
        triggerProductivityProfile(profileID)
    }

    private func notifyTriggered(action: FocusShortcutAction) {
        NotificationCenter.default.post(
            name: .focusShortcutTriggered,
            object: self,
            userInfo: [
                "action": action,
                "actionName": action.rawValue,
                "title": action.displayName,
                "icon": action.iconName
            ]
        )

        #if canImport(AppKit)
        if let appState = appState, appState.showShortcutFeedback {
            NotificationManager.shared.playRichAlertChime(soundName: "Ping")
        }
        #endif
    }

    private static var isHeadlessTestEnvironment: Bool {
        NSClassFromString("XCTestCase") != nil ||
        NSClassFromString("XCTest") != nil ||
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
        ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
        ProcessInfo.processInfo.arguments.contains(where: { $0.contains("xctest") || $0.contains("test") })
    }
}
