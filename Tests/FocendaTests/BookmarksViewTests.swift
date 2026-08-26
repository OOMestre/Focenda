import XCTest
import SwiftUI
@testable import FocendaCore

final class BookmarksViewTests: XCTestCase {
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults.standard
        testDefaults.removeObject(forKey: BookmarkViewModel.userDefaultsKey)
    }

    override func tearDown() {
        testDefaults.removeObject(forKey: BookmarkViewModel.userDefaultsKey)
        testDefaults = nil
        super.tearDown()
    }

    func testBookmarksViewInitializesWithDefaultBookmarks() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        let view = BookmarksView(viewModel: viewModel)

        XCTAssertFalse(viewModel.filteredBookmarks.isEmpty)
        XCTAssertNotNil(view.body)
    }

    func testResponsiveLayoutUsesCompactPaddingAndControlsForNarrowDetailPane() {
        XCTAssertEqual(BookmarksResponsiveLayout.horizontalPadding(for: 579), 12)
        XCTAssertEqual(BookmarksResponsiveLayout.horizontalPadding(for: 580), 20)
        XCTAssertEqual(BookmarksResponsiveLayout.compactControlsWidth, 580)
    }

    func testResponsiveGridUsesFewerFlexibleColumnsInNarrowDetailPanes() {
        let wideColumns = BookmarksResponsiveLayout.bookmarkGridColumns(
            for: 760,
            horizontalPadding: 20
        )
        let narrowColumns = BookmarksResponsiveLayout.bookmarkGridColumns(
            for: 180,
            horizontalPadding: 12
        )

        XCTAssertEqual(wideColumns.count, 3)
        XCTAssertEqual(narrowColumns.count, 1)
    }

    func testResponsiveStatsUseFlexibleColumns() {
        XCTAssertEqual(
            BookmarksResponsiveLayout.statisticsGridColumns(for: 760, horizontalPadding: 20).count,
            3
        )
        XCTAssertEqual(
            BookmarksResponsiveLayout.statisticsGridColumns(for: 260, horizontalPadding: 12).count,
            1
        )
    }
}
