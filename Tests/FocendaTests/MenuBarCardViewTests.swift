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
        XCTAssertEqual(cardView.selectedSection, .focus)
    }

    func testMenuBarCardViewFullInitialization() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let scratchpadVM = ScratchpadViewModel()
        let appState = AppState()

        let cardView = MenuBarCardView(
            timerVM: timerVM,
            taskVM: taskVM,
            scratchpadVM: scratchpadVM,
            appState: appState
        )

        XCTAssertNotNil(cardView)
        XCTAssertEqual(cardView.selectedSection, .focus)
        XCTAssertEqual(cardView.taskVM.tasks.count, taskVM.tasks.count)
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

    func testShortModeTitles() {
        let timerVM = FocusTimerViewModel()
        let cardView = MenuBarCardView(timerVM: timerVM)

        XCTAssertEqual(cardView.shortModeTitle(for: .work), "Focus")
        XCTAssertEqual(cardView.shortModeTitle(for: .shortBreak), "Short")
        XCTAssertEqual(cardView.shortModeTitle(for: .longBreak), "Long")
    }

    func testStatusText() {
        let timerVM = FocusTimerViewModel()
        let cardView = MenuBarCardView(timerVM: timerVM)

        XCTAssertEqual(cardView.statusText, "READY")

        timerVM.start()
        XCTAssertEqual(cardView.statusText, "RUNNING")

        timerVM.pause()
        XCTAssertEqual(cardView.statusText, "PAUSED")
    }

    func testMenuBarSectionsAndIcons() {
        let sections = MenuBarSection.allCases
        XCTAssertEqual(sections.count, 4)
        XCTAssertTrue(sections.contains(.focus))
        XCTAssertTrue(sections.contains(.quickNote))
        XCTAssertTrue(sections.contains(.quickTask))
        XCTAssertTrue(sections.contains(.quickLinks))

        for section in sections {
            XCTAssertFalse(section.iconName.isEmpty)
            XCTAssertFalse(section.rawValue.isEmpty)
        }
    }

    func testQuickLinksModel() {
        let defaultLinks = QuickLink.defaultLinks
        XCTAssertFalse(defaultLinks.isEmpty)
        XCTAssertTrue(defaultLinks.contains { $0.title == "GitHub" })

        let customLink = QuickLink(title: "Linear", urlString: "https://linear.app", iconName: "target")
        XCTAssertEqual(customLink.url?.absoluteString, "https://linear.app")
    }

    func testFloatingMiniTimerPanelAndWidget() {
        let panel = FloatingMiniTimerPanel.shared
        XCTAssertNotNil(panel)
        XCTAssertEqual(panel.level, .floating)
        XCTAssertTrue(panel.isMovableByWindowBackground)

        let timerVM = FocusTimerViewModel()
        var closed = false
        let miniWidget = FloatingMiniTimerView(timerVM: timerVM) {
            closed = true
        }

        XCTAssertNotNil(miniWidget)
        miniWidget.onClose?()
        XCTAssertTrue(closed)
    }

    func testCardBodyRendering() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let scratchpadVM = ScratchpadViewModel()

        let cardView = MenuBarCardView(
            timerVM: timerVM,
            taskVM: taskVM,
            scratchpadVM: scratchpadVM,
        )

        let body = cardView.body
        XCTAssertNotNil(body)
    }

    func testMenuBarCardViewAllSectionsRendering() {
        let timerVM = FocusTimerViewModel()
        let taskVM = TaskListViewModel()
        let scratchpadVM = ScratchpadViewModel()
        let appState = AppState()

        for section in MenuBarSection.allCases {
            let cardView = MenuBarCardView(
                timerVM: timerVM,
                taskVM: taskVM,
                scratchpadVM: scratchpadVM,
                    appState: appState,
                initialSection: section
            )
            XCTAssertNotNil(cardView.body)
            XCTAssertEqual(cardView.selectedSection, section)
        }
    }

    func testMenuBarCardViewFolderSelectionAndSync() {
        let timerVM = FocusTimerViewModel()
        let scratchpadVM = ScratchpadViewModel()
        scratchpadVM.createFolder("Sprint 43")

        let cardView = MenuBarCardView(
            timerVM: timerVM,
            scratchpadVM: scratchpadVM,
            initialSection: .quickNote
        )

        XCTAssertNotNil(cardView)
        XCTAssertTrue(scratchpadVM.folders.contains("Sprint 43"))
        XCTAssertEqual(cardView.selectedSection, .quickNote)
    }

    func testMenuBarCardViewSaveQuickNoteIntoUserFolder() {
        let timerVM = FocusTimerViewModel()
        let scratchpadVM = ScratchpadViewModel()
        scratchpadVM.createFolder("Architecture")

        let cardView = MenuBarCardView(
            timerVM: timerVM,
            scratchpadVM: scratchpadVM,
            initialSection: .quickNote
        )
        XCTAssertNotNil(cardView)

        let initialCount = scratchpadVM.noteCount(for: "Architecture")
        _ = scratchpadVM.createNote(title: "", content: "New architecture note", folder: "Architecture")

        XCTAssertEqual(scratchpadVM.noteCount(for: "Architecture"), initialCount + 1)
        XCTAssertEqual(scratchpadVM.notes.first?.folder, "Architecture")
        XCTAssertEqual(scratchpadVM.notes.first?.content, "New architecture note")
    }

    func testFocusSessionCompletedNotificationTriggersInMenuBarView() {
        let timerVM = FocusTimerViewModel()
        let cardView = MenuBarCardView(timerVM: timerVM)
        XCTAssertNotNil(cardView.body)

        // Post notification and ensure no crash or state inconsistency
        NotificationCenter.default.post(
            name: .focusSessionCompleted,
            object: nil,
            userInfo: ["mode": FocusMode.work]
        )
    }
}
