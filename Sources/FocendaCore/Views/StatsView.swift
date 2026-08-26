import SwiftUI

public struct StatsView: View {
    var timerVM: FocusTimerViewModel
    var taskVM: TaskListViewModel

    public init(
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel
    ) {
        self.timerVM = timerVM
        self.taskVM = taskVM
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Productivity & Analytics")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Track your historical focus output and habit consistency.")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                // Summary Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(
                        title: "Total Sessions",
                        value: "\(timerVM.completedSessionsCount)",
                        subtitle: "\(timerVM.completedWorkSessionsCount) deep focus cycles",
                        icon: "flame.fill",
                        color: AppTheme.sandstone
                    )

                    StatCard(
                        title: "Accumulated Time",
                        value: "\(timerVM.todayFocusMinutes)m today",
                        subtitle: "Consistent progress",
                        icon: "hourglass",
                        color: AppTheme.deepFocus
                    )

                    StatCard(
                        title: "Completion Rate",
                        value: taskVM.tasks.isEmpty ? "100%" : "\(Int((Double(taskVM.completedTasksCount) / Double(taskVM.tasks.count)) * 100))%",
                        subtitle: "\(taskVM.completedTasksCount) of \(taskVM.tasks.count) tasks done",
                        icon: "chart.pie.fill",
                        color: AppTheme.success
                    )
                }

                // Recent Sessions History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Focus Sessions")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    if timerVM.completedSessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.textTertiary)
                            Text("No sessions recorded yet")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Complete a session on the timer to view your session history here.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .calmCard(cornerRadius: 12)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(timerVM.completedSessions.reversed()) { session in
                                HStack(spacing: 12) {
                                    Image(systemName: session.mode.iconName)
                                        .foregroundStyle(session.mode.themeColor)
                                        .frame(width: 32, height: 32)
                                        .background(session.mode.themeColor.opacity(0.12))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.mode.rawValue)
                                            .font(.body.bold())
                                            .foregroundStyle(AppTheme.textPrimary)
                                        Text("Duration: \(session.durationSeconds / 60) minutes")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }

                                    Spacer()

                                    Text(session.completedAt, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                                .padding(12)
                                .calmCard(cornerRadius: 8)
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .background(AppTheme.background)
        .navigationTitle("Statistics")
    }
}
