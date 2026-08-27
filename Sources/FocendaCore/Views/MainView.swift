import SwiftUI

public struct MainView: View {
    /// Enforced minimum dimensions for the macOS window to guarantee all views, controls,
    /// and text remain 100% visible, fully functional, and visually balanced without breaking.
    public static let minimumWindowWidth: CGFloat = 800
    public static let minimumWindowHeight: CGFloat = 560
    public static let defaultWindowWidth: CGFloat = 1060
    public static let defaultWindowHeight: CGFloat = 720

    @Bindable var appState: AppState
    @State private var timerVM: FocusTimerViewModel
    @State private var taskVM: TaskListViewModel
    @State private var scratchpadVM: ScratchpadViewModel
    @State private var bookmarkVM: BookmarkViewModel
    @State private var recurringReminderVM: RecurringReminderViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init(
        appState: AppState = AppState(),
        timerVM: FocusTimerViewModel = FocusTimerViewModel(),
        taskVM: TaskListViewModel = TaskListViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel(),
        bookmarkVM: BookmarkViewModel = BookmarkViewModel(),
        recurringReminderVM: RecurringReminderViewModel = RecurringReminderViewModel()
    ) {
        self.appState = appState
        _timerVM = State(initialValue: timerVM)
        _taskVM = State(initialValue: taskVM)
        _scratchpadVM = State(initialValue: scratchpadVM)
        _bookmarkVM = State(initialValue: bookmarkVM)
        _recurringReminderVM = State(initialValue: recurringReminderVM)
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM,
                bookmarkVM: bookmarkVM,
                recurringReminderVM: recurringReminderVM
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
            .background(AppTheme.sidebarBackground)
        } detail: {
            Group {
                switch appState.selectedTab {
                case .dashboard:
                    DashboardView(
                        appState: appState,
                        timerVM: timerVM,
                        taskVM: taskVM
                    )
                case .timer:
                    FocusTimerView(timerVM: timerVM)
                case .kanban:
                    KanbanBoardView(taskVM: taskVM)
                case .calendar:
                    CalendarView(
                        timerVM: timerVM,
                        taskVM: taskVM,
                        recurringReminderVM: recurringReminderVM
                    )
                case .reminders:
                    RemindersView(
                        recurringReminderVM: recurringReminderVM,
                        taskVM: taskVM
                    )
                case .scratchpad:
                    ScratchpadView(viewModel: scratchpadVM)
                case .bookmarks:
                    BookmarksView(viewModel: bookmarkVM)
                case .stats:
                    StatsView(
                        timerVM: timerVM,
                        taskVM: taskVM
                    )
                case .settings:
                    SettingsView(
                        appState: appState,
                        timerVM: timerVM
                    )
                }
            }
            .background(AppTheme.background)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: Self.minimumWindowWidth,
            minHeight: Self.minimumWindowHeight
        )
        .enforceMinimumWindowSize(
            width: Self.minimumWindowWidth,
            height: Self.minimumWindowHeight
        )
        .background(AppTheme.background)
        .preferredColorScheme(appState.selectedTheme.colorScheme)
    }
}
