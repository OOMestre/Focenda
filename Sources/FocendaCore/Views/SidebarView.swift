import SwiftUI

public struct SidebarView: View {
    @Bindable var appState: AppState
    var timerVM: FocusTimerViewModel
    var taskVM: TaskListViewModel

    @State private var isPulsingDot = false

    public init(
        appState: AppState,
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel
    ) {
        self.appState = appState
        self.timerVM = timerVM
        self.taskVM = taskVM
    }

    public var body: some View {
        List(AppTab.allCases, id: \.self, selection: $appState.selectedTab) { tab in
            NavigationLink(value: tab) {
                SidebarRowItem(
                    tab: tab,
                    isSelected: appState.selectedTab == tab,
                    timerIsRunning: timerVM.status == .running,
                    pendingTasksCount: taskVM.pendingTasksCount,
                    isPulsingDot: isPulsingDot
                )
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            bottomMiniTimerView
        }
        .onAppear {
            if timerVM.status == .running {
                isPulsingDot = true
            }
        }
        .onChange(of: timerVM.status) { _, newStatus in
            isPulsingDot = (newStatus == .running)
        }
    }

    // MARK: - Bottom Mini-Timer Widget
    private var bottomMiniTimerView: some View {
        VStack(spacing: 8) {
            Divider()

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(timerVM.currentMode.themeColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: timerVM.currentMode.iconName)
                        .font(.caption.bold())
                        .foregroundStyle(timerVM.currentMode.themeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timerVM.currentMode.rawValue)
                        .font(.caption.bold())
                    Text(timerVM.formattedTimeRemaining)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        if timerVM.status == .running {
                            timerVM.pause()
                        } else {
                            timerVM.start()
                        }
                    }
                } label: {
                    Image(systemName: timerVM.status == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(timerVM.currentMode.themeColor)
                        )
                }
                .buttonStyle(.plain)
                .help(timerVM.status == .running ? "Pause timer" : "Start timer")
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(timerVM.currentMode.themeColor.opacity(0.18), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Sidebar Row Item

private struct SidebarRowItem: View {
    let tab: AppTab
    let isSelected: Bool
    let timerIsRunning: Bool
    let pendingTasksCount: Int
    let isPulsingDot: Bool

    var body: some View {
        Label {
            HStack {
                Text(tab.rawValue)
                    .font(.body.weight(isSelected ? .semibold : .regular))

                Spacer()

                // Status Badges
                if tab == .timer && timerIsRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                            .scaleEffect(isPulsingDot ? 1.2 : 0.8)
                            .opacity(isPulsingDot ? 1.0 : 0.6)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsingDot)

                        Text("RUNNING")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                } else if tab == .tasks && pendingTasksCount > 0 {
                    Text("\(pendingTasksCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.primary.opacity(0.12) : Color.secondary.opacity(0.15))
                        )
                        .contentTransition(.numericText())
                }
            }
        } icon: {
            Image(systemName: tab.iconName)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
        }
    }
}
