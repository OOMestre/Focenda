import XCTest
import SwiftUI
@testable import FocendaCore

final class FlowLayoutTests: XCTestCase {
    func testEmptyItemsYieldsZeroSizeAndNoRows() {
        let result = FlowLayout.calculateLayout(itemSizes: [], maxWidth: 300)
        XCTAssertEqual(result.rows.count, 0)
        XCTAssertEqual(result.size, .zero)
    }

    func testSingleLineWhenWidthIsUnconstrained() {
        let items = [
            CGSize(width: 50, height: 20),
            CGSize(width: 60, height: 25),
            CGSize(width: 70, height: 20)
        ]
        // Spacing is 8, lineSpacing is 8
        // Width: 50 + 8 + 60 + 8 + 70 = 196
        // Height: max(20, 25, 20) = 25
        let result = FlowLayout.calculateLayout(itemSizes: items, maxWidth: .infinity, spacing: 8, lineSpacing: 8)

        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows[0].itemIndices, [0, 1, 2])
        XCTAssertEqual(result.rows[0].width, 196)
        XCTAssertEqual(result.rows[0].height, 25)
        XCTAssertEqual(result.size.width, 196)
        XCTAssertEqual(result.size.height, 25)
    }

    func testWrappingIntoMultipleRowsWhenWidthIsConstrained() {
        let items = [
            CGSize(width: 80, height: 30),  // Item 0
            CGSize(width: 80, height: 30),  // Item 1: proposed width = 80 + 8 + 80 = 168 <= 200 -> Row 0
            CGSize(width: 80, height: 30),  // Item 2: proposed width = 168 + 8 + 80 = 256 > 200 -> Row 1
            CGSize(width: 80, height: 30),  // Item 3: proposed width = 80 + 8 + 80 = 168 <= 200 -> Row 1
            CGSize(width: 50, height: 30)   // Item 4: proposed width = 168 + 8 + 50 = 226 > 200 -> Row 2
        ]

        let result = FlowLayout.calculateLayout(itemSizes: items, maxWidth: 200, spacing: 8, lineSpacing: 10)

        XCTAssertEqual(result.rows.count, 3)

        // Row 0: Items 0, 1 (width: 80 + 8 + 80 = 168)
        XCTAssertEqual(result.rows[0].itemIndices, [0, 1])
        XCTAssertEqual(result.rows[0].width, 168)
        XCTAssertEqual(result.rows[0].height, 30)

        // Row 1: Items 2, 3 (width: 80 + 8 + 80 = 168)
        XCTAssertEqual(result.rows[1].itemIndices, [2, 3])
        XCTAssertEqual(result.rows[1].width, 168)
        XCTAssertEqual(result.rows[1].height, 30)

        // Row 2: Item 4 (width: 50)
        XCTAssertEqual(result.rows[2].itemIndices, [4])
        XCTAssertEqual(result.rows[2].width, 50)
        XCTAssertEqual(result.rows[2].height, 30)

        // Total Size: maxRowWidth = 168, totalHeight = 30 + 10 + 30 + 10 + 30 = 110
        XCTAssertEqual(result.size.width, 168)
        XCTAssertEqual(result.size.height, 110)
    }

    func testItemsWiderThanMaxWidthArePlacedOnTheirOwnRow() {
        let items = [
            CGSize(width: 60, height: 20),
            CGSize(width: 250, height: 35), // wider than maxWidth (200)
            CGSize(width: 70, height: 20)
        ]

        let result = FlowLayout.calculateLayout(itemSizes: items, maxWidth: 200, spacing: 8, lineSpacing: 8)

        XCTAssertEqual(result.rows.count, 3)
        XCTAssertEqual(result.rows[0].itemIndices, [0])
        XCTAssertEqual(result.rows[1].itemIndices, [1])
        XCTAssertEqual(result.rows[2].itemIndices, [2])
        XCTAssertEqual(result.size.width, 250)
        XCTAssertEqual(result.size.height, 20 + 8 + 35 + 8 + 20)
    }

    func testLayoutInitializationAndCustomParameters() {
        let layout = FlowLayout(
            spacing: 12,
            lineSpacing: 16,
            horizontalAlignment: .center,
            verticalAlignment: .top
        )

        XCTAssertEqual(layout.spacing, 12)
        XCTAssertEqual(layout.lineSpacing, 16)
        XCTAssertEqual(layout.horizontalAlignment, .center)
        XCTAssertEqual(layout.verticalAlignment, .top)
    }

    func testFlowLayoutInSwiftUIViewHierarchy() {
        let view = FlowLayout(spacing: 6, lineSpacing: 6) {
            Text("All")
            Text("Focus & Flow")
            Text("Development")
            Text("Documentation")
            Text("Design & UI")
            Text("Reference")
            Text("Utilities")
        }

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(x: 0, y: 0, width: 250, height: 200)
        let fittingSize = hostingView.fittingSize

        XCTAssertGreaterThan(fittingSize.width, 0)
        XCTAssertGreaterThan(fittingSize.height, 0)
    }
}
