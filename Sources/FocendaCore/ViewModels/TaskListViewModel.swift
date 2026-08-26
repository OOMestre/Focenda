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

    public init() {
        loadTasks()
        if tasks.isEmpty {
            loadSampleTasks()
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

    public var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    public var pendingTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    public var highPriorityPendingCount: Int {
        tasks.filter { !$0.isCompleted && $0.priority == .high }.count
    }

    public func addTask(
        title: String,
        notes: String = "",
        priority: TaskPriority = .medium,
        tags: [String] = [],
        estimatedPomodoros: Int = 1
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let newTask = TaskItem(
            title: trimmedTitle,
            notes: notes,
            priority: priority,
            tags: tags,
            estimatedPomodoros: estimatedPomodoros
        )
        tasks.insert(newTask, at: 0)
        saveTasks()
    }

    public func toggleTaskCompletion(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
            saveTasks()
        }
    }

    public func deleteTask(withId id: UUID) {
        tasks.removeAll { $0.id == id }
        saveTasks()
    }

    public func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }

    public func incrementTaskPomodoro(taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].completedPomodoros += 1
            saveTasks()
        }
    }

    public func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    public func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
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
                tags: ["Planning", "Focus"],
                estimatedPomodoros: 2
            ),
            TaskItem(
                title: "Explore Focenda features",
                notes: "Try out the focus timer and task list",
                priority: .medium,
                tags: ["Welcome"],
                estimatedPomodoros: 1
            ),
            TaskItem(
                title: "Organize project tasks & priorities",
                notes: "Categorize by urgency and impact",
                priority: .low,
                tags: ["Organization"],
                estimatedPomodoros: 1
            )
        ]
        saveTasks()
    }
}
