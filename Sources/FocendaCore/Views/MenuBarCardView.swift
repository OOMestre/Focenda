import SwiftUI
import AppKit

/// Top navigation tabs in Menu Bar Multi-Action Control Center
public enum MenuBarSection: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case quickNote = "Note"
    case quickTask = "Task"
    case reminders = "Alerts"
    case quickLinks = "Links"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .focus: return "timer"
        case .quickNote: return "square.and.pencil"
        case .quickTask: return "checklist"
        case .reminders: return "bell.badge"
        case .quickLinks: return "link"
        }
    }
}

/// An interactive multi-action control center designed for MenuBarExtra popover style
public struct MenuBarCardView: View {
    public var timerVM: FocusTimerViewModel
    public var taskVM: TaskListViewModel
    public var scratchpadVM: ScratchpadViewModel
    public var recurringReminderVM: RecurringReminderViewModel
    public var appState: AppState?

    @State public var selectedSection: MenuBarSection = .focus
    @State public var isPresented: Bool = false
    @State private var isHovered: Bool = false
    @State private var completionAlertMessage: String? = nil

    // In-App Reminder Banner
    @State private var activeReminderAlert: (title: String, subtitle: String, time: String)? = nil

    // Quick Task state
    @State private var newTaskTitle: String = ""
    @State private var newTaskPriority: TaskPriority = .medium

    // Recurring Reminder state
    @State private var newReminderTitle: String = ""
    @State private var newReminderTime: Date = Date()
    @State private var newReminderFrequency: RepeatFrequency = .daily
    @State private var isAddingReminder: Bool = false

    // Quick Note state
    @State public var selectedNoteFolder: String = "General"
    @State private var quickNoteText: String = ""
    @State private var noteSavedFeedback: Bool = false

    // Quick Links state
    @State private var customLinks: [QuickLink] = []
    @State private var newLinkTitle: String = ""
    @State private var newLinkUrl: String = ""
    @State private var isAddingLink: Bool = false

    private let customLinksStorageKey = "focenda_custom_quick_links"

    public init(
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel = TaskListViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel(),
        recurringReminderVM: RecurringReminderViewModel = RecurringReminderViewModel(),
        appState: AppState? = nil,
        initialSection: MenuBarSection = .focus
    ) {
        self.timerVM = timerVM
        self.taskVM = taskVM
        self.scratchpadVM = scratchpadVM
        self.recurringReminderVM = recurringReminderVM
        self.appState = appState
        self._selectedSection = State(initialValue: initialSection)
    }

    public var body: some View {
        cardBody
            .padding(18)
            .frame(width: 360)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        timerVM.currentMode.themeColor.opacity(isHovered ? 0.45 : 0.20),
                        lineWidth: 1.0
                    )
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.12 : 0.05),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 3 : 1
            )
            .scaleEffect(x: 1.0, y: isPresented ? 1.0 : 0.88, anchor: .top)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isHovered)
            .animation(.spring(response: 0.32, dampingFraction: 0.76), value: isPresented)
            .onHover { hovering in
                isHovered = hovering
            }
            .onAppear {
                isPresented = false
                if selectedNoteFolder.isEmpty || !scratchpadVM.folders.contains(where: { $0.caseInsensitiveCompare(selectedNoteFolder) == .orderedSame }) {
                    selectedNoteFolder = scratchpadVM.folders.first ?? "General"
                }
                quickNoteText = scratchpadVM.currentContent
                loadCustomLinks()
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                        isPresented = true
                    }
                }
            }
            .onDisappear {
                isPresented = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusSessionCompleted)) { notification in
                let mode = notification.userInfo?["mode"] as? FocusMode ?? timerVM.currentMode
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    completionAlertMessage = NotificationManager.notificationTitle(for: mode)
                    selectedSection = .focus
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        completionAlertMessage = nil
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.reminderAlertBannerNotification)) { notif in
                let title = notif.userInfo?["title"] as? String ?? "Reminder"
                let subtitle = notif.userInfo?["subtitle"] as? String ?? "Focenda Alert"
                let time = notif.userInfo?["time"] as? String ?? ""
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    activeReminderAlert = (title: title, subtitle: subtitle, time: time)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 25.0) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        activeReminderAlert = nil
                    }
                }
            }
    }

    private var cardBody: some View {
        VStack(spacing: 12) {
            // Header: App Title & Active Mode Tag
            headerSection

            // Active Reminder Banner
            if let reminderAlert = activeReminderAlert {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "alarm.fill")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(reminderAlert.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("\(reminderAlert.subtitle) • \(reminderAlert.time)")
                                .font(.system(size: 9))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            NotificationManager.shared.stopActiveSound()
                            withAnimation { activeReminderAlert = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 6) {
                        Button {
                            NotificationManager.shared.stopActiveSound()
                            withAnimation { activeReminderAlert = nil }
                        } label: {
                            Text("Entendido")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.8))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)

                        Button {
                            NotificationManager.shared.snoozeReminder(
                                title: reminderAlert.title,
                                subtitle: reminderAlert.subtitle,
                                notes: "",
                                minutes: 5
                            )
                            withAnimation { activeReminderAlert = nil }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 9))
                                Text("Adiar 5m")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppTheme.cardBackgroundSubtle)
                            .foregroundStyle(AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            } else if let alertMsg = completionAlertMessage {
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption)
                        .foregroundStyle(timerVM.currentMode.themeColor)
                    Text(alertMsg)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(timerVM.currentMode.themeColor.opacity(0.15))
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            // Top Multi-Action Segmented Bar
            segmentedControlSection

            // Section Content
            Group {
                switch selectedSection {
                case .focus:
                    focusSection
                case .quickNote:
                    quickNoteSection
                case .quickTask:
                    quickTaskSection
                case .reminders:
                    recurringRemindersSection
                case .quickLinks:
                    quickLinksSection
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: selectedSection)

            // Footer actions (Open Main App, Quit)
            footerSection
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundStyle(timerVM.currentMode.themeColor)
                    .font(.headline)
                Text("Focenda")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            // Active Mode Tag
            HStack(spacing: 4) {
                Image(systemName: timerVM.currentMode.iconName)
                    .font(.caption2)
                Text(timerVM.currentMode.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(timerVM.currentMode.themeColor.opacity(0.12))
            .foregroundStyle(timerVM.currentMode.themeColor)
            .clipShape(Capsule())
        }
    }

    // MARK: - Segmented Control Bar
    private var segmentedControlSection: some View {
        HStack(spacing: 3) {
            ForEach(MenuBarSection.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
                        selectedSection = section
                        if section == .quickNote {
                            if !scratchpadVM.folders.contains(where: { $0.caseInsensitiveCompare(selectedNoteFolder) == .orderedSame }) {
                                selectedNoteFolder = scratchpadVM.folders.first ?? "General"
                            }
                            quickNoteText = scratchpadVM.currentContent
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: section.iconName)
                            .font(.system(size: 10, weight: .bold))
                        Text(section.rawValue)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedSection == section
                            ? AppTheme.accent
                            : AppTheme.cardBackgroundSubtle
                    )
                    .foregroundStyle(
                        selectedSection == section
                            ? .white
                            : AppTheme.textSecondary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(SpringScaleButtonStyle())
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(AppTheme.cardBackgroundSubtle.opacity(0.6))
        )
    }

    // MARK: - ⏱️ Focus Section
    private var focusSection: some View {
        VStack(spacing: 12) {
            modeSelectorSection
            miniProgressRingSection
            quickPresetSection
            cycleDotsSection
            controlsSection
        }
    }

    private var modeSelectorSection: some View {
        HStack(spacing: 6) {
            ForEach(FocusMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        timerVM.switchMode(to: mode)
                    }
                } label: {
                    Text(shortModeTitle(for: mode))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(
                            timerVM.currentMode == mode
                                ? mode.themeColor
                                : AppTheme.cardBackgroundSubtle
                        )
                        .foregroundStyle(
                            timerVM.currentMode == mode
                                ? .white
                                : AppTheme.textSecondary
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(SpringScaleButtonStyle())
            }
        }
    }

    public func shortModeTitle(for mode: FocusMode) -> String {
        switch mode {
        case .work: return "Focus"
        case .shortBreak: return "Short"
        case .longBreak: return "Long"
        }
    }

    private var miniProgressRingSection: some View {
        ZStack {
            Circle()
                .stroke(
                    timerVM.currentMode.themeColor.opacity(0.12),
                    lineWidth: 9
                )

            Circle()
                .trim(from: 0.0, to: CGFloat(min(timerVM.progress, 1.0)))
                .stroke(
                    timerVM.currentMode.themeColor,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: timerVM.progress)

            VStack(spacing: 2) {
                Text(timerVM.formattedTimeRemaining)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.textPrimary)

                Text(statusText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(timerVM.currentMode.themeColor)
            }
        }
        .frame(width: 124, height: 124)
        .padding(.vertical, 2)
    }

    public var statusText: String {
        switch timerVM.status {
        case .running:
            return "RUNNING"
        case .paused:
            return "PAUSED"
        case .idle:
            return "READY"
        }
    }

    private var quickPresetSection: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    timerVM.adjustTime(byMinutes: -5)
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                    Text("5m")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppTheme.cardBackgroundSubtle)
                )
                .overlay(
                    Capsule()
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
                .foregroundStyle(AppTheme.textSecondary)
            }
            .buttonStyle(SpringScaleButtonStyle())
            .help("Subtract 5 minutes")

            Spacer()

            Text(timerVM.currentMode.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    timerVM.adjustTime(byMinutes: 5)
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                    Text("5m")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppTheme.cardBackgroundSubtle)
                )
                .overlay(
                    Capsule()
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
                .foregroundStyle(AppTheme.textSecondary)
            }
            .buttonStyle(SpringScaleButtonStyle())
            .help("Add 5 minutes")
        }
        .padding(.horizontal, 8)
    }

    private var cycleDotsSection: some View {
        HStack(spacing: 6) {
            Text("Cycle:")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(0..<4) { index in
                Circle()
                    .fill(
                        (timerVM.completedWorkSessionsCount % 4) > index
                            ? timerVM.currentMode.themeColor
                            : AppTheme.border
                    )
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 16) {
            Button {
                timerVM.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .help("Reset session")

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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(timerVM.currentMode.themeColor)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            .help(timerVM.status == .running ? "Pause timer" : "Start timer")

            Button {
                timerVM.skip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .help("Skip session")
        }
    }

    // MARK: - 🔔 Recurring Reminders Section
    private var recurringRemindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recurring Reminders (\(recurringReminderVM.activeReminders.count))")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isAddingReminder.toggle()
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: isAddingReminder ? "xmark" : "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(isAddingReminder ? "Cancel" : "Add")
                            .font(.caption2.weight(.medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
            }

            if isAddingReminder {
                VStack(spacing: 6) {
                    TextField("Reminder title (e.g. Standup)", text: $newReminderTitle)
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

                    HStack(spacing: 6) {
                        DatePicker("", selection: $newReminderTime, displayedComponents: [.hourAndMinute])
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                            .tint(AppTheme.accent)
                            .labelsHidden()

                        Picker("", selection: $newReminderFrequency) {
                            ForEach(RepeatFrequency.allCases) { freq in
                                Text(freq.rawValue)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .tag(freq)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(AppTheme.textPrimary)
                        .tint(AppTheme.accent)
                        .labelsHidden()

                        Spacer()

                        Button("Save") {
                            saveQuickRecurringReminder()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                        .foregroundStyle(Color.white)
                        .controlSize(.small)
                        .disabled(newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.cardBackgroundSubtle.opacity(0.6))
                )
            }

            if recurringReminderVM.reminders.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("No recurring reminders")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.vertical, 8)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 5) {
                        ForEach(recurringReminderVM.reminders) { reminder in
                            HStack(spacing: 8) {
                                Button {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                        recurringReminderVM.toggleReminder(id: reminder.id)
                                    }
                                } label: {
                                    Image(systemName: reminder.isEnabled ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 11))
                                        .foregroundStyle(reminder.isEnabled ? AppTheme.accent : AppTheme.textTertiary)
                                }
                                .buttonStyle(.plain)

                                Text(reminder.title)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(reminder.isEnabled ? AppTheme.textPrimary : AppTheme.textSecondary)
                                    .lineLimit(1)

                                Spacer()

                                Text(reminder.formattedTime)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(reminder.repeatFrequency.rawValue)
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1.5)
                                    .background(AppTheme.accent.opacity(0.12))
                                    .foregroundStyle(AppTheme.accent)
                                    .clipShape(Capsule())
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(AppTheme.cardBackgroundSubtle.opacity(0.4))
                            )
                        }
                    }
                }
                .frame(maxHeight: 140)
            }
        }
        .padding(.vertical, 2)
    }

    private func saveQuickRecurringReminder() {
        let trimmed = newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        recurringReminderVM.addReminder(
            title: trimmed,
            time: newReminderTime,
            repeatFrequency: newReminderFrequency
        )

        newReminderTitle = ""
        isAddingReminder = false
    }

    // MARK: - 📝 Quick Note Section
    private var quickNoteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Folder Selector Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(scratchpadVM.folders, id: \.self) { folder in
                        let isSelected = selectedNoteFolder.caseInsensitiveCompare(folder) == .orderedSame
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                selectedNoteFolder = folder
                                scratchpadVM.selectFolder(folder)
                                quickNoteText = scratchpadVM.currentContent
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: ScratchpadViewModel.iconForFolder(folder))
                                    .font(.system(size: 9))
                                Text(folder)
                                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                isSelected
                                    ? AppTheme.accent
                                    : AppTheme.cardBackgroundSubtle
                            )
                            .foregroundStyle(
                                isSelected
                                    ? .white
                                    : AppTheme.textSecondary
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.inputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                    )

                if quickNoteText.isEmpty {
                    Text("Capture a quick thought directly into \(selectedNoteFolder)...")
                        .font(.callout)
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(10)
                }

                TextEditor(text: $quickNoteText)
                    .font(.callout)
                    .foregroundStyle(AppTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .onChange(of: quickNoteText) { _, newText in
                        scratchpadVM.updateContent(newText)
                    }
            }
            .frame(height: 120)

            HStack {
                if noteSavedFeedback {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.success)
                        Text("Saved to \(selectedNoteFolder)")
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.success)
                            .lineLimit(1)
                    }
                    .transition(.opacity)
                } else {
                    Text("\(quickNoteText.count) chars • \(selectedNoteFolder)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    saveQuickNote()
                } label: {
                    Label("Save Note", systemImage: "plus.circle")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .controlSize(.small)
                .disabled(quickNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    scratchpadVM.updateContent(quickNoteText)
                    scratchpadVM.copyCurrentNoteToClipboard()
                    withAnimation {
                        noteSavedFeedback = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { noteSavedFeedback = false }
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption2.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    quickNoteText = ""
                    scratchpadVM.clearCurrentNote()
                } label: {
                    Text("Clear")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(.vertical, 2)
    }

    public func saveQuickNote() {
        let trimmed = quickNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = scratchpadVM.createNote(
            title: "",
            content: trimmed,
            folder: selectedNoteFolder
        )
        withAnimation {
            noteSavedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { noteSavedFeedback = false }
        }
    }

    // MARK: - ✅ Quick Task Section
    private var quickTaskSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField("Add task to checklist...", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppTheme.inputBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )
                    .onSubmit {
                        submitQuickTask()
                    }

                Button {
                    submitQuickTask()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(AppTheme.accent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help("Add task")
            }

            HStack(spacing: 6) {
                Text("Priority:")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)

                ForEach(TaskPriority.allCases) { priority in
                    Button {
                        newTaskPriority = priority
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: priority.icon)
                                .font(.system(size: 8))
                            Text(priority.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            newTaskPriority == priority
                                ? priority.color.opacity(0.2)
                                : AppTheme.cardBackgroundSubtle
                        )
                        .foregroundStyle(
                            newTaskPriority == priority
                                ? priority.color
                                : AppTheme.textSecondary
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Pending Tasks (\(taskVM.pendingTasksCount))")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)

                let pending = taskVM.tasks.filter { !$0.isCompleted }.prefix(3)
                if pending.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.title3)
                                .foregroundStyle(AppTheme.success)
                            Text("All tasks completed!")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                } else {
                    ForEach(Array(pending)) { task in
                        HStack(spacing: 8) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    taskVM.toggleTaskCompletion(task)
                                }
                            } label: {
                                Image(systemName: "circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .buttonStyle(.plain)

                            Text(task.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text(task.priority.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(task.priority.color.opacity(0.15))
                                .foregroundStyle(task.priority.color)
                                .clipShape(Capsule())
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(AppTheme.cardBackgroundSubtle.opacity(0.4))
                        )
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func submitQuickTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        taskVM.addTask(title: trimmed, priority: newTaskPriority)
        newTaskTitle = ""
    }

    // MARK: - 🔗 Quick Links Section
    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Saved Bookmarks")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isAddingLink.toggle()
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: isAddingLink ? "xmark" : "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(isAddingLink ? "Cancel" : "Add Link")
                            .font(.caption2.weight(.medium))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
            }

            if isAddingLink {
                VStack(spacing: 6) {
                    TextField("Title (e.g. Jira)", text: $newLinkTitle)
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

                    TextField("URL (e.g. https://...)", text: $newLinkUrl)
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

                    Button("Save Bookmark") {
                        saveNewBookmark()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .foregroundStyle(Color.white)
                    .controlSize(.small)
                    .disabled(newLinkTitle.isEmpty || newLinkUrl.isEmpty)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.cardBackgroundSubtle.opacity(0.6))
                )
            }

            let allLinks = QuickLink.defaultLinks + customLinks
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(allLinks) { link in
                    let isCustom = customLinks.contains(where: { $0.id == link.id })
                    Button {
                        if let url = link.url {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: link.iconName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 20)

                            Text(link.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.cardBackgroundSubtle)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppTheme.subtleBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(SpringScaleButtonStyle())
                    .contextMenu {
                        Button {
                            if let url = link.url {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Label("Open in Browser", systemImage: "arrow.up.right")
                        }

                        Button {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(link.urlString, forType: .string)
                        } label: {
                            Label("Copy URL", systemImage: "doc.on.doc")
                        }

                        if isCustom {
                            Divider()

                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.25)) {
                                    deleteCustomLink(link)
                                }
                            } label: {
                                Label("Delete Bookmark", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func saveNewBookmark() {
        let title = newLinkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        var urlStr = newLinkUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !urlStr.isEmpty else { return }

        if !urlStr.lowercased().hasPrefix("http://") && !urlStr.lowercased().hasPrefix("https://") {
            urlStr = "https://" + urlStr
        }

        let link = QuickLink(title: title, urlString: urlStr)
        customLinks.append(link)
        saveCustomLinks()

        newLinkTitle = ""
        newLinkUrl = ""
        isAddingLink = false
    }

    public func deleteCustomLink(_ link: QuickLink) {
        deleteCustomLink(id: link.id)
    }

    public func deleteCustomLink(id: UUID) {
        customLinks.removeAll(where: { $0.id == id })
        saveCustomLinks()
    }

    private func saveCustomLinks() {
        if let data = try? JSONEncoder().encode(customLinks) {
            UserDefaults.standard.set(data, forKey: customLinksStorageKey)
        }
    }

    private func loadCustomLinks() {
        if let data = UserDefaults.standard.data(forKey: customLinksStorageKey),
           let decoded = try? JSONDecoder().decode([QuickLink].self, from: data) {
            self.customLinks = decoded
        }
    }

    // MARK: - Footer Actions
    private var footerSection: some View {
        VStack(spacing: 8) {
            Divider()

            HStack {
                Button {
                    openMainApp()
                } label: {
                    Label("Open Main App", systemImage: "macwindow")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openMainApp() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Spring Scale Button Style

private struct SpringScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
