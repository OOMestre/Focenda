import XCTest
import SwiftUI
@testable import FocendaCore

final class AppThemeTests: XCTestCase {

    func testFocusModeThemeColors() {
        XCTAssertNotNil(FocusMode.work.themeColor)
        XCTAssertNotNil(FocusMode.shortBreak.themeColor)
        XCTAssertNotNil(FocusMode.longBreak.themeColor)

        XCTAssertEqual(FocusMode.work.themeColor, AppTheme.deepFocus)
        XCTAssertEqual(FocusMode.shortBreak.themeColor, AppTheme.shortBreak)
        XCTAssertEqual(FocusMode.longBreak.themeColor, AppTheme.longBreak)
    }

    func testAppThemeColorsExist() {
        XCTAssertNotNil(AppTheme.deepFocus)
        XCTAssertNotNil(AppTheme.shortBreak)
        XCTAssertNotNil(AppTheme.longBreak)
        XCTAssertNotNil(AppTheme.background)
        XCTAssertNotNil(AppTheme.cardBackground)
        XCTAssertNotNil(AppTheme.cardBackgroundSubtle)
        XCTAssertNotNil(AppTheme.sidebarBackground)
        XCTAssertNotNil(AppTheme.border)
        XCTAssertNotNil(AppTheme.subtleBorder)
        XCTAssertNotNil(AppTheme.textPrimary)
        XCTAssertNotNil(AppTheme.textSecondary)
        XCTAssertNotNil(AppTheme.textTertiary)
        XCTAssertNotNil(AppTheme.accent)
        XCTAssertNotNil(AppTheme.sandstone)
        XCTAssertNotNil(AppTheme.success)
        XCTAssertNotNil(AppTheme.terracotta)
        XCTAssertNotNil(AppTheme.riverSlate)
    }

    func testTaskPriorityColors() {
        XCTAssertEqual(TaskPriority.low.color, AppTheme.riverSlate)
        XCTAssertEqual(TaskPriority.medium.color, AppTheme.sandstone)
        XCTAssertEqual(TaskPriority.high.color, AppTheme.terracotta)
    }

    func testScratchpadColors() {
        for color in ScratchpadColor.allCases {
            XCTAssertNotNil(color.color)
            XCTAssertFalse(color.iconName.isEmpty)
        }
    }
}
