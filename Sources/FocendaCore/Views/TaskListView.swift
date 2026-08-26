import SwiftUI

public enum TaskViewMode: String, CaseIterable, Identifiable {
    case kanban = "Kanban"
    case list = "List"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .kanban: return "Kanban Board"
        case .list: return "List View"
        }
    }

    public var iconName: String {
        switch self {
        case .kanban: return "rectangle.split.3x1"
        case .list: return "list.bullet"
        }
    }
}

public struct TaskListView: View {
    @Bindable var taskVM: TaskListViewModel
    @State private var viewMode: TaskViewMode = .list
    @State private var showingAddTaskSheet: Bool = false
    @State private var editingTask: TaskItem? = nil

    // New task form state
    @State private var newTaskTitle: String = ""
    @State private var newTaskNotes: String = ""
    @State private var newTaskPriority: TaskPriority = .medium
    @State private var newTaskStatus: TaskStatus = .todo
    @State private var newTaskTag: String = ""
    @State private var newTaskEstimatedPomodoros: Int = 1
    @State private var newTaskHasReminder: Bool = false
    @State private var newTaskReminderDate: Date = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var newTaskHasDueDate: Bool = false
    @State private var newTaskDueDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    public init(taskVM: TaskListViewModel) {
        self.taskVM = taskVM
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search, View Switcher and Filter Bar
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(AppTheme.textTertiary)
                            TextField("Search tasks by title, notes, or tags...", text: $taskVM.searchQuery)
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
                        .frame(minWidth: 200, idealWidth: 280)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )

                        // View Mode Switcher (Kanban Board vs List View)
                        Picker("View", selection: $viewMode) {
                            ForEach(TaskViewMode.allCases) { mode in
                                Label(mode.title, systemImage: mode.iconName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                        .fixedSize(horizontal: true, vertical: false)

                        Button {
                            showingAddTaskSheet = true
                        } label: {
                            Label("New Task", systemImage: "plus")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.deepFocus)
                        .controlSize(.regular)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.vertical, 2)
                }

                // Quick Filters (only displayed in List view mode)
                if viewMode == .list {
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack {
                            Picker("Filter", selection: $taskVM.currentFilter) {
                                Text("All (\(taskVM.tasks.count))").tag(TaskFilter.all)
                                Text("Active (\(taskVM.pendingTasksCount))").tag(TaskFilter.active)
                                Text("Completed (\(taskVM.completedTasksCount))").tag(TaskFilter.completed)
                                Text("High Priority (\(taskVM.highPriorityPendingCount))").tag(TaskFilter.highPriority)
                            }
                            .pickerStyle(.segmented)
                            .fixedSize(horizontal: true, vertical: false)

                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(16)
            .background(AppTheme.background)

            Divider()

            // View Content: List vs Kanban Board
            if viewMode == .kanban {
                KanbanBoardView(taskVM: taskVM, showHeader: false, initialViewMode: .kanban)
            } else {
                taskListViewContent
            }
        }
        .background(AppTheme.background)
        .navigationTitle(viewMode == .kanban ? "Kanban Board" : "Tasks")
        .sheet(isPresented: $showingAddTaskSheet) {
            addTaskSheetView
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

    // MARK: - List Mode View Content
    @ViewBuilder
    private var taskListViewContent: some View {
        if taskVM.filteredTasks.isEmpty {
            VStack(spacing: 14) {
                Spacer()
                Image(systemName: "tray.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.6))
                Text("No tasks found")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Adjust your filter or create a new task to get things done.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
        } else {
            GeometryReader { geometry in
                let minTableWidth: CGFloat = 580
                let totalWidth = max(minTableWidth, geometry.size.width)

                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    LazyVStack(spacing: 8) {
                        ForEach(taskVM.filteredTasks) { task in
                            TaskRowView(
                                task: task,
                                onToggle: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                                        taskVM.toggleTaskCompletion(task)
                                    }
                                },
                                onDelete: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        taskVM.deleteTask(withId: task.id)
                                    }
                                },
                                onMove: { newStatus in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        taskVM.moveTask(id: task.id, to: newStatus)
                                    }
                                },
                                onEdit: {
                                    editingTask = task
                                },
                                onIncrementPomodoro: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        taskVM.incrementTaskPomodoro(taskId: task.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(16)
                    .frame(minWidth: totalWidth, alignment: .topLeading)
                }
            }
            .background(AppTheme.background)
            .animation(.default, value: taskVM.filteredTasks)
        }
    }

    // MARK: - Add Task Sheet
    private var addTaskSheetView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New Task")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Task title (e.g. Finish quarterly report)", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (optional)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Notes or extra details...", text: $newTaskNotes)
                    .textFieldStyle(.roundedBorder)
            }

            // Status and Priority segmented pickers with clear top labels to avoid wrapping
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Status")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker("Status", selection: $newTaskStatus) {
                        ForEach(TaskStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Priority")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker("Priority", selection: $newTaskPriority) {
                        ForEach(TaskPriority.allCases) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .frame(maxWidth: .infinity)
            }

            // Tags & Pomodoros row
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tags")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("e.g. Work, Study", text: $newTaskTag)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Estimated Pomodoros: \(newTaskEstimatedPomodoros)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack {
                        Stepper("", value: $newTaskEstimatedPomodoros, in: 1...10)
                            .labelsHidden()
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Timed Reminder Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Enable Timed Reminder", systemImage: "bell.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Toggle("", isOn: $newTaskHasReminder)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if newTaskHasReminder {
                    HStack {
                        Text("Reminder Date & Time:")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $newTaskReminderDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .background(AppTheme.cardBackgroundSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )

            // Due Date Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Set Due Date", systemImage: "calendar")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Toggle("", isOn: $newTaskHasDueDate)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if newTaskHasDueDate {
                    HStack {
                        Text("Due Date:")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $newTaskDueDate,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .background(AppTheme.cardBackgroundSubtle)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )

            HStack {
                Button("Cancel") {
                    showingAddTaskSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create Task") {
                    let tags = newTaskTag.trimmingCharacters(in: .whitespaces).isEmpty ? [] : [newTaskTag.trimmingCharacters(in: .whitespaces)]
                    taskVM.addTask(
                        title: newTaskTitle,
                        notes: newTaskNotes,
                        priority: newTaskPriority,
                        status: newTaskStatus,
                        reminderDate: newTaskHasReminder ? newTaskReminderDate : nil,
                        dueDate: newTaskHasDueDate ? newTaskDueDate : nil,
                        tags: tags,
                        estimatedPomodoros: newTaskEstimatedPomodoros
                    )
                    newTaskTitle = ""
                    newTaskNotes = ""
                    newTaskTag = ""
                    newTaskEstimatedPomodoros = 1
                    newTaskHasReminder = false
                    newTaskHasDueDate = false
                    showingAddTaskSheet = false
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 520)
    }
}

// MARK: - Task Row View

public struct TaskRowView: View {
    public let task: TaskItem
    public let onToggle: () -> Void
    public let onDelete: () -> Void
    public var onMove: ((TaskStatus) -> Void)? = nil
    public var onEdit: (() -> Void)? = nil
    public var onIncrementPomodoro: (() -> Void)? = nil

    @State private var isHovered: Bool = false
    @State private var isChecking: Bool = false

    public init(
        task: TaskItem,
        onToggle: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onMove: ((TaskStatus) -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onIncrementPomodoro: (() -> Void)? = nil
    ) {
        self.task = task
        self.onToggle = onToggle
        self.onDelete = onDelete
        self.onMove = onMove
        self.onEdit = onEdit
        self.onIncrementPomodoro = onIncrementPomodoro
    }

    public var body: some View {
        HStack(spacing: 14) {
            // Bouncy checkmark toggle button
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

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(task.title)
                        .font(.body.weight(task.isCompleted ? .regular : .medium))
                        .strikethrough(task.isCompleted, color: AppTheme.textSecondary)
                        .foregroundStyle(task.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)
                        .lineLimit(2)

                    // Status Pill (Anti-wrapping)
                    HStack(spacing: 3) {
                        Circle()
                            .fill(task.status.color)
                            .frame(width: 5, height: 5)
                        Text(task.status.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(task.status.color.opacity(0.12))
                    .foregroundStyle(task.status.color)
                    .clipShape(Capsule())
                    .fixedSize(horizontal: true, vertical: false)
                }

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    if !task.tags.isEmpty {
                        ForEach(task.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2.bold())
                                .lineLimit(1)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(AppTheme.cardBackgroundSubtle)
                                .foregroundStyle(AppTheme.textSecondary)
                                .clipShape(Capsule())
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }

                    if let reminder = task.reminderDate {
                        HStack(spacing: 3) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 8))
                            Text(formatReminderDate(reminder))
                                .font(.caption2.bold())
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.sandstone.opacity(0.12))
                        .foregroundStyle(AppTheme.sandstone)
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: false)
                    }

                    if let due = task.dueDate {
                        let isOverdue = !task.isCompleted && due < Date()
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 8))
                            Text(formatDueDate(due))
                                .font(.caption2.bold())
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isOverdue ? AppTheme.terracotta.opacity(0.12) : AppTheme.cardBackgroundSubtle)
                        .foregroundStyle(isOverdue ? AppTheme.terracotta : AppTheme.textSecondary)
                        .clipShape(Capsule())
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            // Pomodoro badge (Anti-wrapping)
            Button {
                onIncrementPomodoro?()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 9))
                    Text("\(task.completedPomodoros)/\(task.estimatedPomodoros)")
                        .font(.caption.bold().monospacedDigit())
                        .lineLimit(1)
                    if onIncrementPomodoro != nil {
                        Text("+1")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(AppTheme.accent.opacity(0.12))
                            .clipShape(Capsule())
                            .lineLimit(1)
                    }
                }
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(.plain)
            .disabled(onIncrementPomodoro == nil)
            .fixedSize(horizontal: true, vertical: false)
            .help("Completed pomodoros (tap to +1)")

            // Priority badge (Anti-wrapping)
            HStack(spacing: 4) {
                Image(systemName: task.priority.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(task.priority.rawValue)
                    .font(.caption2.bold())
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(task.priority.color.opacity(0.12))
            .foregroundStyle(task.priority.color)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)

            // Edit button (if onEdit != nil)
            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .fixedSize(horizontal: true, vertical: false)
                .help("Edit task")
            }

            // Move Status Menu
            if let onMove = onMove {
                Menu {
                    Button("To Do") { onMove(.todo) }
                    Button("In Progress") { onMove(.inProgress) }
                    Button("Done") { onMove(.done) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
                .fixedSize(horizontal: true, vertical: false)
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(AppTheme.terracotta.opacity(isHovered ? 0.9 : 0.4))
                    .frame(width: 24, height: 24)
                    .background(isHovered ? AppTheme.terracotta.opacity(0.12) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: false)
            .help("Delete task")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .calmCard(isHovered: isHovered, cornerRadius: 10)
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formatReminderDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if calendar.isDateInToday(date) {
            return "Today \(formatter.string(from: date))"
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
