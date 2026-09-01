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

    func testBookmarksViewInitializesWithoutBookmarks() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        let view = BookmarksView(viewModel: viewModel)

        XCTAssertTrue(viewModel.filteredBookmarks.isEmpty)
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
        // Approximate chip widths: [All: 64, Focus & Flow: 136, Development: 128, Documentation: 144, Design & UI: 128, Reference: 112, Utilities: 112]
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

    func testCategoryFilterWrappingAtSpecificContentWidths() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        let estimatedChipSizes: [CGSize] = viewModel.allCategories.map { category in
            CGSize(width: CGFloat(category.count * 8 + 40), height: 32)
        }

        let testWidths: [CGFloat] = [750, 640, 500, 360]

        for width in testWidths {
            let layoutResult = FlowLayout.calculateLayout(
                itemSizes: estimatedChipSizes,
                maxWidth: width,
                spacing: 8,
                lineSpacing: 8
            )

            // When content width is finite (<= 750pt), the 7 category chips (~872pt total) must wrap across multiple rows
            XCTAssertGreaterThan(
                layoutResult.rows.count,
                1,
                "Categories should wrap into multiple rows for content width \(width)pt"
            )

            // All category items must be preserved
            let allIndices = layoutResult.rows.flatMap(\.itemIndices)
            XCTAssertEqual(allIndices.count, viewModel.allCategories.count)
            XCTAssertEqual(Set(allIndices), Set(0..<viewModel.allCategories.count))

            // No row's width should exceed the given content width
            for (rowIndex, row) in layoutResult.rows.enumerated() {
                XCTAssertLessThanOrEqual(
                    row.width,
                    width,
                    "Row \(rowIndex) width (\(row.width)pt) must not exceed container width (\(width)pt)"
                )
            }
        }
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

    func testBookmarksViewDeleteBookmarkFlow() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.addBookmark(title: "Bookmark to Delete", url: "https://delete.example")
        let initialCount = viewModel.bookmarks.count
        guard let first = viewModel.bookmarks.first else {
            XCTFail("Expected at least one bookmark")
            return
        }

        let view = BookmarksView(viewModel: viewModel)
        XCTAssertNotNil(view.body)

        viewModel.deleteBookmark(first)
        XCTAssertEqual(viewModel.bookmarks.count, initialCount - 1)
        XCTAssertFalse(viewModel.bookmarks.contains(where: { $0.id == first.id }))
    }

    func testBookmarksViewDeleteFromCategoryUpdatesCounts() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.addBookmark(title: "Rust Lang", url: "https://rust-lang.org", category: "Development")
        let devCountBefore = viewModel.categoryCount(for: "Development")

        guard let rustBookmark = viewModel.bookmarks.first(where: { $0.title == "Rust Lang" }) else {
            XCTFail("Rust bookmark not found")
            return
        }

        viewModel.deleteBookmark(id: rustBookmark.id)
        let devCountAfter = viewModel.categoryCount(for: "Development")
        XCTAssertEqual(devCountAfter, devCountBefore - 1)
    }
}
