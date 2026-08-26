import SwiftUI

public struct DashboardView: View {
    @Bindable var appState: AppState
    var timerVM: FocusTimerViewModel
    var taskVM: TaskListViewModel

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                statsGridSection
                timerBannerSection
                featuredTasksSection
            }
            .padding(28)
        }
        .navigationTitle("Dashboard")
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ready to focus?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Track your daily progress and reach your goals effortlessly.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                appState.selectedTab = .timer
                if timerVM.status != .running {
                    timerVM.start()
                }
            } label: {
                Label("Start Focus", systemImage: "play.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: - Stats Grid
    private var statsGridSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Focus Time Today",
                value: "\(timerVM.todayFocusMinutes) min",
                subtitle: "Goal: \(appState.dailyFocusGoalMinutes) min",
                icon: "clock.badge.checkmark.fill",
                color: .indigo
            )

            StatCard(
                title: "Focus Sessions",
                value: "\(timerVM.completedWorkSessionsCount)",
                subtitle: "\(timerVM.completedSessionsCount) total cycles",
                icon: "brain.head.profile",
                color: .teal
            )

            StatCard(
                title: "Pending Tasks",
                value: "\(taskVM.pendingTasksCount)",
                subtitle: "\(taskVM.highPriorityPendingCount) high priority",
                icon: "checklist",
                color: .orange
            )

            StatCard(
                title: "Completed Tasks",
                value: "\(taskVM.completedTasksCount)",
                subtitle: "Keep up the momentum!",
                icon: "checkmark.seal.fill",
                color: .green
            )
        }
    }

    // MARK: - Timer Banner
    private var timerBannerSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Focus Session")
                    .font(.headline)
                Text(timerVM.currentMode.motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Text(timerVM.formattedTimeRemaining)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(timerVM.currentMode.themeColor)

                Button {
                    if timerVM.status == .running {
                        timerVM.pause()
                    } else {
                        timerVM.start()
                    }
                } label: {
                    Image(systemName: timerVM.status == .running ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(timerVM.currentMode.themeColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(timerVM.currentMode.themeColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Featured Tasks
    private var featuredTasks: [TaskItem] {
        let pending = taskVM.tasks.filter { !$0.isCompleted }
        return Array(pending.prefix(4))
    }

    private var featuredTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured Tasks")
                    .font(.title2.bold())

                Spacer()

                Button("View all") {
                    appState.selectedTab = .tasks
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }

            if featuredTasks.isEmpty {
                emptyTasksView
            } else {
                VStack(spacing: 8) {
                    ForEach(featuredTasks) { task in
                        taskRow(task)
                    }
                }
            }
        }
    }

    private var emptyTasksView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("All tasks completed!")
                .font(.headline)
            Text("Enjoy your free time or add new goals.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func taskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button {
                taskVM.toggleTaskCompletion(task)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: task.priority.icon)
                Text(task.priority.rawValue)
            }
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(task.priority.color.opacity(0.15))
            .foregroundStyle(task.priority.color)
            .clipShape(Capsule())
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}
