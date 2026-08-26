import SwiftUI

public struct SidebarView: View {
    @Bindable var appState: AppState
    var timerVM: FocusTimerViewModel
    var taskVM: TaskListViewModel

    public var body: some View {
        List(AppTab.allCases, id: \.self, selection: $appState.selectedTab) { tab in
            NavigationLink(value: tab) {
                Label {
                    HStack {
                        Text(tab.rawValue)
                            .font(.body)

                        Spacer()

                        // Status badges
                        if tab == .timer && timerVM.status == .running {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        } else if tab == .tasks && taskVM.pendingTasksCount > 0 {
                            Text("\(taskVM.pendingTasksCount)")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                } icon: {
                    Image(systemName: tab.iconName)
                        .foregroundStyle(appState.selectedTab == tab ? Color.accentColor : Color.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundStyle(timerVM.currentMode.themeColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(timerVM.currentMode.rawValue)
                            .font(.caption.bold())
                        Text(timerVM.formattedTimeRemaining)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        if timerVM.status == .running {
                            timerVM.pause()
                        } else {
                            timerVM.start()
                        }
                    } label: {
                        Image(systemName: timerVM.status == .running ? "pause.fill" : "play.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(10)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
}
