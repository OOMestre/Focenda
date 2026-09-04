import Foundation
import SwiftUI
import Observation
#if os(macOS)
import AppKit
#endif

/// Navigation tabs in Focenda
public enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case timer = "Focus Timer"
    case kanban = "Tasks"
    case calendar = "Calendar"
    case reminders = "Reminders"
    case scratchpad = "Scratchpad"
    case bookmarks = "Bookmarks"
    case profiles = "Profiles"
    case settings = "Settings"
    case about = "About"
    case support = "Support"

    public var id: String { rawValue }

    /// Tabs exposed in the current app build. Hidden tabs remain in the enum so
    /// their implementation and persisted data can be restored later.
    public var isAvailableInApp: Bool {
        switch self {
        case .profiles:
            return ProductivityProfilesFeature.isEnabled
        default:
            return true
        }
    }

    public static var availableCases: [Self] {
        allCases.filter { $0.isAvailableInApp }
    }

    public var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .timer: return "timer"
        case .kanban: return "rectangle.split.3x1"
        case .calendar: return "calendar"
        case .reminders: return "bell.badge"
        case .scratchpad: return "square.and.pencil"
        case .bookmarks: return "bookmark.fill"
        case .profiles: return "rectangle.3.group"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        case .support: return "heart.fill"
        }
    }
}

/// Global application state and user preferences
@Observable
public final class AppState {
    /// Stable key used to remember that the first-launch guided tour was seen.
    public static let onboardingCompletionKey = "focenda_onboarding_completed_v1"
    public static let reminderSoundRepeatUntilDoneKey = "reminderSoundRepeatUntilDone"

    public var moduleManager: AppModuleManager

    public var selectedTab: AppTab = .dashboard {
        didSet {
            guard isTabAvailable(selectedTab) else {
                selectedTab = isTabAvailable(oldValue) ? oldValue : .dashboard
                return
            }
        }
    }
    public private(set) var hasCompletedOnboarding: Bool
    public var dailyFocusGoalMinutes: Int = 120 {
        didSet {
            savePreferences()
        }
    }
    public var soundEnabled: Bool = true {
        didSet {
            savePreferences()
        }
    }
    public var reminderSoundEnabled: Bool = true {
        didSet {
            savePreferences()
        }
    }
    public var reminderSoundType: ReminderSoundType = .hero {
        didSet {
            savePreferences()
        }
    }
    public var reminderCustomSoundPath: String = "" {
        didSet {
            savePreferences()
        }
    }
    public var reminderCustomSoundName: String = "" {
        didSet {
            savePreferences()
        }
    }
    /// Security-scoped bookmark for the user-selected custom reminder sound.
    /// The bookmark is encrypted together with the other local preferences.
    public var reminderCustomSoundBookmarkData: Data? {
        didSet {
            savePreferences()
        }
    }
    public var reminderSoundRepeatCount: Int = 3 {
        didSet {
            let clamped = max(ReminderSoundType.minRepeatCount, min(ReminderSoundType.maxRepeatCount, reminderSoundRepeatCount))
            if reminderSoundRepeatCount != clamped {
                reminderSoundRepeatCount = clamped
            } else {
                savePreferences()
            }
        }
    }
    public var reminderSoundRepeatUntilDone: Bool = false {
        didSet {
            savePreferences()
        }
    }
    public var autoStartBreaks: Bool = false
    public var autoStartFocus: Bool = false
    public var globalShortcutsEnabled: Bool = true {
        didSet {
            GlobalShortcutManager.shared.setEnabled(globalShortcutsEnabled)
            savePreferences()
        }
    }
    public var shortcutPreset: GlobalShortcutPreset = .standard {
        didSet {
            GlobalShortcutManager.shared.setPreset(shortcutPreset)
            savePreferences()
        }
    }
    public var showShortcutFeedback: Bool = true {
        didSet {
            savePreferences()
        }
    }
    public var automaticUpdateChecksEnabled: Bool = true {
        didSet {
            savePreferences()
        }
    }
    public private(set) var persistenceErrorMessage: String?
    public var selectedTheme: AppThemeOption {
        didSet {
            secureStore.set(selectedTheme.rawValue, forKey: AppTheme.storageKey)
            AppTheme.current = selectedTheme
            #if os(macOS)
            DispatchQueue.main.async {
                for window in NSApp.windows {
                    window.contentView?.needsDisplay = true
                    window.viewsNeedDisplay = true
                }
            }
            #endif
        }
    }

    private let secureStore: SecureStore
    private var preferencesPersistenceReady = false

    public init(secureStore: SecureStore = .shared, moduleManager: AppModuleManager? = nil) {
        self.secureStore = secureStore
        self.moduleManager = moduleManager ?? AppModuleManager(secureStore: secureStore)
        self.hasCompletedOnboarding = secureStore.bool(forKey: Self.onboardingCompletionKey) ?? false
        let savedGoal = secureStore.integer(forKey: "dailyFocusGoalMinutes") ?? 0
        self.dailyFocusGoalMinutes = savedGoal == 0 ? 120 : savedGoal
        self.soundEnabled = secureStore.bool(forKey: "soundEnabled") ?? true
        self.reminderSoundEnabled = secureStore.bool(forKey: "reminderSoundEnabled") ?? true

        if let savedSoundTypeRaw = secureStore.string(forKey: "reminderSoundType"),
           let soundType = ReminderSoundType(rawValue: savedSoundTypeRaw) {
            self.reminderSoundType = soundType
        } else {
            self.reminderSoundType = .hero
        }

        self.reminderCustomSoundPath = secureStore.string(forKey: "reminderCustomSoundPath") ?? ""
        self.reminderCustomSoundName = secureStore.string(forKey: "reminderCustomSoundName") ?? ""
        self.reminderCustomSoundBookmarkData = secureStore.data(forKey: "reminderCustomSoundBookmarkData")

        let savedRepeatCount = secureStore.integer(forKey: "reminderSoundRepeatCount") ?? 0
        self.reminderSoundRepeatCount = savedRepeatCount == 0 ? ReminderSoundType.defaultRepeatCount : max(ReminderSoundType.minRepeatCount, min(ReminderSoundType.maxRepeatCount, savedRepeatCount))
        self.reminderSoundRepeatUntilDone = secureStore.bool(forKey: Self.reminderSoundRepeatUntilDoneKey) ?? false
        
        self.globalShortcutsEnabled = secureStore.bool(forKey: "globalShortcutsEnabled") ?? true
        if let savedPresetRaw = secureStore.string(forKey: "shortcutPreset"),
           let preset = GlobalShortcutPreset(rawValue: savedPresetRaw) {
            self.shortcutPreset = preset
        } else {
            self.shortcutPreset = .standard
        }
        self.showShortcutFeedback = secureStore.bool(forKey: "showShortcutFeedback") ?? true
        self.automaticUpdateChecksEnabled = secureStore.bool(forKey: AppUpdatePreferences.automaticChecksEnabledKey) ?? true

        let storedTheme = secureStore.string(forKey: AppTheme.storageKey)
        let resolvedTheme = AppThemeOption.from(storedValue: storedTheme)
        self.selectedTheme = resolvedTheme
        // Do not replace an unreadable saved theme with the default while the
        // app is starting. A missing value is safe to initialize; a present
        // but unreadable value must remain untouched for migration/recovery.
        if storedTheme != nil || !secureStore.containsValue(forKey: AppTheme.storageKey) {
            AppTheme.current = resolvedTheme
        }

        preferencesPersistenceReady = Self.areStoredPreferencesReadable(in: secureStore)
        if !preferencesPersistenceReady {
            persistenceErrorMessage = "Some saved preferences could not be read. They were left untouched."
        }
    }

    /// Marks the guided tour as complete so it no longer appears on launch.
    public func completeOnboarding() {
        guard !hasCompletedOnboarding else { return }
        hasCompletedOnboarding = true
        secureStore.set(true, forKey: Self.onboardingCompletionKey)
        if secureStore.string(forKey: AppUpdatePreferences.lastAcknowledgedVersionKey) == nil {
            secureStore.set(AppRuntime.currentReleaseIdentifier, forKey: AppUpdatePreferences.lastAcknowledgedVersionKey)
        }
    }

    /// Resets the tour state for an explicit replay or a future reset action.
    public func resetOnboarding() {
        hasCompletedOnboarding = false
        secureStore.set(false, forKey: Self.onboardingCompletionKey)
    }

    public func savePreferences() {
        guard preferencesPersistenceReady else { return }
        secureStore.set(dailyFocusGoalMinutes, forKey: "dailyFocusGoalMinutes")
        secureStore.set(soundEnabled, forKey: "soundEnabled")
        secureStore.set(reminderSoundEnabled, forKey: "reminderSoundEnabled")
        secureStore.set(reminderSoundType.rawValue, forKey: "reminderSoundType")
        secureStore.set(reminderCustomSoundPath, forKey: "reminderCustomSoundPath")
        secureStore.set(reminderCustomSoundName, forKey: "reminderCustomSoundName")
        if let reminderCustomSoundBookmarkData {
            secureStore.setData(reminderCustomSoundBookmarkData, forKey: "reminderCustomSoundBookmarkData")
        } else {
            secureStore.removeObject(forKey: "reminderCustomSoundBookmarkData")
        }
        secureStore.set(reminderSoundRepeatCount, forKey: "reminderSoundRepeatCount")
        secureStore.set(reminderSoundRepeatUntilDone, forKey: Self.reminderSoundRepeatUntilDoneKey)
        secureStore.set(globalShortcutsEnabled, forKey: "globalShortcutsEnabled")
        secureStore.set(shortcutPreset.rawValue, forKey: "shortcutPreset")
        secureStore.set(showShortcutFeedback, forKey: "showShortcutFeedback")
        secureStore.set(automaticUpdateChecksEnabled, forKey: AppUpdatePreferences.automaticChecksEnabledKey)
        secureStore.set(selectedTheme.rawValue, forKey: AppTheme.storageKey)
        AppTheme.current = selectedTheme
    }

    /// Checks whether a tab is available given app builds and user-installed modules.
    public func isTabAvailable(_ tab: AppTab) -> Bool {
        guard tab.isAvailableInApp else { return false }
        return moduleManager.isTabAvailable(tab)
    }

    /// List of tabs currently available to the user in the sidebar.
    public var availableTabs: [AppTab] {
        AppTab.allCases.filter { isTabAvailable($0) }
    }

    /// Checks if a modular feature is installed.
    public func isModuleInstalled(_ module: AppModule) -> Bool {
        moduleManager.isInstalled(module)
    }

    /// Installs a modular feature, restoring its ViewModel and data.
    public func installModule(_ module: AppModule) {
        moduleManager.installModule(module)
    }

    /// Uninstalls a modular feature, freeing its ViewModel from RAM while preserving data on disk.
    public func uninstallModule(_ module: AppModule) {
        moduleManager.uninstallModule(module)
        ensureValidSelectedTab()
    }

    /// Toggles a modular feature's installation status.
    public func toggleModule(_ module: AppModule) {
        if isModuleInstalled(module) {
            uninstallModule(module)
        } else {
            installModule(module)
        }
    }

    /// Ensures the currently selected tab is valid; otherwise redirects safely to Dashboard.
    public func ensureValidSelectedTab() {
        if !isTabAvailable(selectedTab) {
            selectedTab = .dashboard
        }
    }

    private static func areStoredPreferencesReadable(in secureStore: SecureStore) -> Bool {
        let readableValues = [
            !secureStore.containsValue(forKey: "dailyFocusGoalMinutes") || secureStore.integer(forKey: "dailyFocusGoalMinutes") != nil,
            !secureStore.containsValue(forKey: "soundEnabled") || secureStore.bool(forKey: "soundEnabled") != nil,
            !secureStore.containsValue(forKey: "reminderSoundEnabled") || secureStore.bool(forKey: "reminderSoundEnabled") != nil,
            !secureStore.containsValue(forKey: "reminderSoundType") || secureStore.string(forKey: "reminderSoundType") != nil,
            !secureStore.containsValue(forKey: "reminderCustomSoundPath") || secureStore.string(forKey: "reminderCustomSoundPath") != nil,
            !secureStore.containsValue(forKey: "reminderCustomSoundName") || secureStore.string(forKey: "reminderCustomSoundName") != nil,
            !secureStore.containsValue(forKey: "reminderCustomSoundBookmarkData") || secureStore.data(forKey: "reminderCustomSoundBookmarkData") != nil,
            !secureStore.containsValue(forKey: "reminderSoundRepeatCount") || secureStore.integer(forKey: "reminderSoundRepeatCount") != nil,
            !secureStore.containsValue(forKey: Self.reminderSoundRepeatUntilDoneKey) || secureStore.bool(forKey: Self.reminderSoundRepeatUntilDoneKey) != nil,
            !secureStore.containsValue(forKey: "globalShortcutsEnabled") || secureStore.bool(forKey: "globalShortcutsEnabled") != nil,
            !secureStore.containsValue(forKey: "shortcutPreset") || secureStore.string(forKey: "shortcutPreset") != nil,
            !secureStore.containsValue(forKey: "showShortcutFeedback") || secureStore.bool(forKey: "showShortcutFeedback") != nil,
            !secureStore.containsValue(forKey: AppUpdatePreferences.automaticChecksEnabledKey) || secureStore.bool(forKey: AppUpdatePreferences.automaticChecksEnabledKey) != nil,
            !secureStore.containsValue(forKey: AppTheme.storageKey) || secureStore.string(forKey: AppTheme.storageKey) != nil,
            !secureStore.containsValue(forKey: Self.onboardingCompletionKey) || secureStore.bool(forKey: Self.onboardingCompletionKey) != nil,
            !secureStore.containsValue(forKey: AppModuleManager.storageKey) || secureStore.stringArray(forKey: AppModuleManager.storageKey) != nil
        ]
        return readableValues.allSatisfy { $0 }
    }
}
