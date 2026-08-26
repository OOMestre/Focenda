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
}
