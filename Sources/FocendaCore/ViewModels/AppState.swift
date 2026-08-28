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
    case settings = "Settings"

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
        case .settings: return "gearshape"
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
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: AppTheme.storageKey)
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

    public init() {
        let savedGoal = UserDefaults.standard.integer(forKey: "dailyFocusGoalMinutes")
        self.dailyFocusGoalMinutes = savedGoal == 0 ? 120 : savedGoal
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "soundEnabled")
        self.reminderSoundEnabled = UserDefaults.standard.object(forKey: "reminderSoundEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "reminderSoundEnabled")

        if let savedSoundTypeRaw = UserDefaults.standard.string(forKey: "reminderSoundType"),
           let soundType = ReminderSoundType(rawValue: savedSoundTypeRaw) {
            self.reminderSoundType = soundType
        } else {
            self.reminderSoundType = .hero
        }

        self.reminderCustomSoundPath = UserDefaults.standard.string(forKey: "reminderCustomSoundPath") ?? ""
        self.reminderCustomSoundName = UserDefaults.standard.string(forKey: "reminderCustomSoundName") ?? ""

        let savedRepeatCount = UserDefaults.standard.integer(forKey: "reminderSoundRepeatCount")
        self.reminderSoundRepeatCount = savedRepeatCount == 0 ? ReminderSoundType.defaultRepeatCount : max(ReminderSoundType.minRepeatCount, min(ReminderSoundType.maxRepeatCount, savedRepeatCount))
        
        self.globalShortcutsEnabled = UserDefaults.standard.object(forKey: "globalShortcutsEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "globalShortcutsEnabled")
        if let savedPresetRaw = UserDefaults.standard.string(forKey: "shortcutPreset"),
           let preset = GlobalShortcutPreset(rawValue: savedPresetRaw) {
            self.shortcutPreset = preset
        } else {
            self.shortcutPreset = .standard
        }
        self.showShortcutFeedback = UserDefaults.standard.object(forKey: "showShortcutFeedback") == nil ? true : UserDefaults.standard.bool(forKey: "showShortcutFeedback")
        self.automaticUpdateChecksEnabled = UserDefaults.standard.object(forKey: AppUpdatePreferences.automaticChecksEnabledKey) == nil ? true : UserDefaults.standard.bool(forKey: AppUpdatePreferences.automaticChecksEnabledKey)

        let storedTheme = UserDefaults.standard.string(forKey: AppTheme.storageKey)
        let resolvedTheme = AppThemeOption.from(storedValue: storedTheme)
        self.selectedTheme = resolvedTheme
        AppTheme.current = resolvedTheme
    }

    public func savePreferences() {
        UserDefaults.standard.set(dailyFocusGoalMinutes, forKey: "dailyFocusGoalMinutes")
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(reminderSoundEnabled, forKey: "reminderSoundEnabled")
        UserDefaults.standard.set(reminderSoundType.rawValue, forKey: "reminderSoundType")
        UserDefaults.standard.set(reminderCustomSoundPath, forKey: "reminderCustomSoundPath")
        UserDefaults.standard.set(reminderCustomSoundName, forKey: "reminderCustomSoundName")
        UserDefaults.standard.set(reminderSoundRepeatCount, forKey: "reminderSoundRepeatCount")
        UserDefaults.standard.set(globalShortcutsEnabled, forKey: "globalShortcutsEnabled")
        UserDefaults.standard.set(shortcutPreset.rawValue, forKey: "shortcutPreset")
        UserDefaults.standard.set(showShortcutFeedback, forKey: "showShortcutFeedback")
        UserDefaults.standard.set(automaticUpdateChecksEnabled, forKey: AppUpdatePreferences.automaticChecksEnabledKey)
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: AppTheme.storageKey)
        AppTheme.current = selectedTheme
    }
}
