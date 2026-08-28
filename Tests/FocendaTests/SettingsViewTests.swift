import XCTest
import SwiftUI
@testable import FocendaCore

final class SettingsViewTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AppTheme.storageKey)
        UserDefaults.standard.removeObject(forKey: "dailyFocusGoalMinutes")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: AppUpdatePreferences.automaticChecksEnabledKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AppTheme.storageKey)
        UserDefaults.standard.removeObject(forKey: "dailyFocusGoalMinutes")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: AppUpdatePreferences.automaticChecksEnabledKey)
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

    func testAutomaticUpdateChecksDefaultToEnabledAndPersist() {
        let appState = AppState()

        XCTAssertTrue(appState.automaticUpdateChecksEnabled)

        appState.automaticUpdateChecksEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: AppUpdatePreferences.automaticChecksEnabledKey))

        let reloadedAppState = AppState()
        XCTAssertFalse(reloadedAppState.automaticUpdateChecksEnabled)
    }

    func testSettingsViewWithShortcutsDisabled() {
        let appState = AppState()
        appState.globalShortcutsEnabled = false
        let timerVM = FocusTimerViewModel()
        let settingsView = SettingsView(appState: appState, timerVM: timerVM)

        XCTAssertNotNil(settingsView)
        XCTAssertNotNil(settingsView.body)
    }

    func testAppStateReminderSoundPreferencesSaveAndLoad() {
        let appState = AppState()
        appState.reminderSoundEnabled = true
        appState.reminderSoundType = .glass
        appState.reminderSoundRepeatCount = 4
        appState.reminderCustomSoundPath = "/path/to/custom.mp3"
        appState.reminderCustomSoundName = "custom.mp3"
        appState.savePreferences()

        XCTAssertTrue(UserDefaults.standard.bool(forKey: "reminderSoundEnabled"))
        XCTAssertEqual(UserDefaults.standard.string(forKey: "reminderSoundType"), ReminderSoundType.glass.rawValue)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "reminderSoundRepeatCount"), 4)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "reminderCustomSoundPath"), "/path/to/custom.mp3")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "reminderCustomSoundName"), "custom.mp3")

        let reloadedAppState = AppState()
        XCTAssertTrue(reloadedAppState.reminderSoundEnabled)
        XCTAssertEqual(reloadedAppState.reminderSoundType, .glass)
        XCTAssertEqual(reloadedAppState.reminderSoundRepeatCount, 4)
        XCTAssertEqual(reloadedAppState.reminderCustomSoundPath, "/path/to/custom.mp3")
        XCTAssertEqual(reloadedAppState.reminderCustomSoundName, "custom.mp3")

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "reminderSoundEnabled")
        UserDefaults.standard.removeObject(forKey: "reminderSoundType")
        UserDefaults.standard.removeObject(forKey: "reminderSoundRepeatCount")
        UserDefaults.standard.removeObject(forKey: "reminderCustomSoundPath")
        UserDefaults.standard.removeObject(forKey: "reminderCustomSoundName")
    }

    func testAppStateReminderSoundRepeatClamping() {
        let appState = AppState()
        appState.reminderSoundRepeatCount = 10
        XCTAssertEqual(appState.reminderSoundRepeatCount, ReminderSoundType.maxRepeatCount)

        appState.reminderSoundRepeatCount = 0
        XCTAssertEqual(appState.reminderSoundRepeatCount, ReminderSoundType.minRepeatCount)
    }

    func testSettingsViewWithCustomSoundSelected() {
        let appState = AppState()
        appState.reminderSoundType = .custom
        appState.reminderCustomSoundName = "custom_bell.wav"
        appState.reminderCustomSoundPath = "/Users/test/custom_bell.wav"
        let timerVM = FocusTimerViewModel()
        let settingsView = SettingsView(appState: appState, timerVM: timerVM)

        XCTAssertNotNil(settingsView)
        XCTAssertNotNil(settingsView.body)
    }

    func testSettingsViewWithReminderSoundDisabled() {
        let appState = AppState()
        appState.reminderSoundEnabled = false
        let timerVM = FocusTimerViewModel()
        let settingsView = SettingsView(appState: appState, timerVM: timerVM)

        XCTAssertNotNil(settingsView)
        XCTAssertNotNil(settingsView.body)
    }
}
