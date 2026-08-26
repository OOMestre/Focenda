import SwiftUI

public struct TaskListView: View {
    @Bindable var taskVM: TaskListViewModel
    @State private var showingAddTaskSheet: Bool = false
    @State private var newTaskTitle: String = ""
    @State private var newTaskNotes: String = ""
    @State private var newTaskPriority: TaskPriority = .medium
    @State private var newTaskTag: String = ""
    @State private var newTaskEstimatedPomodoros: Int = 1

    public init(taskVM: TaskListViewModel) {
        self.taskVM = taskVM
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search tasks by title, notes, or tags...", text: $taskVM.searchQuery)
                            .textFieldStyle(.plain)
                        if !taskVM.searchQuery.isEmpty {
                            Button {
                                taskVM.searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button {
                        showingAddTaskSheet = true
                    } label: {
                        Label("New Task", systemImage: "plus")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }

                // Quick Filters
                HStack {
                    Picker("Filter", selection: $taskVM.currentFilter) {
                        Text("All (\(taskVM.tasks.count))").tag(TaskFilter.all)
                        Text("Active (\(taskVM.pendingTasksCount))").tag(TaskFilter.active)
                        Text("Completed (\(taskVM.completedTasksCount))").tag(TaskFilter.completed)
                        Text("High Priority (\(taskVM.highPriorityPendingCount))").tag(TaskFilter.highPriority)
                    }
                    .pickerStyle(.segmented)

                    Spacer()
                }
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Task List
            if taskVM.filteredTasks.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "tray.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text("No tasks found")
                        .font(.title3.bold())
                    Text("Adjust your filter or create a new task to get things done.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                }
                .listStyle(.plain)
                .animation(.default, value: taskVM.filteredTasks)
            }
        }
        .navigationTitle("Tasks")
        .sheet(isPresented: $showingAddTaskSheet) {
            VStack(alignment: .leading, spacing: 18) {
                Text("New Task")
                    .font(.title2.bold())

                TextField("Task title (e.g. Finish quarterly report)", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)

                TextField("Notes or extra details (optional)", text: $newTaskNotes)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 20) {
                    Picker("Priority:", selection: $newTaskPriority) {
                        ForEach(TaskPriority.allCases) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack {
                    TextField("Tag (e.g. Work, Study)", text: $newTaskTag)
                        .textFieldStyle(.roundedBorder)

                    Stepper("Estimated Pomodoros: \(newTaskEstimatedPomodoros)", value: $newTaskEstimatedPomodoros, in: 1...10)
                }

                HStack {
                    Button("Cancel") {
                        showingAddTaskSheet = false
                    }
                    .keyboardShortcut(.cancelAction)

                    Spacer()

                    Button("Create Task") {
                        let tags = newTaskTag.isEmpty ? [] : [newTaskTag.trimmingCharacters(in: .whitespaces)]
                        taskVM.addTask(
                            title: newTaskTitle,
                            notes: newTaskNotes,
                            priority: newTaskPriority,
                            tags: tags,
                            estimatedPomodoros: newTaskEstimatedPomodoros
                        )
                        newTaskTitle = ""
                        newTaskNotes = ""
                        newTaskTag = ""
                        newTaskEstimatedPomodoros = 1
                        showingAddTaskSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 10)
            }
            .padding(24)
            .frame(width: 480)
        }
    }
}

// MARK: - Task Row View

private struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovered: Bool = false
    @State private var isChecking: Bool = false

    var body: some View {
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
                    .foregroundStyle(task.isCompleted ? Color.green : Color.secondary)
                    .scaleEffect(isChecking ? 1.3 : 1.0)
            }
            .buttonStyle(.plain)
            .help(task.isCompleted ? "Mark as active" : "Mark as completed")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body.weight(task.isCompleted ? .regular : .medium))
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !task.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(task.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2.bold())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .foregroundStyle(.secondary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            // Pomodoro badge
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("\(task.completedPomodoros)/\(task.estimatedPomodoros)")
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.04))
            .clipShape(Capsule())

            // Priority badge
            HStack(spacing: 4) {
                Image(systemName: task.priority.icon)
                Text(task.priority.rawValue)
            }
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(task.priority.color.opacity(0.14))
            .foregroundStyle(task.priority.color)
            .clipShape(Capsule())

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(isHovered ? 0.85 : 0.4))
                    .frame(width: 24, height: 24)
                    .background(isHovered ? Color.red.opacity(0.1) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete task")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor) : Color.primary.opacity(0.02))
                .shadow(
                    color: isHovered ? Color.black.opacity(0.06) : Color.clear,
                    radius: 6,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isHovered ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03),
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
