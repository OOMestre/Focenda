import XCTest
import SwiftUI
@testable import FocendaCore

final class ReminderAlertHUDTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ReminderAlertHUDPanel.shared.dismiss()
    }

    override func tearDown() {
        ReminderAlertHUDPanel.shared.dismiss()
        super.tearDown()
    }

    func testReminderAlertHUDPanelInitialization() {
        let panel = ReminderAlertHUDPanel.shared
        XCTAssertNotNil(panel)
        XCTAssertEqual(panel.level, .floating)
        XCTAssertTrue(panel.isFloatingPanel)
        XCTAssertFalse(panel.hidesOnDeactivate)
        XCTAssertFalse(panel.isOpaque)
        XCTAssertTrue(panel.hasShadow)
        XCTAssertFalse(panel.isShowingAlert)
    }

    func testReminderAlertHUDPanelShowAndDismiss() {
        let panel = ReminderAlertHUDPanel.shared

        var didSnooze = false
        var didComplete = false
        var didOpenApp = false

        panel.show(
            title: "Team Standup",
            subtitle: "6:00 PM • Daily",
            notes: "Review progress and align on daily goals.",
            type: "recurring",
            timeoutSeconds: 30.0,
            onSnooze: { didSnooze = true },
            onComplete: { didComplete = true },
            onOpenApp: { didOpenApp = true }
        )

        XCTAssertTrue(panel.isShowingAlert)
        XCTAssertEqual(panel.currentTitle, "Team Standup")
        XCTAssertEqual(panel.currentSubtitle, "6:00 PM • Daily")
        XCTAssertEqual(panel.currentNotes, "Review progress and align on daily goals.")
        XCTAssertEqual(panel.currentType, "recurring")

        // Verify callbacks directly
        let hudView = ReminderAlertHUDView(
            title: "Team Standup",
            onSnooze: { didSnooze = true },
            onComplete: { didComplete = true },
            onOpenApp: { didOpenApp = true }
        )
        hudView.onSnooze?()
        hudView.onComplete?()
        hudView.onOpenApp?()

        XCTAssertTrue(didSnooze)
        XCTAssertTrue(didComplete)
        XCTAssertTrue(didOpenApp)

        panel.dismiss()
        XCTAssertFalse(panel.isShowingAlert)
    }

    func testReminderAlertHUDViewRendersCorrectly() {
        var snoozeCalled = false
        var completeCalled = false
        var openAppCalled = false
        var closeCalled = false

        let view = ReminderAlertHUDView(
            title: "Team Standup",
            subtitle: "6:00 PM • Daily",
            notes: "Review progress and goals",
            timeoutSeconds: 25.0,
            onSnooze: { snoozeCalled = true },
            onComplete: { completeCalled = true },
            onOpenApp: { openAppCalled = true },
            onClose: { closeCalled = true }
        )

        XCTAssertEqual(view.title, "Team Standup")
        XCTAssertEqual(view.subtitle, "6:00 PM • Daily")
        XCTAssertEqual(view.notes, "Review progress and goals")
        XCTAssertEqual(view.timeoutSeconds, 25.0)

        view.onSnooze?()
        XCTAssertTrue(snoozeCalled)

        view.onComplete?()
        XCTAssertTrue(completeCalled)

        view.onOpenApp?()
        XCTAssertTrue(openAppCalled)

        view.onClose?()
        XCTAssertTrue(closeCalled)
    }

    func testFocusSessionCompletionShowsPomodoroHUD() {
        let manager = NotificationManager()
        let expectation = expectation(description: "Pomodoro completion HUD shown")

        manager.notifySessionCompleted(mode: .work)

        DispatchQueue.main.async {
            let panel = ReminderAlertHUDPanel.shared
            XCTAssertTrue(panel.isShowingAlert)
            XCTAssertEqual(panel.currentType, "pomodoro")
            XCTAssertEqual(panel.currentTitle, "Focus Session Completed")
            XCTAssertTrue(panel.currentSubtitle.contains("Pomodoro"))
            XCTAssertEqual(panel.currentNotes, "Great job! Time to take a well-deserved break.")
            panel.dismiss()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testNotificationManagerSnoozeReminder() {
        let expectation = expectation(description: "Reminder snoozed notification posted")

        let observer = NotificationCenter.default.addObserver(
            forName: NotificationManager.reminderSnoozedNotification,
            object: nil,
            queue: .main
        ) { notification in
            let title = notification.userInfo?["title"] as? String
            let minutes = notification.userInfo?["minutes"] as? Int
            XCTAssertEqual(title, "Team Standup")
            XCTAssertEqual(minutes, 5)
            expectation.fulfill()
        }

        NotificationManager.shared.snoozeReminder(
            title: "Team Standup",
            subtitle: "Daily Reminder",
            notes: "Review progress",
            minutes: 5
        )

        wait(for: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testNotificationManagerTestAlertHUD() {
        let expectation = expectation(description: "Reminder alert banner notification posted")

        let observer = NotificationCenter.default.addObserver(
            forName: NotificationManager.reminderAlertBannerNotification,
            object: nil,
            queue: .main
        ) { notification in
            let title = notification.userInfo?["title"] as? String
            let type = notification.userInfo?["type"] as? String
            XCTAssertEqual(title, "Daily Standup")
            XCTAssertEqual(type, "test")
            expectation.fulfill()
        }

        NotificationManager.shared.testReminderAlertHUD(
            title: "Daily Standup",
            subtitle: "Daily Reminder • 6:00 PM",
            notes: "Time to review your daily accomplishments and plan ahead!"
        )

        wait(for: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testTriggerInAppRecurringReminderFallbackPostsNotificationsAndShowsHUD() {
        let reminder = RecurringReminder(
            title: "Daily Standup",
            time: Date(),
            repeatFrequency: .daily,
            isEnabled: true,
            notes: "Daily team check-in"
        )

        let recurringExpectation = expectation(description: "Recurring reminder fired notification posted")
        let bannerExpectation = expectation(description: "Banner notification posted")

        let observer1 = NotificationCenter.default.addObserver(
            forName: NotificationManager.recurringReminderFiredNotification,
            object: nil,
            queue: .main
        ) { _ in
            recurringExpectation.fulfill()
        }

        let observer2 = NotificationCenter.default.addObserver(
            forName: NotificationManager.reminderAlertBannerNotification,
            object: nil,
            queue: .main
        ) { _ in
            bannerExpectation.fulfill()
        }

        NotificationManager.shared.triggerInAppRecurringReminderFallback(for: reminder)

        wait(for: [recurringExpectation, bannerExpectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer1)
        NotificationCenter.default.removeObserver(observer2)

        XCTAssertEqual(NotificationManager.shared.lastFiredRecurringReminder?.id, reminder.id)
    }

    func testTriggerInAppTaskReminderFallbackPostsNotifications() {
        let task = TaskItem(
            title: "Submit quarterly report",
            notes: "High priority",
            reminderDate: Date().addingTimeInterval(60)
        )

        let taskExpectation = expectation(description: "Task reminder fired notification posted")
        let bannerExpectation = expectation(description: "Banner notification posted")

        let observer1 = NotificationCenter.default.addObserver(
            forName: NotificationManager.taskReminderFiredNotification,
            object: nil,
            queue: .main
        ) { _ in
            taskExpectation.fulfill()
        }

        let observer2 = NotificationCenter.default.addObserver(
            forName: NotificationManager.reminderAlertBannerNotification,
            object: nil,
            queue: .main
        ) { _ in
            bannerExpectation.fulfill()
        }

        NotificationManager.shared.triggerInAppReminderFallback(for: task)

        wait(for: [taskExpectation, bannerExpectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer1)
        NotificationCenter.default.removeObserver(observer2)

        XCTAssertEqual(NotificationManager.shared.lastFiredTask?.id, task.id)
    }
}
