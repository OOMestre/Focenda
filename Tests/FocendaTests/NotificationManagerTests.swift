import XCTest
import UserNotifications
@testable import FocendaCore

final class NotificationManagerTests: XCTestCase {

    func testNotificationTitles() {
        XCTAssertEqual(
            NotificationManager.notificationTitle(for: .work),
            "Focus Session Completed"
        )
        XCTAssertEqual(
            NotificationManager.notificationTitle(for: .shortBreak),
            "Short Break Finished"
        )
        XCTAssertEqual(
            NotificationManager.notificationTitle(for: .longBreak),
            "Long Break Ended"
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
            "Task Reminder: Write documentation"
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
            "Task Reminder: Quick Sync"
        )
        XCTAssertEqual(
            NotificationManager.taskReminderBody(for: taskWithoutNotes),
            "Time to focus on 'Quick Sync'."
        )
    }

    func testRecurringReminderTitlesAndBodies() {
        let reminder = RecurringReminder(
            title: "Team Standup",
            time: Date(),
            repeatFrequency: .weekdays,
            notes: "Discuss blockers"
        )

        XCTAssertEqual(
            NotificationManager.recurringReminderTitle(for: reminder),
            "Reminder (Weekdays): Team Standup"
        )
        XCTAssertTrue(
            NotificationManager.recurringReminderBody(for: reminder).contains("Discuss blockers")
        )
    }

    func testNotifySessionCompletedDoesNotCrash() {
        let manager = NotificationManager()
        for mode in FocusMode.allCases {
            manager.notifySessionCompleted(mode: mode)
        }
    }

    func testPlayRichAlertChimeDoesNotCrash() {
        let manager = NotificationManager()
        manager.playRichAlertChime(soundName: "Hero")
        manager.playRichAlertChime(soundName: "Ping")
        manager.playRichAlertChime(soundName: "UnknownSoundFallback")
    }

    func testPlayReminderAlertChimeWithRepetitions() {
        let manager = NotificationManager()
        manager.playReminderAlertChime(soundName: "Hero", repeatCount: 3, interval: 0.1)
        manager.playReminderAlertChime(soundName: "Ping", customFilePath: nil, repeatCount: 5, interval: 0.05)
        manager.stopActiveSound()
        XCTAssertFalse(manager.isPlayingSound)
    }

    func testPlayReminderAlertChimeWithCustomPathFallback() {
        let manager = NotificationManager()
        manager.playReminderAlertChime(soundName: "Hero", customFilePath: "/non/existent/path/sound.wav", repeatCount: 2, interval: 0.05)
        manager.stopActiveSound()
    }

    func testPlayUserReminderSoundRespectsPreferences() {
        let manager = NotificationManager()
        UserDefaults.standard.set(true, forKey: "reminderSoundEnabled")
        UserDefaults.standard.set(ReminderSoundType.glass.rawValue, forKey: "reminderSoundType")
        UserDefaults.standard.set(4, forKey: "reminderSoundRepeatCount")
        manager.playUserReminderSound()
        manager.stopActiveSound()

        UserDefaults.standard.set(false, forKey: "reminderSoundEnabled")
        manager.playUserReminderSound()
        XCTAssertFalse(manager.isPlayingSound)

        // Reset
        UserDefaults.standard.removeObject(forKey: "reminderSoundEnabled")
        UserDefaults.standard.removeObject(forKey: "reminderSoundType")
        UserDefaults.standard.removeObject(forKey: "reminderSoundRepeatCount")
    }

    func testReminderSoundOptionProperties() {
        XCTAssertEqual(ReminderSoundType.hero.displayName, "Hero (Default)")
        XCTAssertEqual(ReminderSoundType.custom.displayName, "Custom Audio File...")
        XCTAssertEqual(ReminderSoundType.ping.displayName, "Ping")
        XCTAssertFalse(ReminderSoundType.hero.isCustom)
        XCTAssertTrue(ReminderSoundType.custom.isCustom)
        XCTAssertEqual(ReminderSoundType.hero.systemSoundName, "Hero")
        XCTAssertNil(ReminderSoundType.custom.systemSoundName)
        XCTAssertEqual(ReminderSoundType.defaultSound, .hero)
        XCTAssertEqual(ReminderSoundType.defaultRepeatCount, 3)
        XCTAssertEqual(ReminderSoundType.minRepeatCount, 1)
        XCTAssertEqual(ReminderSoundType.maxRepeatCount, 5)
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

    func testScheduleRecurringReminderDoesNotCrash() {
        let manager = NotificationManager()
        let reminder = RecurringReminder(
            title: "Daily Standup",
            time: Date(),
            repeatFrequency: .weekdays
        )
        manager.scheduleRecurringReminder(reminder: reminder)
        XCTAssertEqual(manager.lastScheduledRecurringReminder?.title, "Daily Standup")

        manager.cancelRecurringReminder(reminder: reminder)
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

    func testInAppRecurringReminderFallbackTrigger() {
        let manager = NotificationManager()
        let reminder = RecurringReminder(
            title: "Hydration Check",
            time: Date(),
            repeatFrequency: .daily
        )

        var callbackFired = false
        var firedReminder: RecurringReminder?
        manager.onRecurringReminderFired = { rem in
            callbackFired = true
            firedReminder = rem
        }

        let expectation = expectation(forNotification: NotificationManager.recurringReminderFiredNotification, object: nil) { notification in
            let item = notification.object as? RecurringReminder
            return item?.title == "Hydration Check"
        }

        manager.triggerInAppRecurringReminderFallback(for: reminder)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(callbackFired)
        XCTAssertEqual(firedReminder?.title, "Hydration Check")
        XCTAssertEqual(manager.lastFiredRecurringReminder?.title, "Hydration Check")
    }

    func testSharedInstance() {
        XCTAssertNotNil(NotificationManager.shared)
    }

    func testMockNotificationProtocolTracking() {
        final class MockNotificationManager: NotificationManagerProtocol {
            var notifiedModes: [FocusMode] = []
            var scheduledTasks: [TaskItem] = []
            var cancelledTasks: [TaskItem] = []
            var scheduledRecurring: [RecurringReminder] = []
            var cancelledRecurring: [RecurringReminder] = []
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

            func scheduleRecurringReminder(reminder: RecurringReminder) {
                scheduledRecurring.append(reminder)
            }

            func cancelRecurringReminder(reminder: RecurringReminder) {
                cancelledRecurring.append(reminder)
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

        let sampleRecurring = RecurringReminder(title: "Mock recurring", time: Date(), repeatFrequency: .daily)
        mock.scheduleRecurringReminder(reminder: sampleRecurring)
        XCTAssertEqual(mock.scheduledRecurring.count, 1)

        mock.cancelRecurringReminder(reminder: sampleRecurring)
        XCTAssertEqual(mock.cancelledRecurring.count, 1)
    }

    func testRequestAuthorizationAsyncWhenUnavailable() async throws {
        let manager = NotificationManager()
        let result = try await manager.requestAuthorization()
        XCTAssertFalse(result) // In test runner environment, UNUserNotificationCenter is mocked or nil
    }
}
