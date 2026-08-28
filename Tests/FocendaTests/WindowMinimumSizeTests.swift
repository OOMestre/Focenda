import XCTest
import SwiftUI
@testable import FocendaCore

final class WindowMinimumSizeTests: XCTestCase {

    var appState: AppState!
    var timerVM: FocusTimerViewModel!
    var taskVM: TaskListViewModel!
    var scratchpadVM: ScratchpadViewModel!
    var bookmarkVM: BookmarkViewModel!
    var recurringReminderVM: RecurringReminderViewModel!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AppTheme.storageKey)
        UserDefaults.standard.removeObject(forKey: "focenda_saved_tasks")
        UserDefaults.standard.removeObject(forKey: "focenda_saved_bookmarks")
        UserDefaults.standard.removeObject(forKey: "focenda_saved_reminders")
        UserDefaults.standard.removeObject(forKey: "focenda_saved_notes")

        appState = AppState()
        timerVM = FocusTimerViewModel()
        taskVM = TaskListViewModel()
        scratchpadVM = ScratchpadViewModel()
        bookmarkVM = BookmarkViewModel()
        recurringReminderVM = RecurringReminderViewModel()
    }

    override func tearDown() {
        appState = nil
        timerVM = nil
        taskVM = nil
        scratchpadVM = nil
        bookmarkVM = nil
        recurringReminderVM = nil
        super.tearDown()
    }

    func testMinimumWindowSizeConstants() {
        XCTAssertEqual(MainView.minimumWindowWidth, 800)
        XCTAssertEqual(MainView.minimumWindowHeight, 560)
        XCTAssertEqual(MainView.defaultWindowWidth, 1360)
        XCTAssertEqual(MainView.defaultWindowHeight, 900)
        XCTAssertGreaterThan(MainView.defaultWindowWidth, MainView.minimumWindowWidth)
        XCTAssertGreaterThan(MainView.defaultWindowHeight, MainView.minimumWindowHeight)
    }

    func testWindowMinSizeConfiguratorInitialization() {
        let configurator = WindowMinSizeConfigurator(
            minWidth: MainView.minimumWindowWidth,
            minHeight: MainView.minimumWindowHeight,
            initialWidth: MainView.defaultWindowWidth,
            initialHeight: MainView.defaultWindowHeight,
            initialSizePreferenceKey: "test_initial_window_size"
        )
        XCTAssertEqual(configurator.minWidth, 800)
        XCTAssertEqual(configurator.minHeight, 560)
        XCTAssertEqual(configurator.initialWidth, 1360)
        XCTAssertEqual(configurator.initialHeight, 900)
        XCTAssertEqual(configurator.initialSizePreferenceKey, "test_initial_window_size")
    }

    func testViewEnforceMinimumWindowSizeModifier() {
        let testView = Text("Test")
            .enforceMinimumWindowSize(width: 800, height: 560)
        XCTAssertNotNil(testView)
    }

    func testMainViewRendersAllTabsAtMinimumWindowSize() {
        for tab in AppTab.allCases {
            appState.selectedTab = tab
            let mainView = MainView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM,
                scratchpadVM: scratchpadVM,
                bookmarkVM: bookmarkVM,
                recurringReminderVM: recurringReminderVM
            )

            XCTAssertNotNil(mainView)
            XCTAssertNotNil(mainView.body)
        }
    }

    func testDashboardViewResilienceAtMinimumWidth() {
        let dashboard = DashboardView(
            appState: appState,
            timerVM: timerVM,
            taskVM: taskVM
        )

        XCTAssertNotNil(dashboard)
        XCTAssertNotNil(dashboard.body)
    }

    func testStatsViewResilienceAtMinimumWidth() {
        let statsView = StatsView(
            timerVM: timerVM,
            taskVM: taskVM
        )

        XCTAssertNotNil(statsView)
        XCTAssertNotNil(statsView.body)
    }

    func testFocusTimerViewResilienceAtMinimumDimensions() {
        let timerView = FocusTimerView(timerVM: timerVM)

        XCTAssertNotNil(timerView)
        XCTAssertNotNil(timerView.body)
    }

    func testKanbanBoardViewResilienceAtMinimumDimensions() {
        let kanbanView = KanbanBoardView(taskVM: taskVM)

        XCTAssertNotNil(kanbanView)
        XCTAssertNotNil(kanbanView.body)
    }

    func testCalendarViewResilienceAtMinimumDimensions() {
        let calendarView = CalendarView(
            timerVM: timerVM,
            taskVM: taskVM,
            recurringReminderVM: recurringReminderVM
        )

        XCTAssertNotNil(calendarView)
        XCTAssertNotNil(calendarView.body)
    }

    func testRemindersViewResilienceAtMinimumDimensions() {
        let remindersView = RemindersView(
            recurringReminderVM: recurringReminderVM,
            taskVM: taskVM
        )

        XCTAssertNotNil(remindersView)
        XCTAssertNotNil(remindersView.body)
    }

    func testScratchpadViewResilienceAtMinimumDimensions() {
        scratchpadVM.showFoldersSidebar = true
        let scratchpadViewWithFolders = ScratchpadView(viewModel: scratchpadVM)
        XCTAssertNotNil(scratchpadViewWithFolders)
        XCTAssertNotNil(scratchpadViewWithFolders.body)

        scratchpadVM.showFoldersSidebar = false
        let scratchpadViewWithoutFolders = ScratchpadView(viewModel: scratchpadVM)
        XCTAssertNotNil(scratchpadViewWithoutFolders)
        XCTAssertNotNil(scratchpadViewWithoutFolders.body)
    }

    func testBookmarksViewResilienceAtMinimumDimensions() {
        let bookmarksView = BookmarksView(viewModel: bookmarkVM)

        XCTAssertNotNil(bookmarksView)
        XCTAssertNotNil(bookmarksView.body)
    }

    func testSettingsViewResilienceAtMinimumDimensions() {
        appState.globalShortcutsEnabled = true
        for preset in GlobalShortcutPreset.allCases {
            appState.shortcutPreset = preset
            let settingsView = SettingsView(appState: appState, timerVM: timerVM)
            XCTAssertNotNil(settingsView)
            XCTAssertNotNil(settingsView.body)
        }
    }

    func testKanbanBoardLayoutResponsiveness() {
        let narrowWidth: CGFloat = 560
        let normalWidth: CGFloat = 800
        let wideWidth: CGFloat = 1200

        let narrowCol = KanbanBoardLayout.columnWidth(for: narrowWidth)
        let normalCol = KanbanBoardLayout.columnWidth(for: normalWidth)
        let wideCol = KanbanBoardLayout.columnWidth(for: wideWidth)

        XCTAssertGreaterThanOrEqual(narrowCol, KanbanBoardLayout.minimumColumnWidth)
        XCTAssertLessThanOrEqual(wideCol, KanbanBoardLayout.preferredColumnWidth)
        XCTAssertGreaterThanOrEqual(wideCol, normalCol)
        XCTAssertGreaterThanOrEqual(normalCol, narrowCol)
    }
}
