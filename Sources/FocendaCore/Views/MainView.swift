import SwiftUI

public struct MainView: View {
    @State private var appState: AppState
    @State private var timerVM: FocusTimerViewModel
    @State private var taskVM: TaskListViewModel

    public init(
        appState: AppState = AppState(),
        timerVM: FocusTimerViewModel = FocusTimerViewModel(),
        taskVM: TaskListViewModel = TaskListViewModel()
    ) {
        _appState = State(initialValue: appState)
        _timerVM = State(initialValue: timerVM)
        _taskVM = State(initialValue: taskVM)
    }

    public var body: some View {
        NavigationSplitView {
            SidebarView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM
            )
            .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
        } detail: {
            switch appState.selectedTab {
            case .dashboard:
                DashboardView(
                    appState: appState,
                    timerVM: timerVM,
                    taskVM: taskVM
                )
            case .timer:
                FocusTimerView(timerVM: timerVM)
            case .tasks:
                TaskListView(taskVM: taskVM)
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
        .frame(minWidth: 860, minHeight: 580)
    }
}
