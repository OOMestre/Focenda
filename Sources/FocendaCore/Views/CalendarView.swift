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
    public let dueTasksCount: Int
    public let hasDueTasks: Bool
    public let hasReminders: Bool
    public let hasHabitStreak: Bool

    public var focusHeatmapLevel: Int {
        if focusMinutes <= 0 { return 0 }
        if focusMinutes <= 25 { return 1 }
        if focusMinutes <= 60 { return 2 }
        return 3
    }

    public init(
        date: Date,
        dayNumber: Int,
        isCurrentMonth: Bool,
        isToday: Bool,
        isSelected: Bool,
        focusMinutes: Int,
        focusSessionsCount: Int,
        habitsCompletedCount: Int,
        tasksCount: Int,
        dueTasksCount: Int = 0,
        hasDueTasks: Bool = false,
        hasReminders: Bool = false,
        hasHabitStreak: Bool = false
    ) {
        self.date = date
        self.dayNumber = dayNumber
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.isSelected = isSelected
        self.focusMinutes = focusMinutes
        self.focusSessionsCount = focusSessionsCount
        self.habitsCompletedCount = habitsCompletedCount
        self.tasksCount = tasksCount
        self.dueTasksCount = dueTasksCount
        self.hasDueTasks = hasDueTasks
        self.hasReminders = hasReminders
        self.hasHabitStreak = hasHabitStreak
    }
}

/// Interactive monthly calendar and timebox agenda view with responsive split layout
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
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 760

            if isCompact {
                ScrollView {
                    VStack(spacing: 20) {
                        calendarMonthSection
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        Divider()
                            .background(AppTheme.border)
                            .padding(.horizontal, 16)

                        selectedDayAgendaSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                }
            } else {
                HStack(spacing: 0) {
                    // Left Column: Monthly Calendar & Navigation
                    ScrollView {
                        calendarMonthSection
                            .padding(20)
                    }
                    .frame(minWidth: 320, maxWidth: .infinity)

                    Divider()
                        .background(AppTheme.border)

                    // Right Column: Selected Day Agenda & Timebox Pane
                    ScrollView {
                        selectedDayAgendaSection
                            .padding(20)
                    }
                    .frame(minWidth: 300, idealWidth: 360, maxWidth: 420)
                    .background(AppTheme.cardBackgroundSubtle.opacity(0.35))
                }
            }
        }
        .background(AppTheme.background)
        .navigationTitle("Calendar & Agenda")
    }

    // MARK: - Left Pane: Calendar Month View
    private var calendarMonthSection: some View {
        VStack(alignment: .leading, spacing: 18) {
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
    }

    // MARK: - Month Header Bar
    private var monthHeaderBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(formattedMonthTitle(from: displayedMonth))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Focus consistency & daily timebox breakdown")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                // Previous Month Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        previousMonth()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
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
                        .font(.system(size: 11, weight: .bold))
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
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 28), spacing: 6), count: 7), spacing: 6) {
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

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 28), spacing: 6), count: 7), spacing: 6) {
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
            VStack(spacing: 3) {
                // Day Number + Today / Streak / Reminder Indicator
                HStack(spacing: 2) {
                    Text("\(day.dayNumber)")
                        .font(.system(size: 12, weight: day.isToday ? .heavy : (day.isSelected ? .bold : .medium), design: .rounded))
                        .foregroundStyle(
                            day.isSelected
                                ? .white
                                : (day.isCurrentMonth ? AppTheme.textPrimary : AppTheme.textTertiary.opacity(0.5))
                        )

                    if day.isToday && !day.isSelected {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 4, height: 4)
                    }

                    Spacer(minLength: 0)

                    if day.hasReminders {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(day.isSelected ? .white.opacity(0.9) : AppTheme.sandstone)
                    }

                    if day.hasHabitStreak {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(day.isSelected ? .white : AppTheme.sandstone)
                    }
                }

                Spacer(minLength: 1)

                // Heatmap dots & task indicators (Focus + Due Tasks + Tasks)
                HStack(spacing: 3) {
                    // Focus Heatmap indicator
                    if day.focusHeatmapLevel > 0 {
                        Circle()
                            .fill(heatmapDotColor(level: day.focusHeatmapLevel, isSelected: day.isSelected))
                            .frame(width: 5, height: 5)
                    }

                    // Due Tasks indicator (amber / sandstone dot)
                    if day.hasDueTasks {
                        Circle()
                            .fill(day.isSelected ? Color.white : AppTheme.sandstone)
                            .frame(width: 4, height: 4)
                    }

                    // Tasks indicator
                    if day.tasksCount > day.dueTasksCount || (!day.hasDueTasks && day.tasksCount > 0) {
                        Circle()
                            .fill(day.isSelected ? Color.white.opacity(0.85) : AppTheme.riverSlate)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(6)
            .frame(minHeight: 44, idealHeight: 48)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        day.isSelected
                            ? AppTheme.accent
                            : (day.isToday
                                ? AppTheme.accent.opacity(0.12)
                                : (isHovered ? AppTheme.cardBackgroundSubtle : AppTheme.cardBackground))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        day.isSelected
                            ? AppTheme.accent
                            : (day.isToday ? AppTheme.accent.opacity(0.4) : AppTheme.subtleBorder),
                        lineWidth: day.isToday ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: Color.black.opacity(day.isSelected ? 0.10 : (isHovered ? 0.04 : 0.0)),
                radius: day.isSelected ? 3 : 1,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredDate = hovering ? day.date : nil
        }
        .help("\(formattedFullDate(day.date)): \(day.focusMinutes)m focus, \(day.habitsCompletedCount) habits, \(day.tasksCount) tasks\(day.dueTasksCount > 0 ? ", \(day.dueTasksCount) due" : "")\(day.hasReminders ? ", has reminders" : "")")
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
        HStack(spacing: 10) {
            Text("Focus:")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 4) {
                Circle().fill(AppTheme.border).frame(width: 6, height: 6)
                Text("0m")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 4) {
                Circle().fill(AppTheme.shortBreak).frame(width: 6, height: 6)
                Text("1-25m")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 4) {
                Circle().fill(AppTheme.deepFocus).frame(width: 6, height: 6)
                Text("26-60m")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 4) {
                Circle().fill(AppTheme.success).frame(width: 6, height: 6)
                Text("60m+")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer(minLength: 4)

            HStack(spacing: 3) {
                Circle().fill(AppTheme.sandstone).frame(width: 5, height: 5)
                Text("Due Task")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(AppTheme.sandstone)
                Text("Habit Done")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.cardBackgroundSubtle.opacity(0.5))
        )
    }

    // MARK: - Monthly Summary Cards
    private var monthlySummaryCards: some View {
        let stats = calculateMonthlyStats(for: displayedMonth)

        return LazyVGrid(columns: [
            GridItem(.flexible(minimum: 90), spacing: 8),
            GridItem(.flexible(minimum: 90), spacing: 8),
            GridItem(.flexible(minimum: 90), spacing: 8)
        ], spacing: 8) {
            monthlyStatCard(
                title: "Month Focus",
                value: "\(stats.totalFocusMinutes) min",
                subtitle: "\(stats.sessionsCount) sessions",
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
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Right Pane: Selected Day Agenda & Timebox
    private var selectedDayAgendaSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Selected Day Header Banner
            selectedDayHeaderBanner

            // Focus Sessions Log
            focusSessionsLogSection

            // Daily Habits Consistency
            dailyHabitsSection

            // Scheduled & Completed Tasks
            dailyTasksSection
        }
    }

    // MARK: - Selected Day Header Banner
    private var selectedDayHeaderBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(formattedDayHeader(selectedDate))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(relativeDayLabel(selectedDate))
                            .font(.system(size: 9, weight: .bold))
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

                Spacer(minLength: 8)
            }

            // Summary Metric Chips
            let dayFocusMinutes = focusMinutes(for: selectedDate)
            let dayHabits = habitsCompleted(for: selectedDate)
            let dayTasks = tasks(for: selectedDate)

            HStack(spacing: 6) {
                agendaChip(
                    icon: "timer",
                    label: "\(dayFocusMinutes)m",
                    color: AppTheme.deepFocus
                )

                agendaChip(
                    icon: "flame.fill",
                    label: "\(dayHabits.count)/\(habitVM.habits.count)",
                    color: AppTheme.sandstone
                )

                agendaChip(
                    icon: "checklist",
                    label: "\(dayTasks.filter(\.isCompleted).count)/\(dayTasks.count)",
                    color: AppTheme.success
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    private func agendaChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - ⏱️ Focus Sessions Log Section
    private var focusSessionsLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Focus Sessions", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                let sessions = sessions(for: selectedDate)
                Text("\(sessions.count) logged")
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
                VStack(spacing: 6) {
                    ForEach(daySessions) { session in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(session.mode.themeColor)
                                .frame(width: 7, height: 7)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(session.mode.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(formattedSessionTime(session.completedAt))
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }

                            Spacer()

                            Text("\(session.durationSeconds / 60) min")
                                .font(.system(size: 10, weight: .bold))
                                .monospacedDigit()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(session.mode.themeColor.opacity(0.12))
                                .foregroundStyle(session.mode.themeColor)
                                .clipShape(Capsule())
                        }
                        .padding(8)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Habits", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
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

                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    habitVM.toggleHabitCompletion(id: habit.id, on: selectedDate, calendar: calendar)
                                }
                            } label: {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.body)
                                    .foregroundStyle(isDone ? AppTheme.success : AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .help(isDone ? "Mark habit incomplete" : "Mark habit completed on this day")

                            Image(systemName: habit.iconName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(habit.color)
                                .frame(width: 22, height: 22)
                                .background(habit.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                            Text(habit.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            if habit.streakCount > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 7))
                                        .foregroundStyle(AppTheme.sandstone)
                                    Text("\(habit.streakCount)d")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                        }
                        .padding(8)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Tasks & Milestones", systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                let dayTasks = tasks(for: selectedDate)
                Text("\(dayTasks.count) tasks")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // Quick Add Task for this Day
            HStack(spacing: 6) {
                TextField("Add task for \(formattedDayHeader(selectedDate))...", text: $quickTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .padding(6)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
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
                .frame(width: 80)

                Button {
                    addQuickTaskForSelectedDay()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
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
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    taskVM.toggleTaskCompletion(task)
                                }
                            } label: {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.body)
                                    .foregroundStyle(task.isCompleted ? AppTheme.success : AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(task.title)
                                    .font(.caption.weight(.medium))
                                    .strikethrough(task.isCompleted, color: AppTheme.textSecondary)
                                    .foregroundStyle(task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                                    .lineLimit(1)

                                if !task.notes.isEmpty {
                                    Text(task.notes)
                                        .font(.system(size: 9))
                                        .foregroundStyle(AppTheme.textTertiary)
                                        .lineLimit(1)
                                }

                                // Badges: Due Date Badge and Reminder Badge
                                HStack(spacing: 4) {
                                    if let dueBadge = dueDateBadge(for: task, on: selectedDate) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 7, weight: .semibold))
                                            Text(dueBadge.text)
                                                .font(.system(size: 8, weight: .semibold))
                                        }
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(dueBadge.color.opacity(0.12))
                                        .foregroundStyle(dueBadge.color)
                                        .clipShape(Capsule())
                                    }

                                    if let reminderText = reminderBadge(for: task) {
                                        Text(reminderText)
                                            .font(.system(size: 8, weight: .semibold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(AppTheme.sandstone.opacity(0.12))
                                            .foregroundStyle(AppTheme.sandstone)
                                            .clipShape(Capsule())
                                    }
                                }
                            }

                            Spacer()

                            Text(task.priority.rawValue)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(task.priority.color.opacity(0.12))
                                .foregroundStyle(task.priority.color)
                                .clipShape(Capsule())
                        }
                        .padding(8)
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
            priority: quickTaskPriority,
            dueDate: selectedDate
        )
        quickTaskTitle = ""
    }

    private func emptyAgendaCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(AppTheme.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(10)
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

            let dueTasks = tasksList.filter { task in
                if let due = task.dueDate {
                    return calendar.isDate(due, inSameDayAs: currentDate)
                }
                return false
            }
            let hasReminders = tasksList.contains { task in
                if let rem = task.reminderDate {
                    return calendar.isDate(rem, inSameDayAs: currentDate)
                }
                return false
            }

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
                dueTasksCount: dueTasks.count,
                hasDueTasks: !dueTasks.isEmpty,
                hasReminders: hasReminders,
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
            if let dueDate = task.dueDate, calendar.isDate(dueDate, inSameDayAs: date) {
                return true
            }
            if let reminderDate = task.reminderDate, calendar.isDate(reminderDate, inSameDayAs: date) {
                return true
            }
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

    public func dueDateBadge(for task: TaskItem, on referenceDate: Date = Date()) -> (text: String, color: Color)? {
        guard let dueDate = task.dueDate else { return nil }

        let startOfDue = calendar.startOfDay(for: dueDate)
        let startOfToday = calendar.startOfDay(for: Date())

        if !task.isCompleted && startOfDue < startOfToday {
            return ("Overdue", AppTheme.terracotta)
        }

        if calendar.isDate(dueDate, inSameDayAs: referenceDate) {
            if calendar.isDateInToday(dueDate) {
                return ("Due Today", AppTheme.sandstone)
            } else if calendar.isDateInTomorrow(dueDate) {
                return ("Due Tomorrow", AppTheme.sandstone)
            } else {
                return ("Due on this day", AppTheme.sandstone)
            }
        } else if calendar.isDateInTomorrow(dueDate) {
            return ("Due Tomorrow", AppTheme.sandstone)
        } else if calendar.isDateInToday(dueDate) {
            return ("Due Today", AppTheme.sandstone)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return ("Due \(formatter.string(from: dueDate))", AppTheme.sandstone)
        }
    }

    public func reminderBadge(for task: TaskItem) -> String? {
        guard let reminderDate = task.reminderDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "🔔 \(formatter.string(from: reminderDate))"
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
