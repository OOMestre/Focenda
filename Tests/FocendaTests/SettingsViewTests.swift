import XCTest
import CryptoKit
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
        XCTAssertEqual(SecureStore.shared.string(forKey: AppTheme.storageKey), AppThemeOption.obsidianMinimal.rawValue)
        XCTAssertEqual(AppTheme.current, .obsidianMinimal)

        appState.selectedTheme = .warmSandstone
        XCTAssertEqual(SecureStore.shared.string(forKey: AppTheme.storageKey), AppThemeOption.warmSandstone.rawValue)
        XCTAssertEqual(AppTheme.current, .warmSandstone)

        appState.selectedTheme = .nordicFrost
        XCTAssertEqual(SecureStore.shared.string(forKey: AppTheme.storageKey), AppThemeOption.nordicFrost.rawValue)
        XCTAssertEqual(AppTheme.current, .nordicFrost)

        appState.selectedTheme = .forestMatcha
        XCTAssertEqual(SecureStore.shared.string(forKey: AppTheme.storageKey), AppThemeOption.forestMatcha.rawValue)
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

    func testSettingsViewRendersReplayForTheLatestUpdateGuide() throws {
        let suiteName = "Focenda.SettingsUpdateGuideTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SecureStore(
            defaults: defaults,
            encryptionKey: SymmetricKey(data: Data(repeating: 0x29, count: 32))
        )
        let guide = AppUpdateGuide(
            releaseTag: "v1.2.0",
            version: "1.2.0",
            title: "A calmer way to focus",
            sections: [
                AppUpdateGuideSection(title: "Enhancements", items: ["A better focus flow."])
            ]
        )
        store.set(guide, forKey: AppUpdatePreferences.lastUpdateGuideKey)

        let appState = AppState(secureStore: store)
        let updateManager = AppUpdateManager(
            currentReleaseIdentifier: "v1.2.0",
            secureStore: store
        )
        let settingsView = SettingsView(
            appState: appState,
            timerVM: FocusTimerViewModel(),
            updateManager: updateManager
        )

        XCTAssertEqual(updateManager.lastUpdateGuide, guide)
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

        XCTAssertEqual(SecureStore.shared.integer(forKey: "dailyFocusGoalMinutes") ?? 0, 180)
        XCTAssertFalse(SecureStore.shared.bool(forKey: "soundEnabled") ?? true)
        XCTAssertEqual(SecureStore.shared.string(forKey: AppTheme.storageKey), AppThemeOption.obsidianMinimal.rawValue)
        XCTAssertFalse(SecureStore.shared.bool(forKey: "globalShortcutsEnabled") ?? true)
        XCTAssertEqual(SecureStore.shared.string(forKey: "shortcutPreset"), GlobalShortcutPreset.powerUser.rawValue)
        XCTAssertFalse(SecureStore.shared.bool(forKey: "showShortcutFeedback") ?? true)
    }

    func testUnreadablePreferenceIsNeverOverwrittenByAUserAction() {
        let suiteName = "Focenda.SettingsUnreadablePreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let secureStore = SecureStore(
            defaults: defaults,
            encryptionKey: SymmetricKey(data: Data(repeating: 0x17, count: 32))
        )
        let corruptedPayload = Data("preference from an incompatible build".utf8)
        defaults.set(corruptedPayload, forKey: "soundEnabled")

        let appState = AppState(secureStore: secureStore)
        appState.dailyFocusGoalMinutes = 180
        appState.savePreferences()

        XCTAssertEqual(defaults.data(forKey: "soundEnabled"), corruptedPayload)
        XCTAssertEqual(
            appState.persistenceErrorMessage,
            "Some saved preferences could not be read. They were left untouched."
        )
    }

    func testAutomaticUpdateChecksDefaultToEnabledAndPersist() {
        let appState = AppState()

        XCTAssertTrue(appState.automaticUpdateChecksEnabled)

        appState.automaticUpdateChecksEnabled = false
        XCTAssertFalse(SecureStore.shared.bool(forKey: AppUpdatePreferences.automaticChecksEnabledKey) ?? true)

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

        XCTAssertTrue(SecureStore.shared.bool(forKey: "reminderSoundEnabled") ?? false)
        XCTAssertEqual(SecureStore.shared.string(forKey: "reminderSoundType"), ReminderSoundType.glass.rawValue)
        XCTAssertEqual(SecureStore.shared.integer(forKey: "reminderSoundRepeatCount") ?? 0, 4)
        XCTAssertEqual(SecureStore.shared.string(forKey: "reminderCustomSoundPath"), "/path/to/custom.mp3")
        XCTAssertEqual(SecureStore.shared.string(forKey: "reminderCustomSoundName"), "custom.mp3")

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

    func testAppUpdateManagerProvidesDefaultGuideOnFreshInstall() {
        let suiteName = "Focenda.FreshInstallUpdateGuideTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let secureStore = SecureStore(defaults: defaults)
        let manager = AppUpdateManager(
            currentReleaseIdentifier: "0.1.0",
            userDefaults: defaults,
            secureStore: secureStore
        )

        XCTAssertNotNil(manager.lastUpdateGuide)
        XCTAssertEqual(manager.lastUpdateGuide?.version, "0.1.0")
        XCTAssertFalse(manager.lastUpdateGuide?.sections.isEmpty ?? true)
    }
}

