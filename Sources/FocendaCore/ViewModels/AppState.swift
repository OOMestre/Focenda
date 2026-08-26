import Foundation
import SwiftUI
import Observation

/// Navigation tabs in Focenda
public enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case timer = "Focus Timer"
    case kanban = "Tasks"
    case calendar = "Calendar"
    case reminders = "Reminders"
    case scratchpad = "Scratchpad"
    case bookmarks = "Bookmarks"
    case stats = "Statistics"
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
        case .stats: return "chart.bar.xaxis"
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
    public var autoStartBreaks: Bool = false
    public var autoStartFocus: Bool = false
    public var selectedTheme: AppThemeOption {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: AppTheme.storageKey)
            AppTheme.current = selectedTheme
        }
    }

    public init() {
        let savedGoal = UserDefaults.standard.integer(forKey: "dailyFocusGoalMinutes")
        self.dailyFocusGoalMinutes = savedGoal == 0 ? 120 : savedGoal
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "soundEnabled")
        
        let storedTheme = UserDefaults.standard.string(forKey: AppTheme.storageKey)
        let resolvedTheme = AppThemeOption.from(storedValue: storedTheme)
        self.selectedTheme = resolvedTheme
        AppTheme.current = resolvedTheme
    }

    public func savePreferences() {
        UserDefaults.standard.set(dailyFocusGoalMinutes, forKey: "dailyFocusGoalMinutes")
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: AppTheme.storageKey)
        AppTheme.current = selectedTheme
    }
}
