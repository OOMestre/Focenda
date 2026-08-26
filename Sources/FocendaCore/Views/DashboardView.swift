import SwiftUI

public struct DashboardView: View {
    @Bindable var appState: AppState
    var timerVM: FocusTimerViewModel
    var taskVM: TaskListViewModel
    var habitVM: HabitViewModel

    public init(
        appState: AppState,
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel,
        habitVM: HabitViewModel = HabitViewModel()
    ) {
        self.appState = appState
        self.timerVM = timerVM
        self.taskVM = taskVM
        self.habitVM = habitVM
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                statsGridSection
                timerBannerSection
                habitsSummarySection
                featuredTasksSection
            }
            .padding(28)
        }
        .background(AppTheme.background)
        .navigationTitle("Dashboard")
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 16) {
                // Subtle organic icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
                        )

                    Image(systemName: greetingIcon)
                        .font(.title2)
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(greetingTitle)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Track your daily focus flow and accomplish your high-impact goals.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
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
            .tint(AppTheme.deepFocus)
            .controlSize(.large)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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
                color: AppTheme.deepFocus
            )

            StatCard(
                title: "Focus Sessions",
                value: "\(timerVM.completedWorkSessionsCount)",
                subtitle: "\(timerVM.completedSessionsCount) total cycles",
                icon: "brain.head.profile",
                color: AppTheme.shortBreak
            )

            StatCard(
                title: "Pending Tasks",
                value: "\(taskVM.pendingTasksCount)",
                subtitle: "\(taskVM.highPriorityPendingCount) high priority",
                icon: "checklist",
                color: AppTheme.sandstone
            )

            StatCard(
                title: "Completed Tasks",
                value: "\(taskVM.completedTasksCount)",
                subtitle: "Keep up the momentum!",
                icon: "checkmark.seal.fill",
                color: AppTheme.success
            )
        }
    }

    // MARK: - Timer Banner
    private var timerBannerSection: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(timerVM.status == .running ? AppTheme.success : timerVM.currentMode.themeColor)
                        .frame(width: 8, height: 8)

                    Text(timerVM.status == .running ? "Active Session" : "Current Focus Session")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Text(timerVM.currentMode.motivationalMessage)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
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
                                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
                .help(timerVM.status == .running ? "Pause" : "Start")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.035), radius: 4, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(timerVM.currentMode.themeColor.opacity(0.22), lineWidth: 1)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: timerVM.currentMode)
    }

    // MARK: - Habits Summary Section
    private var habitsSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("Daily Habit Streaks")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    if !habitVM.habits.isEmpty {
                        Text("\(habitVM.totalCompletionsToday)/\(habitVM.habits.count) done today")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(habitVM.totalCompletionsToday == habitVM.habits.count ? AppTheme.success.opacity(0.15) : AppTheme.accent.opacity(0.12))
                            )
                            .foregroundStyle(habitVM.totalCompletionsToday == habitVM.habits.count ? AppTheme.success : AppTheme.accent)
                    }
                }

                Spacer()

                Button("View all") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        appState.selectedTab = .habits
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
                .font(.subheadline.weight(.medium))
            }

            if habitVM.habits.isEmpty {
                emptyHabitsSummaryView
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(habitVM.habits.prefix(3)) { habit in
                        DashboardHabitCard(habit: habit) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                habitVM.toggleHabitCompletion(id: habit.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyHabitsSummaryView: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame")
                .font(.title)
                .foregroundStyle(AppTheme.sandstone)
            VStack(alignment: .leading, spacing: 2) {
                Text("No active habits")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Start tracking daily routines to unlock consistency streaks.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Button("Explore Habits") {
                appState.selectedTab = .habits
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .calmCard(cornerRadius: 12)
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
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Button("View all") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        appState.selectedTab = .tasks
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
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
                .font(.system(size: 38))
                .foregroundStyle(AppTheme.success)
            Text("All tasks completed!")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("Enjoy your free time or add new goals.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .calmCard(cornerRadius: 12)
    }
}

// MARK: - Dashboard Habit Mini Card

private struct DashboardHabitCard: View {
    let habit: HabitItem
    let onToggle: () -> Void

    @State private var isHovered = false
    @State private var isBouncing = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: habit.iconName)
                .font(.headline)
                .foregroundStyle(habit.color)
                .frame(width: 34, height: 34)
                .background(habit.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(habit.streakCount > 0 ? AppTheme.sandstone : AppTheme.textTertiary)
                    Text("\(habit.streakCount)d streak")
                        .font(.caption2)
                        .foregroundStyle(habit.streakCount > 0 ? AppTheme.sandstone : AppTheme.textSecondary)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    isBouncing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBouncing = false
                }
                onToggle()
            } label: {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(habit.isCompletedToday ? AppTheme.success : AppTheme.textTertiary)
                    .scaleEffect(isBouncing ? 1.25 : 1.0)
            }
            .buttonStyle(.plain)
            .help(habit.isCompletedToday ? "Completed today" : "Mark as completed today")
        }
        .padding(12)
        .calmCard(isHovered: isHovered, cornerRadius: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    habit.isCompletedToday ? AppTheme.success.opacity(0.3) : AppTheme.subtleBorder,
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            isHovered = hovering
        }
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
                    .foregroundStyle(task.isCompleted ? AppTheme.success : AppTheme.textTertiary)
                    .scaleEffect(isChecking ? 1.25 : 1.0)
            }
            .buttonStyle(.plain)
            .help(task.isCompleted ? "Mark as active" : "Mark as completed")

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body.weight(task.isCompleted ? .regular : .medium))
                    .strikethrough(task.isCompleted, color: AppTheme.textSecondary)
                    .foregroundStyle(task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
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
            .background(task.priority.color.opacity(0.12))
            .foregroundStyle(task.priority.color)
            .clipShape(Capsule())
        }
        .padding(14)
        .calmCard(isHovered: isHovered, cornerRadius: 10)
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
