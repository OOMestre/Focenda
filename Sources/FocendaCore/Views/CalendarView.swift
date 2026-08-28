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
    public let tasksCount: Int
    public let dueTasksCount: Int
    public let hasDueTasks: Bool
    public let hasReminders: Bool
    public let recurringRemindersCount: Int
    public let hasRecurringReminders: Bool

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
        tasksCount: Int,
        dueTasksCount: Int = 0,
        hasDueTasks: Bool = false,
        hasReminders: Bool = false,
        recurringRemindersCount: Int = 0,
        hasRecurringReminders: Bool = false
    ) {
        self.date = date
        self.dayNumber = dayNumber
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.isSelected = isSelected
        self.focusMinutes = focusMinutes
        self.focusSessionsCount = focusSessionsCount
        self.tasksCount = tasksCount
        self.dueTasksCount = dueTasksCount
        self.hasDueTasks = hasDueTasks
        self.hasReminders = hasReminders
        self.recurringRemindersCount = recurringRemindersCount
        self.hasRecurringReminders = hasRecurringReminders
    }
}

/// Interactive monthly calendar, hover popover previews, and timebox agenda view with recurring reminders
public struct CalendarView: View {
    private enum CalendarQuickAction: String, Identifiable {
        case task
        case reminder

        var id: String { rawValue }
    }

    private enum QuickActionField: Hashable {
        case taskTitle
        case reminderTitle
    }

    public var timerVM: FocusTimerViewModel
    public var taskVM: TaskListViewModel
    public var recurringReminderVM: RecurringReminderViewModel

    @State public var selectedDate: Date
    @State public var displayedMonth: Date
    @State private var quickTaskTitle: String = ""
    @State private var quickTaskPriority: TaskPriority = .medium
    @State private var activeQuickAction: CalendarQuickAction? = nil
    @FocusState private var focusedQuickActionField: QuickActionField?
    @State private var hoveredDate: Date? = nil
    @State private var hoveredPopoverDay: CalendarDay? = nil
    @State private var pinnedPopoverDate: Date? = nil
    @State private var hoverDebounceTask: Task<Void, Never>? = nil

    // Recurring reminder creation state
    @State private var isAddingRecurringReminder: Bool = false
    @State private var newReminderTitle: String = ""
    @State private var newReminderTime: Date = Date()
    @State private var newReminderFrequency: RepeatFrequency = .daily
    @State private var newReminderNotes: String = ""

    // In-app alert banner
    @State private var activeAlertBanner: (title: String, subtitle: String, time: String)? = nil

    private let calendar: Calendar = .current
    /// The smallest practical width for the seven-day grid, including the monthly summary.
    /// Below this width the calendar remains usable through an explicit horizontal fallback.
    private let minimumCalendarContentWidth: CGFloat = 320

    public init(
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel,
        recurringReminderVM: RecurringReminderViewModel = RecurringReminderViewModel(),
        initialDate: Date = Date()
    ) {
        self.timerVM = timerVM
        self.taskVM = taskVM
        self.recurringReminderVM = recurringReminderVM
        let startOfDay = Calendar.current.startOfDay(for: initialDate)
        _selectedDate = State(initialValue: startOfDay)
        let comp = Calendar.current.dateComponents([.year, .month], from: initialDate)
        _displayedMonth = State(initialValue: Calendar.current.date(from: comp) ?? startOfDay)
    }

    public var body: some View {
        GeometryReader { geometry in
            let availableContentWidth = max(0, geometry.size.width - 40)
            let requiresHorizontalFallback = availableContentWidth < minimumCalendarContentWidth

            VStack(spacing: 0) {
                // In-App Reminder Alert Banner (if active)
                if let alert = activeAlertBanner {
                    reminderBannerCard(title: alert.title, subtitle: alert.subtitle, time: alert.time)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // The calendar and agenda share one vertical scroll area.  A horizontal
                // fallback is kept only for windows too narrow for a seven-day grid.
                ScrollView(.vertical, showsIndicators: true) {
                    if requiresHorizontalFallback {
                        ScrollView(.horizontal, showsIndicators: true) {
                            calendarAndAgendaContent
                                .frame(width: minimumCalendarContentWidth, alignment: .topLeading)
                                .padding(20)
                        }
                        .forceVisibleScrollers(horizontal: true, vertical: false)
                    } else {
                        calendarAndAgendaContent
                            .frame(width: availableContentWidth, alignment: .topLeading)
                            .padding(20)
                    }
                }
                .forceVisibleScrollers(horizontal: false, vertical: true)
            }
        }
        .background(AppTheme.background)
        .navigationTitle("Calendar & Schedule")
        .onReceive(NotificationCenter.default.publisher(for: NotificationManager.reminderAlertBannerNotification)) { notif in
            let title = notif.userInfo?["title"] as? String ?? "Reminder"
            let subtitle = notif.userInfo?["subtitle"] as? String ?? "Focenda Alert"
            let time = notif.userInfo?["time"] as? String ?? ""
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                activeAlertBanner = (title: title, subtitle: subtitle, time: time)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    activeAlertBanner = nil
                }
            }
        }
        .onDisappear {
            hoverDebounceTask?.cancel()
            hoverDebounceTask = nil
        }
        .sheet(item: $activeQuickAction) { action in
            quickActionForm(for: action)
        }
    }

    private var calendarAndAgendaContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            calendarMonthSection
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(AppTheme.border)

            selectedDayAgendaSection
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.cardBackgroundSubtle.opacity(0.35))
                )
        }
    }

    // MARK: - In-App Reminder Banner Card
    private func reminderBannerCard(title: String, subtitle: String, time: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.sandstone)
                .frame(width: 32, height: 32)
                .background(AppTheme.sandstone.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 4) {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textSecondary)

                    if !time.isEmpty {
                        Text("• \(time)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.sandstone)
                    }
                }
            }

            Spacer()

            Button {
                withAnimation { activeAlertBanner = nil }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.sandstone.opacity(0.4), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
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

                Text("Focus consistency, timebox breakdown & recurring reminders")
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
        let isPopoverPresented = isDayPopoverPresented(for: day)

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                selectedDate = day.date
                hoverDebounceTask?.cancel()
                hoverDebounceTask = nil
                hoveredPopoverDay = nil
                pinnedPopoverDate = day.date
                if !day.isCurrentMonth {
                    displayedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: day.date)) ?? displayedMonth
                }
            }
        } label: {
            VStack(spacing: 3) {
                // Day Number + Today / Reminder Indicator
                HStack(spacing: 2) {
                    Text("\(day.dayNumber)")
                        .font(.system(size: 12, weight: day.isToday ? .heavy : (day.isSelected ? .bold : .medium), design: .rounded))
                        .foregroundStyle(
                            day.isSelected
                                ? AppTheme.textOnAccent
                                : (day.isCurrentMonth ? AppTheme.textPrimary : AppTheme.textTertiary.opacity(0.5))
                        )

                    if day.isToday && !day.isSelected {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 4, height: 4)
                    }

                    Spacer(minLength: 0)

                    if day.hasRecurringReminders {
                        Image(systemName: "repeat")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(day.isSelected ? AppTheme.textOnAccent.opacity(0.9) : AppTheme.accent)
                    } else if day.hasReminders {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(day.isSelected ? AppTheme.textOnAccent.opacity(0.9) : AppTheme.sandstone)
                    }
                }

                Spacer(minLength: 1)

                // Heatmap dots & task indicators (Focus + Due Tasks + Tasks + Recurring)
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
                            .fill(day.isSelected ? AppTheme.textOnAccent : AppTheme.sandstone)
                            .frame(width: 4, height: 4)
                    }

                    // Recurring Reminders indicator
                    if day.hasRecurringReminders {
                        Circle()
                            .fill(day.isSelected ? AppTheme.textOnAccent : AppTheme.deepFocus)
                            .frame(width: 4, height: 4)
                    }

                    // Tasks indicator
                    if day.tasksCount > day.dueTasksCount || (!day.hasDueTasks && day.tasksCount > 0) {
                        Circle()
                            .fill(day.isSelected ? AppTheme.textOnAccent.opacity(0.85) : AppTheme.riverSlate)
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
                            : (day.isToday ? AppTheme.accent.opacity(0.4) : (isHovered ? AppTheme.accent.opacity(0.3) : AppTheme.subtleBorder)),
                        lineWidth: day.isToday ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: Color.black.opacity(day.isSelected ? 0.10 : (isHovered ? 0.05 : 0.0)),
                radius: day.isSelected ? 3 : 1,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if pinnedPopoverDate != nil {
                hoveredDate = nil
                return
            }

            hoveredDate = hovering ? day.date : nil
            if hovering {
                hoverDebounceTask?.cancel()
                hoverDebounceTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if !Task.isCancelled {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            hoveredPopoverDay = day
                        }
                    }
                }
            } else {
                hoverDebounceTask?.cancel()
                hoverDebounceTask = nil
                guard !keepsDayPopoverOpen(for: day.date, pinnedDate: pinnedPopoverDate) else { return }
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    hoveredPopoverDay = nil
                }
            }
        }
        .popover(
            isPresented: Binding(
                get: { isPopoverPresented },
                set: { presenting in
                    if !presenting {
                        hoverDebounceTask?.cancel()
                        if keepsDayPopoverOpen(for: day.date, pinnedDate: pinnedPopoverDate) {
                            pinnedPopoverDate = nil
                        }
                        if hoveredPopoverDay?.id == day.id {
                            hoveredPopoverDay = nil
                        }
                    }
                }
            ),
            arrowEdge: .top
        ) {
            dayHoverPreviewCard(for: day)
        }
        .help("\(formattedFullDate(day.date)): \(day.focusMinutes)m focus, \(day.tasksCount) tasks\(day.dueTasksCount > 0 ? ", \(day.dueTasksCount) due" : "")\(day.recurringRemindersCount > 0 ? ", \(day.recurringRemindersCount) reminders" : "")")
    }

    private func isDayPopoverPresented(for day: CalendarDay) -> Bool {
        keepsDayPopoverOpen(for: day.date, pinnedDate: pinnedPopoverDate)
            || hoveredPopoverDay?.id == day.id
    }

    /// A clicked day remains open while the pointer travels from the cell to its popover.
    /// This is internal so the interaction contract can be covered by unit tests.
    func keepsDayPopoverOpen(for date: Date, pinnedDate: Date?) -> Bool {
        guard let pinnedDate else { return false }
        return calendar.isDate(pinnedDate, inSameDayAs: date)
    }

    // MARK: - Day Hover Popover Preview Card
    private func dayHoverPreviewCard(for day: CalendarDay) -> some View {
        let dayTasks = tasks(for: day.date)
        let dayReminders = recurringReminderVM.reminders(for: day.date, calendar: calendar)
        let daySessions = sessions(for: day.date)
        let completedTaskCount = dayTasks.filter(\.isCompleted).count
        let isPinned = keepsDayPopoverOpen(for: day.date, pinnedDate: pinnedPopoverDate)

        return VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDayHeader(day.date))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(formattedFullDate(day.date))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer(minLength: 12)

                HStack(spacing: 6) {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .help("Preview pinned")
                    }

                    Text(relativeDayLabel(day.date))
                        .font(.system(size: 8, weight: .heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accent.opacity(0.15))
                        .foregroundStyle(AppTheme.accent)
                        .clipShape(Capsule())

                    Button {
                        dismissDayPopover()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.textTertiary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Close day preview")
                }
            }

            Divider()

            // Compact metrics summary
            HStack(spacing: 0) {
                dayPreviewMetric(
                    icon: "timer",
                    value: "\(day.focusMinutes)m",
                    label: "Focus",
                    color: AppTheme.deepFocus
                )

                Divider()
                    .frame(height: 24)

                dayPreviewMetric(
                    icon: "checklist",
                    value: "\(completedTaskCount)/\(dayTasks.count)",
                    label: "Tasks",
                    color: AppTheme.success
                )

                if !dayReminders.isEmpty {
                    Divider()
                        .frame(height: 24)

                    dayPreviewMetric(
                        icon: "repeat",
                        value: "\(dayReminders.count)",
                        label: "Reminders",
                        color: AppTheme.accent
                    )
                }
            }

            // Compact recurring reminder preview
            if !dayReminders.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                        Text("Reminders")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    ForEach(dayReminders.prefix(2)) { reminder in
                        dayPreviewRow(
                            icon: "bell.fill",
                            title: reminder.title,
                            detail: reminder.formattedTime,
                            color: AppTheme.accent
                        )
                    }

                    if dayReminders.count > 2 {
                        Text("+\(dayReminders.count - 2) more reminders")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }

            // Compact scheduled task preview
            if !dayTasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.success)
                        Text("Tasks")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    ForEach(dayTasks.prefix(2)) { task in
                        dayPreviewRow(
                            icon: task.isCompleted ? "checkmark.circle.fill" : "circle",
                            title: task.title,
                            detail: task.priority.rawValue,
                            color: task.isCompleted ? AppTheme.success : task.priority.color,
                            isCompleted: task.isCompleted
                        )
                    }

                    if dayTasks.count > 2 {
                        Text("+\(dayTasks.count - 2) more tasks")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            } else if dayReminders.isEmpty && daySessions.isEmpty {
                Text("Nothing scheduled for this day yet.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.vertical, 2)
            }

            // Keep focus history as a single line; the full breakdown lives below.
            if !daySessions.isEmpty {
                Text("\(daySessions.count) focus session\(daySessions.count == 1 ? "" : "s") recorded")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Divider()

            HStack(spacing: 6) {
                Label("Add to day", systemImage: "plus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer(minLength: 4)

                Button {
                    openQuickAction(.task, for: day.date)
                } label: {
                    Label("Task", systemImage: "checklist")
                        .font(.system(size: 9, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(AppTheme.accent)

                Button {
                    openQuickAction(.reminder, for: day.date)
                } label: {
                    Label("Reminder", systemImage: "bell.badge")
                        .font(.system(size: 9, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(AppTheme.sandstone)
            }
        }
        .padding(14)
        .frame(width: 300)
        .background(AppTheme.cardBackground)
    }

    private func dayPreviewMetric(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dayPreviewRow(
        icon: String,
        title: String,
        detail: String,
        color: Color,
        isCompleted: Bool = false
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 13)

            Text(title)
                .font(.system(size: 10))
                .strikethrough(isCompleted, color: AppTheme.textSecondary)
                .foregroundStyle(isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(detail)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    private func heatmapDotColor(level: Int, isSelected: Bool) -> Color {
        if isSelected {
            return AppTheme.textOnAccent
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
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                focusLegendItems
                Spacer(minLength: 4)
                reminderLegendItems
            }

            VStack(alignment: .leading, spacing: 5) {
                focusLegendItems
                reminderLegendItems
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.cardBackgroundSubtle.opacity(0.5))
        )
    }

    private var focusLegendItems: some View {
        HStack(spacing: 10) {
            Text("Focus:")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            heatmapLegendItem(color: AppTheme.border, label: "0m")
            heatmapLegendItem(color: AppTheme.shortBreak, label: "1-25m")
            heatmapLegendItem(color: AppTheme.deepFocus, label: "26-60m")
            heatmapLegendItem(color: AppTheme.success, label: "60m+")
        }
    }

    private var reminderLegendItems: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                Image(systemName: "repeat")
                    .font(.system(size: 8))
                    .foregroundStyle(AppTheme.accent)
                Text("Recurring")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            HStack(spacing: 3) {
                Circle().fill(AppTheme.sandstone).frame(width: 5, height: 5)
                Text("Due Task")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    private func heatmapLegendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textTertiary)
        }
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
                title: "Active Days",
                value: "\(stats.activeDays)",
                subtitle: "with deep focus",
                icon: "calendar.badge.clock",
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

            // Quick actions for the selected calendar day
            selectedDayQuickActions

            // Recurring Reminders for Day
            recurringRemindersSection

            // Focus Sessions Log
            focusSessionsLogSection

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
            let dayTasks = tasks(for: selectedDate)
            let dayReminders = recurringReminderVM.reminders(for: selectedDate, calendar: calendar)

            HStack(spacing: 6) {
                agendaChip(
                    icon: "timer",
                    label: "\(dayFocusMinutes)m focus",
                    color: AppTheme.deepFocus
                )

                agendaChip(
                    icon: "repeat",
                    label: "\(dayReminders.count) rem",
                    color: AppTheme.accent
                )

                agendaChip(
                    icon: "checklist",
                    label: "\(dayTasks.filter(\.isCompleted).count)/\(dayTasks.count) tasks",
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

    // MARK: - Selected Day Quick Actions
    private var selectedDayQuickActions: some View {
        HStack(spacing: 8) {
            Label("Quick actions", systemImage: "bolt.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer(minLength: 8)

            Button {
                openQuickAction(.task)
            } label: {
                Label("New Task", systemImage: "checklist")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(AppTheme.accent)
            .help("Create a task due on \(formattedFullDate(selectedDate))")

            Button {
                openQuickAction(.reminder)
            } label: {
                Label("New Reminder", systemImage: "bell.badge")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(AppTheme.sandstone)
            .help("Create a reminder for \(formattedFullDate(selectedDate))")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.cardBackgroundSubtle.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func quickActionForm(for action: CalendarQuickAction) -> some View {
        switch action {
        case .task:
            quickTaskForm
        case .reminder:
            quickReminderForm
        }
    }

    private var quickTaskForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            quickPopoverHeader(
                title: "New Task",
                subtitle: "Due \(formattedFullDate(selectedDate))",
                icon: "checklist",
                color: AppTheme.accent
            )

            TextField("Task title", text: $quickTaskTitle)
                .textFieldStyle(.roundedBorder)
                .focused($focusedQuickActionField, equals: .taskTitle)
                .onSubmit {
                    saveQuickTask()
                }

            Picker("Priority", selection: $quickTaskPriority) {
                ForEach(TaskPriority.allCases) { priority in
                    Text(priority.rawValue).tag(priority)
                }
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    closeQuickAction()
                }
                .buttonStyle(.bordered)

                Button("Create Task") {
                    saveQuickTask()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.textOnAccent)
                .keyboardShortcut(.defaultAction)
                .disabled(quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(AppTheme.cardBackground)
        .onAppear {
            DispatchQueue.main.async {
                focusedQuickActionField = .taskTitle
            }
        }
        .onDisappear {
            focusedQuickActionField = nil
        }
    }

    private var quickReminderForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            quickPopoverHeader(
                title: "New Reminder",
                subtitle: "Anchor date: \(formattedFullDate(selectedDate))",
                icon: "bell.badge",
                color: AppTheme.sandstone
            )

            TextField("Reminder title", text: $newReminderTitle)
                .textFieldStyle(.roundedBorder)
                .focused($focusedQuickActionField, equals: .reminderTitle)
                .onSubmit {
                    saveNewRecurringReminder()
                }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)

                    IntuitiveTimePicker("Reminder Time", selection: $newReminderTime, style: .compact)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Repeat")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)

                    Picker("Frequency", selection: $newReminderFrequency) {
                        ForEach(RepeatFrequency.allCases) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    .labelsHidden()
                }
            }

            Text("Choose how often this reminder repeats.")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)

            HStack {
                Spacer()

                Button("Cancel") {
                    closeQuickAction()
                }
                .buttonStyle(.bordered)

                Button("Create Reminder") {
                    saveNewRecurringReminder()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.sandstone)
                .foregroundStyle(AppTheme.textOnAccent)
                .keyboardShortcut(.defaultAction)
                .disabled(newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 330)
        .background(AppTheme.cardBackground)
        .onAppear {
            DispatchQueue.main.async {
                focusedQuickActionField = .reminderTitle
            }
        }
        .onDisappear {
            focusedQuickActionField = nil
        }
    }

    private func quickPopoverHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
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

    // MARK: - 🔔 Recurring Reminders Section
    private var recurringRemindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Recurring Reminders", systemImage: "repeat")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Button {
                    toggleRecurringReminderForm()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: isAddingRecurringReminder ? "xmark" : "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(isAddingRecurringReminder ? "Cancel" : "Add")
                            .font(.caption2.weight(.medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
            }

            if isAddingRecurringReminder {
                addRecurringReminderForm
            }

            let dayReminders = recurringReminderVM.reminders(for: selectedDate, calendar: calendar)
            if dayReminders.isEmpty {
                emptyAgendaCard(
                    icon: "bell.badge",
                    title: "No recurring reminders for this day",
                    subtitle: "Add a daily or repeating reminder above to stay on track."
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(dayReminders) { reminder in
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                    recurringReminderVM.toggleReminder(id: reminder.id)
                                }
                            } label: {
                                Image(systemName: reminder.isEnabled ? "checkmark.circle.fill" : "circle")
                                    .font(.body)
                                    .foregroundStyle(reminder.isEnabled ? AppTheme.accent : AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .help(reminder.isEnabled ? "Disable reminder" : "Enable reminder")

                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.title)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(reminder.isEnabled ? AppTheme.textPrimary : AppTheme.textSecondary)

                                if !reminder.notes.isEmpty {
                                    Text(reminder.notes)
                                        .font(.system(size: 9))
                                        .foregroundStyle(AppTheme.textTertiary)
                                }
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Text(reminder.formattedTime)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.cardBackgroundSubtle)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(reminder.repeatFrequency.rawValue)
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.accent.opacity(0.12))
                                    .foregroundStyle(AppTheme.accent)
                                    .clipShape(Capsule())
                            }
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

    private var addRecurringReminderForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Reminder title (e.g. Daily Standup)", text: $newReminderTitle)
                .textFieldStyle(.plain)
                .font(.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(6)
                .background(AppTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )

            HStack(spacing: 8) {
                IntuitiveTimePicker("Reminder Time", selection: $newReminderTime, style: .compact)

                Picker("Frequency", selection: $newReminderFrequency) {
                    ForEach(RepeatFrequency.allCases) { freq in
                        Text(freq.rawValue)
                            .foregroundStyle(AppTheme.textPrimary)
                            .tag(freq)
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .labelsHidden()

                Spacer()

                Button("Save Reminder") {
                    saveNewRecurringReminder()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.textOnAccent)
                .controlSize(.small)
                .disabled(newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.cardBackgroundSubtle.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
        )
    }

    private func saveNewRecurringReminder() {
        let trimmed = newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        recurringReminderVM.addReminder(
            title: trimmed,
            time: newReminderTime,
            repeatFrequency: newReminderFrequency,
            notes: newReminderNotes
        )

        newReminderTitle = ""
        newReminderNotes = ""
        isAddingRecurringReminder = false
        closeQuickAction()
    }

    // MARK: - ⏱️ Focus Sessions Log Section
    private var focusSessionsLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Focus Sessions", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                let sessionsList = sessions(for: selectedDate)
                Text("\(sessionsList.count) logged")
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

    // MARK: - Scheduled & Daily Tasks Section
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
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(6)
                    .background(AppTheme.inputBackground)
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
                        Text(priority.rawValue)
                            .foregroundStyle(AppTheme.textPrimary)
                            .tag(priority)
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.textPrimary)
                .labelsHidden()
                .frame(width: 80)

                Button {
                    addQuickTaskForSelectedDay()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textOnAccent)
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

    private func openQuickAction(_ action: CalendarQuickAction) {
        dismissDayPopover()

        switch action {
        case .task:
            quickTaskTitle = ""
            quickTaskPriority = .medium
        case .reminder:
            prepareNewRecurringReminder()
        }

        activeQuickAction = action
    }

    private func openQuickAction(_ action: CalendarQuickAction, for date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        if !calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: selectedDate)
            ) ?? displayedMonth
        }
        openQuickAction(action)
    }

    private func dismissDayPopover() {
        hoverDebounceTask?.cancel()
        hoverDebounceTask = nil
        hoveredDate = nil
        hoveredPopoverDay = nil
        pinnedPopoverDate = nil
    }

    private func closeQuickAction() {
        activeQuickAction = nil
        focusedQuickActionField = nil
    }

    private func saveQuickTask() {
        let trimmed = quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        taskVM.addTask(
            title: trimmed,
            priority: quickTaskPriority,
            dueDate: calendar.startOfDay(for: selectedDate)
        )
        quickTaskTitle = ""
        closeQuickAction()
    }

    private func toggleRecurringReminderForm() {
        if isAddingRecurringReminder {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                isAddingRecurringReminder = false
            }
            focusedQuickActionField = nil
        } else {
            prepareNewRecurringReminder()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                isAddingRecurringReminder = true
            }
        }
    }

    private func prepareNewRecurringReminder() {
        newReminderTitle = ""
        newReminderNotes = ""
        newReminderTime = defaultReminderDate(for: selectedDate, preservingTimeFrom: Date())
        newReminderFrequency = .daily
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
            let sessionsList = sessions(for: currentDate)
            let tasksList = tasks(for: currentDate)
            let recurringRemindersList = recurringReminderVM.reminders(for: currentDate, calendar: calendar)

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
                focusSessionsCount: sessionsList.count,
                tasksCount: tasksList.count,
                dueTasksCount: dueTasks.count,
                hasDueTasks: !dueTasks.isEmpty,
                hasReminders: hasReminders || !recurringRemindersList.isEmpty,
                recurringRemindersCount: recurringRemindersList.count,
                hasRecurringReminders: !recurringRemindersList.isEmpty
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

    /// Builds the initial reminder date from the selected day while preserving a useful time of day.
    /// The selected date is important for weekly and monthly recurrence matching.
    public func defaultReminderDate(for day: Date, preservingTimeFrom sourceDate: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: sourceDate)
        components.hour = timeComponents.hour ?? 9
        components.minute = timeComponents.minute ?? 0
        components.second = 0
        return calendar.date(from: components) ?? calendar.startOfDay(for: day)
    }

    public func calculateMonthlyStats(for month: Date) -> (totalFocusMinutes: Int, sessionsCount: Int, tasksCompleted: Int, activeDays: Int) {
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

        let tasksCompleted = taskVM.tasks.filter { task in
            if let completedAt = task.completedAt {
                return calendar.isDate(completedAt, equalTo: month, toGranularity: .month)
            }
            return false
        }.count

        return (
            totalFocusMinutes: totalFocusMinutes,
            sessionsCount: sessionsCount,
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
