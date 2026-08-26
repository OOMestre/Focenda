import SwiftUI

public struct MainView: View {
    @State private var appState: AppState
    @State private var timerVM: FocusTimerViewModel
    @State private var taskVM: TaskListViewModel
    @State private var scratchpadVM: ScratchpadViewModel
    @State private var bookmarkVM: BookmarkViewModel

    public init(
        appState: AppState = AppState(),
        timerVM: FocusTimerViewModel = FocusTimerViewModel(),
        taskVM: TaskListViewModel = TaskListViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel(),
        bookmarkVM: BookmarkViewModel = BookmarkViewModel()
    ) {
        _appState = State(initialValue: appState)
        _timerVM = State(initialValue: timerVM)
        _taskVM = State(initialValue: taskVM)
        _scratchpadVM = State(initialValue: scratchpadVM)
        _bookmarkVM = State(initialValue: bookmarkVM)
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM,
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
                        taskVM: taskVM
                    )
                case .timer:
                    FocusTimerView(timerVM: timerVM)
                case .kanban:
                    KanbanBoardView(taskVM: taskVM)
                case .calendar:
                    CalendarView(
                        timerVM: timerVM,
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
        .frame(minWidth: 860, minHeight: 580)
        .background(AppTheme.background)
        .preferredColorScheme(appState.selectedTheme.colorScheme)
        .id(appState.selectedTheme)
    }
}
