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
    case support = "Support"

    public var id: String { rawValue }

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
        case .support: return "heart.fill"
        }
    }
}

/// Global application state and user preferences
@Observable
public final class AppState {
    public var selectedTab: AppTab = .dashboard
    public var dailyFocusGoalMinutes: Int = 120
    public var soundEnabled: Bool = true
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

    public init(secureStore: SecureStore = .shared) {
        self.secureStore = secureStore
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
        AppTheme.current = resolvedTheme
    }

    public func savePreferences() {
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
        secureStore.set(globalShortcutsEnabled, forKey: "globalShortcutsEnabled")
        secureStore.set(shortcutPreset.rawValue, forKey: "shortcutPreset")
        secureStore.set(showShortcutFeedback, forKey: "showShortcutFeedback")
        secureStore.set(automaticUpdateChecksEnabled, forKey: AppUpdatePreferences.automaticChecksEnabledKey)
        secureStore.set(selectedTheme.rawValue, forKey: AppTheme.storageKey)
        AppTheme.current = selectedTheme
    }
}
