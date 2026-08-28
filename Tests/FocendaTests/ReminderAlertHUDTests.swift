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
            title: "Bater o ponto",
            subtitle: "18:00 • Diário",
            notes: "Não esqueça de registrar seu ponto de saída!",
            type: "recurring",
            timeoutSeconds: 30.0,
            onSnooze: { didSnooze = true },
            onComplete: { didComplete = true },
            onOpenApp: { didOpenApp = true }
        )

        XCTAssertTrue(panel.isShowingAlert)
        XCTAssertEqual(panel.currentTitle, "Bater o ponto")
        XCTAssertEqual(panel.currentSubtitle, "18:00 • Diário")
        XCTAssertEqual(panel.currentNotes, "Não esqueça de registrar seu ponto de saída!")

        panel.dismiss()
        XCTAssertFalse(panel.isShowingAlert)
    }

    func testReminderAlertHUDViewRendersCorrectly() {
        var snoozeCalled = false
        var completeCalled = false
        var openAppCalled = false
        var closeCalled = false

        let view = ReminderAlertHUDView(
            title: "Bater o ponto",
            subtitle: "18:00 • Diário",
            notes: "Registro obrigatório",
            timeoutSeconds: 25.0,
            onSnooze: { snoozeCalled = true },
            onComplete: { completeCalled = true },
            onOpenApp: { openAppCalled = true },
            onClose: { closeCalled = true }
        )

        XCTAssertEqual(view.title, "Bater o ponto")
        XCTAssertEqual(view.subtitle, "18:00 • Diário")
        XCTAssertEqual(view.notes, "Registro obrigatório")
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

    func testNotificationManagerSnoozeReminder() {
        let expectation = expectation(description: "Reminder snoozed notification posted")

        let observer = NotificationCenter.default.addObserver(
            forName: NotificationManager.reminderSnoozedNotification,
            object: nil,
            queue: .main
        ) { notification in
            let title = notification.userInfo?["title"] as? String
            let minutes = notification.userInfo?["minutes"] as? Int
            XCTAssertEqual(title, "Bater o ponto")
            XCTAssertEqual(minutes, 5)
            expectation.fulfill()
        }

        NotificationManager.shared.snoozeReminder(
            title: "Bater o ponto",
            subtitle: "Lembrete Diário",
            notes: "Registro de ponto",
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
            XCTAssertEqual(title, "Bater o ponto")
            XCTAssertEqual(type, "test")
            expectation.fulfill()
        }

        NotificationManager.shared.testReminderAlertHUD(
            title: "Bater o ponto",
            subtitle: "Lembrete Diário • 18:00",
            notes: "Não se esqueça de registrar seu ponto no sistema!"
        )

        wait(for: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testTriggerInAppRecurringReminderFallbackPostsNotificationsAndShowsHUD() {
        let reminder = RecurringReminder(
            title: "Bater o ponto",
            time: Date(),
            repeatFrequency: .daily,
            isEnabled: true,
            notes: "Check-in diário"
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
            title: "Entregar relatório",
            notes: "Prioridade alta",
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
