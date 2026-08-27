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

    func testBookmarksViewAllCategoriesContainsPresetsAndCustomCategories() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.addBookmark(title: "Custom Link", url: "https://example.com", category: "Custom Category")

        let categories = viewModel.allCategories
        XCTAssertTrue(categories.contains("All"))
        XCTAssertTrue(categories.contains("Focus & Flow"))
        XCTAssertTrue(categories.contains("Development"))
        XCTAssertTrue(categories.contains("Documentation"))
        XCTAssertTrue(categories.contains("Design & UI"))
        XCTAssertTrue(categories.contains("Reference"))
        XCTAssertTrue(categories.contains("Utilities"))
        XCTAssertTrue(categories.contains("Custom Category"))

        XCTAssertEqual(viewModel.categoryCount(for: "Custom Category"), 1)
        XCTAssertEqual(viewModel.categoryCount(for: "All"), viewModel.bookmarks.count)
    }

    func testBookmarksCategoryFilterChipsWrapInConstrainedWidth() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        // Approximate chip widths: [All: 65, Focus & Flow: 125, Development: 125, Documentation: 135, Design & UI: 120, Reference: 110, Utilities: 100]
        let estimatedChipSizes: [CGSize] = viewModel.allCategories.map { category in
            CGSize(width: CGFloat(category.count * 8 + 40), height: 32)
        }

        // With unconstrained width, all categories are in 1 row
        let unconstrainedResult = FlowLayout.calculateLayout(itemSizes: estimatedChipSizes, maxWidth: 2000)
        XCTAssertEqual(unconstrainedResult.rows.count, 1)

        // In a narrow window / detail pane (e.g. 360pt), categories wrap into multiple rows
        let constrainedResult = FlowLayout.calculateLayout(itemSizes: estimatedChipSizes, maxWidth: 360)
        XCTAssertGreaterThan(constrainedResult.rows.count, 1)
        // All items are accounted for across the rows
        let totalItemsInRows = constrainedResult.rows.reduce(0) { $0 + $1.itemIndices.count }
        XCTAssertEqual(totalItemsInRows, viewModel.allCategories.count)
    }

    func testBookmarksViewRendersInHostingView() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        let view = BookmarksView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(x: 0, y: 0, width: 450, height: 600)
        hostingView.layoutSubtreeIfNeeded()

        XCTAssertNotNil(hostingView)
        XCTAssertEqual(hostingView.frame.width, 450)
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
