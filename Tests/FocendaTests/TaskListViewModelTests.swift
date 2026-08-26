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
        viewModel.addTask(
            title: "New unit test task",
            notes: "Additional notes",
            priority: .high,
            tags: ["Testing"],
            estimatedPomodoros: 2
        )

        XCTAssertEqual(viewModel.tasks.count, initialCount + 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "New unit test task")
        XCTAssertEqual(viewModel.tasks.first?.priority, .high)
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

    func testFilterTasks() {
        viewModel.tasks = [
            TaskItem(title: "Active 1", priority: .low, isCompleted: false),
            TaskItem(title: "Active 2", priority: .high, isCompleted: false),
            TaskItem(title: "Completed 1", priority: .medium, isCompleted: true)
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
}
