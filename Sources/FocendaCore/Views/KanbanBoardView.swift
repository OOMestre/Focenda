import SwiftUI

/// A visual, interactive 3-column Kanban board for managing task workflows in Focenda
public struct KanbanBoardView: View {
    @Bindable var taskVM: TaskListViewModel
    public var showHeader: Bool

    @State private var showingAddTaskSheet: Bool = false
    @State private var targetColumnStatus: TaskStatus = .todo
    @State private var editingTask: TaskItem? = nil

    public init(taskVM: TaskListViewModel, showHeader: Bool = true) {
        self.taskVM = taskVM
        self.showHeader = showHeader
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showHeader {
                headerView
                Divider()
            }

            // 3-Column Kanban Board Layout
            GeometryReader { geometry in
                let columnWidth = max(280, (geometry.size.width - 64) / 3)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(TaskStatus.allCases) { status in
                            KanbanColumnView(
                                status: status,
                                tasks: taskVM.tasks(for: status),
                                columnWidth: columnWidth,
                                onAddTask: {
                                    targetColumnStatus = status
                                    showingAddTaskSheet = true
                                },
                                onQuickAdd: { title, priority in
                                    taskVM.addTask(
                                        title: title,
                                        priority: priority,
                                        status: status
                                    )
                                },
                                onMoveTask: { taskId, newStatus in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        taskVM.moveTask(id: taskId, to: newStatus)
                                    }
                                },
                                onToggleTask: { task in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        taskVM.toggleTaskCompletion(task)
                                    }
                                },
                                onDeleteTask: { taskId in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        taskVM.deleteTask(withId: taskId)
                                    }
                                },
                                onEditTask: { task in
                                    editingTask = task
                                },
                                onIncrementPomodoro: { taskId in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        taskVM.incrementTaskPomodoro(taskId: taskId)
                                    }
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(AppTheme.background)
        .navigationTitle("Kanban Board")
        .sheet(isPresented: $showingAddTaskSheet) {
            KanbanTaskFormSheet(
                initialStatus: targetColumnStatus,
                onSave: { title, notes, priority, status, reminderDate, dueDate, tags, pomodoros in
                    taskVM.addTask(
                        title: title,
                        notes: notes,
                        priority: priority,
                        status: status,
                        reminderDate: reminderDate,
                        dueDate: dueDate,
                        tags: tags,
                        estimatedPomodoros: pomodoros
                    )
                }
            )
        }
        .sheet(item: $editingTask) { task in
            KanbanTaskFormSheet(
                editingTask: task,
                onSave: { title, notes, priority, status, reminderDate, dueDate, tags, pomodoros in
                    var updated = task
                    updated.title = title
                    updated.notes = notes
                    updated.priority = priority
                    updated.status = status
                    updated.reminderDate = reminderDate
                    updated.dueDate = dueDate
                    updated.tags = tags
                    updated.estimatedPomodoros = pomodoros
                    taskVM.updateTask(updated)
                }
            )
        }
    }

    // MARK: - Header Bar
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Board summary & search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.textTertiary)
                    TextField("Search Kanban tasks by title, notes, or tags...", text: $taskVM.searchQuery)
                        .textFieldStyle(.plain)
                        .foregroundStyle(AppTheme.textPrimary)
                    if !taskVM.searchQuery.isEmpty {
                        Button {
                            taskVM.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

                // Quick statistics chips
                HStack(spacing: 8) {
                    KanbanStatPill(
                        title: "To Do",
                        count: taskVM.todoTasksCount,
                        color: AppTheme.riverSlate
                    )
                    KanbanStatPill(
                        title: "In Progress",
                        count: taskVM.inProgressTasksCount,
                        color: AppTheme.sandstone
                    )
                    KanbanStatPill(
                        title: "Done",
                        count: taskVM.doneTasksCount,
                        color: AppTheme.success
                    )
                }

                Button {
                    targetColumnStatus = .todo
                    showingAddTaskSheet = true
                } label: {
                    Label("New Task", systemImage: "plus")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .controlSize(.regular)
            }
        }
        .padding(16)
        .background(AppTheme.background)
    }
}

// MARK: - Kanban Stat Pill

private struct KanbanStatPill: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(count)")
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
}

// MARK: - Kanban Column View

private struct KanbanColumnView: View {
    let status: TaskStatus
    let tasks: [TaskItem]
    let columnWidth: CGFloat
    let onAddTask: () -> Void
    let onQuickAdd: (String, TaskPriority) -> Void
    let onMoveTask: (UUID, TaskStatus) -> Void
    let onToggleTask: (TaskItem) -> Void
    let onDeleteTask: (UUID) -> Void
    let onEditTask: (TaskItem) -> Void
    let onIncrementPomodoro: (UUID) -> Void

    @State private var isShowingInlineAdd: Bool = false
    @State private var inlineTaskTitle: String = ""
    @State private var inlineTaskPriority: TaskPriority = .medium

    var body: some View {
        VStack(spacing: 0) {
            // Column Header
            columnHeaderView
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

            Divider()

            // Inline Quick Add Bar (when active)
            if isShowingInlineAdd {
                inlineAddBar
                    .padding(12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Divider()
            }

            // Scrollable Task Cards
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if tasks.isEmpty {
                        emptyColumnPlaceholder
                    } else {
                        ForEach(tasks) { task in
                            KanbanCardView(
                                task: task,
                                onMove: { newStatus in onMoveTask(task.id, newStatus) },
                                onToggle: { onToggleTask(task) },
                                onDelete: { onDeleteTask(task.id) },
                                onEdit: { onEditTask(task) },
                                onIncrementPomodoro: { onIncrementPomodoro(task.id) }
                            )
                        }
                    }
                }
                .padding(12)
            }

            // Column Bottom Add Button
            if !isShowingInlineAdd {
                Divider()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isShowingInlineAdd = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text("Add Task")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        }
        .frame(width: columnWidth)
        .background(AppTheme.sidebarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var columnHeaderView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text(status.rawValue)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("\(tasks.count)")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(Capsule())

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isShowingInlineAdd.toggle()
                }
            } label: {
                Image(systemName: isShowingInlineAdd ? "xmark" : "plus")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.cardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(isShowingInlineAdd ? "Close inline add" : "Quick add task to \(status.rawValue)")
        }
    }

    private var inlineAddBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Task title...", text: $inlineTaskTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitInlineAdd()
                }

            HStack {
                Picker("Priority", selection: $inlineTaskPriority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .controlSize(.small)

                Spacer()

                Button("Cancel") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isShowingInlineAdd = false
                        inlineTaskTitle = ""
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

                Button("Add") {
                    submitInlineAdd()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .controlSize(.small)
                .disabled(inlineTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(8)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func submitInlineAdd() {
        let trimmed = inlineTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onQuickAdd(trimmed, inlineTaskPriority)
        inlineTaskTitle = ""
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            isShowingInlineAdd = false
        }
    }

    private var emptyColumnPlaceholder: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 24)
            Image(systemName: emptyIcon)
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.textTertiary.opacity(0.5))
            Text(emptyMessage)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textTertiary)
            Spacer().frame(height: 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var emptyIcon: String {
        switch status {
        case .todo: return "tray"
        case .inProgress: return "hourglass.bottomhalf.filled"
        case .done: return "checkmark.seal"
        }
    }

    private var emptyMessage: String {
        switch status {
        case .todo: return "No tasks to do"
        case .inProgress: return "No tasks in progress"
        case .done: return "No completed tasks"
        }
    }
}

// MARK: - Kanban Card View

private struct KanbanCardView: View {
    let task: TaskItem
    let onMove: (TaskStatus) -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onIncrementPomodoro: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Card Top Badges: Priority + Pomodoro
            HStack {
                // Priority Badge
                HStack(spacing: 3) {
                    Image(systemName: task.priority.icon)
                    Text(task.priority.rawValue)
                }
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(task.priority.color.opacity(0.12))
                .foregroundStyle(task.priority.color)
                .clipShape(Capsule())

                Spacer()

                // Pomodoro estimate pill
                Button {
                    onIncrementPomodoro()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "timer")
                            .font(.system(size: 9))
                        Text("\(task.completedPomodoros)/\(task.estimatedPomodoros)")
                            .font(.caption2.monospacedDigit().bold())
                        if isHovered {
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.cardBackgroundSubtle)
                    .foregroundStyle(AppTheme.textSecondary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Completed pomodoros (tap to +1)")
            }

            // Title & Notes
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body.weight(task.isCompleted ? .regular : .semibold))
                    .strikethrough(task.isCompleted, color: AppTheme.textSecondary)
                    .foregroundStyle(task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .lineLimit(2)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
            }

            // Tags
            if !task.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(task.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.cardBackgroundSubtle)
                            .foregroundStyle(AppTheme.textTertiary)
                            .clipShape(Capsule())
                    }
                }
            }

            // Reminders & Due Dates Indicators
            if task.reminderDate != nil || task.dueDate != nil {
                HStack(spacing: 8) {
                    if let reminder = task.reminderDate {
                        HStack(spacing: 3) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 8))
                            Text(formatReminderDate(reminder))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(AppTheme.sandstone)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.sandstone.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    if let due = task.dueDate {
                        let isOverdue = !task.isCompleted && due < Date()
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 8))
                            Text(formatDueDate(due))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(isOverdue ? AppTheme.terracotta : AppTheme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isOverdue ? AppTheme.terracotta.opacity(0.12) : AppTheme.cardBackgroundSubtle)
                        .clipShape(Capsule())
                    }
                }
            }

            Divider()

            // Card Action Buttons Footer (One-tap moves)
            cardActionFooter
        }
        .padding(12)
        .calmCard(isHovered: isHovered, cornerRadius: 10)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Menu("Move to...") {
                Button("To Do") { onMove(.todo) }
                Button("In Progress") { onMove(.inProgress) }
                Button("Done") { onMove(.done) }
            }

            Button {
                onIncrementPomodoro()
            } label: {
                Label("Add Pomodoro (+1)", systemImage: "timer")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit Task", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    // MARK: - Action Buttons Footer
    @ViewBuilder
    private var cardActionFooter: some View {
        HStack(spacing: 6) {
            switch task.status {
            case .todo:
                // Move Right to In Progress
                Button {
                    onMove(.inProgress)
                } label: {
                    HStack(spacing: 3) {
                        Text("Start")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.sandstone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.sandstone.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Move to In Progress")

                Spacer()

                // Mark Done Checkmark
                Button {
                    onMove(.done)
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Mark as Done")

            case .inProgress:
                // Move Left to To Do
                Button {
                    onMove(.todo)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.left")
                        Text("To Do")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(AppTheme.cardBackgroundSubtle)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Move back to To Do")

                Spacer()

                // Move Right to Done
                Button {
                    onMove(.done)
                } label: {
                    HStack(spacing: 3) {
                        Text("Done")
                        Image(systemName: "checkmark")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.success.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Mark as Done")

            case .done:
                // Move Left to In Progress
                Button {
                    onMove(.inProgress)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.left")
                        Text("In Progress")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(AppTheme.cardBackgroundSubtle)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Move back to In Progress")

                // Move back to To Do
                Button {
                    onMove(.todo)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Restart in To Do")

                Spacer()

                // Delete
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(AppTheme.terracotta.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Delete Task")
            }
        }
    }

    private func formatReminderDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if calendar.isDateInToday(date) {
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }

    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            return "Due today"
        } else if calendar.isDateInTomorrow(date) {
            return "Due tomorrow"
        } else {
            formatter.dateFormat = "MMM d"
            return "Due \(formatter.string(from: date))"
        }
    }
}

// MARK: - Kanban Task Form Sheet (Add / Edit)

private struct KanbanTaskFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    var editingTask: TaskItem?
    var initialStatus: TaskStatus = .todo
    var onSave: (String, String, TaskPriority, TaskStatus, Date?, Date?, [String], Int) -> Void

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var priority: TaskPriority = .medium
    @State private var status: TaskStatus = .todo
    @State private var tagText: String = ""
    @State private var pomodoros: Int = 1

    @State private var hasReminder: Bool = false
    @State private var reminderDate: Date = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()

    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    init(
        initialStatus: TaskStatus = .todo,
        editingTask: TaskItem? = nil,
        onSave: @escaping (String, String, TaskPriority, TaskStatus, Date?, Date?, [String], Int) -> Void
    ) {
        self.initialStatus = initialStatus
        self.editingTask = editingTask
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(editingTask == nil ? "New Task" : "Edit Task")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            TextField("Task title (e.g. Finish quarterly report)", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Notes or extra details (optional)", text: $notes)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 20) {
                Picker("Status:", selection: $status) {
                    ForEach(TaskStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Priority:", selection: $priority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack {
                TextField("Tag (e.g. Work, Study)", text: $tagText)
                    .textFieldStyle(.roundedBorder)

                Stepper("Estimated Pomodoros: \(pomodoros)", value: $pomodoros, in: 1...10)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            // Timed Reminder Section
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable Timed Reminder", isOn: $hasReminder)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)

                if hasReminder {
                    DatePicker(
                        "Reminder Date & Time:",
                        selection: $reminderDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                }
            }
            .padding(10)
            .background(AppTheme.cardBackgroundSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Due Date Section
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Set Due Date", isOn: $hasDueDate)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)

                if hasDueDate {
                    DatePicker(
                        "Due Date:",
                        selection: $dueDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                }
            }
            .padding(10)
            .background(AppTheme.cardBackgroundSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(editingTask == nil ? "Create Task" : "Save Changes") {
                    let tags = tagText.trimmingCharacters(in: .whitespaces).isEmpty ? [] : [tagText.trimmingCharacters(in: .whitespaces)]
                    onSave(
                        title,
                        notes,
                        priority,
                        status,
                        hasReminder ? reminderDate : nil,
                        hasDueDate ? dueDate : nil,
                        tags,
                        pomodoros
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 520)
        .onAppear {
            if let task = editingTask {
                title = task.title
                notes = task.notes
                priority = task.priority
                status = task.status
                tagText = task.tags.joined(separator: ", ")
                pomodoros = task.estimatedPomodoros
                if let r = task.reminderDate {
                    hasReminder = true
                    reminderDate = r
                }
                if let d = task.dueDate {
                    hasDueDate = true
                    dueDate = d
                }
            } else {
                status = initialStatus
            }
        }
    }
}
