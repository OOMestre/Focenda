import XCTest
import SwiftUI
import AppKit
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

    func testDockIconAddsTransparentBreathingRoom() {
        let source = OwlBrandAssets.mascotImage
        let dockIcon = OwlBrandAssets.dockIconImage(from: source)

        XCTAssertTrue(dockIcon.isValid, "Dock icon should be a valid NSImage")
        XCTAssertEqual(dockIcon.size.width, source.size.width, accuracy: 0.1)
        XCTAssertEqual(dockIcon.size.height, source.size.height, accuracy: 0.1)
        XCTAssertEqual(OwlBrandAssets.dockIconArtworkScale, 0.92, accuracy: 0.001)
        XCTAssertFalse(dockIcon === source, "Dock icon should be rendered onto its own canvas")

        guard let tiffRepresentation = dockIcon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation),
              let bitmapData = bitmap.bitmapData else {
            XCTFail("Dock icon should expose a bitmap representation")
            return
        }

        let edgeOffset = (bitmap.pixelsHigh - 1) * bitmap.bytesPerRow
            + (bitmap.pixelsWide / 2) * bitmap.samplesPerPixel
        let edgePixel = (0..<bitmap.samplesPerPixel).map { bitmapData[edgeOffset + $0] }
        XCTAssertTrue(edgePixel.allSatisfy { $0 == 0 }, "Dock icon should have a transparent outer margin")
    }

    func testSwiftUIBrandViewsInstantiation() {
        let menuBarView = OwlMenuBarIconView()
        XCTAssertNotNil(menuBarView.body)

        let faceView = OwlFaceView(size: 32)
        XCTAssertEqual(faceView.size, 32)
        XCTAssertNotNil(faceView.body)

        let mascotView = OwlMascotView(size: 96)
        XCTAssertEqual(mascotView.size, 96)
        XCTAssertFalse(mascotView.isCircular)
        XCTAssertNotNil(mascotView.body)

        let circularMascotView = OwlMascotView(size: 96, isCircular: true)
        XCTAssertTrue(circularMascotView.isCircular)
        XCTAssertNotNil(circularMascotView.body)
    }
}
