import XCTest
import SwiftUI
@testable import FocendaCore

final class OwlBrandAssetsTests: XCTestCase {

    func testMenuBarIconValidity() {
        let icon = OwlBrandAssets.menuBarIcon
        XCTAssertTrue(icon.isValid, "MenuBar icon should be a valid NSImage")
        XCTAssertTrue(icon.isTemplate, "MenuBar icon must be a template image for macOS status bar adaptation")
        XCTAssertEqual(icon.size.width, 18, accuracy: 0.1, "MenuBar icon width should be 18pt")
        XCTAssertEqual(icon.size.height, 18, accuracy: 0.1, "MenuBar icon height should be 18pt")
    }

    func testMascotImageValidity() {
        let mascot = OwlBrandAssets.mascotImage
        XCTAssertTrue(mascot.isValid, "Mascot image should be valid")
    }

    func testHeadIconImageValidity() {
        let head = OwlBrandAssets.headIconImage
        XCTAssertTrue(head.isValid, "Head icon image should be valid")
    }

    func testConfigureDockIconExecutesSafely() {
        OwlBrandAssets.configureDockIcon()
        // Should execute without throwing or crashing
    }

    func testSwiftUIBrandViewsInstantiation() {
        let menuBarView = OwlMenuBarIconView()
        XCTAssertNotNil(menuBarView.body)

        let faceView = OwlFaceView(size: 32)
        XCTAssertEqual(faceView.size, 32)
        XCTAssertNotNil(faceView.body)

        let mascotView = OwlMascotView(size: 96)
        XCTAssertEqual(mascotView.size, 96)
        XCTAssertNotNil(mascotView.body)
    }
}
