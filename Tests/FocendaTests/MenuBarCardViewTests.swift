import XCTest
import SwiftUI
@testable import FocendaCore

final class MenuBarCardViewTests: XCTestCase {

    func testMenuBarCardViewInitialization() {
        let timerVM = FocusTimerViewModel()
        let appState = AppState()
        let cardView = MenuBarCardView(timerVM: timerVM, appState: appState)

        XCTAssertNotNil(cardView)
        XCTAssertEqual(cardView.timerVM.currentMode, .work)
        XCTAssertNotNil(cardView.appState)
    }

    func testMenuBarCardViewDefaultInitialization() {
        let timerVM = FocusTimerViewModel()
        let cardView = MenuBarCardView(timerVM: timerVM)

        XCTAssertNotNil(cardView)
        XCTAssertEqual(cardView.timerVM.currentMode, .work)
        XCTAssertNil(cardView.appState)
    }

    func testMenuBarCardViewWithDifferentModes() {
        let timerVM = FocusTimerViewModel()

        for mode in FocusMode.allCases {
            timerVM.switchMode(to: mode)
            let cardView = MenuBarCardView(timerVM: timerVM)
            XCTAssertEqual(cardView.timerVM.currentMode, mode)
            XCTAssertFalse(cardView.timerVM.formattedTimeRemaining.isEmpty)
        }
    }

    func testTimerControlsThroughViewModel() {
        let timerVM = FocusTimerViewModel()
        XCTAssertEqual(timerVM.status, .idle)

        timerVM.start()
        XCTAssertEqual(timerVM.status, .running)

        timerVM.pause()
        XCTAssertEqual(timerVM.status, .paused)

        timerVM.reset()
        XCTAssertEqual(timerVM.status, .idle)
        XCTAssertEqual(timerVM.timeRemainingSeconds, 25 * 60)

        timerVM.skip()
        XCTAssertEqual(timerVM.currentMode, .shortBreak)
    }

    func testQuickTimePresets() {
        let timerVM = FocusTimerViewModel()
        let initialSeconds = timerVM.timeRemainingSeconds

        timerVM.adjustTime(byMinutes: 5)
        XCTAssertEqual(timerVM.timeRemainingSeconds, initialSeconds + 300)

        timerVM.adjustTime(byMinutes: -5)
        XCTAssertEqual(timerVM.timeRemainingSeconds, initialSeconds)
    }

    func testMenuBarCardViewCycleProgress() {
        let timerVM = FocusTimerViewModel()
        XCTAssertEqual(timerVM.completedWorkSessionsCount, 0)

        timerVM.completedWorkSessionsCount = 1
        XCTAssertEqual(timerVM.completedWorkSessionsCount % 4, 1)

        timerVM.completedWorkSessionsCount = 4
        XCTAssertEqual(timerVM.completedWorkSessionsCount % 4, 0)
    }

    func testMenuBarCardViewProgressCalculations() {
        let timerVM = FocusTimerViewModel()
        XCTAssertEqual(timerVM.progress, 0.0, accuracy: 0.001)

        timerVM.timeRemainingSeconds = 12 * 60 + 30 // Halfway through 25 min
        XCTAssertEqual(timerVM.progress, 0.5, accuracy: 0.01)
    }
}
