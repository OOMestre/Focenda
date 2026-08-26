import SwiftUI

public struct DashboardView: View {
    @Bindable var appState: AppState
    var timerVM: FocusTimerViewModel
    var taskVM: TaskListViewModel

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
        HStack(alignment: .center) {
            HStack(spacing: 16) {
                // Subtle icon flair
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.indigo, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.indigo.opacity(0.3), radius: 8, x: 0, y: 3)

                    Image(systemName: greetingIcon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(greetingTitle)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Track your daily focus flow and accomplish your high-impact goals.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                appState.selectedTab = .timer
                if timerVM.status != .running {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        timerVM.start()
                    }
                }
            } label: {
                Label("Start Focus", systemImage: "play.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .shadow(color: Color.accentColor.opacity(0.25), radius: 6, x: 0, y: 2)
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "sun.max.fill"
        case 12..<17:
            return "sun.horizon.fill"
        case 17..<22:
            return "moon.stars.fill"
        default:
            return "sparkles"
        }
    }

    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Ready to Focus"
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
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(timerVM.status == .running ? Color.green : timerVM.currentMode.themeColor)
                        .frame(width: 9, height: 9)
                        .shadow(color: (timerVM.status == .running ? Color.green : timerVM.currentMode.themeColor).opacity(0.6), radius: 4, x: 0, y: 0)

                    Text(timerVM.status == .running ? "Active Session" : "Current Focus Session")
                        .font(.headline)
                }

                Text(timerVM.currentMode.motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 14) {
                Text(timerVM.formattedTimeRemaining)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(timerVM.currentMode.themeColor)
                    .contentTransition(.numericText())

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
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(timerVM.currentMode.themeColor)
                                .shadow(color: timerVM.currentMode.themeColor.opacity(0.35), radius: 6, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
                .help(timerVM.status == .running ? "Pause" : "Start")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(timerVM.currentMode.themeColor.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            timerVM.currentMode.themeColor.opacity(0.35),
                            timerVM.currentMode.themeColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: timerVM.currentMode)
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        appState.selectedTab = .tasks
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .font(.subheadline.weight(.medium))
            }

            if featuredTasks.isEmpty {
                emptyTasksView
            } else {
                VStack(spacing: 8) {
                    ForEach(featuredTasks) { task in
                        FeaturedTaskRowView(task: task) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                taskVM.toggleTaskCompletion(task)
                            }
                        }
                    }
                }
                .animation(.default, value: featuredTasks)
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
}

// MARK: - Featured Task Row View

private struct FeaturedTaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void

    @State private var isHovered: Bool = false
    @State private var isChecking: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    isChecking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isChecking = false
                }
                onToggle()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? Color.green : Color.secondary)
                    .scaleEffect(isChecking ? 1.3 : 1.0)
            }
            .buttonStyle(.plain)
            .help(task.isCompleted ? "Mark as active" : "Mark as completed")

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body.weight(task.isCompleted ? .regular : .medium))
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

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
            .background(task.priority.color.opacity(0.14))
            .foregroundStyle(task.priority.color)
            .clipShape(Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor) : Color.primary.opacity(0.02))
                .shadow(
                    color: isHovered ? Color.black.opacity(0.06) : Color.clear,
                    radius: 6,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(isHovered ? 0.14 : 0.04),
                            Color.primary.opacity(isHovered ? 0.06 : 0.01)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
