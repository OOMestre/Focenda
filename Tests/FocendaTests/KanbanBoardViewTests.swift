import XCTest
import SwiftUI
@testable import FocendaCore

final class KanbanBoardViewTests: XCTestCase {

    var taskVM: TaskListViewModel!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "focenda_saved_tasks")
        taskVM = TaskListViewModel()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "focenda_saved_tasks")
        taskVM = nil
        super.tearDown()
    }

    func testKanbanBoardViewInitialization() {
        let kanbanView = KanbanBoardView(taskVM: taskVM, showHeader: true)
        XCTAssertTrue(kanbanView.showHeader)
        XCTAssertEqual(kanbanView.viewMode, .kanban)
        XCTAssertNotNil(kanbanView.body)

        let embeddedView = KanbanBoardView(taskVM: taskVM, showHeader: false, initialViewMode: .list)
        XCTAssertFalse(embeddedView.showHeader)
        XCTAssertEqual(embeddedView.viewMode, .list)
        XCTAssertNotNil(embeddedView.body)
    }

    func testKanbanColumnDataDistribution() {
        taskVM.tasks = [
            TaskItem(title: "Task A", priority: .high, status: .todo),
            TaskItem(title: "Task B", priority: .low, status: .todo),
            TaskItem(title: "Task C", priority: .medium, status: .inProgress),
            TaskItem(title: "Task D", priority: .high, status: .done),
            TaskItem(title: "Task E", priority: .low, status: .done)
        ]

        let todoTasks = taskVM.tasks(for: .todo)
        let inProgressTasks = taskVM.tasks(for: .inProgress)
        let doneTasks = taskVM.tasks(for: .done)

        XCTAssertEqual(todoTasks.count, 2)
        XCTAssertEqual(inProgressTasks.count, 1)
        XCTAssertEqual(doneTasks.count, 2)

        XCTAssertEqual(todoTasks.first?.title, "Task A") // High priority ranked first
        XCTAssertEqual(inProgressTasks.first?.title, "Task C")
        XCTAssertEqual(doneTasks.first?.title, "Task D")
    }

    func testKanbanMoveWorkflows() {
        let task = TaskItem(title: "Workflow Task", priority: .medium, status: .todo)
        taskVM.tasks = [task]

        // 1. Move To Do -> In Progress
        taskVM.moveTask(id: task.id, to: .inProgress)
        XCTAssertEqual(taskVM.tasks(for: .todo).count, 0)
        XCTAssertEqual(taskVM.tasks(for: .inProgress).count, 1)
        XCTAssertEqual(taskVM.tasks(for: .done).count, 0)
        XCTAssertFalse(taskVM.tasks.first?.isCompleted ?? true)

        // 2. Move In Progress -> Done
        taskVM.moveTask(id: task.id, to: .done)
        XCTAssertEqual(taskVM.tasks(for: .todo).count, 0)
        XCTAssertEqual(taskVM.tasks(for: .inProgress).count, 0)
        XCTAssertEqual(taskVM.tasks(for: .done).count, 1)
        XCTAssertTrue(taskVM.tasks.first?.isCompleted ?? false)
        XCTAssertNotNil(taskVM.tasks.first?.completedAt)

        // 3. Move Done -> In Progress
        taskVM.moveTask(id: task.id, to: .inProgress)
        XCTAssertEqual(taskVM.tasks(for: .inProgress).count, 1)
        XCTAssertFalse(taskVM.tasks.first?.isCompleted ?? true)
        XCTAssertNil(taskVM.tasks.first?.completedAt)

        // 4. Move In Progress -> To Do
        taskVM.moveTask(id: task.id, to: .todo)
        XCTAssertEqual(taskVM.tasks(for: .todo).count, 1)
        XCTAssertEqual(taskVM.tasks(for: .inProgress).count, 0)
    }

    func testKanbanDragAndDropUUIDExtractionAndMove() {
        let task = TaskItem(title: "Draggable Task", priority: .high, status: .todo)
        taskVM.tasks = [task]

        // Simulate dragged string item containing UUID string
        let draggedString = task.id.uuidString
        guard let extractedUUID = UUID(uuidString: draggedString) else {
            XCTFail("Should successfully decode UUID from dragged string")
            return
        }

        XCTAssertEqual(extractedUUID, task.id)

        // Move to inProgress
        taskVM.moveTask(id: extractedUUID, to: .inProgress)
        XCTAssertEqual(taskVM.tasks(for: .inProgress).count, 1)
        XCTAssertEqual(taskVM.tasks(for: .todo).count, 0)

        // Move to done
        taskVM.moveTask(id: extractedUUID, to: .done)
        XCTAssertEqual(taskVM.tasks(for: .done).count, 1)
        XCTAssertTrue(taskVM.tasks.first?.isCompleted ?? false)
    }

    func testKanbanTaskQuickAdd() {
        let initialTodoCount = taskVM.todoTasksCount
        let initialInProgressCount = taskVM.inProgressTasksCount

        taskVM.addTask(
            title: "Quick To Do Task",
            priority: .high,
            status: .todo,
            tags: ["Kanban"]
        )

        taskVM.addTask(
            title: "Quick In Progress Task",
            priority: .medium,
            status: .inProgress,
            tags: ["Active"]
        )

        XCTAssertEqual(taskVM.todoTasksCount, initialTodoCount + 1)
        XCTAssertEqual(taskVM.inProgressTasksCount, initialInProgressCount + 1)

        let addedTodo = taskVM.tasks(for: .todo).first { $0.title == "Quick To Do Task" }
        XCTAssertNotNil(addedTodo)
        XCTAssertEqual(addedTodo?.priority, .high)
        XCTAssertEqual(addedTodo?.tags, ["Kanban"])

        let addedInProgress = taskVM.tasks(for: .inProgress).first { $0.title == "Quick In Progress Task" }
        XCTAssertNotNil(addedInProgress)
        XCTAssertEqual(addedInProgress?.status, .inProgress)
    }

    func testKanbanSearchFilteringAcrossColumns() {
        taskVM.tasks = [
            TaskItem(title: "Design Landing Page", notes: "Figma mockup", status: .todo),
            TaskItem(title: "Implement Landing Page", notes: "SwiftUI view", status: .inProgress),
            TaskItem(title: "Review PR", notes: "Code review for landing page", status: .done),
            TaskItem(title: "Backend Setup", notes: "Database migration", status: .todo)
        ]

        taskVM.searchQuery = "landing"

        let todoResults = taskVM.tasks(for: .todo)
        let inProgressResults = taskVM.tasks(for: .inProgress)
        let doneResults = taskVM.tasks(for: .done)

        XCTAssertEqual(todoResults.count, 1)
        XCTAssertEqual(todoResults.first?.title, "Design Landing Page")

        XCTAssertEqual(inProgressResults.count, 1)
        XCTAssertEqual(inProgressResults.first?.title, "Implement Landing Page")

        XCTAssertEqual(doneResults.count, 1)
        XCTAssertEqual(doneResults.first?.title, "Review PR")
    }

    func testKanbanPomodoroIncrement() {
        let task = TaskItem(title: "Focus Task", estimatedPomodoros: 4, completedPomodoros: 1)
        taskVM.tasks = [task]

        taskVM.incrementTaskPomodoro(taskId: task.id)
        XCTAssertEqual(taskVM.tasks.first?.completedPomodoros, 2)

        taskVM.incrementTaskPomodoro(taskId: task.id)
        XCTAssertEqual(taskVM.tasks.first?.completedPomodoros, 3)
    }

    func testKanbanStatPill() {
        let pill = KanbanStatPill(title: "In Progress", count: 5, color: AppTheme.sandstone)
        XCTAssertEqual(pill.title, "In Progress")
        XCTAssertEqual(pill.count, 5)
        XCTAssertNotNil(pill.body)
    }

    func testKanbanTaskFormSheet() {
        var savedTitle: String? = nil
        var savedPriority: TaskPriority? = nil
        var savedStatus: TaskStatus? = nil

        let sheet = KanbanTaskFormSheet(
            initialStatus: .inProgress,
            onSave: { title, notes, priority, status, reminder, due, tags, pomodoros in
                savedTitle = title
                savedPriority = priority
                savedStatus = status
            }
        )
        XCTAssertEqual(sheet.initialStatus, .inProgress)
        XCTAssertNil(sheet.editingTask)
        XCTAssertNotNil(sheet.body)

        sheet.onSave("Form Task", "Notes", .high, .done, nil, nil, ["Tag"], 2)
        XCTAssertEqual(savedTitle, "Form Task")
        XCTAssertEqual(savedPriority, .high)
        XCTAssertEqual(savedStatus, .done)
    }

    func testTaskViewModeEnum() {
        XCTAssertEqual(TaskViewMode.list.rawValue, "List")
        XCTAssertEqual(TaskViewMode.kanban.rawValue, "Kanban")
        XCTAssertEqual(TaskViewMode.list.id, "List")
        XCTAssertEqual(TaskViewMode.kanban.id, "Kanban")
        XCTAssertEqual(TaskViewMode.list.title, "List View")
        XCTAssertEqual(TaskViewMode.kanban.title, "Kanban Board")
        XCTAssertEqual(TaskViewMode.list.iconName, "list.bullet")
        XCTAssertEqual(TaskViewMode.kanban.iconName, "rectangle.split.3x1")
    }

    func testAppTabEnumUnified() {
        let allTabs = AppTab.allCases
        XCTAssertFalse(allTabs.map(\.rawValue).contains("Tasks"), "Standalone 'Tasks' tab must be removed")
        XCTAssertTrue(allTabs.contains(.kanban))
        XCTAssertEqual(AppTab.kanban.rawValue, "Tasks & Kanban")
        XCTAssertEqual(AppTab.kanban.iconName, "rectangle.split.3x1")
    }
}
