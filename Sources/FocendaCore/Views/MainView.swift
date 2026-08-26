import SwiftUI

public struct MainView: View {
    @State private var appState: AppState
    @State private var timerVM: FocusTimerViewModel
    @State private var taskVM: TaskListViewModel
    @State private var habitVM: HabitViewModel
    @State private var scratchpadVM: ScratchpadViewModel
    @State private var bookmarkVM: BookmarkViewModel
    @State private var recurringReminderVM: RecurringReminderViewModel

    public init(
        appState: AppState = AppState(),
        timerVM: FocusTimerViewModel = FocusTimerViewModel(),
        taskVM: TaskListViewModel = TaskListViewModel(),
        habitVM: HabitViewModel = HabitViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel(),
        bookmarkVM: BookmarkViewModel = BookmarkViewModel(),
        recurringReminderVM: RecurringReminderViewModel = RecurringReminderViewModel()
    ) {
        _appState = State(initialValue: appState)
        _timerVM = State(initialValue: timerVM)
        _taskVM = State(initialValue: taskVM)
        _habitVM = State(initialValue: habitVM)
        _scratchpadVM = State(initialValue: scratchpadVM)
        _bookmarkVM = State(initialValue: bookmarkVM)
        _recurringReminderVM = State(initialValue: recurringReminderVM)
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM,
                habitVM: habitVM,
                bookmarkVM: bookmarkVM
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
            .background(AppTheme.sidebarBackground)
        } detail: {
            Group {
                switch appState.selectedTab {
                case .dashboard:
                    DashboardView(
                        appState: appState,
                        timerVM: timerVM,
                        taskVM: taskVM,
                        habitVM: habitVM
                    )
                case .timer:
                    FocusTimerView(timerVM: timerVM)
                case .tasks:
                    TaskListView(taskVM: taskVM)
                case .kanban:
                    KanbanBoardView(taskVM: taskVM)
                case .habits:
                    HabitTrackerView(habitVM: habitVM)
                case .calendar:
                    CalendarView(
                        timerVM: timerVM,
                        taskVM: taskVM,
                        habitVM: habitVM,
                        recurringReminderVM: recurringReminderVM
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
        .frame(minWidth: 860, minHeight: 580)
        .background(AppTheme.background)
    }
}
