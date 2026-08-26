import XCTest
@testable import FocendaCore

final class TaskItemTests: XCTestCase {

    func testTaskInitialization() {
        let task = TaskItem(
            title: "Write documentation",
            notes: "Document APIs and architecture",
            priority: .high,
            tags: ["Docs", "Swift"],
            estimatedPomodoros: 3
        )

        XCTAssertEqual(task.title, "Write documentation")
        XCTAssertEqual(task.notes, "Document APIs and architecture")
        XCTAssertEqual(task.priority, .high)
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)
        XCTAssertEqual(task.tags, ["Docs", "Swift"])
        XCTAssertEqual(task.estimatedPomodoros, 3)
        XCTAssertEqual(task.completedPomodoros, 0)
    }

    func testTaskPriorityComparison() {
        XCTAssertTrue(TaskPriority.low < TaskPriority.medium)
        XCTAssertTrue(TaskPriority.medium < TaskPriority.high)
        XCTAssertTrue(TaskPriority.low < TaskPriority.high)
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
