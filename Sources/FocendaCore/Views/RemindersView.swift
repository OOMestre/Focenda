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

/// Dedicated, clean and user-friendly Reminders & Alerts center for Focenda
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
            // Clean Top Header & Actions
            headerBar

            Divider()
                .background(AppTheme.border)

            // Main Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    // In-App Alert Banner (if triggered)
                    if let alert = activeAlertBanner {
                        inAppAlertBanner(title: alert.title, subtitle: alert.subtitle, time: alert.time)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Minimal Filter Bar
                    filterBarSection

                    // Reminders Content Sections
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
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.accent)

                    Text("Reminders & Alerts")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer(minLength: 12)

                searchFieldView

                testChimeButton

                testHUDAlertButton

                newReminderButton
            }

            // Compact layout
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.accent)

                    Text("Reminders & Alerts")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    testChimeButton
                    testHUDAlertButton
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

            TextField("Search reminders...", text: $searchQuery)
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
        .frame(minWidth: 140, idealWidth: 180, maxWidth: 220)
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
            Image(systemName: "speaker.wave.2")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 28, height: 28)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("Test notification alert chime")
    }

    private var testHUDAlertButton: some View {
        Button {
            NotificationManager.shared.testReminderAlertHUD(
                title: "Daily Standup",
                subtitle: "Daily Reminder • 6:00 PM",
                notes: "Time to review your daily accomplishments and plan ahead!"
            )
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                Text("Test Alert")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Test visual popup and floating screen alert (HUD)")
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
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.sandstone)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

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
    }

    // MARK: - Minimal Filter Bar Section
    private var filterBarSection: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) {
            ForEach(ReminderFilter.allCases) { filter in
                let isSelected = selectedFilter == filter
                let count = countForFilter(filter)

                Button {
                    withAnimation(.spring(response: 0.25)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(filter.rawValue)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textPrimary)

                        Text("\(count)")
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium).monospacedDigit())
                            .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AppTheme.accent.opacity(0.16) : AppTheme.cardBackgroundSubtle)
                            )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(isSelected ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(isSelected ? AppTheme.accent.opacity(0.35) : AppTheme.subtleBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Recurring Reminders List Section
    private var recurringRemindersSection: some View {
        let items = filteredRecurringReminders(filter: selectedFilter, query: searchQuery)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recurring Schedules")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                Text("(\(items.count))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)

                Spacer()
            }

            if items.isEmpty {
                emptyStateCard(
                    icon: "bell.slash",
                    title: searchQuery.isEmpty ? "No recurring reminders in this filter" : "No matching reminders",
                    subtitle: searchQuery.isEmpty
                        ? "Click '+ New Reminder' to set up focus prompts or review cues."
                        : "Try adjusting your search terms or filter selection."
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(items) { reminder in
                        recurringReminderRow(reminder)
                    }
                }
            }
        }
    }

    // MARK: - Simplified Recurring Reminder Row
    private func recurringReminderRow(_ reminder: RecurringReminder) -> some View {
        let isPlaying = playingChimeId == reminder.id

        return HStack(spacing: 12) {
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
            .help(reminder.isEnabled ? "Disable reminder" : "Enable reminder")

            // Clean Time Display
            Text(reminder.formattedTime)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(reminder.isEnabled ? AppTheme.textPrimary : AppTheme.textTertiary)
                .frame(width: 68, alignment: .leading)

            // Title, Frequency & Notes
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(reminder.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(reminder.isEnabled ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .lineLimit(1)

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textTertiary)

                    Text(reminder.repeatFrequency.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                if !reminder.notes.isEmpty {
                    Text(reminder.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            // Subtle Action Buttons
            HStack(spacing: 2) {
                Button {
                    triggerChimeFeedback(for: reminder.id)
                } label: {
                    Image(systemName: isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.system(size: 11))
                        .foregroundStyle(isPlaying ? AppTheme.accent : AppTheme.textTertiary)
                        .frame(width: 26, height: 26)
                        .background(isPlaying ? AppTheme.accent.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help("Test chime")

                Button {
                    startEditing(reminder)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .help("Edit reminder")

                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.25)) {
                        recurringReminderVM.deleteReminder(id: reminder.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.terracotta.opacity(0.8))
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .help("Delete reminder")
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(reminder.isEnabled ? AppTheme.subtleBorder : AppTheme.border.opacity(0.4), lineWidth: 1)
        )
        .contextMenu {
            Button {
                triggerChimeFeedback(for: reminder.id)
            } label: {
                Label("Test Chime Sound", systemImage: "speaker.wave.2")
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

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Timed Task Reminders")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)

                Text("(\(taskItems.count))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)

                Spacer()
            }

            if taskItems.isEmpty {
                emptyStateCard(
                    icon: "calendar.badge.clock",
                    title: "No timed task reminders scheduled",
                    subtitle: "Set a reminder date and time on any task in Tasks to see it here."
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(taskItems) { task in
                        taskReminderRow(task)
                    }
                }
            }
        }
    }

    // MARK: - Simplified Task Reminder Row
    private func taskReminderRow(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            // Task Completion Checkbox
            Button {
                withAnimation(.spring(response: 0.25)) {
                    taskVM.toggleTaskCompletion(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(task.isCompleted ? AppTheme.success : AppTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .help(task.isCompleted ? "Mark incomplete" : "Mark completed")

            // Scheduled Date/Time
            if let reminderDate = task.reminderDate {
                Text(formattedTaskReminderDate(reminderDate))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.accent)
                    .frame(minWidth: 105, alignment: .leading)
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
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            // Priority Indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 6, height: 6)
                Text(task.priority.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.cardBackgroundSubtle)
            .clipShape(Capsule())

            // Clear Reminder Button
            Button {
                withAnimation(.spring(response: 0.25)) {
                    taskVM.removeReminder(for: task.id)
                }
            } label: {
                Image(systemName: "bell.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Remove reminder")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Empty State Card
    private func emptyStateCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.textTertiary)

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.cardBackgroundSubtle.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Reminder Form Modal Sheet
    private func reminderFormSheet(isEditing: Bool, existing: RecurringReminder? = nil) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Sheet Header
            HStack {
                Text(isEditing ? "Edit Reminder" : "New Reminder")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

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
            VStack(alignment: .leading, spacing: 12) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    TextField("e.g. Daily Standup, Stretch & Hydrate", text: $formTitle)
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
                        Text("Time")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        DatePicker("", selection: $formTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .font(.system(size: 13))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repeat")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Picker("Frequency", selection: $formFrequency) {
                            ForEach(RepeatFrequency.allCases) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .labelsHidden()
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes (Optional)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    TextField("e.g. Review top 3 priorities", text: $formNotes)
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
                Toggle("Active Schedule", isOn: $formIsEnabled)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Divider()
                .background(AppTheme.border)

            // Sheet Actions
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

                Button(isEditing ? "Save Changes" : "Create Reminder") {
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
        .padding(20)
        .frame(width: 400)
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
        NotificationManager.shared.playUserReminderSound()
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
