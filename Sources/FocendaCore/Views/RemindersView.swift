import SwiftUI
import AppKit

/// Filter categories for the Reminders & Alerts view
public enum ReminderFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case taskReminders = "Task Reminders"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .all: return "tray.full.fill"
        case .daily: return "repeat"
        case .weekdays: return "briefcase.fill"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .taskReminders: return "checklist"
        }
    }
}

/// Dedicated, first-class Reminders & Alerts center for Focenda
public struct RemindersView: View {
    @Bindable public var recurringReminderVM: RecurringReminderViewModel
    @Bindable public var taskVM: TaskListViewModel

    @State public var selectedFilter: ReminderFilter = .all
    @State public var searchQuery: String = ""
    @State public var showingAddSheet: Bool = false
    @State public var editingReminder: RecurringReminder? = nil
    @State private var playingChimeId: UUID? = nil

    // Form fields for Add / Edit sheet
    @State private var formTitle: String = ""
    @State private var formTime: Date = Date()
    @State private var formFrequency: RepeatFrequency = .daily
    @State private var formNotes: String = ""
    @State private var formIsEnabled: Bool = true

    // Active in-app alert banner
    @State private var activeAlertBanner: (title: String, subtitle: String, time: String)? = nil

    private let calendar: Calendar = .current

    public init(
        recurringReminderVM: RecurringReminderViewModel,
        taskVM: TaskListViewModel,
        initialFilter: ReminderFilter = .all,
        initialSearchQuery: String = ""
    ) {
        self.recurringReminderVM = recurringReminderVM
        self.taskVM = taskVM
        _selectedFilter = State(initialValue: initialFilter)
        _searchQuery = State(initialValue: initialSearchQuery)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Header & Actions
            headerBar

            Divider()
                .background(AppTheme.border)

            // Scrollable Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // In-App Alert Banner if triggered
                    if let alert = activeAlertBanner {
                        inAppAlertBanner(title: alert.title, subtitle: alert.subtitle, time: alert.time)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Stats Banner
                    statsBannerSection

                    // Filter Chips Bar
                    filterChipsSection

                    // Main Reminders Sections
                    if selectedFilter == .taskReminders {
                        timedTaskRemindersSection
                    } else if selectedFilter == .all {
                        recurringRemindersSection
                        timedTaskRemindersSection
                    } else {
                        recurringRemindersSection
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle("Reminders & Alerts")
        .sheet(isPresented: $showingAddSheet) {
            reminderFormSheet(isEditing: false)
        }
        .sheet(item: $editingReminder) { reminder in
            reminderFormSheet(isEditing: true, existing: reminder)
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationManager.reminderAlertBannerNotification)) { notif in
            let title = notif.userInfo?["title"] as? String ?? "Reminder"
            let subtitle = notif.userInfo?["subtitle"] as? String ?? "Alert"
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
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        ViewThatFits(in: .horizontal) {
            // Wide layout
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.accent)

                        Text("Reminders & Alerts")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Text("Manage scheduled alerts, recurring focus prompts, and task deadlines.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                searchFieldView

                testChimeButton

                newReminderButton
            }

            // Compact 2-row layout
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.accent)

                    Text("Reminders & Alerts")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    testChimeButton
                    newReminderButton
                }

                searchFieldView
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(AppTheme.background)
    }

    private var searchFieldView: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)

            TextField("Search reminders or notes...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textPrimary)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minWidth: 140, idealWidth: 180, maxWidth: 240)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var testChimeButton: some View {
        Button {
            triggerChimeFeedback()
        } label: {
            Label("Test Chime", systemImage: "speaker.wave.2.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .help("Play the rich native notification alert chime")
    }

    private var newReminderButton: some View {
        Button {
            resetForm()
            showingAddSheet = true
        } label: {
            Label("New Reminder", systemImage: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.accent)
        .controlSize(.regular)
        .help("Create a new recurring reminder schedule")
    }

    // MARK: - In-App Alert Banner
    private func inAppAlertBanner(title: String, subtitle: String, time: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.sandstone.opacity(0.18))
                    .frame(width: 34, height: 34)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.sandstone)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("ACTIVE ALERT")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(AppTheme.sandstone.opacity(0.2))
                        .foregroundStyle(AppTheme.sandstone)
                        .clipShape(Capsule())

                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                HStack(spacing: 4) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    if !time.isEmpty {
                        Text("• \(time)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.sandstone)
                    }
                }
            }

            Spacer()

            Button {
                triggerChimeFeedback()
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(6)
            }
            .buttonStyle(.plain)
            .help("Play sound again")

            Button {
                withAnimation { activeAlertBanner = nil }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.sandstone.opacity(0.45), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Stats Banner Section
    private var statsBannerSection: some View {
        let totalCount = recurringReminderVM.reminders.count
        let activeTodayCount = calculateActiveTodayCount()
        let nextAlarmInfo = calculateNextAlarm()

        return LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 180, maximum: .infinity), spacing: 12)
            ],
            spacing: 12
        ) {
            statCard(
                title: "Total Reminders",
                value: "\(totalCount)",
                subtitle: "\(recurringReminderVM.activeReminders.count) active schedules",
                icon: "bell.badge.fill",
                color: AppTheme.deepFocus
            )

            statCard(
                title: "Active Today",
                value: "\(activeTodayCount)",
                subtitle: "matching today's schedule",
                icon: "calendar.badge.clock",
                color: AppTheme.sandstone
            )

            statCard(
                title: "Next Alarm",
                value: nextAlarmInfo.time,
                subtitle: nextAlarmInfo.title,
                icon: "alarm.fill",
                color: AppTheme.accent
            )
        }
    }

    private func statCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Filter Chips Section
    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 8) {
                ForEach(ReminderFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    let count = countForFilter(filter)

                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: filter.iconName)
                                .font(.system(size: 11))
                                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)

                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textPrimary)
                                .lineLimit(1)

                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold).monospacedDigit())
                                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? AppTheme.accent.opacity(0.18) : AppTheme.cardBackgroundSubtle)
                                )
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isSelected ? AppTheme.accent.opacity(0.4) : AppTheme.subtleBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    // MARK: - Recurring Reminders List Section
    private var recurringRemindersSection: some View {
        let items = filteredRecurringReminders(filter: selectedFilter, query: searchQuery)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "repeat")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.accent)

                    Text("Recurring Schedules")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("(\(items.count))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Spacer()

                if items.isEmpty && !recurringReminderVM.reminders.isEmpty {
                    Text("No reminders match the active search or filter.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            if items.isEmpty {
                emptyStateCard(
                    icon: "bell.slash",
                    title: searchQuery.isEmpty ? "No recurring reminders in this filter" : "No matching reminders",
                    subtitle: searchQuery.isEmpty
                        ? "Click '+ New Reminder' to set up daily focus prompts, standup alerts, or review cues."
                        : "Try adjusting your search terms or filter selection."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { reminder in
                        recurringReminderRow(reminder)
                    }
                }
            }
        }
    }

    // MARK: - Recurring Reminder Row
    private func recurringReminderRow(_ reminder: RecurringReminder) -> some View {
        let isPlaying = playingChimeId == reminder.id

        return HStack(spacing: 14) {
            // Enable / Disable Toggle Switch
            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { _ in
                    withAnimation(.spring(response: 0.25)) {
                        recurringReminderVM.toggleReminder(id: reminder.id)
                    }
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
            .help(reminder.isEnabled ? "Disable this reminder" : "Enable this reminder")

            // Formatted Time Badge
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(reminder.isEnabled ? AppTheme.accent : AppTheme.textTertiary)

                Text(reminder.formattedTime)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(reminder.isEnabled ? AppTheme.textPrimary : AppTheme.textTertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(reminder.isEnabled ? AppTheme.accent.opacity(0.12) : AppTheme.cardBackgroundSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(reminder.isEnabled ? AppTheme.accent.opacity(0.25) : AppTheme.subtleBorder, lineWidth: 1)
            )

            // Title & Notes
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(reminder.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(reminder.isEnabled ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .lineLimit(1)

                    // Recurrence Badge
                    HStack(spacing: 3) {
                        Image(systemName: reminder.repeatFrequency.iconName)
                            .font(.system(size: 9))

                        Text(reminder.repeatFrequency.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.cardBackgroundSubtle)
                    .foregroundStyle(AppTheme.textSecondary)
                    .clipShape(Capsule())
                }

                if !reminder.notes.isEmpty {
                    Text(reminder.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Next fire preview
            if reminder.isEnabled, let nextFire = reminder.nextFireDate() {
                Text("Next: \(formattedRelativeTime(nextFire))")
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }

            // Action Buttons: Sound Test, Edit, Delete
            HStack(spacing: 6) {
                // Sound Test Button
                Button {
                    triggerChimeFeedback(for: reminder.id)
                } label: {
                    Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.system(size: 12))
                        .foregroundStyle(isPlaying ? AppTheme.accent : AppTheme.textSecondary)
                        .padding(6)
                        .background(isPlaying ? AppTheme.accent.opacity(0.15) : AppTheme.cardBackgroundSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Test notification chime")

                // Edit Button
                Button {
                    startEditing(reminder)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(6)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Edit reminder")

                // Delete Button
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.25)) {
                        recurringReminderVM.deleteReminder(id: reminder.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.terracotta)
                        .padding(6)
                        .background(AppTheme.terracotta.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Delete reminder")
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(reminder.isEnabled ? AppTheme.subtleBorder : AppTheme.border.opacity(0.5), lineWidth: 1)
        )
        .contextMenu {
            Button {
                triggerChimeFeedback(for: reminder.id)
            } label: {
                Label("Test Sound Chime", systemImage: "speaker.wave.2")
            }

            Button {
                recurringReminderVM.toggleReminder(id: reminder.id)
            } label: {
                Label(reminder.isEnabled ? "Disable Reminder" : "Enable Reminder", systemImage: reminder.isEnabled ? "bell.slash" : "bell")
            }

            Divider()

            Button {
                startEditing(reminder)
            } label: {
                Label("Edit Reminder", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                recurringReminderVM.deleteReminder(id: reminder.id)
            } label: {
                Label("Delete Reminder", systemImage: "trash")
            }
        }
    }

    // MARK: - Timed Task Reminders Section
    private var timedTaskRemindersSection: some View {
        let taskItems = filteredTaskReminders(query: searchQuery)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.sandstone)

                    Text("Timed Task Reminders")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("(\(taskItems.count))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Spacer()
            }

            if taskItems.isEmpty {
                emptyStateCard(
                    icon: "calendar.badge.exclamationmark",
                    title: "No timed task reminders scheduled",
                    subtitle: "Set a reminder date and time on any task in the Tasks board to have it alert you here."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(taskItems) { task in
                        taskReminderRow(task)
                    }
                }
            }
        }
    }

    // MARK: - Task Reminder Row
    private func taskReminderRow(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            // Task Completion Checkbox
            Button {
                withAnimation(.spring(response: 0.25)) {
                    taskVM.toggleTaskCompletion(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(task.isCompleted ? AppTheme.success : AppTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .help(task.isCompleted ? "Mark incomplete" : "Mark completed")

            // Scheduled Time Pill
            if let reminderDate = task.reminderDate {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.sandstone)

                    Text(formattedTaskReminderDate(reminderDate))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.sandstone.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            // Task Details
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: 13, weight: .medium))
                    .strikethrough(task.isCompleted, color: AppTheme.textSecondary)
                    .foregroundStyle(task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .lineLimit(1)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Priority Badge
            Text(task.priority.rawValue)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(task.priority.color.opacity(0.14))
                .foregroundStyle(task.priority.color)
                .clipShape(Capsule())

            // Status Badge
            Text(task.status.rawValue)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.cardBackgroundSubtle)
                .foregroundStyle(AppTheme.textSecondary)
                .clipShape(Capsule())

            // Clear Task Reminder Button
            Button {
                withAnimation(.spring(response: 0.25)) {
                    taskVM.removeReminder(for: task.id)
                }
            } label: {
                Image(systemName: "bell.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(5)
                    .background(AppTheme.cardBackgroundSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .help("Clear task reminder")
        }
        .padding(10)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Empty State Card
    private func emptyStateCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.textTertiary)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.cardBackgroundSubtle.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Reminder Form Modal Sheet
    private func reminderFormSheet(isEditing: Bool, existing: RecurringReminder? = nil) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Sheet Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: isEditing ? "pencil.circle.fill" : "bell.badge.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.accent)

                    Text(isEditing ? "Edit Recurring Reminder" : "New Recurring Reminder")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer()

                Button {
                    if isEditing {
                        editingReminder = nil
                    } else {
                        showingAddSheet = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(AppTheme.border)

            // Form Inputs
            VStack(alignment: .leading, spacing: 14) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminder Title")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    TextField("e.g. Daily Standup, Afternoon Hydration, Wrap-up", text: $formTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(8)
                        .background(AppTheme.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppTheme.subtleBorder, lineWidth: 1)
                        )
                }

                // Time Picker & Recurrence Frequency
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scheduled Time")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        DatePicker("", selection: $formTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .font(.system(size: 13))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repeat Frequency")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Picker("Frequency", selection: $formFrequency) {
                            ForEach(RepeatFrequency.allCases) { freq in
                                Label(freq.rawValue, systemImage: freq.iconName)
                                    .tag(freq)
                            }
                        }
                        .labelsHidden()
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes / Actionable Prompt (Optional)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    TextField("e.g. Review top 3 priority tasks before starting deep focus", text: $formNotes)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(8)
                        .background(AppTheme.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppTheme.subtleBorder, lineWidth: 1)
                        )
                }

                // Enabled Toggle
                Toggle("Active / Enable Notification Alert", isOn: $formIsEnabled)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Divider()
                .background(AppTheme.border)

            // Sheet Action Buttons with High-Contrast Typography
            HStack {
                Spacer()

                Button("Cancel") {
                    if isEditing {
                        editingReminder = nil
                    } else {
                        showingAddSheet = false
                    }
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button(isEditing ? "Save Changes" : "Save Reminder") {
                    saveFormData(isEditing: isEditing, existing: existing)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .foregroundStyle(Color.white)
                .font(.system(size: 13, weight: .bold))
                .keyboardShortcut(.defaultAction)
                .disabled(formTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 440)
        .background(AppTheme.cardBackground)
    }

    // MARK: - Helpers & Calculations
    private func resetForm() {
        formTitle = ""
        formTime = Date()
        formFrequency = .daily
        formNotes = ""
        formIsEnabled = true
    }

    private func startEditing(_ reminder: RecurringReminder) {
        formTitle = reminder.title
        formTime = reminder.time
        formFrequency = reminder.repeatFrequency
        formNotes = reminder.notes
        formIsEnabled = reminder.isEnabled
        editingReminder = reminder
    }

    private func saveFormData(isEditing: Bool, existing: RecurringReminder?) {
        let cleanTitle = formTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        if isEditing, var reminder = existing {
            reminder.title = cleanTitle
            reminder.time = formTime
            reminder.repeatFrequency = formFrequency
            reminder.notes = formNotes
            reminder.isEnabled = formIsEnabled
            recurringReminderVM.updateReminder(reminder)
            editingReminder = nil
        } else {
            recurringReminderVM.addReminder(
                title: cleanTitle,
                time: formTime,
                repeatFrequency: formFrequency,
                notes: formNotes,
                isEnabled: formIsEnabled
            )
            showingAddSheet = false
        }
    }

    private func triggerChimeFeedback(for id: UUID? = nil) {
        NotificationManager.shared.playRichAlertChime()
        if let id = id {
            withAnimation(.spring(response: 0.2)) {
                playingChimeId = id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation {
                    if playingChimeId == id {
                        playingChimeId = nil
                    }
                }
            }
        }
    }

    public func filteredRecurringReminders(filter: ReminderFilter, query: String) -> [RecurringReminder] {
        let list = recurringReminderVM.reminders
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return list.filter { reminder in
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .daily:
                matchesFilter = reminder.repeatFrequency == .daily
            case .weekdays:
                matchesFilter = reminder.repeatFrequency == .weekdays
            case .weekly:
                matchesFilter = reminder.repeatFrequency == .weekly
            case .monthly:
                matchesFilter = reminder.repeatFrequency == .monthly
            case .taskReminders:
                matchesFilter = false
            }

            let matchesSearch: Bool
            if trimmed.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = reminder.title.localizedCaseInsensitiveContains(trimmed) ||
                                reminder.notes.localizedCaseInsensitiveContains(trimmed) ||
                                reminder.repeatFrequency.rawValue.localizedCaseInsensitiveContains(trimmed)
            }

            return matchesFilter && matchesSearch
        }
    }

    public func filteredTaskReminders(query: String) -> [TaskItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return taskVM.tasks.filter { task in
            guard task.reminderDate != nil else { return false }
            if trimmed.isEmpty {
                return true
            }
            return task.title.localizedCaseInsensitiveContains(trimmed) ||
                   task.notes.localizedCaseInsensitiveContains(trimmed) ||
                   task.tags.contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }.sorted { ($0.reminderDate ?? Date.distantFuture) < ($1.reminderDate ?? Date.distantFuture) }
    }

    public func countForFilter(_ filter: ReminderFilter) -> Int {
        switch filter {
        case .all:
            return recurringReminderVM.reminders.count + taskVM.tasks.filter { $0.reminderDate != nil }.count
        case .daily:
            return recurringReminderVM.reminders.filter { $0.repeatFrequency == .daily }.count
        case .weekdays:
            return recurringReminderVM.reminders.filter { $0.repeatFrequency == .weekdays }.count
        case .weekly:
            return recurringReminderVM.reminders.filter { $0.repeatFrequency == .weekly }.count
        case .monthly:
            return recurringReminderVM.reminders.filter { $0.repeatFrequency == .monthly }.count
        case .taskReminders:
            return taskVM.tasks.filter { $0.reminderDate != nil }.count
        }
    }

    public func calculateActiveTodayCount() -> Int {
        let today = Date()
        let todayRecurring = recurringReminderVM.reminders(for: today, calendar: calendar).count
        let todayTasks = taskVM.tasks.filter { task in
            guard let rDate = task.reminderDate, !task.isCompleted else { return false }
            return calendar.isDate(rDate, inSameDayAs: today)
        }.count
        return todayRecurring + todayTasks
    }

    public func calculateNextAlarm() -> (time: String, title: String) {
        let now = Date()
        var upcomingEvents: [(date: Date, title: String)] = []

        for reminder in recurringReminderVM.reminders where reminder.isEnabled {
            if let nextDate = reminder.nextFireDate(after: now, calendar: calendar) {
                upcomingEvents.append((date: nextDate, title: reminder.title))
            }
        }

        for task in taskVM.tasks where !task.isCompleted {
            if let reminderDate = task.reminderDate, reminderDate > now {
                upcomingEvents.append((date: reminderDate, title: task.title))
            }
        }

        guard let earliest = upcomingEvents.min(by: { $0.date < $1.date }) else {
            return (time: "None", title: "No upcoming alarms")
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeStr = timeFormatter.string(from: earliest.date)

        if calendar.isDateInToday(earliest.date) {
            return (time: timeStr, title: "Today • \(earliest.title)")
        } else if calendar.isDateInTomorrow(earliest.date) {
            return (time: timeStr, title: "Tomorrow • \(earliest.title)")
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "MMM d"
            return (time: timeStr, title: "\(dayFormatter.string(from: earliest.date)) • \(earliest.title)")
        }
    }

    private func formattedRelativeTime(_ date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeStr = timeFormatter.string(from: date)

        if calendar.isDateInToday(date) {
            return "Today \(timeStr)"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow \(timeStr)"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE, MMM d"
            return "\(dayFormatter.string(from: date)) \(timeStr)"
        }
    }

    private func formattedTaskReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today,' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tmrw,' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        return formatter.string(from: date)
    }
}
