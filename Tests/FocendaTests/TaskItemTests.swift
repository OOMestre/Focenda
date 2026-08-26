import XCTest
@testable import FocendaCore

final class TaskItemTests: XCTestCase {

    func testTaskInitialization() {
        let reminder = Date().addingTimeInterval(3600)
        let due = Date().addingTimeInterval(86400)
        let task = TaskItem(
            title: "Write documentation",
            notes: "Document APIs and architecture",
            priority: .high,
            status: .inProgress,
            reminderDate: reminder,
            dueDate: due,
            tags: ["Docs", "Swift"],
            estimatedPomodoros: 3,
            completedPomodoros: 1
        )

        XCTAssertEqual(task.title, "Write documentation")
        XCTAssertEqual(task.notes, "Document APIs and architecture")
        XCTAssertEqual(task.priority, .high)
        XCTAssertEqual(task.status, .inProgress)
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
        XCTAssertEqual(task.reminderDate, reminder)
        XCTAssertEqual(task.dueDate, due)
        XCTAssertEqual(task.tags, ["Docs", "Swift"])
        XCTAssertEqual(task.estimatedPomodoros, 3)
        XCTAssertEqual(task.completedPomodoros, 1)
    }

    func testTaskStatusProperties() {
        XCTAssertEqual(TaskStatus.todo.rawValue, "To Do")
        XCTAssertEqual(TaskStatus.inProgress.rawValue, "In Progress")
        XCTAssertEqual(TaskStatus.done.rawValue, "Done")

        XCTAssertEqual(TaskStatus.todo.id, "To Do")
        XCTAssertEqual(TaskStatus.inProgress.id, "In Progress")
        XCTAssertEqual(TaskStatus.done.id, "Done")

        XCTAssertFalse(TaskStatus.todo.icon.isEmpty)
        XCTAssertFalse(TaskStatus.inProgress.icon.isEmpty)
        XCTAssertFalse(TaskStatus.done.icon.isEmpty)
    }

    func testIsCompletedStatusSynchronization() {
        var task = TaskItem(title: "Check sync", status: .todo)
        XCTAssertFalse(task.isCompleted)
        XCTAssertEqual(task.status, .todo)
        XCTAssertNil(task.completedAt)

        task.isCompleted = true
        XCTAssertEqual(task.status, .done)
        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedAt)

        task.isCompleted = false
        XCTAssertEqual(task.status, .todo)
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)

        task.status = .inProgress
        XCTAssertFalse(task.isCompleted)

        task.status = .done
        XCTAssertTrue(task.isCompleted)
    }

    func testTaskPriorityComparison() {
        XCTAssertTrue(TaskPriority.low < TaskPriority.medium)
        XCTAssertTrue(TaskPriority.medium < TaskPriority.high)
        XCTAssertTrue(TaskPriority.low < TaskPriority.high)
    }

    func testCodableRoundTrip() throws {
        let original = TaskItem(
            title: "Codable test",
            notes: "Testing serialization",
            priority: .high,
            status: .inProgress,
            reminderDate: Date(timeIntervalSince1970: 100000),
            dueDate: Date(timeIntervalSince1970: 200000),
            tags: ["Testing"],
            estimatedPomodoros: 4,
            completedPomodoros: 2
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.notes, original.notes)
        XCTAssertEqual(decoded.priority, original.priority)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.isCompleted, original.isCompleted)
        XCTAssertEqual(decoded.tags, original.tags)
        XCTAssertEqual(decoded.estimatedPomodoros, original.estimatedPomodoros)
        XCTAssertEqual(decoded.completedPomodoros, original.completedPomodoros)
    }

    func testLegacyJsonDecodingBackwardsCompatibility() throws {
        // Legacy JSON without 'status', but with 'isCompleted: true'
        let legacyJson = """
        {
            "id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
            "title": "Legacy Completed Task",
            "notes": "Old note format",
            "priority": "High",
            "isCompleted": true,
            "createdAt": 0,
            "tags": ["Legacy"],
            "estimatedPomodoros": 2,
            "completedPomodoros": 2
        }
        """

        let data = legacyJson.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(TaskItem.self, from: data)

        XCTAssertEqual(decoded.title, "Legacy Completed Task")
        XCTAssertEqual(decoded.status, .done)
        XCTAssertTrue(decoded.isCompleted)
    }

    func testFocusModeProperties() {
        let work = FocusMode.work
        let shortBreak = FocusMode.shortBreak
        let longBreak = FocusMode.longBreak

        XCTAssertEqual(work.defaultDurationMinutes, 25)
        XCTAssertEqual(shortBreak.defaultDurationMinutes, 5)
        XCTAssertEqual(longBreak.defaultDurationMinutes, 15)

        XCTAssertEqual(work.rawValue, "Deep Focus")
        XCTAssertEqual(shortBreak.rawValue, "Short Break")
        XCTAssertEqual(longBreak.rawValue, "Long Break")
    }
}
