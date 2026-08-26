import SwiftUI
import AppKit

/// Model representing a single day in the calendar grid
public struct CalendarDay: Identifiable, Equatable {
    public var id: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    public let date: Date
    public let dayNumber: Int
    public let isCurrentMonth: Bool
    public let isToday: Bool
    public let isSelected: Bool
    public let focusMinutes: Int
    public let focusSessionsCount: Int
    public let habitsCompletedCount: Int
    public let tasksCount: Int
    public let hasHabitStreak: Bool

    public var focusHeatmapLevel: Int {
        if focusMinutes <= 0 { return 0 }
        if focusMinutes <= 25 { return 1 }
        if focusMinutes <= 60 { return 2 }
        return 3
    }
}

/// Interactive monthly calendar and timebox agenda view
public struct CalendarView: View {
    public var timerVM: FocusTimerViewModel
    public var taskVM: TaskListViewModel
    public var habitVM: HabitViewModel

    @State public var selectedDate: Date
    @State public var displayedMonth: Date
    @State private var quickTaskTitle: String = ""
    @State private var quickTaskPriority: TaskPriority = .medium
    @State private var hoveredDate: Date? = nil

    private let calendar: Calendar = .current

    public init(
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel,
        habitVM: HabitViewModel = HabitViewModel(),
        initialDate: Date = Date()
    ) {
        self.timerVM = timerVM
        self.taskVM = taskVM
        self.habitVM = habitVM
        let startOfDay = Calendar.current.startOfDay(for: initialDate)
        _selectedDate = State(initialValue: startOfDay)
        let comp = Calendar.current.dateComponents([.year, .month], from: initialDate)
        _displayedMonth = State(initialValue: Calendar.current.date(from: comp) ?? startOfDay)
    }

    public var body: some View {
        HSplitView {
            // Left Column: Monthly Calendar & Navigation
            calendarMonthSection
                .frame(minWidth: 420, idealWidth: 480)
                .layoutPriority(1)

            // Right Column: Selected Day Agenda & Timebox Pane
            selectedDayAgendaSection
                .frame(minWidth: 360, idealWidth: 400)
        }
        .background(AppTheme.background)
        .navigationTitle("Calendar & Agenda")
    }

    // MARK: - Left Pane: Calendar Month View
    private var calendarMonthSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with navigation
                monthHeaderBar

                // Weekday Headers
                weekdayHeadersGrid

                // Monthly Grid of Days
                monthlyDaysGrid

                // Heatmap Legend
                heatmapLegendBar

                // Monthly Performance Highlights
                monthlySummaryCards
            }
            .padding(24)
        }
    }

    // MARK: - Month Header Bar
    private var monthHeaderBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(formattedMonthTitle(from: displayedMonth))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Focus consistency & daily timebox breakdown")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                // Previous Month Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        previousMonth()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Previous month")

                // Today Jump Button
                Button("Today") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        goToToday()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Jump to current day")

                // Next Month Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        nextMonth()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Next month")
            }
        }
    }

    // MARK: - Weekday Headers
    private var weekdayHeadersGrid: some View {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Monthly Days Grid
    private var monthlyDaysGrid: some View {
        let days = calculateDaysInMonth(for: displayedMonth)

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(days) { day in
                calendarDayCell(day: day)
            }
        }
    }

    private func calendarDayCell(day: CalendarDay) -> some View {
        let isHovered = hoveredDate != nil && calendar.isDate(hoveredDate!, inSameDayAs: day.date)

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                selectedDate = day.date
                if !day.isCurrentMonth {
                    displayedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: day.date)) ?? displayedMonth
                }
            }
        } label: {
            VStack(spacing: 4) {
                // Day Number + Today Badge
                HStack(spacing: 2) {
                    Text("\(day.dayNumber)")
                        .font(.system(size: 13, weight: day.isToday ? .heavy : (day.isSelected ? .bold : .medium), design: .rounded))
                        .foregroundStyle(
                            day.isSelected
                                ? .white
                                : (day.isCurrentMonth ? AppTheme.textPrimary : AppTheme.textTertiary.opacity(0.6))
                        )

                    if day.isToday && !day.isSelected {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 4, height: 4)
                    }

                    Spacer(minLength: 0)

                    if day.hasHabitStreak {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(day.isSelected ? .white : AppTheme.sandstone)
                    }
                }

                Spacer(minLength: 2)

                // Heatmap dots & indicators
                HStack(spacing: 3) {
                    // Focus Heatmap indicator
                    if day.focusHeatmapLevel > 0 {
                        Circle()
                            .fill(heatmapDotColor(level: day.focusHeatmapLevel, isSelected: day.isSelected))
                            .frame(width: 6, height: 6)
                    }

                    // Tasks indicator
                    if day.tasksCount > 0 {
                        Circle()
                            .fill(day.isSelected ? Color.white.opacity(0.8) : AppTheme.riverSlate)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(7)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        day.isSelected
                            ? AppTheme.accent
                            : (day.isToday
                                ? AppTheme.accent.opacity(0.12)
                                : (isHovered ? AppTheme.cardBackgroundSubtle : AppTheme.cardBackground))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        day.isSelected
                            ? AppTheme.accent
                            : (day.isToday ? AppTheme.accent.opacity(0.45) : AppTheme.subtleBorder),
                        lineWidth: day.isToday ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: Color.black.opacity(day.isSelected ? 0.12 : (isHovered ? 0.05 : 0.0)),
                radius: day.isSelected ? 4 : 2,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredDate = hovering ? day.date : nil
        }
        .help("\(formattedFullDate(day.date)): \(day.focusMinutes)m focus, \(day.habitsCompletedCount) habits, \(day.tasksCount) tasks")
    }

    private func heatmapDotColor(level: Int, isSelected: Bool) -> Color {
        if isSelected {
            return .white
        }
        switch level {
        case 1:
            return AppTheme.shortBreak
        case 2:
            return AppTheme.deepFocus
        case 3:
            return AppTheme.success
        default:
            return Color.clear
        }
    }

    // MARK: - Heatmap Legend
    private var heatmapLegendBar: some View {
        HStack(spacing: 12) {
            Text("Focus Intensity:")
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 5) {
                Circle().fill(AppTheme.border).frame(width: 7, height: 7)
                Text("0m")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 5) {
                Circle().fill(AppTheme.shortBreak).frame(width: 7, height: 7)
                Text("1-25m")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 5) {
                Circle().fill(AppTheme.deepFocus).frame(width: 7, height: 7)
                Text("26-60m")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 5) {
                Circle().fill(AppTheme.success).frame(width: 7, height: 7)
                Text("60m+")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(AppTheme.sandstone)
                Text("Habit Done")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.cardBackgroundSubtle.opacity(0.5))
        )
    }

    // MARK: - Monthly Summary Cards
    private var monthlySummaryCards: some View {
        let stats = calculateMonthlyStats(for: displayedMonth)

        return HStack(spacing: 12) {
            monthlyStatCard(
                title: "Month Focus",
                value: "\(stats.totalFocusMinutes) min",
                subtitle: "\(stats.sessionsCount) sessions logged",
                icon: "timer",
                color: AppTheme.deepFocus
            )

            monthlyStatCard(
                title: "Habits Completed",
                value: "\(stats.habitsCompleted)",
                subtitle: "\(stats.activeDays) active days",
                icon: "flame.fill",
                color: AppTheme.sandstone
            )

            monthlyStatCard(
                title: "Tasks Done",
                value: "\(stats.tasksCompleted)",
                subtitle: "in this month",
                icon: "checklist.checked",
                color: AppTheme.success
            )
        }
    }

    private func monthlyStatCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Right Pane: Selected Day Agenda & Timebox
    private var selectedDayAgendaSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Selected Day Header Banner
                selectedDayHeaderBanner

                // Focus Sessions Log
                focusSessionsLogSection

                // Daily Habits Consistency
                dailyHabitsSection

                // Scheduled & Completed Tasks
                dailyTasksSection
            }
            .padding(24)
        }
        .background(AppTheme.cardBackgroundSubtle.opacity(0.25))
    }

    // MARK: - Selected Day Header Banner
    private var selectedDayHeaderBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(formattedDayHeader(selectedDate))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(relativeDayLabel(selectedDate))
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                calendar.isDateInToday(selectedDate)
                                    ? AppTheme.accent.opacity(0.18)
                                    : AppTheme.cardBackgroundSubtle
                            )
                            .foregroundStyle(
                                calendar.isDateInToday(selectedDate)
                                    ? AppTheme.accent
                                    : AppTheme.textSecondary
                            )
                            .clipShape(Capsule())
                    }

                    Text(formattedFullDate(selectedDate))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }

            // Summary Metric Chips
            let dayFocusMinutes = focusMinutes(for: selectedDate)
            let dayHabits = habitsCompleted(for: selectedDate)
            let dayTasks = tasks(for: selectedDate)

            HStack(spacing: 8) {
                agendaChip(
                    icon: "timer",
                    label: "\(dayFocusMinutes)m focus",
                    color: AppTheme.deepFocus
                )

                agendaChip(
                    icon: "flame.fill",
                    label: "\(dayHabits.count)/\(habitVM.habits.count) habits",
                    color: AppTheme.sandstone
                )

                agendaChip(
                    icon: "checklist",
                    label: "\(dayTasks.filter(\.isCompleted).count)/\(dayTasks.count) tasks",
                    color: AppTheme.success
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    private func agendaChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - ⏱️ Focus Sessions Log Section
    private var focusSessionsLogSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Focus Sessions Log", systemImage: "timer")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                let sessions = sessions(for: selectedDate)
                Text("\(sessions.count) completed")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            let daySessions = sessions(for: selectedDate)
            if daySessions.isEmpty {
                emptyAgendaCard(
                    icon: "clock.badge.exclamationmark",
                    title: "No focus sessions logged",
                    subtitle: calendar.isDateInToday(selectedDate)
                        ? "Start the focus timer to record deep work on this day."
                        : "No recorded timer cycles for this date."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(daySessions) { session in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(session.mode.themeColor)
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(session.mode.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(formattedSessionTime(session.completedAt))
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }

                            Spacer()

                            Text("\(session.durationSeconds / 60) min")
                                .font(.caption.bold())
                                .monospacedDigit()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(session.mode.themeColor.opacity(0.12))
                                .foregroundStyle(session.mode.themeColor)
                                .clipShape(Capsule())
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppTheme.subtleBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - 🔥 Daily Habits Section
    private var dailyHabitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Habits Consistency", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                let done = habitsCompleted(for: selectedDate).count
                Text("\(done)/\(habitVM.habits.count) done")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if habitVM.habits.isEmpty {
                emptyAgendaCard(
                    icon: "flame",
                    title: "No habits tracked",
                    subtitle: "Create daily habits in the Habits tab."
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(habitVM.habits) { habit in
                        let isDone = habit.isCompleted(on: selectedDate, calendar: calendar)

                        HStack(spacing: 10) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    habitVM.toggleHabitCompletion(id: habit.id, on: selectedDate, calendar: calendar)
                                }
                            } label: {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isDone ? AppTheme.success : AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .help(isDone ? "Mark habit incomplete" : "Mark habit completed on this day")

                            Image(systemName: habit.iconName)
                                .font(.caption.bold())
                                .foregroundStyle(habit.color)
                                .frame(width: 24, height: 24)
                                .background(habit.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                            Text(habit.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)

                            Spacer()

                            if habit.streakCount > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(AppTheme.sandstone)
                                    Text("\(habit.streakCount)d")
                                        .font(.caption2.bold())
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isDone ? AppTheme.success.opacity(0.3) : AppTheme.subtleBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - ✅ Scheduled & Daily Tasks Section
    private var dailyTasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Tasks & Milestones", systemImage: "checklist")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                let dayTasks = tasks(for: selectedDate)
                Text("\(dayTasks.count) tasks")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // Quick Add Task for this Day
            HStack(spacing: 8) {
                TextField("Add task for \(formattedDayHeader(selectedDate))...", text: $quickTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .padding(8)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )
                    .onSubmit {
                        addQuickTaskForSelectedDay()
                    }

                // Priority Picker
                Picker("", selection: $quickTaskPriority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .labelsHidden()
                .frame(width: 88)

                Button {
                    addQuickTaskForSelectedDay()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            let dayTasks = tasks(for: selectedDate)
            if dayTasks.isEmpty {
                emptyAgendaCard(
                    icon: "checklist",
                    title: "No tasks scheduled",
                    subtitle: "Add a task above to schedule productivity for this day."
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(dayTasks) { task in
                        HStack(spacing: 10) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    taskVM.toggleTaskCompletion(task)
                                }
                            } label: {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(task.isCompleted ? AppTheme.success : AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.caption.weight(.medium))
                                    .strikethrough(task.isCompleted, color: AppTheme.textSecondary)
                                    .foregroundStyle(task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)

                                if !task.notes.isEmpty {
                                    Text(task.notes)
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                            }

                            Spacer()

                            Text(task.priority.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(task.priority.color.opacity(0.12))
                                .foregroundStyle(task.priority.color)
                                .clipShape(Capsule())
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppTheme.subtleBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func addQuickTaskForSelectedDay() {
        let trimmed = quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        taskVM.addTask(
            title: trimmed,
            priority: quickTaskPriority
        )
        quickTaskTitle = ""
    }

    private func emptyAgendaCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.cardBackground.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Calculations & Queries
    public func calculateDaysInMonth(for date: Date) -> [CalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }

        var days: [CalendarDay] = []
        var currentDate = monthFirstWeek.start

        while currentDate < monthLastWeek.end {
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: date, toGranularity: .month)
            let isToday = calendar.isDateInToday(currentDate)
            let isSelected = calendar.isDate(currentDate, inSameDayAs: selectedDate)
            let dayNumber = calendar.component(.day, from: currentDate)

            let focusMin = focusMinutes(for: currentDate)
            let sessions = sessions(for: currentDate)
            let habits = habitsCompleted(for: currentDate)
            let tasksList = tasks(for: currentDate)

            let day = CalendarDay(
                date: currentDate,
                dayNumber: dayNumber,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                focusMinutes: focusMin,
                focusSessionsCount: sessions.count,
                habitsCompletedCount: habits.count,
                tasksCount: tasksList.count,
                hasHabitStreak: !habits.isEmpty
            )
            days.append(day)

            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        return days
    }

    public func focusMinutes(for date: Date) -> Int {
        let sessionsOnDate = timerVM.completedSessions.filter {
            $0.mode == .work && calendar.isDate($0.completedAt, inSameDayAs: date)
        }
        let totalSeconds = sessionsOnDate.reduce(0) { $0 + $1.durationSeconds }
        return totalSeconds / 60
    }

    public func sessions(for date: Date) -> [FocusSession] {
        timerVM.completedSessions.filter {
            calendar.isDate($0.completedAt, inSameDayAs: date)
        }
    }

    public func habitsCompleted(for date: Date) -> [HabitItem] {
        habitVM.habits.filter {
            $0.isCompleted(on: date, calendar: calendar)
        }
    }

    public func tasks(for date: Date) -> [TaskItem] {
        taskVM.tasks.filter { task in
            if let completedAt = task.completedAt, calendar.isDate(completedAt, inSameDayAs: date) {
                return true
            }
            if calendar.isDate(task.createdAt, inSameDayAs: date) {
                return true
            }
            if calendar.isDateInToday(date) && !task.isCompleted {
                return true
            }
            return false
        }
    }

    public func calculateMonthlyStats(for month: Date) -> (totalFocusMinutes: Int, sessionsCount: Int, habitsCompleted: Int, tasksCompleted: Int, activeDays: Int) {
        let sessionsInMonth = timerVM.completedSessions.filter {
            calendar.isDate($0.completedAt, equalTo: month, toGranularity: .month)
        }
        let totalFocusMinutes = sessionsInMonth.filter { $0.mode == .work }.reduce(0) { $0 + $1.durationSeconds } / 60
        let sessionsCount = sessionsInMonth.count

        var activeDateSet = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for session in sessionsInMonth {
            activeDateSet.insert(formatter.string(from: session.completedAt))
        }

        var habitsDoneCount = 0
        for habit in habitVM.habits {
            for completedDate in habit.completedDates {
                if calendar.isDate(completedDate, equalTo: month, toGranularity: .month) {
                    habitsDoneCount += 1
                    activeDateSet.insert(formatter.string(from: completedDate))
                }
            }
        }

        let tasksCompleted = taskVM.tasks.filter { task in
            if let completedAt = task.completedAt {
                return calendar.isDate(completedAt, equalTo: month, toGranularity: .month)
            }
            return false
        }.count

        return (
            totalFocusMinutes: totalFocusMinutes,
            sessionsCount: sessionsCount,
            habitsCompleted: habitsDoneCount,
            tasksCompleted: tasksCompleted,
            activeDays: activeDateSet.count
        )
    }

    public func nextMonthDate(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    public func previousMonthDate(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }

    public func nextMonth() {
        displayedMonth = nextMonthDate(from: displayedMonth)
    }

    public func previousMonth() {
        displayedMonth = previousMonthDate(from: displayedMonth)
    }

    public func goToToday() {
        let today = Date()
        selectedDate = calendar.startOfDay(for: today)
        displayedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
    }

    // MARK: - Formatters
    public func formattedMonthTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    public func formattedDayHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    public func formattedFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    public func formattedSessionTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    public func relativeDayLabel(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "TODAY"
        } else if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        } else if calendar.isDateInTomorrow(date) {
            return "TOMORROW"
        } else if date < Date() {
            return "PAST"
        } else {
            return "UPCOMING"
        }
    }
}
