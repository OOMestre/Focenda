import XCTest
@testable import FocendaCore

final class FocusTimerViewModelTests: XCTestCase {

    var viewModel: FocusTimerViewModel!
    private var clock: TestClock!
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!

    override func setUp() {
        super.setUp()
        clock = TestClock()
        testSuiteName = "Focenda.FocusTimerViewModelTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        viewModel = FocusTimerViewModel(
            userDefaults: testDefaults,
            now: { [clock] in clock!.now }
        )
    }

    override func tearDown() {
        viewModel?.pause()
        viewModel?.reset()
        ReminderAlertHUDPanel.shared.dismiss()
        viewModel = nil
        clock = nil
        testDefaults?.removePersistentDomain(forName: testSuiteName)
        testDefaults = nil
        testSuiteName = nil
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

        clock.advance(by: .seconds(1))
        viewModel.tick()
        XCTAssertEqual(viewModel.timeRemainingSeconds, (25 * 60) - 1)
        XCTAssertGreaterThan(viewModel.progress, 0.0)
    }

    func testTickUsesElapsedTimeWhenCallbacksAreDelayed() {
        viewModel.start()

        clock.advance(by: .seconds(7))
        viewModel.tick()

        XCTAssertEqual(viewModel.timeRemainingSeconds, (25 * 60) - 7)
    }

    func testPauseStopsElapsedTimeUntilResume() {
        viewModel.start()
        clock.advance(by: .seconds(10))
        viewModel.pause()

        clock.advance(by: .seconds(60))
        XCTAssertEqual(viewModel.timeRemainingSeconds, (25 * 60) - 10)

        viewModel.resume()
        clock.advance(by: .seconds(4))
        viewModel.tick()

        XCTAssertEqual(viewModel.timeRemainingSeconds, (25 * 60) - 14)
    }

    func testAdjustTimePreservesElapsedTimeWhileRunning() {
        viewModel.start()
        clock.advance(by: .seconds(10))

        viewModel.adjustTime(bySeconds: 5 * 60)
        clock.advance(by: .seconds(5))
        viewModel.tick()

        XCTAssertEqual(viewModel.timeRemainingSeconds, (25 * 60) + (5 * 60) - 15)
    }

    func testDelayedTickCompletesTheSession() {
        viewModel.start()
        clock.advance(by: .seconds(25 * 60 + 30))

        viewModel.tick()

        XCTAssertEqual(viewModel.completedSessionsCount, 1)
        XCTAssertEqual(viewModel.currentMode, .shortBreak)
        XCTAssertEqual(viewModel.status, .idle)
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

    func testCompletedSessionsPersistAcrossViewModelInstances() {
        viewModel.currentMode = .work
        viewModel.completeCurrentSession()

        viewModel.currentMode = .shortBreak
        viewModel.resetToCurrentMode()
        viewModel.completeCurrentSession()

        let reloadedViewModel = FocusTimerViewModel(userDefaults: testDefaults)

        XCTAssertEqual(reloadedViewModel.completedSessions, viewModel.completedSessions)
        XCTAssertEqual(reloadedViewModel.completedSessionsCount, 2)
        XCTAssertEqual(reloadedViewModel.completedWorkSessionsCount, 1)
        XCTAssertEqual(reloadedViewModel.todayFocusMinutes, 25)
        XCTAssertNotNil(testDefaults.data(forKey: FocusTimerViewModel.userDefaultsKey))
    }

    func testTimerDurationsPersistAcrossViewModelInstances() {
        viewModel.workDurationMinutes = 50
        viewModel.shortBreakDurationMinutes = 10
        viewModel.longBreakDurationMinutes = 20

        let reloadedViewModel = FocusTimerViewModel(userDefaults: testDefaults)

        XCTAssertEqual(reloadedViewModel.workDurationMinutes, 50)
        XCTAssertEqual(reloadedViewModel.shortBreakDurationMinutes, 10)
        XCTAssertEqual(reloadedViewModel.longBreakDurationMinutes, 20)
    }

    func testUnreadableTimerSettingsAreNeverOverwrittenByAUserAction() throws {
        let corruptedPayload = Data("timer settings from an incompatible build".utf8)
        testDefaults.set(corruptedPayload, forKey: FocusTimerViewModel.timerSettingsKey)

        let reloadedViewModel = FocusTimerViewModel(userDefaults: testDefaults)
        let payloadAfterLoad = try XCTUnwrap(testDefaults.data(forKey: FocusTimerViewModel.timerSettingsKey))
        reloadedViewModel.workDurationMinutes = 50

        XCTAssertEqual(payloadAfterLoad, corruptedPayload)
        XCTAssertEqual(testDefaults.data(forKey: FocusTimerViewModel.timerSettingsKey), payloadAfterLoad)
    }

    func testUnreadableSessionHistoryIsNeverOverwrittenByAUserAction() throws {
        let corruptedPayload = Data("focus history from an incompatible build".utf8)
        testDefaults.set(corruptedPayload, forKey: FocusTimerViewModel.userDefaultsKey)

        let reloadedViewModel = FocusTimerViewModel(userDefaults: testDefaults)
        let payloadAfterLoad = try XCTUnwrap(testDefaults.data(forKey: FocusTimerViewModel.userDefaultsKey))
        reloadedViewModel.completedSessions.append(FocusSession(mode: .work, durationSeconds: 1))

        XCTAssertNotEqual(payloadAfterLoad, corruptedPayload)
        XCTAssertEqual(testDefaults.data(forKey: FocusTimerViewModel.userDefaultsKey), payloadAfterLoad)
    }

    func testLoadingHistoryRebuildsCountersFromStoredSessions() throws {
        let sessions = [
            FocusSession(mode: .work, durationSeconds: 30 * 60),
            FocusSession(mode: .shortBreak, durationSeconds: 5 * 60),
            FocusSession(mode: .work, durationSeconds: 45 * 60)
        ]
        testDefaults.set(try JSONEncoder().encode(sessions), forKey: FocusTimerViewModel.userDefaultsKey)

        let reloadedViewModel = FocusTimerViewModel(userDefaults: testDefaults)

        XCTAssertEqual(reloadedViewModel.completedSessions, sessions)
        XCTAssertEqual(reloadedViewModel.completedSessionsCount, 3)
        XCTAssertEqual(reloadedViewModel.completedWorkSessionsCount, 2)
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

private final class TestClock {
    var now = ContinuousClock.now

    func advance(by duration: Duration) {
        now = now.advanced(by: duration)
    }
}
