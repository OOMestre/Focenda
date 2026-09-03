import XCTest
@testable import FocendaCore

final class ScratchpadTextEditorTests: XCTestCase {
    func testLineTextUsesTheCompleteLineContainingTheSelection() {
        let content = "Capture this\n  Plan the sprint  \nDone"
        let selectedRange = (content as NSString).range(of: "the sprint")

        let line = ScratchpadTextSelection.lineText(
            in: content,
            selectedRange: selectedRange
        )

        XCTAssertEqual(line, "Plan the sprint")
    }

    func testLineTextUsesTheCaretLineWhenNothingIsSelected() {
        let content = "Capture this\nPlan the sprint\nDone"
        let caretLocation = (content as NSString).range(of: "the").location

        let line = ScratchpadTextSelection.lineText(
            in: content,
            selectedRange: NSRange(location: caretLocation, length: 0)
        )

        XCTAssertEqual(line, "Plan the sprint")
    }

    func testLineTextIgnoresBlankLinesAndInvalidSelections() {
        let content = "First\n\nThird"
        let blankLine = ScratchpadTextSelection.lineText(
            in: content,
            selectedRange: NSRange(location: 6, length: 0)
        )

        XCTAssertNil(blankLine)
        XCTAssertNil(
            ScratchpadTextSelection.lineText(
                in: content,
                selectedRange: NSRange(location: NSNotFound, length: 0)
            )
        )
        XCTAssertNil(
            ScratchpadTextSelection.lineText(
                in: "",
                selectedRange: NSRange(location: 0, length: 0)
            )
        )
    }

    func testCaretAfterTrailingNewlineDoesNotReuseThePreviousLine() {
        let content = "First\n"

        XCTAssertNil(
            ScratchpadTextSelection.lineText(
                in: content,
                selectedRange: NSRange(location: (content as NSString).length, length: 0)
            )
        )
    }

    func testMultipleSelectedLinesBecomeOneTaskTitle() {
        let content = "First\nSecond\nThird"
        let selectedRange = NSRange(location: 0, length: (content as NSString).length)

        let line = ScratchpadTextSelection.lineText(
            in: content,
            selectedRange: selectedRange
        )

        XCTAssertEqual(line, "First Second Third")
    }
}
