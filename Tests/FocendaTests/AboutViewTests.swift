import XCTest
import SwiftUI
@testable import FocendaCore

final class AboutViewTests: XCTestCase {
    func testAboutTabIsAvailableInNavigation() {
        XCTAssertTrue(AppTab.allCases.contains(.about))
        XCTAssertTrue(AppTab.availableCases.contains(.about))
        XCTAssertEqual(AppTab.about.rawValue, "About")
        XCTAssertEqual(AppTab.about.iconName, "info.circle")
    }

    func testAboutURLPointsToFocendaRepository() {
        XCTAssertEqual(AboutView.githubURL.absoluteString, "https://github.com/OOMestre/Focenda")
    }

    func testAboutViewInitialization() {
        let appState = AppState()
        let updateManager = AppUpdateManager()
        let aboutView = AboutView(appState: appState, updateManager: updateManager)

        XCTAssertNotNil(aboutView)
        XCTAssertNotNil(aboutView.body)
    }

    func testAboutViewRendersWithEveryTheme() {
        let originalTheme = AppTheme.current
        defer { AppTheme.current = originalTheme }

        for theme in AppThemeOption.allCases {
            AppTheme.current = theme
            let aboutView = AboutView(appState: AppState(), updateManager: AppUpdateManager())

            XCTAssertNotNil(aboutView.body)
        }
    }
}
