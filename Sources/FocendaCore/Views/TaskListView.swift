import SwiftUI

public struct TaskListView: View {
    @Bindable var taskVM: TaskListViewModel
    @State private var showingAddTaskSheet: Bool = false
    @State private var newTaskTitle: String = ""
    @State private var newTaskNotes: String = ""
    @State private var newTaskPriority: TaskPriority = .medium
    @State private var newTaskTag: String = ""
    @State private var newTaskEstimatedPomodoros: Int = 1

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
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No tasks found")
                        .font(.title3.bold())
                    Text("Try adjusting your filters or add a new task above.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(taskVM.filteredTasks) { task in
                        HStack(spacing: 14) {
                            Button {
                                withAnimation {
                                    taskVM.toggleTaskCompletion(task)
                                }
                            } label: {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.body.weight(task.isCompleted ? .regular : .medium))
                                    .strikethrough(task.isCompleted)
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
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.secondary.opacity(0.12))
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
                            .font(.caption)
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
                            .background(task.priority.color.opacity(0.15))
                            .foregroundStyle(task.priority.color)
                            .clipShape(Capsule())

                            // Delete button
                            Button {
                                taskVM.deleteTask(withId: task.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .help("Delete task")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("Tasks")
        .sheet(isPresented: $showingAddTaskSheet) {
            VStack(alignment: .leading, spacing: 18) {
                Text("New Task")
                    .font(.title2.bold())

                TextField("Task title (e.g. Finish quarterly presentation)", text: $newTaskTitle)
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
