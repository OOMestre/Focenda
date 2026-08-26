import XCTest
import SwiftUI
@testable import FocendaCore

final class SidebarViewTests: XCTestCase {

    var appState: AppState!
    var timerVM: FocusTimerViewModel!
    var taskVM: TaskListViewModel!
    var bookmarkVM: BookmarkViewModel!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AppTheme.storageKey)
        UserDefaults.standard.removeObject(forKey: "focenda_saved_tasks")
        UserDefaults.standard.removeObject(forKey: "focenda_saved_bookmarks")
        appState = AppState()
        timerVM = FocusTimerViewModel()
        taskVM = TaskListViewModel()
        bookmarkVM = BookmarkViewModel()
    }

    override func tearDown() {
        appState = nil
        timerVM = nil
        taskVM = nil
        bookmarkVM = nil
        super.tearDown()
    }

    func testSidebarViewInitialization() {
        let sidebar = SidebarView(
            appState: appState,
            timerVM: timerVM,
            taskVM: taskVM,
            bookmarkVM: bookmarkVM
        )
        XCTAssertNotNil(sidebar)
        XCTAssertNotNil(sidebar.body)
    }

    func testSidebarRowItemRenderingForAllTabs() {
        for tab in AppTab.allCases {
            let row = SidebarRowItem(
                tab: tab,
                isSelected: appState.selectedTab == tab,
                timerIsRunning: false,
                pendingTasksCount: 0,
                inProgressTasksCount: 0,
                totalBookmarksCount: 0,
                isPulsingDot: false
            )
            XCTAssertEqual(row.tab, tab)
            XCTAssertNotNil(row.body)
        }
    }

    func testSidebarRowItemTimerRunningBadge() {
        let runningRow = SidebarRowItem(
            tab: .timer,
            isSelected: true,
            timerIsRunning: true,
            isPulsingDot: true
        )
        XCTAssertTrue(runningRow.timerIsRunning)
        XCTAssertTrue(runningRow.isPulsingDot)
        XCTAssertNotNil(runningRow.body)
    }

    func testSidebarRowItemTaskCounter() {
        let taskRow = SidebarRowItem(
            tab: .kanban,
            isSelected: false,
            pendingTasksCount: 5
        )
        XCTAssertEqual(taskRow.pendingTasksCount, 5)
        XCTAssertNotNil(taskRow.body)
    }

    func testSidebarRowItemBookmarksCounter() {
        let bookmarkRow = SidebarRowItem(
            tab: .bookmarks,
            isSelected: false,
            totalBookmarksCount: 12
        )
        XCTAssertEqual(bookmarkRow.totalBookmarksCount, 12)
        XCTAssertNotNil(bookmarkRow.body)
    }

    func testMainViewInitialization() {
        let mainView = MainView(
            appState: appState,
            timerVM: timerVM,
            taskVM: taskVM,
            bookmarkVM: bookmarkVM
        )
        XCTAssertNotNil(mainView)
        XCTAssertNotNil(mainView.body)
    }

    func testMainViewSupportsCompactMacWindows() {
        XCTAssertEqual(MainView.minimumWindowWidth, 720)
        XCTAssertEqual(MainView.minimumWindowHeight, 540)
    }
}
