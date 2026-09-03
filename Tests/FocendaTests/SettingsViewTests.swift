import XCTest
import CryptoKit
import SwiftUI
@testable import FocendaCore

final class SettingsViewTests: XCTestCase {

    override func setUp() {
        super.setUp()
        cleanupDefaults()
    }

    override func tearDown() {
        cleanupDefaults()
        super.tearDown()
    }

    private func cleanupDefaults() {
        let keys = [
            AppTheme.storageKey,
            "dailyFocusGoalMinutes",
            "soundEnabled",
            "reminderSoundEnabled",
            "reminderSoundType",
            "reminderSoundRepeatCount",
            "reminderCustomSoundPath",
            "reminderCustomSoundName",
            "reminderCustomSoundBookmarkData",
            AppState.reminderSoundRepeatUntilDoneKey,
            "globalShortcutsEnabled",
            "shortcutPreset",
            "showShortcutFeedback",
            AppUpdatePreferences.automaticChecksEnabledKey,
            AppState.onboardingCompletionKey
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
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
        SecureStore.shared.set(AppThemeOption.forestMatcha.rawValue, forKey: AppTheme.storageKey)
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

    func testSettingsViewKeepsStoredUpdateGuideWhileFeatureIsHidden() throws {
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
            timerVM: FocusTimerViewModel()
        )

        XCTAssertEqual(updateManager.lastUpdateGuide, guide)
        XCTAssertFalse(AppUpdateGuide.isEnabled)
        XCTAssertNotNil(settingsView.body)
    }

    func testAppStateSavePreferences() {
        let suiteName = "Focenda.SettingsSavePreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let secureStore = SecureStore(defaults: defaults)

        let appState = AppState(secureStore: secureStore)
        appState.dailyFocusGoalMinutes = 180
        appState.soundEnabled = false
        appState.selectedTheme = .obsidianMinimal
        appState.globalShortcutsEnabled = false
        appState.shortcutPreset = .powerUser
        appState.showShortcutFeedback = false
        appState.savePreferences()

        XCTAssertEqual(secureStore.integer(forKey: "dailyFocusGoalMinutes") ?? 0, 180)
        XCTAssertFalse(secureStore.bool(forKey: "soundEnabled") ?? true)
        XCTAssertEqual(secureStore.string(forKey: AppTheme.storageKey), AppThemeOption.obsidianMinimal.rawValue)
        XCTAssertFalse(secureStore.bool(forKey: "globalShortcutsEnabled") ?? true)
        XCTAssertEqual(secureStore.string(forKey: "shortcutPreset"), GlobalShortcutPreset.powerUser.rawValue)
        XCTAssertFalse(secureStore.bool(forKey: "showShortcutFeedback") ?? true)
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
        let suiteName = "Focenda.SettingsUpdateCheckTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let secureStore = SecureStore(defaults: defaults)

        let appState = AppState(secureStore: secureStore)
        XCTAssertTrue(appState.automaticUpdateChecksEnabled)

        appState.automaticUpdateChecksEnabled = false
        XCTAssertFalse(secureStore.bool(forKey: AppUpdatePreferences.automaticChecksEnabledKey) ?? true)

        let reloadedAppState = AppState(secureStore: secureStore)
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
        let suiteName = "Focenda.SettingsReminderSoundTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let secureStore = SecureStore(defaults: defaults)

        let appState = AppState(secureStore: secureStore)
        appState.reminderSoundEnabled = true
        appState.reminderSoundType = .glass
        appState.reminderSoundRepeatCount = 4
        appState.reminderSoundRepeatUntilDone = true
        appState.reminderCustomSoundPath = "/path/to/custom.mp3"
        appState.reminderCustomSoundName = "custom.mp3"
        appState.savePreferences()

        XCTAssertTrue(secureStore.bool(forKey: "reminderSoundEnabled") ?? false)
        XCTAssertEqual(secureStore.string(forKey: "reminderSoundType"), ReminderSoundType.glass.rawValue)
        XCTAssertEqual(secureStore.integer(forKey: "reminderSoundRepeatCount") ?? 0, 4)
        XCTAssertTrue(secureStore.bool(forKey: AppState.reminderSoundRepeatUntilDoneKey) ?? false)
        XCTAssertEqual(secureStore.string(forKey: "reminderCustomSoundPath"), "/path/to/custom.mp3")
        XCTAssertEqual(secureStore.string(forKey: "reminderCustomSoundName"), "custom.mp3")

        let reloadedAppState = AppState(secureStore: secureStore)
        XCTAssertTrue(reloadedAppState.reminderSoundEnabled)
        XCTAssertEqual(reloadedAppState.reminderSoundType, .glass)
        XCTAssertEqual(reloadedAppState.reminderSoundRepeatCount, 4)
        XCTAssertTrue(reloadedAppState.reminderSoundRepeatUntilDone)
        XCTAssertEqual(reloadedAppState.reminderCustomSoundPath, "/path/to/custom.mp3")
        XCTAssertEqual(reloadedAppState.reminderCustomSoundName, "custom.mp3")
    }

    func testAppStateReminderSoundRepeatClamping() {
        let appState = AppState()
        XCTAssertFalse(appState.reminderSoundRepeatUntilDone)
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
            currentReleaseIdentifier: "1.0.0",
            userDefaults: defaults,
            secureStore: secureStore
        )

        XCTAssertNotNil(manager.lastUpdateGuide)
        XCTAssertEqual(manager.lastUpdateGuide?.version, "1.0.0")
        XCTAssertFalse(manager.lastUpdateGuide?.sections.isEmpty ?? true)
    }
}
