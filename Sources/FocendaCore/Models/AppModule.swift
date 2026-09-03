import Foundation

/// Represents individual modular features that can be installed or uninstalled by the user.
public enum AppModule: String, CaseIterable, Identifiable, Codable, Sendable {
    case kanban = "kanban"
    case calendar = "calendar"
    case reminders = "reminders"
    case scratchpad = "scratchpad"
    case bookmarks = "bookmarks"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .kanban:
            return "Tasks (Kanban)"
        case .calendar:
            return "Calendar"
        case .reminders:
            return "Reminders"
        case .scratchpad:
            return "Scratchpad"
        case .bookmarks:
            return "Bookmarks"
        }
    }

    public var description: String {
        switch self {
        case .kanban:
            return "Task management board with status columns, priority tags, and Pomodoro cycle tracking."
        case .calendar:
            return "Interactive monthly grid, daily timebox agenda, and focus session heatmap."
        case .reminders:
            return "Scheduled recurring alerts, customizable chime sounds, and system notifications."
        case .scratchpad:
            return "Distraction-free quick notepad with instant auto-save and folder organization."
        case .bookmarks:
            return "Quick-access launcher for reference links, documentation, and web tools."
        }
    }

    public var iconName: String {
        switch self {
        case .kanban:
            return "rectangle.split.3x1"
        case .calendar:
            return "calendar"
        case .reminders:
            return "bell.badge"
        case .scratchpad:
            return "square.and.pencil"
        case .bookmarks:
            return "bookmark.fill"
        }
    }

    public var correspondingTab: AppTab {
        switch self {
        case .kanban:
            return .kanban
        case .calendar:
            return .calendar
        case .reminders:
            return .reminders
        case .scratchpad:
            return .scratchpad
        case .bookmarks:
            return .bookmarks
        }
    }
}

/// Represents core essential components of Focenda that are permanently active and cannot be uninstalled.
public enum EssentialModule: String, CaseIterable, Identifiable, Sendable {
    case timer = "timer"
    case dashboard = "dashboard"
    case settings = "settings"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .timer:
            return "Focus Timer"
        case .dashboard:
            return "Dashboard"
        case .settings:
            return "Settings"
        }
    }

    public var description: String {
        switch self {
        case .timer:
            return "Core Pomodoro focus intervals, session tracking, and Menu Bar status."
        case .dashboard:
            return "Central productivity flow overview and daily achievements."
        case .settings:
            return "Application preferences, audio chimes, theme customization, and updates."
        }
    }

    public var iconName: String {
        switch self {
        case .timer:
            return "timer"
        case .dashboard:
            return "square.grid.2x2"
        case .settings:
            return "gearshape"
        }
    }
}
