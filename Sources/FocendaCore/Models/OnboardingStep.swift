import Foundation

/// The guided tour pages shown when Focenda is opened for the first time.
///
/// Every navigation area has a dedicated page so the onboarding remains a
/// reliable source of truth as new sections are added to the app.
public enum OnboardingStep: Int, CaseIterable, Identifiable, Hashable {
    case welcome
    case dashboard
    case focusTimer
    case tasks
    case calendar
    case reminders
    case scratchpad
    case bookmarks
    case profiles
    case menuBar
    case settings
    case about
    case support

    public var id: Int { rawValue }

    /// The app section represented by this page, when it is a sidebar tab.
    public var appTab: AppTab? {
        switch self {
        case .welcome, .menuBar:
            return nil
        case .dashboard:
            return .dashboard
        case .focusTimer:
            return .timer
        case .tasks:
            return .kanban
        case .calendar:
            return .calendar
        case .reminders:
            return .reminders
        case .scratchpad:
            return .scratchpad
        case .bookmarks:
            return .bookmarks
        case .profiles:
            return .profiles
        case .settings:
            return .settings
        case .about:
            return .about
        case .support:
            return .support
        }
    }

    /// All pages that explain a navigable Focenda section.
    public static var featureSteps: [Self] {
        availableCases.filter { $0.appTab != nil || $0 == .menuBar }
    }

    /// Onboarding pages exposed in the current app build.
    public static var availableCases: [Self] {
        allCases.filter { step in
            step.appTab?.isAvailableInApp ?? true
        }
    }

    public var progressLabel: String {
        guard let index = Self.availableCases.firstIndex(of: self) else {
            return "Unavailable"
        }
        return "\(index + 1) of \(Self.availableCases.count)"
    }

    public var isLast: Bool {
        self == Self.availableCases.last
    }

    public var eyebrow: String {
        switch self {
        case .welcome:
            return "A calmer way to get things done"
        case .dashboard:
            return "Your home base"
        case .focusTimer:
            return "Protect your attention"
        case .tasks:
            return "Turn plans into progress"
        case .calendar:
            return "See the shape of your day"
        case .reminders:
            return "Let Focenda remember"
        case .scratchpad:
            return "Keep ideas close"
        case .bookmarks:
            return "Your focus hub"
        case .profiles:
            return "Return to the right setup"
        case .menuBar:
            return "Quick actions, always nearby"
        case .settings:
            return "Make Focenda yours"
        case .about:
            return "Get to know Focenda"
        case .support:
            return "Built independently"
        }
    }

    public var title: String {
        switch self {
        case .welcome:
            return "Welcome to Focenda"
        case .dashboard:
            return "Start from the Dashboard"
        case .focusTimer:
            return "Focus Timer"
        case .tasks:
            return "Tasks & Kanban"
        case .calendar:
            return "Calendar"
        case .reminders:
            return "Reminders"
        case .scratchpad:
            return "Scratchpad"
        case .bookmarks:
            return "Bookmarks & Focus Hub"
        case .profiles:
            return "Productivity Profiles"
        case .menuBar:
            return "The Menu Bar Control Center"
        case .settings:
            return "Settings"
        case .about:
            return "About Focenda"
        case .support:
            return "Keep Focenda growing"
        }
    }

    public var systemImage: String {
        switch self {
        case .welcome:
            return "sparkles"
        case .dashboard:
            return AppTab.dashboard.iconName
        case .focusTimer:
            return AppTab.timer.iconName
        case .tasks:
            return AppTab.kanban.iconName
        case .calendar:
            return AppTab.calendar.iconName
        case .reminders:
            return AppTab.reminders.iconName
        case .scratchpad:
            return AppTab.scratchpad.iconName
        case .bookmarks:
            return AppTab.bookmarks.iconName
        case .profiles:
            return AppTab.profiles.iconName
        case .menuBar:
            return "menubar.arrow.up.rectangle"
        case .settings:
            return AppTab.settings.iconName
        case .about:
            return AppTab.about.iconName
        case .support:
            return AppTab.support.iconName
        }
    }

    public var summary: String {
        switch self {
        case .welcome:
            return "Focenda brings focus sessions, tasks, notes, reminders and timeboxing into one quiet workspace."
        case .dashboard:
            return "See today's momentum at a glance and jump straight into the next meaningful action."
        case .focusTimer:
            return "Work in intentional cycles with Deep Focus, Short Break and Long Break modes."
        case .tasks:
            return "Organize the work in front of you with a visual board that stays simple and actionable."
        case .calendar:
            return "Timebox your commitments and understand how tasks, reminders and focus fit together."
        case .reminders:
            return "Schedule recurring nudges for routines, follow-ups and anything you do not want to hold in your head."
        case .scratchpad:
            return "Capture thoughts quickly in lightweight notebooks without breaking your flow."
        case .bookmarks:
            return "Keep the references, tools and websites you use most one click away."
        case .profiles:
            return "Save a complete app and window arrangement so your workspace can come back when you need it."
        case .menuBar:
            return "Start focus, add a task, capture a note, manage alerts and open links without leaving your current app."
        case .settings:
            return "Tune the visual style, intervals, sounds, daily goal and shortcuts to fit your workday."
        case .about:
            return "See Focenda's identity and version, check for updates, and find the open-source project."
        case .support:
            return "Focenda is free and open source. A star, contribution or thoughtful feedback helps it stay that way."
        }
    }

    public var tips: [String] {
        switch self {
        case .welcome:
            return [
                "Everything you create stays on this Mac in encrypted local storage.",
                "This tour covers every sidebar section plus the menu bar control center.",
                "You can replay the tour at any time from Settings."
            ]
        case .dashboard:
            return [
                "Track focus minutes, completed sessions and task progress in one glance.",
                "Use Start Focus to begin immediately, or choose a section from the sidebar.",
                "Return here to review today's progress and your highest-impact tasks."
            ]
        case .focusTimer:
            return [
                "Start a 25-minute Deep Focus session, then use Short Break and Long Break to recover.",
                "Adjust intervals, sounds and automatic starts in Settings.",
                "The mini timer and the menu bar keep the current session visible while you work."
            ]
        case .tasks:
            return [
                "Move work through To Do, In Progress and Done with drag and drop or status controls.",
                "Add priorities, tags, notes, Pomodoro estimates and due dates to make the next step clear.",
                "Switch between the visual Kanban board and a focused list view whenever you prefer."
            ]
        case .calendar:
            return [
                "Browse a monthly view with focus heatmaps, task due dates and reminder indicators.",
                "Hover over a day for a quick preview, then click it to keep the preview open.",
                "Create or inspect tasks and reminders in the context of the day they belong to."
            ]
        case .reminders:
            return [
                "Create daily, weekday, weekly or monthly recurring reminders with notes and a time.",
                "Focenda schedules native macOS alerts and can play a configurable chime.",
                "Use the menu bar Alerts section when you need to capture a reminder quickly."
            ]
        case .scratchpad:
            return [
                "Keep notes in General, Projects, Work, Personal or Ideas folders, and add your own folders.",
                "Titles and content save as you type, with pinning, search and word counts built in.",
                "Use the menu bar Note section for a quick capture without opening the full workspace."
            ]
        case .bookmarks:
            return [
                "Browse curated Focus & Flow, Development, Documentation, Design and Reference links.",
                "Search, filter, pin and open resources directly in your browser.",
                "Add personal quick links from the menu bar Links section when something is missing."
            ]
        case .profiles:
            return [
                "Save the apps you need for a context such as Writing, Study or Deep Work.",
                "Record each window's monitor, position and size, then activate the profile on demand.",
                "Assign a global shortcut in the profile and grant macOS Accessibility access when prompted."
            ]
        case .menuBar:
            return [
                "Click the Focenda owl in the macOS menu bar to open the compact control center.",
                "Its Focus, Note, Task, Alerts and Links sections cover the most common quick actions.",
                "Global shortcuts can bring focus controls and quick capture to you from anywhere."
            ]
        case .settings:
            return [
                "Choose from five themes and customize focus intervals, break behavior and your daily goal.",
                "Configure reminder and completion sounds, global shortcut presets and shortcut feedback.",
                "Replay this guided tour from Getting Started whenever you want a quick refresher."
            ]
        case .about:
            return [
                "See the Focenda logo, app name and the version currently installed on your Mac.",
                "Check GitHub Releases manually or keep automatic update checks enabled.",
                "Read about Focenda's privacy and open-source project from one dedicated place."
            ]
        case .support:
            return [
                "Focenda has no account, telemetry or cloud tracking; your productivity data remains local.",
                "Use Support to visit the project on GitHub or contribute to its independent development.",
                "You are ready to build a calmer, more intentional workday."
            ]
        }
    }

    public var locationHint: String? {
        switch self {
        case .welcome:
            return nil
        case .menuBar:
            return "Look for the Focenda owl in the macOS menu bar."
        default:
            return "Find \(appTab?.rawValue ?? title) in the Focenda sidebar."
        }
    }
}
