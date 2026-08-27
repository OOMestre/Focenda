import SwiftUI

/// Centralizes the Kanban width rules so that all three columns remain visible in
/// the standard detail area, while retaining horizontal scrolling as a fallback.
enum KanbanBoardLayout {
    static let columnCount: CGFloat = 3
    static let preferredColumnWidth: CGFloat = 320
    static let minimumColumnWidth: CGFloat = 200
    static let columnSpacing: CGFloat = 14
    static let horizontalPadding: CGFloat = 32

    static func columnWidth(for availableWidth: CGFloat) -> CGFloat {
        let equalColumnWidth = (
            availableWidth
                - horizontalPadding
                - (columnSpacing * (columnCount - 1))
        ) / columnCount

        return min(preferredColumnWidth, max(minimumColumnWidth, equalColumnWidth))
    }

    static func contentWidth(for availableWidth: CGFloat) -> CGFloat {
        max(
            availableWidth,
            (columnWidth(for: availableWidth) * columnCount)
                + (columnSpacing * (columnCount - 1))
                + horizontalPadding
        )
    }
}

/// A unified visual task hub featuring an interactive 3-column Kanban board and linear List view in Focenda
public struct KanbanBoardView: View {
    @Bindable var taskVM: TaskListViewModel
    public var showHeader: Bool
    @State public var viewMode: TaskViewMode = .kanban

    @State private var showingAddTaskSheet: Bool = false
    @State private var targetColumnStatus: TaskStatus = .todo
    @State private var editingTask: TaskItem? = nil

    public init(
        taskVM: TaskListViewModel,
        showHeader: Bool = true,
        initialViewMode: TaskViewMode = .kanban
    ) {
        self.taskVM = taskVM
        self.showHeader = showHeader
        self._viewMode = State(initialValue: initialViewMode)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showHeader {
                headerView
                Divider()
            }

            // View Content Switcher: Kanban Board (Default) vs Linear List View
            if viewMode == .kanban {
                kanbanBoardContent
            } else {
                listViewContent
            }
        }
        .background(AppTheme.background)
        .navigationTitle(viewMode == .kanban ? "Kanban Board" : "Tasks")
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

    // MARK: - Header Bar & Controls
    private var headerView: some View {
        ViewThatFits(in: .horizontal) {
            fullHeaderControls
            compactHeaderControls
        }
        .padding(16)
        .background(AppTheme.background)
    }

    private var fullHeaderControls: some View {
        HStack(spacing: 14) {
            searchField
            viewModeSwitcher
            headerOverview
            newTaskButton
        }
    }

    private var compactHeaderControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                searchField
                newTaskButton
            }

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 14) {
                    viewModeSwitcher
                    headerOverview
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textTertiary)
            TextField(
                viewMode == .kanban
                    ? "Search Kanban tasks by title, notes, or tags..."
                    : "Search tasks by title, notes, or tags...",
                text: $taskVM.searchQuery
            )
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
        .frame(minWidth: 180, idealWidth: 260, maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var viewModeSwitcher: some View {
        HStack(spacing: 2) {
            Button {
                withAnimation(.spring(response: 0.25)) {
                    viewMode = .kanban
                }
            } label: {
                Image(systemName: "rectangle.split.3x1")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(viewMode == .kanban ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 28, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(viewMode == .kanban ? AppTheme.accent.opacity(0.15) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(viewMode == .kanban ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Kanban Board")

            Button {
                withAnimation(.spring(response: 0.25)) {
                    viewMode = .list
                }
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(viewMode == .list ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 28, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(viewMode == .list ? AppTheme.accent.opacity(0.15) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(viewMode == .list ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("List View")
        }
        .padding(2)
        .background(AppTheme.cardBackgroundSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private var headerOverview: some View {
        if viewMode == .kanban {
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
            .fixedSize(horizontal: true, vertical: false)
        } else {
            Picker("Filter", selection: $taskVM.currentFilter) {
                Text("All (\(taskVM.tasks.count))").tag(TaskFilter.all)
                Text("Active (\(taskVM.pendingTasksCount))").tag(TaskFilter.active)
                Text("Completed (\(taskVM.completedTasksCount))").tag(TaskFilter.completed)
                Text("High Priority (\(taskVM.highPriorityPendingCount))").tag(TaskFilter.highPriority)
            }
            .pickerStyle(.segmented)
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var newTaskButton: some View {
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
        .fixedSize(horizontal: true, vertical: false)
    }

    // MARK: - 3-Column Kanban Board Layout
    private var kanbanBoardContent: some View {
        GeometryReader { geometry in
            let columnWidth = KanbanBoardLayout.columnWidth(for: geometry.size.width)
            let totalWidth = KanbanBoardLayout.contentWidth(for: geometry.size.width)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: KanbanBoardLayout.columnSpacing) {
                    ForEach(TaskStatus.allCases) { status in
                        KanbanColumnView(
                            status: status,
                            tasks: taskVM.tasks(for: status),
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
                            onDuplicateTask: { taskId in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    _ = taskVM.duplicateTask(withId: taskId)
                                }
                            },
                            onIncrementPomodoro: { taskId in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    taskVM.incrementTaskPomodoro(taskId: taskId)
                                }
                            }
                        )
                        .frame(width: columnWidth)
                        .frame(maxHeight: .infinity)
                    }
                }
                .padding(20)
                .frame(
                    minWidth: totalWidth,
                    maxWidth: totalWidth,
                    minHeight: max(0, geometry.size.height - 40),
                    alignment: .topLeading
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .forceVisibleScrollers(horizontal: true, vertical: false)
        }
    }

    // MARK: - Linear List View Layout
    @ViewBuilder
    private var listViewContent: some View {
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
            List {
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
                        onDuplicate: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                _ = taskVM.duplicateTask(task)
                            }
                        },
                        onIncrementPomodoro: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                taskVM.incrementTaskPomodoro(taskId: task.id)
                            }
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .background(AppTheme.background)
            .animation(.default, value: taskVM.filteredTasks)
        }
    }
}

// MARK: - Kanban Stat Pill

public struct KanbanStatPill: View {
    public let title: String
    public let count: Int
    public let color: Color

    public init(title: String, count: Int, color: Color) {
        self.title = title
        self.count = count
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(count)")
                .font(.caption.bold())
                .monospacedDigit()
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Kanban Column View

public struct KanbanColumnView: View {
    public let status: TaskStatus
    public let tasks: [TaskItem]
    public let onAddTask: () -> Void
    public let onQuickAdd: (String, TaskPriority) -> Void
    public let onMoveTask: (UUID, TaskStatus) -> Void
    public let onToggleTask: (TaskItem) -> Void
    public let onDeleteTask: (UUID) -> Void
    public let onEditTask: (TaskItem) -> Void
    public let onDuplicateTask: (UUID) -> Void
    public let onIncrementPomodoro: (UUID) -> Void

    @State private var isShowingInlineAdd: Bool = false
    @State private var inlineTaskTitle: String = ""
    @State private var inlineTaskPriority: TaskPriority = .medium
    @State private var isDropTargeted: Bool = false

    public init(
        status: TaskStatus,
        tasks: [TaskItem],
        onAddTask: @escaping () -> Void,
        onQuickAdd: @escaping (String, TaskPriority) -> Void,
        onMoveTask: @escaping (UUID, TaskStatus) -> Void,
        onToggleTask: @escaping (TaskItem) -> Void,
        onDeleteTask: @escaping (UUID) -> Void,
        onEditTask: @escaping (TaskItem) -> Void,
        onDuplicateTask: @escaping (UUID) -> Void = { _ in },
        onIncrementPomodoro: @escaping (UUID) -> Void
    ) {
        self.status = status
        self.tasks = tasks
        self.onAddTask = onAddTask
        self.onQuickAdd = onQuickAdd
        self.onMoveTask = onMoveTask
        self.onToggleTask = onToggleTask
        self.onDeleteTask = onDeleteTask
        self.onEditTask = onEditTask
        self.onDuplicateTask = onDuplicateTask
        self.onIncrementPomodoro = onIncrementPomodoro
    }

    public var body: some View {
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
                                onDuplicate: { onDuplicateTask(task.id) },
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
                            .lineLimit(1)
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        }
        .background(
            isDropTargeted ? status.color.opacity(0.08) : AppTheme.sidebarBackground
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isDropTargeted ? status.color : AppTheme.border,
                    lineWidth: isDropTargeted ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
        .dropDestination(for: String.self) { items, location in
            guard let idString = items.first, let taskId = UUID(uuidString: idString) else {
                return false
            }
            onMoveTask(taskId, status)
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = targeted
            }
        }
    }

    private var columnHeaderView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text(status.rawValue)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Text("\(tasks.count)")
                .font(.caption.bold())
                .monospacedDigit()
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(Capsule())
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

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
                .lineLimit(1)
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

public struct KanbanCardView: View {
    public let task: TaskItem
    public let onMove: (TaskStatus) -> Void
    public let onToggle: () -> Void
    public let onDelete: () -> Void
    public let onEdit: () -> Void
    public let onDuplicate: () -> Void
    public let onIncrementPomodoro: () -> Void

    @State private var isHovered: Bool = false

    public init(
        task: TaskItem,
        onMove: @escaping (TaskStatus) -> Void,
        onToggle: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDuplicate: @escaping () -> Void = {},
        onIncrementPomodoro: @escaping () -> Void
    ) {
        self.task = task
        self.onMove = onMove
        self.onToggle = onToggle
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.onDuplicate = onDuplicate
        self.onIncrementPomodoro = onIncrementPomodoro
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                expandedCardActions
                compactCardActions
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

            if !task.tags.isEmpty {
                ViewThatFits(in: .horizontal) {
                    tagPills
                    compactTagPill
                }
            }

            if task.reminderDate != nil || task.dueDate != nil {
                ViewThatFits(in: .horizontal) {
                    datePills
                    compactDatePills
                }
            }

            Divider()

            // Card Direct Move Pill Selector Footer (Anti-wrapping)
            cardDirectMoveFooter
        }
        .padding(12)
        .calmCard(isHovered: isHovered, cornerRadius: 10)
        .onHover { hovering in
            isHovered = hovering
        }
        .draggable(task.id.uuidString)
        .contextMenu {
            Menu("Move to...") {
                Button("To Do") { onMove(.todo) }
                Button("In Progress") { onMove(.inProgress) }
                Button("Done") { onMove(.done) }
            }

            Button {
                onDuplicate()
            } label: {
                Label("Duplicate Task", systemImage: "doc.on.doc")
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

    private var expandedCardActions: some View {
        HStack(spacing: 6) {
            priorityBadge
            Spacer(minLength: 0)
            pomodoroButton
            duplicateButton
            editButton
            deleteButton
            moreActionsMenu
        }
    }

    private var compactCardActions: some View {
        HStack(spacing: 6) {
            priorityBadge
            Spacer(minLength: 0)
            moreActionsMenu
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: task.priority.icon)
                .font(.system(size: 9, weight: .bold))
            Text(task.priority.rawValue)
                .font(.system(size: 10, weight: .bold))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(task.priority.color.opacity(0.12))
        .foregroundStyle(task.priority.color)
        .clipShape(Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }

    private var pomodoroButton: some View {
        Button {
            onIncrementPomodoro()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "timer")
                    .font(.system(size: 9))
                Text("\(task.completedPomodoros)/\(task.estimatedPomodoros)")
                    .font(.caption2.monospacedDigit().bold())
                    .lineLimit(1)
                Text("+1")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Capsule())
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.cardBackgroundSubtle)
            .foregroundStyle(AppTheme.textSecondary)
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .help("Completed pomodoros (tap to +1)")
    }

    private var duplicateButton: some View {
        Button {
            onDuplicate()
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 20, height: 20)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .help("Duplicate task")
    }

    private var editButton: some View {
        Button {
            onEdit()
        } label: {
            Image(systemName: "pencil")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 20, height: 20)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .help("Edit task")
    }

    private var deleteButton: some View {
        Button {
            onDelete()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.terracotta.opacity(0.85))
                .frame(width: 20, height: 20)
                .background(AppTheme.terracotta.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .help("Delete task")
    }

    private var moreActionsMenu: some View {
        Menu {
            Menu("Move to...") {
                Button("To Do") { onMove(.todo) }
                Button("In Progress") { onMove(.inProgress) }
                Button("Done") { onMove(.done) }
            }

            Button {
                onDuplicate()
            } label: {
                Label("Duplicate Task", systemImage: "doc.on.doc")
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
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 20, height: 20)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(Circle())
        }
        .menuStyle(.borderlessButton)
        .frame(width: 20, height: 20)
        .fixedSize(horizontal: true, vertical: false)
        .help("More actions")
    }

    private var tagPills: some View {
        HStack(spacing: 4) {
            ForEach(task.tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.cardBackgroundSubtle)
                    .foregroundStyle(AppTheme.textTertiary)
                    .clipShape(Capsule())
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var compactTagPill: some View {
        Text(compactTagsLabel)
            .font(.system(size: 10, weight: .medium))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.cardBackgroundSubtle)
            .foregroundStyle(AppTheme.textTertiary)
            .clipShape(Capsule())
            .accessibilityLabel("Tags: \(task.tags.joined(separator: ", "))")
    }

    private var compactTagsLabel: String {
        guard let firstTag = task.tags.first else { return "" }
        let remainingTagCount = task.tags.count - 1
        return remainingTagCount == 0 ? "#\(firstTag)" : "#\(firstTag) +\(remainingTagCount)"
    }

    @ViewBuilder
    private var datePills: some View {
        HStack(spacing: 8) {
            if let reminder = task.reminderDate {
                HStack(spacing: 3) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 8))
                    Text(formatReminderDate(reminder))
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(AppTheme.sandstone)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.sandstone.opacity(0.12))
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false)
            }

            if let due = task.dueDate {
                let isOverdue = !task.isCompleted && due < Date()
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 8))
                    Text(formatDueDate(due))
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(isOverdue ? AppTheme.terracotta : AppTheme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isOverdue ? AppTheme.terracotta.opacity(0.12) : AppTheme.cardBackgroundSubtle)
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var compactDatePills: some View {
        HStack(spacing: 8) {
            if task.reminderDate != nil {
                Image(systemName: "bell.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.sandstone)
                    .accessibilityLabel("Task has a reminder")
            }

            if task.dueDate != nil {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                    .foregroundStyle(taskIsOverdue ? AppTheme.terracotta : AppTheme.textSecondary)
                    .accessibilityLabel("Task has a due date")
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(AppTheme.cardBackgroundSubtle)
        .clipShape(Capsule())
    }

    private var taskIsOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }

    // MARK: - Direct Move Pill Selector Footer
    private var cardDirectMoveFooter: some View {
        ViewThatFits(in: .horizontal) {
            expandedMoveControls
            compactMoveMenu
        }
    }

    private var expandedMoveControls: some View {
        HStack(spacing: 5) {
            Text("Move:")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            ForEach(TaskStatus.allCases) { targetStatus in
                let isCurrent = (task.status == targetStatus)
                Button {
                    if !isCurrent {
                        onMove(targetStatus)
                    }
                } label: {
                    HStack(spacing: 3) {
                        if isCurrent {
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                        } else {
                            Circle()
                                .fill(targetStatus.color)
                                .frame(width: 4, height: 4)
                        }
                        Text(targetStatus.rawValue)
                            .font(.system(size: 9, weight: isCurrent ? .bold : .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isCurrent ? targetStatus.color.opacity(0.18) : AppTheme.cardBackgroundSubtle)
                    .foregroundStyle(isCurrent ? targetStatus.color : AppTheme.textSecondary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isCurrent ? targetStatus.color.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
                    .fixedSize(horizontal: true, vertical: false)
                }
                .buttonStyle(.plain)
                .disabled(isCurrent)
                .fixedSize(horizontal: true, vertical: false)
                .help(isCurrent ? "Current column: \(targetStatus.rawValue)" : "Move to \(targetStatus.rawValue)")
            }
        }
    }

    private var compactMoveMenu: some View {
        Menu {
            ForEach(TaskStatus.allCases) { targetStatus in
                Button(targetStatus.rawValue) {
                    if task.status != targetStatus {
                        onMove(targetStatus)
                    }
                }
                .disabled(task.status == targetStatus)
            }
        } label: {
            Label("Move", systemImage: "arrow.right.circle")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .help("Move task to another column")
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

public struct KanbanTaskFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    public var editingTask: TaskItem?
    public var initialStatus: TaskStatus = .todo
    public var onSave: (String, String, TaskPriority, TaskStatus, Date?, Date?, [String], Int) -> Void

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

    public init(
        initialStatus: TaskStatus = .todo,
        editingTask: TaskItem? = nil,
        onSave: @escaping (String, String, TaskPriority, TaskStatus, Date?, Date?, [String], Int) -> Void
    ) {
        self.initialStatus = initialStatus
        self.editingTask = editingTask
        self.onSave = onSave
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(editingTask == nil ? "New Task" : "Edit Task")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Task title (e.g. Finish quarterly report)", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes (optional)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                TextField("Notes or extra details...", text: $notes)
                    .textFieldStyle(.roundedBorder)
            }

            // Status and Priority segmented pickers with clear top labels to avoid wrapping
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Status")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases) { s in
                            Text(s.rawValue).tag(s)
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
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { p in
                            Text(p.rawValue).tag(p)
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
                    TextField("e.g. Work, Study", text: $tagText)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Estimated Pomodoros: \(pomodoros)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    HStack {
                        Stepper("", value: $pomodoros, in: 1...10)
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
                    Toggle("", isOn: $hasReminder)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if hasReminder {
                    HStack {
                        Text("Reminder Date & Time:")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $reminderDate,
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
                    Toggle("", isOn: $hasDueDate)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                if hasDueDate {
                    HStack {
                        Text("Due Date:")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $dueDate,
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
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(editingTask == nil ? "Create Task" : "Save Changes") {
                    let tags = tagText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
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
        .frame(minWidth: 380, idealWidth: 480, maxWidth: 520)
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
