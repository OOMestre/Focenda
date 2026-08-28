import XCTest
import SwiftUI
@testable import FocendaCore

final class SupportViewTests: XCTestCase {

    func testSupportTabIsAvailableInNavigation() {
        XCTAssertTrue(AppTab.allCases.contains(.support))
        XCTAssertEqual(AppTab.support.rawValue, "Support")
        XCTAssertEqual(AppTab.support.iconName, "heart.fill")
    }

    func testSupportURLPointsToBuyMeACoffee() {
        XCTAssertEqual(SupportView.supportURL.absoluteString, "https://buymeacoffee.com/omestre")
    }

    func testSupportViewInitialization() {
        let supportView = SupportView()

        XCTAssertNotNil(supportView)
        XCTAssertNotNil(supportView.body)
    }

    func testSupportViewRendersWithEveryTheme() {
        let originalTheme = AppTheme.current
        defer { AppTheme.current = originalTheme }

        for theme in AppThemeOption.allCases {
            AppTheme.current = theme
            let supportView = SupportView()

            XCTAssertNotNil(supportView.body)
        }
    }
}
