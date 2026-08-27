import XCTest
@testable import FocendaCore

final class TaskListViewModelTests: XCTestCase {

    var viewModel: TaskListViewModel!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "focenda_saved_tasks")
        viewModel = TaskListViewModel()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "focenda_saved_tasks")
        viewModel = nil
        super.tearDown()
    }

    func testAddTask() {
        let initialCount = viewModel.tasks.count
        let reminder = Date().addingTimeInterval(7200)
        let due = Date().addingTimeInterval(86400)

        viewModel.addTask(
            title: "New unit test task",
            notes: "Additional notes",
            priority: .high,
            status: .inProgress,
            reminderDate: reminder,
            dueDate: due,
            tags: ["Testing"],
            estimatedPomodoros: 3
        )

        XCTAssertEqual(viewModel.tasks.count, initialCount + 1)
        let added = viewModel.tasks.first
        XCTAssertEqual(added?.title, "New unit test task")
        XCTAssertEqual(added?.priority, .high)
        XCTAssertEqual(added?.status, .inProgress)
        XCTAssertEqual(added?.reminderDate, reminder)
        XCTAssertEqual(added?.dueDate, due)
        XCTAssertEqual(added?.estimatedPomodoros, 3)
    }

    func testMoveTask() {
        guard let task = viewModel.tasks.first else {
            XCTFail("Should contain sample tasks")
            return
        }

        // Move to inProgress
        viewModel.moveTask(id: task.id, to: .inProgress)
        XCTAssertEqual(viewModel.tasks.first { $0.id == task.id }?.status, .inProgress)
        XCTAssertFalse(viewModel.tasks.first { $0.id == task.id }?.isCompleted ?? true)
        XCTAssertNil(viewModel.tasks.first { $0.id == task.id }?.completedAt)

        // Move to done
        viewModel.moveTask(id: task.id, to: .done)
        XCTAssertEqual(viewModel.tasks.first { $0.id == task.id }?.status, .done)
        XCTAssertTrue(viewModel.tasks.first { $0.id == task.id }?.isCompleted ?? false)
        XCTAssertNotNil(viewModel.tasks.first { $0.id == task.id }?.completedAt)

        // Move back to todo
        viewModel.moveTask(id: task.id, to: .todo)
        XCTAssertEqual(viewModel.tasks.first { $0.id == task.id }?.status, .todo)
        XCTAssertFalse(viewModel.tasks.first { $0.id == task.id }?.isCompleted ?? true)
        XCTAssertNil(viewModel.tasks.first { $0.id == task.id }?.completedAt)
    }

    func testMoveTaskAllStatusPermutations() {
        let task = TaskItem(title: "Permutation Task", status: .todo)
        viewModel.tasks = [task]

        // todo -> done
        viewModel.moveTask(id: task.id, to: .done)
        XCTAssertEqual(viewModel.tasks.first?.status, .done)
        XCTAssertTrue(viewModel.tasks.first?.isCompleted ?? false)
        XCTAssertNotNil(viewModel.tasks.first?.completedAt)

        // done -> todo
        viewModel.moveTask(id: task.id, to: .todo)
        XCTAssertEqual(viewModel.tasks.first?.status, .todo)
        XCTAssertFalse(viewModel.tasks.first?.isCompleted ?? true)
        XCTAssertNil(viewModel.tasks.first?.completedAt)

        // todo -> inProgress
        viewModel.moveTask(id: task.id, to: .inProgress)
        XCTAssertEqual(viewModel.tasks.first?.status, .inProgress)

        // inProgress -> todo
        viewModel.moveTask(id: task.id, to: .todo)
        XCTAssertEqual(viewModel.tasks.first?.status, .todo)
    }

    func testTasksForStatusColumn() {
        viewModel.tasks = [
            TaskItem(title: "Task 1", priority: .low, status: .todo),
            TaskItem(title: "Task 2", priority: .high, status: .todo),
            TaskItem(title: "Task 3", priority: .medium, status: .inProgress),
            TaskItem(title: "Task 4", priority: .high, status: .done)
        ]

        let todoTasks = viewModel.tasks(for: .todo)
        XCTAssertEqual(todoTasks.count, 2)
        XCTAssertEqual(todoTasks.first?.title, "Task 2") // High priority first

        let inProgressTasks = viewModel.tasks(for: .inProgress)
        XCTAssertEqual(inProgressTasks.count, 1)
        XCTAssertEqual(inProgressTasks.first?.title, "Task 3")

        let doneTasks = viewModel.tasks(for: .done)
        XCTAssertEqual(doneTasks.count, 1)
        XCTAssertEqual(doneTasks.first?.title, "Task 4")
    }

    func testToggleTaskCompletion() {
        guard let task = viewModel.tasks.first else {
            XCTFail("Should contain initial sample task")
            return
        }

        let initialStatus = task.isCompleted
        viewModel.toggleTaskCompletion(task)

        let updatedTask = viewModel.tasks.first { $0.id == task.id }
        XCTAssertNotEqual(updatedTask?.isCompleted, initialStatus)
    }

    func testDeleteTask() {
        guard let task = viewModel.tasks.first else {
            XCTFail("Should contain initial sample task")
            return
        }

        let countBefore = viewModel.tasks.count
        viewModel.deleteTask(withId: task.id)

        XCTAssertEqual(viewModel.tasks.count, countBefore - 1)
        XCTAssertFalse(viewModel.tasks.contains { $0.id == task.id })
    }

    func testUpdateTask() {
        guard var task = viewModel.tasks.first else {
            XCTFail("Should contain initial sample task")
            return
        }

        task.title = "Updated Task Title"
        task.notes = "Updated Task Notes"
        task.priority = .high
        task.status = .inProgress

        viewModel.updateTask(task)

        let retrieved = viewModel.tasks.first { $0.id == task.id }
        XCTAssertEqual(retrieved?.title, "Updated Task Title")
        XCTAssertEqual(retrieved?.notes, "Updated Task Notes")
        XCTAssertEqual(retrieved?.priority, .high)
        XCTAssertEqual(retrieved?.status, .inProgress)
    }

    func testFilterTasks() {
        viewModel.tasks = [
            TaskItem(title: "Active 1", priority: .low, status: .todo),
            TaskItem(title: "Active 2", priority: .high, status: .inProgress),
            TaskItem(title: "Completed 1", priority: .medium, status: .done)
        ]

        viewModel.currentFilter = .all
        XCTAssertEqual(viewModel.filteredTasks.count, 3)

        viewModel.currentFilter = .active
        XCTAssertEqual(viewModel.filteredTasks.count, 2)

        viewModel.currentFilter = .completed
        XCTAssertEqual(viewModel.filteredTasks.count, 1)

        viewModel.currentFilter = .highPriority
        XCTAssertEqual(viewModel.filteredTasks.count, 1)
        XCTAssertEqual(viewModel.filteredTasks.first?.title, "Active 2")
    }

    func testSearchQuery() {
        viewModel.tasks = [
            TaskItem(title: "Buy groceries", notes: "at market", tags: ["Shopping"]),
            TaskItem(title: "Study SwiftUI", notes: "chapter 3", tags: ["Studies"])
        ]

        viewModel.searchQuery = "groceries"
        XCTAssertEqual(viewModel.filteredTasks.count, 1)
        XCTAssertEqual(viewModel.filteredTasks.first?.title, "Buy groceries")

        viewModel.searchQuery = "Studies"
        XCTAssertEqual(viewModel.filteredTasks.count, 1)
        XCTAssertEqual(viewModel.filteredTasks.first?.title, "Study SwiftUI")
    }

    func testIncrementTaskPomodoro() {
        let task = TaskItem(title: "Pomodoro task", estimatedPomodoros: 3, completedPomodoros: 0)
        viewModel.tasks = [task]

        viewModel.incrementTaskPomodoro(taskId: task.id)
        XCTAssertEqual(viewModel.tasks.first?.completedPomodoros, 1)

        viewModel.incrementTaskPomodoro(taskId: task.id)
        XCTAssertEqual(viewModel.tasks.first?.completedPomodoros, 2)
    }

    func testScheduleAndRemoveReminder() {
        let task = TaskItem(title: "Reminder task")
        viewModel.tasks = [task]

        let reminderDate = Date().addingTimeInterval(3600)
        viewModel.scheduleReminder(for: task.id, at: reminderDate)
        XCTAssertEqual(viewModel.tasks.first?.reminderDate, reminderDate)

        viewModel.removeReminder(for: task.id)
        XCTAssertNil(viewModel.tasks.first?.reminderDate)
    }

    func testStatusCounters() {
        viewModel.tasks = [
            TaskItem(title: "T1", status: .todo),
            TaskItem(title: "T2", status: .todo),
            TaskItem(title: "T3", priority: .high, status: .inProgress),
            TaskItem(title: "T4", status: .done),
            TaskItem(title: "T5", status: .done)
        ]

        XCTAssertEqual(viewModel.todoTasksCount, 2)
        XCTAssertEqual(viewModel.inProgressTasksCount, 1)
        XCTAssertEqual(viewModel.doneTasksCount, 2)
        XCTAssertEqual(viewModel.pendingTasksCount, 3)
        XCTAssertEqual(viewModel.completedTasksCount, 2)
        XCTAssertEqual(viewModel.highPriorityPendingCount, 1)
    }

    func testDuplicateTask() {
        let original = TaskItem(
            title: "Original Feature Task",
            notes: "Deep focus notes",
            priority: .high,
            status: .inProgress,
            dueDate: Date().addingTimeInterval(86400),
            tags: ["Feature", "Urgent"],
            estimatedPomodoros: 4,
            completedPomodoros: 2
        )
        viewModel.tasks = [original]

        let duplicate = viewModel.duplicateTask(withId: original.id)

        XCTAssertNotNil(duplicate)
        XCTAssertEqual(viewModel.tasks.count, 2)
        XCTAssertEqual(duplicate?.title, "Original Feature Task (Copy)")
        XCTAssertEqual(duplicate?.notes, "Deep focus notes")
        XCTAssertEqual(duplicate?.priority, .high)
        XCTAssertEqual(duplicate?.status, .inProgress)
        XCTAssertEqual(duplicate?.dueDate, original.dueDate)
        XCTAssertEqual(duplicate?.tags, ["Feature", "Urgent"])
        XCTAssertEqual(duplicate?.estimatedPomodoros, 4)
        XCTAssertEqual(duplicate?.completedPomodoros, 0)
        XCTAssertNotEqual(duplicate?.id, original.id)

        // Verify non-existent ID
        let nonExistentDuplicate = viewModel.duplicateTask(withId: UUID())
        XCTAssertNil(nonExistentDuplicate)
        XCTAssertEqual(viewModel.tasks.count, 2)
    }
}
