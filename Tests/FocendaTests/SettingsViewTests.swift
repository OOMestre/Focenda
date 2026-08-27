import XCTest
import SwiftUI
@testable import FocendaCore

final class SettingsViewTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AppTheme.storageKey)
        UserDefaults.standard.removeObject(forKey: "dailyFocusGoalMinutes")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AppTheme.storageKey)
        UserDefaults.standard.removeObject(forKey: "dailyFocusGoalMinutes")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        super.tearDown()
    }

    func testAppStateThemeSelection() {
        let appState = AppState()
        XCTAssertEqual(appState.selectedTheme, .zenCalm)

        appState.selectedTheme = .obsidianMinimal
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppTheme.storageKey), AppThemeOption.obsidianMinimal.rawValue)
        XCTAssertEqual(AppTheme.current, .obsidianMinimal)

        appState.selectedTheme = .warmSandstone
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppTheme.storageKey), AppThemeOption.warmSandstone.rawValue)
        XCTAssertEqual(AppTheme.current, .warmSandstone)

        appState.selectedTheme = .nordicFrost
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppTheme.storageKey), AppThemeOption.nordicFrost.rawValue)
        XCTAssertEqual(AppTheme.current, .nordicFrost)

        appState.selectedTheme = .forestMatcha
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppTheme.storageKey), AppThemeOption.forestMatcha.rawValue)
        XCTAssertEqual(AppTheme.current, .forestMatcha)
    }

    func testAppStateLoadsStoredTheme() {
        UserDefaults.standard.set(AppThemeOption.forestMatcha.rawValue, forKey: AppTheme.storageKey)
        let appState = AppState()
        XCTAssertEqual(appState.selectedTheme, .forestMatcha)
        XCTAssertEqual(AppTheme.current, .forestMatcha)
    }

    func testSettingsViewInitialization() {
        let appState = AppState()
        let timerVM = FocusTimerViewModel()
        let settingsView = SettingsView(appState: appState, timerVM: timerVM)

        XCTAssertNotNil(settingsView)
        XCTAssertNotNil(settingsView.body)
    }

    func testAppStateSavePreferences() {
        let appState = AppState()
        appState.dailyFocusGoalMinutes = 180
        appState.soundEnabled = false
        appState.selectedTheme = .obsidianMinimal
        appState.globalShortcutsEnabled = false
        appState.shortcutPreset = .powerUser
        appState.showShortcutFeedback = false
        appState.savePreferences()

        XCTAssertEqual(UserDefaults.standard.integer(forKey: "dailyFocusGoalMinutes"), 180)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "soundEnabled"))
        XCTAssertEqual(UserDefaults.standard.string(forKey: AppTheme.storageKey), AppThemeOption.obsidianMinimal.rawValue)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "globalShortcutsEnabled"))
        XCTAssertEqual(UserDefaults.standard.string(forKey: "shortcutPreset"), GlobalShortcutPreset.powerUser.rawValue)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "showShortcutFeedback"))
    }

    func testSettingsViewWithShortcutsDisabled() {
        let appState = AppState()
        appState.globalShortcutsEnabled = false
        let timerVM = FocusTimerViewModel()
        let settingsView = SettingsView(appState: appState, timerVM: timerVM)

        XCTAssertNotNil(settingsView)
        XCTAssertNotNil(settingsView.body)
    }
}
