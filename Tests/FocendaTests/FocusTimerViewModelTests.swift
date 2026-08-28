import XCTest
@testable import FocendaCore

final class FocusTimerViewModelTests: XCTestCase {

    var viewModel: FocusTimerViewModel!

    override func setUp() {
        super.setUp()
        viewModel = FocusTimerViewModel()
    }

    override func tearDown() {
        viewModel?.pause()
        viewModel?.reset()
        ReminderAlertHUDPanel.shared.dismiss()
        viewModel = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.currentMode, .work)
        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertEqual(viewModel.timeRemainingSeconds, 25 * 60)
        XCTAssertEqual(viewModel.totalDurationSeconds, 25 * 60)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertEqual(viewModel.formattedTimeRemaining, "25:00")
        XCTAssertEqual(viewModel.completedSessionsCount, 0)
    }

    func testSwitchMode() {
        viewModel.switchMode(to: .shortBreak)
        XCTAssertEqual(viewModel.currentMode, .shortBreak)
        XCTAssertEqual(viewModel.timeRemainingSeconds, 5 * 60)
        XCTAssertEqual(viewModel.formattedTimeRemaining, "05:00")

        viewModel.switchMode(to: .longBreak)
        XCTAssertEqual(viewModel.currentMode, .longBreak)
        XCTAssertEqual(viewModel.timeRemainingSeconds, 15 * 60)
        XCTAssertEqual(viewModel.formattedTimeRemaining, "15:00")
    }

    func testTickDecrementsTime() {
        viewModel.start()
        XCTAssertEqual(viewModel.status, .running)

        viewModel.tick()
        XCTAssertEqual(viewModel.timeRemainingSeconds, (25 * 60) - 1)
        XCTAssertGreaterThan(viewModel.progress, 0.0)
    }

    func testPauseAndResume() {
        viewModel.start()
        XCTAssertEqual(viewModel.status, .running)

        viewModel.pause()
        XCTAssertEqual(viewModel.status, .paused)

        viewModel.resume()
        XCTAssertEqual(viewModel.status, .running)
    }

    func testReset() {
        viewModel.start()
        viewModel.tick()
        viewModel.reset()

        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertEqual(viewModel.timeRemainingSeconds, 25 * 60)
        XCTAssertEqual(viewModel.progress, 0.0)
    }

    func testSkipAdvancesMode() {
        viewModel.start()
        viewModel.skip()

        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertEqual(viewModel.currentMode, .shortBreak)
        XCTAssertEqual(viewModel.timeRemainingSeconds, 5 * 60)
    }

    func testSessionCompletionTransitionsToBreak() {
        viewModel.timeRemainingSeconds = 0
        viewModel.start()
        viewModel.tick()

        XCTAssertEqual(viewModel.completedSessionsCount, 1)
        XCTAssertEqual(viewModel.completedWorkSessionsCount, 1)
        XCTAssertEqual(viewModel.currentMode, .shortBreak)
        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertEqual(viewModel.timeRemainingSeconds, 5 * 60)
    }

    func testLongBreakAfterFourWorkSessions() {
        for _ in 1...4 {
            viewModel.currentMode = .work
            viewModel.resetToCurrentMode()
            viewModel.timeRemainingSeconds = 0
            viewModel.start()
            viewModel.tick()
        }

        XCTAssertEqual(viewModel.completedWorkSessionsCount, 4)
        XCTAssertEqual(viewModel.currentMode, .longBreak)
        XCTAssertEqual(viewModel.timeRemainingSeconds, 15 * 60)
    }

    func testTodayFocusMinutes() {
        viewModel.timeRemainingSeconds = 0
        viewModel.completeCurrentSession()

        XCTAssertEqual(viewModel.todayFocusMinutes, 25)
    }

    func testCompleteCurrentSessionPostsNotificationAndTriggersCallback() {
        var callbackCalled = false
        var completedMode: FocusMode?

        viewModel.onSessionCompleted = { mode in
            callbackCalled = true
            completedMode = mode
        }

        let expectation = expectation(description: "FocusSessionCompleted notification received")
        var receivedNotificationMode: FocusMode?

        let observer = NotificationCenter.default.addObserver(
            forName: .focusSessionCompleted,
            object: nil,
            queue: .main
        ) { notification in
            receivedNotificationMode = notification.userInfo?["mode"] as? FocusMode
            expectation.fulfill()
        }

        viewModel.currentMode = .work
        viewModel.completeCurrentSession()

        waitForExpectations(timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(completedMode, .work)
        XCTAssertEqual(receivedNotificationMode, .work)
    }

    func testNotificationManagerNotifiedOnSessionCompletion() {
        viewModel.currentMode = .shortBreak
        viewModel.completeCurrentSession()

        XCTAssertEqual(NotificationManager.shared.lastNotifiedMode, .shortBreak)
    }

    func testSessionCompletionDoesNotAutoOpenByDefault() {
        XCTAssertFalse(viewModel.autoOpenOnCompletion)
    }

    func testFocusTimerViewRendersAcrossAllThemesAndFocusModes() {
        for theme in AppThemeOption.allCases {
            AppTheme.current = theme
            for mode in FocusMode.allCases {
                viewModel.switchMode(to: mode)
                let timerView = FocusTimerView(timerVM: viewModel)
                XCTAssertNotNil(timerView.body)
                XCTAssertEqual(viewModel.currentMode, mode)
            }
        }
    }

    func testCircularProgressViewDefaultThemeAccent() {
        let progressView = CircularProgressView(
            progress: 0.5,
            formattedTime: "12:30",
            subtitle: "Long Break"
        )
        XCTAssertNotNil(progressView.body)
    }
}
