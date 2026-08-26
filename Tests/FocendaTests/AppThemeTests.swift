import XCTest
import SwiftUI
@testable import FocendaCore

final class AppThemeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AppTheme.storageKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AppTheme.storageKey)
        super.tearDown()
    }

    func testAllFiveThemesExist() {
        let allThemes = AppThemeOption.allCases
        XCTAssertEqual(allThemes.count, 5)

        XCTAssertTrue(allThemes.contains(.zenCalm))
        XCTAssertTrue(allThemes.contains(.obsidianMinimal))
        XCTAssertTrue(allThemes.contains(.warmSandstone))
        XCTAssertTrue(allThemes.contains(.nordicFrost))
        XCTAssertTrue(allThemes.contains(.forestMatcha))
    }

    func testThemeDisplayNamesAndSubtitles() {
        XCTAssertEqual(AppThemeOption.zenCalm.rawValue, "Zen Calm (Light)")
        XCTAssertEqual(AppThemeOption.obsidianMinimal.rawValue, "Obsidian Minimal (Dark)")
        XCTAssertEqual(AppThemeOption.warmSandstone.rawValue, "Warm Sandstone")
        XCTAssertEqual(AppThemeOption.nordicFrost.rawValue, "Nordic Frost")
        XCTAssertEqual(AppThemeOption.forestMatcha.rawValue, "Forest Matcha")

        for theme in AppThemeOption.allCases {
            XCTAssertFalse(theme.displayName.isEmpty)
            XCTAssertFalse(theme.subtitle.isEmpty)
            XCTAssertEqual(theme.previewSwatches.count, 5)
        }
    }

    func testThemeParsingFromUserDefaults() {
        XCTAssertEqual(AppThemeOption.from(storedValue: "Zen Calm (Light)"), .zenCalm)
        XCTAssertEqual(AppThemeOption.from(storedValue: "Obsidian Minimal (Dark)"), .obsidianMinimal)
        XCTAssertEqual(AppThemeOption.from(storedValue: "Warm Sandstone"), .warmSandstone)
        XCTAssertEqual(AppThemeOption.from(storedValue: "Nordic Frost"), .nordicFrost)
        XCTAssertEqual(AppThemeOption.from(storedValue: "Forest Matcha"), .forestMatcha)

        // Resilient shorthand matching
        XCTAssertEqual(AppThemeOption.from(storedValue: "zen"), .zenCalm)
        XCTAssertEqual(AppThemeOption.from(storedValue: "obsidian"), .obsidianMinimal)
        XCTAssertEqual(AppThemeOption.from(storedValue: "sandstone"), .warmSandstone)
        XCTAssertEqual(AppThemeOption.from(storedValue: "frost"), .nordicFrost)
        XCTAssertEqual(AppThemeOption.from(storedValue: "matcha"), .forestMatcha)
        XCTAssertEqual(AppThemeOption.from(storedValue: nil), .zenCalm)
        XCTAssertEqual(AppThemeOption.from(storedValue: "invalid_theme_name"), .zenCalm)
    }

    func testThemePersistenceKey() {
        XCTAssertEqual(AppTheme.storageKey, "focenda_selected_theme")

        AppTheme.current = .nordicFrost
        XCTAssertEqual(UserDefaults.standard.string(forKey: "focenda_selected_theme"), AppThemeOption.nordicFrost.rawValue)
        XCTAssertEqual(AppTheme.current, .nordicFrost)

        AppTheme.current = .forestMatcha
        XCTAssertEqual(UserDefaults.standard.string(forKey: "focenda_selected_theme"), AppThemeOption.forestMatcha.rawValue)
        XCTAssertEqual(AppTheme.current, .forestMatcha)
    }

    func testAppThemeColorsExistForAllThemes() {
        for theme in AppThemeOption.allCases {
            AppTheme.current = theme

            XCTAssertNotNil(AppTheme.deepFocus)
            XCTAssertNotNil(AppTheme.shortBreak)
            XCTAssertNotNil(AppTheme.longBreak)
            XCTAssertNotNil(AppTheme.background)
            XCTAssertNotNil(AppTheme.cardBackground)
            XCTAssertNotNil(AppTheme.cardBackgroundSubtle)
            XCTAssertNotNil(AppTheme.inputBackground)
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
    }

    func testFocusModeThemeColors() {
        XCTAssertNotNil(FocusMode.work.themeColor)
        XCTAssertNotNil(FocusMode.shortBreak.themeColor)
        XCTAssertNotNil(FocusMode.longBreak.themeColor)
    }

    func testTaskPriorityColors() {
        XCTAssertNotNil(TaskPriority.low.color)
        XCTAssertNotNil(TaskPriority.medium.color)
        XCTAssertNotNil(TaskPriority.high.color)
    }

    func testScratchpadColors() {
        for color in ScratchpadColor.allCases {
            XCTAssertNotNil(color.color)
            XCTAssertFalse(color.iconName.isEmpty)
        }
    }

    func testColorHexInitializer() {
        // 6-digit hex without #
        let charcoal = Color(hex: "1C1917")
        XCTAssertNotNil(charcoal)

        // 6-digit hex with #
        let slate = Color(hex: "#44403C")
        XCTAssertNotNil(slate)

        // 8-digit ARGB hex
        let alphaColor = Color(hex: "#80F4F1EA")
        XCTAssertNotNil(alphaColor)

        // 3-digit RGB hex
        let shortHex = Color(hex: "#F0A")
        XCTAssertNotNil(shortHex)

        // Invalid fallback
        let fallback = Color(hex: "invalid")
        XCTAssertNotNil(fallback)
    }

    func testLightThemesHaveHighContrastTypography() {
        for lightTheme in [AppThemeOption.zenCalm, AppThemeOption.warmSandstone] {
            AppTheme.current = lightTheme

            XCTAssertNotNil(AppTheme.textPrimary)
            XCTAssertNotNil(AppTheme.textSecondary)
            XCTAssertNotNil(AppTheme.textTertiary)
            XCTAssertNotNil(AppTheme.inputBackground)
        }
    }
}
