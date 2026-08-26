import SwiftUI

public struct StatsView: View {
    var timerVM: FocusTimerViewModel
    var taskVM: TaskListViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Productivity & Analytics")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Track your historical focus output and habit consistency.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // Summary Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(
                        title: "Total Sessions",
                        value: "\(timerVM.completedSessionsCount)",
                        subtitle: "\(timerVM.completedWorkSessionsCount) deep focus cycles",
                        icon: "flame.fill",
                        color: .orange
                    )

                    StatCard(
                        title: "Accumulated Time",
                        value: "\(timerVM.todayFocusMinutes)m today",
                        subtitle: "Consistent progress",
                        icon: "hourglass",
                        color: .indigo
                    )

                    StatCard(
                        title: "Completion Rate",
                        value: taskVM.tasks.isEmpty ? "100%" : "\(Int((Double(taskVM.completedTasksCount) / Double(taskVM.tasks.count)) * 100))%",
                        subtitle: "\(taskVM.completedTasksCount) of \(taskVM.tasks.count) tasks done",
                        icon: "chart.pie.fill",
                        color: .green
                    )
                }

                // Recent Sessions History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Focus Sessions")
                        .font(.title2.bold())

                    if timerVM.completedSessions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("No sessions recorded yet")
                                .font(.headline)
                            Text("Complete a session on the timer to view your session history here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(Color.primary.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                        Text("Duration: \(session.durationSeconds / 60) minutes")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(session.completedAt, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .navigationTitle("Statistics")
    }
}
