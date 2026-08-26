import XCTest
import UserNotifications
@testable import FocendaCore

final class NotificationManagerTests: XCTestCase {

    func testNotificationTitles() {
        XCTAssertEqual(
            NotificationManager.notificationTitle(for: .work),
            "Focus Session Completed! 🎯"
        )
        XCTAssertEqual(
            NotificationManager.notificationTitle(for: .shortBreak),
            "Short Break Finished! ⚡"
        )
        XCTAssertEqual(
            NotificationManager.notificationTitle(for: .longBreak),
            "Long Break Ended! 🚀"
        )
    }

    func testNotificationBodies() {
        XCTAssertEqual(
            NotificationManager.notificationBody(for: .work),
            "Great job! Time to take a well-deserved break."
        )
        XCTAssertEqual(
            NotificationManager.notificationBody(for: .shortBreak),
            "Ready to jump back into deep focus?"
        )
        XCTAssertEqual(
            NotificationManager.notificationBody(for: .longBreak),
            "Feeling refreshed? Let's get back to work!"
        )
    }

    func testTaskReminderTitlesAndBodies() {
        let taskWithNotes = TaskItem(
            title: "Write documentation",
            notes: "Include architecture diagrams",
            reminderDate: Date().addingTimeInterval(300)
        )
        XCTAssertEqual(
            NotificationManager.taskReminderTitle(for: taskWithNotes),
            "⏰ Task Reminder: Write documentation"
        )
        XCTAssertEqual(
            NotificationManager.taskReminderBody(for: taskWithNotes),
            "Include architecture diagrams"
        )

        let taskWithoutNotes = TaskItem(
            title: "Quick Sync",
            notes: "",
            reminderDate: Date().addingTimeInterval(300)
        )
        XCTAssertEqual(
            NotificationManager.taskReminderTitle(for: taskWithoutNotes),
            "⏰ Task Reminder: Quick Sync"
        )
        XCTAssertEqual(
            NotificationManager.taskReminderBody(for: taskWithoutNotes),
            "Time to focus on 'Quick Sync'."
        )
    }

    func testNotifySessionCompletedDoesNotCrash() {
        let manager = NotificationManager()
        for mode in FocusMode.allCases {
            manager.notifySessionCompleted(mode: mode)
        }
    }

    func testScheduleTaskReminderDoesNotCrash() {
        let manager = NotificationManager()
        let futureTask = TaskItem(
            title: "Future Task Reminder",
            notes: "Don't forget this task",
            reminderDate: Date().addingTimeInterval(3600)
        )
        manager.scheduleTaskReminder(task: futureTask)
        XCTAssertEqual(manager.lastScheduledTask?.title, "Future Task Reminder")

        manager.cancelTaskReminder(task: futureTask)
    }

    func testInAppReminderFallbackTrigger() {
        let manager = NotificationManager()
        let task = TaskItem(
            title: "Urgent Meeting",
            notes: "Discuss roadmap",
            reminderDate: Date().addingTimeInterval(60)
        )

        var callbackFired = false
        var firedTask: TaskItem?
        manager.onTaskReminderFired = { taskItem in
            callbackFired = true
            firedTask = taskItem
        }

        let expectation = expectation(forNotification: NotificationManager.taskReminderFiredNotification, object: nil) { notification in
            let item = notification.object as? TaskItem
            return item?.title == "Urgent Meeting"
        }

        manager.triggerInAppReminderFallback(for: task)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(callbackFired)
        XCTAssertEqual(firedTask?.title, "Urgent Meeting")
        XCTAssertEqual(manager.lastFiredTask?.title, "Urgent Meeting")
    }

    func testSharedInstance() {
        XCTAssertNotNil(NotificationManager.shared)
    }

    func testMockNotificationProtocolTracking() {
        final class MockNotificationManager: NotificationManagerProtocol {
            var notifiedModes: [FocusMode] = []
            var scheduledTasks: [TaskItem] = []
            var cancelledTasks: [TaskItem] = []
            var authorizationRequested = false

            func requestAuthorization(completion: ((Bool, Error?) -> Void)?) {
                authorizationRequested = true
                completion?(true, nil)
            }

            func notifySessionCompleted(mode: FocusMode) {
                notifiedModes.append(mode)
            }

            func scheduleTaskReminder(task: TaskItem) {
                scheduledTasks.append(task)
            }

            func cancelTaskReminder(task: TaskItem) {
                cancelledTasks.append(task)
            }
        }

        let mock = MockNotificationManager()
        mock.requestAuthorization { granted, _ in
            XCTAssertTrue(granted)
        }
        XCTAssertTrue(mock.authorizationRequested)

        mock.notifySessionCompleted(mode: .work)
        mock.notifySessionCompleted(mode: .shortBreak)
        mock.notifySessionCompleted(mode: .longBreak)

        XCTAssertEqual(mock.notifiedModes, [.work, .shortBreak, .longBreak])

        let sampleTask = TaskItem(title: "Mock task", reminderDate: Date().addingTimeInterval(600))
        mock.scheduleTaskReminder(task: sampleTask)
        XCTAssertEqual(mock.scheduledTasks.count, 1)
        XCTAssertEqual(mock.scheduledTasks.first?.title, "Mock task")

        mock.cancelTaskReminder(task: sampleTask)
        XCTAssertEqual(mock.cancelledTasks.count, 1)
    }

    func testRequestAuthorizationAsyncWhenUnavailable() async throws {
        let manager = NotificationManager()
        let result = try await manager.requestAuthorization()
        XCTAssertFalse(result) // In test runner environment, UNUserNotificationCenter is mocked or nil
    }
}
