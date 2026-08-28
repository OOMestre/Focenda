import Foundation
import SwiftUI
import Observation

public enum TaskFilter: Hashable {
    case all
    case active
    case completed
    case highPriority
}

@Observable
public final class TaskListViewModel {
    public var tasks: [TaskItem] = []
    public var currentFilter: TaskFilter = .all
    public var searchQuery: String = ""

    private let storageKey = "focenda_saved_tasks"
    private let secureStore: SecureStore

    public init(secureStore: SecureStore = .shared) {
        self.secureStore = secureStore
        // An empty array is a valid persisted state. Only seed sample tasks
        // when no value has ever been stored; a failed decode must not replace
        // the user's data with samples.
        if !secureStore.containsValue(forKey: storageKey) {
            loadSampleTasks()
        } else {
            loadTasks()
        }
    }

    public var filteredTasks: [TaskItem] {
        tasks.filter { task in
            let matchesFilter: Bool
            switch currentFilter {
            case .all:
                matchesFilter = true
            case .active:
                matchesFilter = !task.isCompleted
            case .completed:
                matchesFilter = task.isCompleted
            case .highPriority:
                matchesFilter = !task.isCompleted && task.priority == .high
            }

            let matchesSearch: Bool
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                matchesSearch = task.title.localizedCaseInsensitiveContains(searchQuery) ||
                                task.notes.localizedCaseInsensitiveContains(searchQuery) ||
                                task.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }

            return matchesFilter && matchesSearch
        }.sorted { (t1: TaskItem, t2: TaskItem) -> Bool in
            if t1.isCompleted != t2.isCompleted {
                return !t1.isCompleted
            }
            if t1.priority != t2.priority {
                return t1.priority > t2.priority
            }
            return t1.createdAt > t2.createdAt
        }
    }

    /// Tasks filtered for a specific Kanban column status, matching current search query
    public func tasks(for status: TaskStatus) -> [TaskItem] {
        tasks.filter { task in
            guard task.status == status else { return false }
            let trimmedSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSearch.isEmpty {
                return true
            }
            return task.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                   task.notes.localizedCaseInsensitiveContains(trimmedSearch) ||
                   task.tags.contains { $0.localizedCaseInsensitiveContains(trimmedSearch) }
        }.sorted { (t1: TaskItem, t2: TaskItem) -> Bool in
            if t1.priority != t2.priority {
                return t1.priority > t2.priority
            }
            return t1.createdAt > t2.createdAt
        }
    }

    public var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    public var pendingTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    public var highPriorityPendingCount: Int {
        tasks.filter { !$0.isCompleted && $0.priority == .high }.count
    }

    public var todoTasksCount: Int {
        tasks.filter { $0.status == .todo }.count
    }

    public var inProgressTasksCount: Int {
        tasks.filter { $0.status == .inProgress }.count
    }

    public var doneTasksCount: Int {
        tasks.filter { $0.status == .done }.count
    }

    public func addTask(
        title: String,
        notes: String = "",
        priority: TaskPriority = .medium,
        status: TaskStatus = .todo,
        reminderDate: Date? = nil,
        dueDate: Date? = nil,
        tags: [String] = [],
        estimatedPomodoros: Int = 1
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let newTask = TaskItem(
            title: trimmedTitle,
            notes: notes,
            priority: priority,
            status: status,
            reminderDate: reminderDate,
            dueDate: dueDate,
            tags: tags,
            estimatedPomodoros: estimatedPomodoros
        )
        tasks.insert(newTask, at: 0)

        if let reminderDate = reminderDate, reminderDate > Date() {
            NotificationManager.shared.scheduleTaskReminder(task: newTask)
        }

        saveTasks()
    }

    /// Moves a task to a different Kanban status column
    public func moveTask(id: UUID, to newStatus: TaskStatus) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].status = newStatus
        if newStatus == .done {
            if tasks[index].completedAt == nil {
                tasks[index].completedAt = Date()
            }
        } else {
            tasks[index].completedAt = nil
        }
        saveTasks()
    }

    public func toggleTaskCompletion(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            if tasks[index].status == .done {
                tasks[index].status = .todo
                tasks[index].completedAt = nil
            } else {
                tasks[index].status = .done
                tasks[index].completedAt = Date()
            }
            saveTasks()
        }
    }

    public func deleteTask(withId id: UUID) {
        if let task = tasks.first(where: { $0.id == id }) {
            NotificationManager.shared.cancelTaskReminder(task: task)
        }
        tasks.removeAll { $0.id == id }
        saveTasks()
    }

    @discardableResult
    public func duplicateTask(withId id: UUID) -> TaskItem? {
        guard let original = tasks.first(where: { $0.id == id }) else { return nil }
        return duplicateTask(original)
    }

    @discardableResult
    public func duplicateTask(_ task: TaskItem) -> TaskItem {
        let duplicated = TaskItem(
            id: UUID(),
            title: "\(task.title) (Copy)",
            notes: task.notes,
            priority: task.priority,
            status: task.status,
            isCompleted: task.isCompleted,
            createdAt: Date(),
            completedAt: task.isCompleted ? Date() : nil,
            reminderDate: (task.reminderDate != nil && task.reminderDate! > Date()) ? task.reminderDate : nil,
            dueDate: task.dueDate,
            tags: task.tags,
            estimatedPomodoros: task.estimatedPomodoros,
            completedPomodoros: 0
        )

        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.insert(duplicated, at: index + 1)
        } else {
            tasks.insert(duplicated, at: 0)
        }

        if let reminder = duplicated.reminderDate, reminder > Date() {
            NotificationManager.shared.scheduleTaskReminder(task: duplicated)
        }

        saveTasks()
        return duplicated
    }

    public func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            if let reminder = task.reminderDate, reminder > Date() {
                NotificationManager.shared.scheduleTaskReminder(task: task)
            } else if task.reminderDate == nil {
                NotificationManager.shared.cancelTaskReminder(task: task)
            }
            saveTasks()
        }
    }

    public func incrementTaskPomodoro(taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].completedPomodoros += 1
            saveTasks()
        }
    }

    public func scheduleReminder(for taskId: UUID, at date: Date) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].reminderDate = date
            NotificationManager.shared.scheduleTaskReminder(task: tasks[index])
            saveTasks()
        }
    }

    public func removeReminder(for taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            NotificationManager.shared.cancelTaskReminder(task: tasks[index])
            tasks[index].reminderDate = nil
            saveTasks()
        }
    }

    public func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            secureStore.setData(encoded, forKey: storageKey)
        }
    }

    public func loadTasks() {
        if let data = secureStore.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            self.tasks = decoded
        }
    }

    private func loadSampleTasks() {
        self.tasks = [
            TaskItem(
                title: "Plan weekly productivity goals",
                notes: "Block dedicated deep work focus sessions",
                priority: .high,
                status: .inProgress,
                reminderDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                tags: ["Planning", "Focus"],
                estimatedPomodoros: 2,
                completedPomodoros: 1
            ),
            TaskItem(
                title: "Explore Focenda features",
                notes: "Try out the focus timer, kanban board, and scratchpad",
                priority: .medium,
                status: .todo,
                reminderDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                tags: ["Welcome"],
                estimatedPomodoros: 1,
                completedPomodoros: 0
            ),
            TaskItem(
                title: "Organize project tasks & priorities",
                notes: "Categorize by urgency and impact",
                priority: .low,
                status: .done,
                completedAt: Date(),
                tags: ["Organization"],
                estimatedPomodoros: 1,
                completedPomodoros: 1
            )
        ]
        saveTasks()
    }
}
