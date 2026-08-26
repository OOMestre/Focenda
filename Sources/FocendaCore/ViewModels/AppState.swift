import Foundation
import SwiftUI
import Observation

/// Navigation tabs in Focenda
public enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case timer = "Focus Timer"
    case tasks = "Tasks"
    case kanban = "Kanban"
    case calendar = "Calendar"
    case habits = "Habits"
    case calendar = "Calendar"
    case scratchpad = "Scratchpad"
    case bookmarks = "Bookmarks"
    case stats = "Statistics"
    case settings = "Settings"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .timer: return "timer"
        case .tasks: return "checklist"
        case .kanban: return "rectangle.split.3x1"
        case .calendar: return "calendar"
        case .habits: return "flame.fill"
        case .calendar: return "calendar"
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

    public init() {
        let savedGoal = UserDefaults.standard.integer(forKey: "dailyFocusGoalMinutes")
        self.dailyFocusGoalMinutes = savedGoal == 0 ? 120 : savedGoal
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    public func savePreferences() {
        UserDefaults.standard.set(dailyFocusGoalMinutes, forKey: "dailyFocusGoalMinutes")
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
    }
}
