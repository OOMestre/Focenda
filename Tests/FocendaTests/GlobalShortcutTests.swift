import XCTest
@testable import FocendaCore

final class GlobalShortcutTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "globalShortcutsEnabled")
        UserDefaults.standard.removeObject(forKey: "shortcutPreset")
        UserDefaults.standard.removeObject(forKey: "showShortcutFeedback")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "globalShortcutsEnabled")
        UserDefaults.standard.removeObject(forKey: "shortcutPreset")
        UserDefaults.standard.removeObject(forKey: "showShortcutFeedback")
        super.tearDown()
    }

    // MARK: - FocusShortcutAction Tests

    func testFocusShortcutActionProperties() {
        let allActions = FocusShortcutAction.allCases
        XCTAssertEqual(allActions.count, 6)

        for action in allActions {
            XCTAssertFalse(action.displayName.isEmpty)
            XCTAssertFalse(action.description.isEmpty)
            XCTAssertFalse(action.iconName.isEmpty)
            XCTAssertGreaterThan(action.numericId, 1000)
            XCTAssertEqual(FocusShortcutAction.from(numericId: action.numericId), action)
        }

        XCTAssertNil(FocusShortcutAction.from(numericId: 9999))
    }

    // MARK: - ShortcutModifier Tests

    func testShortcutModifierSymbolsAndMasks() {
        XCTAssertEqual(ShortcutModifier.command.symbol, "⌘")
        XCTAssertEqual(ShortcutModifier.option.symbol, "⌥")
        XCTAssertEqual(ShortcutModifier.control.symbol, "⌃")
        XCTAssertEqual(ShortcutModifier.shift.symbol, "⇧")

        XCTAssertEqual(ShortcutModifier.command.carbonModifier, 0x0100)
        XCTAssertEqual(ShortcutModifier.shift.carbonModifier, 0x0200)
        XCTAssertEqual(ShortcutModifier.option.carbonModifier, 0x0800)
        XCTAssertEqual(ShortcutModifier.control.carbonModifier, 0x1000)

        #if canImport(AppKit)
        XCTAssertEqual(ShortcutModifier.command.nsEventFlag, .command)
        XCTAssertEqual(ShortcutModifier.option.nsEventFlag, .option)
        XCTAssertEqual(ShortcutModifier.control.nsEventFlag, .control)
        XCTAssertEqual(ShortcutModifier.shift.nsEventFlag, .shift)
        #endif
    }

    // MARK: - GlobalShortcutPreset Tests

    func testGlobalShortcutPresets() {
        let standard = GlobalShortcutPreset.standard
        XCTAssertEqual(standard.displayName, "Standard (⌥ ⌘)")
        XCTAssertEqual(standard.modifiers, [.option, .command])

        let powerUser = GlobalShortcutPreset.powerUser
        XCTAssertEqual(powerUser.displayName, "Power User (⌃ ⌥ ⌘)")
        XCTAssertEqual(powerUser.modifiers, [.control, .option, .command])

        let ctrlOpt = GlobalShortcutPreset.controlOption
        XCTAssertEqual(ctrlOpt.displayName, "Compact (⌃ ⌥)")
        XCTAssertEqual(ctrlOpt.modifiers, [.control, .option])
    }

    // MARK: - ShortcutKeyCombination Tests

    func testShortcutKeyCombinationBadgesAndDisplay() {
        let combo = ShortcutKeyCombination(
            action: .toggleFocus,
            keyCode: CarbonKeyCode.f,
            keyCharacter: "f",
            modifiers: [.option, .command]
        )

        XCTAssertEqual(combo.keyCharacter, "F")
        XCTAssertEqual(combo.keyBadges, ["⌥", "⌘", "F"])
        XCTAssertEqual(combo.displayString, "⌥ ⌘ F")
        XCTAssertEqual(combo.carbonModifiers, 0x0800 | 0x0100)

        #if canImport(AppKit)
        let flags = combo.eventModifierFlags
        XCTAssertTrue(flags.contains(.option))
        XCTAssertTrue(flags.contains(.command))
        XCTAssertFalse(flags.contains(.control))
        #endif
    }

    func testDefaultCombinationsForAllPresets() {
        for preset in GlobalShortcutPreset.allCases {
            let combos = ShortcutKeyCombination.defaultCombinations(for: preset)
            XCTAssertEqual(combos.count, 6)

            let actions = combos.map { $0.action }
            XCTAssertTrue(actions.contains(.toggleFocus))
            XCTAssertTrue(actions.contains(.startWork))
            XCTAssertTrue(actions.contains(.startShortBreak))
            XCTAssertTrue(actions.contains(.startLongBreak))
            XCTAssertTrue(actions.contains(.resetTimer))
            XCTAssertTrue(actions.contains(.skipSession))

            for combo in combos {
                XCTAssertEqual(combo.modifiers, preset.modifiers)
                XCTAssertFalse(combo.keyCharacter.isEmpty)
            }
        }
    }

    // MARK: - GlobalShortcutManager Tests

    func testGlobalShortcutManagerSetupAndTriggerToggleFocus() {
        let timerVM = FocusTimerViewModel()
        let appState = AppState()
        let manager = GlobalShortcutManager()

        manager.setup(timerVM: timerVM, appState: appState)
        XCTAssertEqual(manager.isEnabled, true)
        XCTAssertEqual(manager.preset, .standard)
        XCTAssertEqual(manager.registeredCombinations.count, 6)

        // Idle -> Toggle should start timer
        XCTAssertEqual(timerVM.status, .idle)
        manager.triggerAction(.toggleFocus)
        XCTAssertEqual(manager.lastTriggeredAction, .toggleFocus)
        XCTAssertEqual(timerVM.status, .running)

        // Running -> Toggle should pause timer
        manager.triggerAction(.toggleFocus)
        XCTAssertEqual(timerVM.status, .paused)

        timerVM.reset()
    }

    func testGlobalShortcutManagerTriggerModes() {
        let timerVM = FocusTimerViewModel()
        let manager = GlobalShortcutManager()
        manager.setup(timerVM: timerVM)

        // Start Short Break
        manager.triggerAction(.startShortBreak)
        XCTAssertEqual(timerVM.currentMode, .shortBreak)
        XCTAssertEqual(timerVM.status, .running)

        // Start Long Break
        manager.triggerAction(.startLongBreak)
        XCTAssertEqual(timerVM.currentMode, .longBreak)
        XCTAssertEqual(timerVM.status, .running)

        // Start Work
        manager.triggerAction(.startWork)
        XCTAssertEqual(timerVM.currentMode, .work)
        XCTAssertEqual(timerVM.status, .running)

        // Reset
        manager.triggerAction(.resetTimer)
        XCTAssertEqual(timerVM.status, .idle)
        XCTAssertEqual(timerVM.timeRemainingSeconds, timerVM.workDurationMinutes * 60)

        // Skip
        manager.triggerAction(.skipSession)
        XCTAssertEqual(timerVM.currentMode, .shortBreak)

        timerVM.reset()
    }

    func testGlobalShortcutManagerCallbackAndNotification() {
        let timerVM = FocusTimerViewModel()
        let manager = GlobalShortcutManager()
        manager.setup(timerVM: timerVM)

        var callbackAction: FocusShortcutAction?
        manager.onActionTriggered = { action in
            callbackAction = action
        }

        let expectation = expectation(forNotification: .focusShortcutTriggered, object: manager)

        manager.triggerAction(.startWork)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(callbackAction, .startWork)
        XCTAssertEqual(manager.lastTriggeredAction, .startWork)

        timerVM.reset()
    }

    func testGlobalShortcutManagerEnableDisableAndPreset() {
        let manager = GlobalShortcutManager()
        manager.setEnabled(false)
        XCTAssertFalse(manager.isEnabled)

        manager.setPreset(.powerUser)
        XCTAssertEqual(manager.preset, .powerUser)
        XCTAssertEqual(manager.registeredCombinations.first?.modifiers, [.control, .option, .command])

        manager.setEnabled(true)
        XCTAssertTrue(manager.isEnabled)
    }

    // MARK: - AppState Persistence Tests

    func testAppStateShortcutPreferencesPersistence() {
        let state1 = AppState()
        state1.globalShortcutsEnabled = false
        state1.shortcutPreset = .powerUser
        state1.showShortcutFeedback = false
        state1.savePreferences()

        let state2 = AppState()
        XCTAssertEqual(state2.globalShortcutsEnabled, false)
        XCTAssertEqual(state2.shortcutPreset, .powerUser)
        XCTAssertEqual(state2.showShortcutFeedback, false)
    }

    // MARK: - FocusTimerViewModel Helper Tests

    func testFocusTimerViewModelToggleStartPauseAndStartMode() {
        let vm = FocusTimerViewModel()
        XCTAssertEqual(vm.status, .idle)

        vm.toggleStartPause()
        XCTAssertEqual(vm.status, .running)

        vm.toggleStartPause()
        XCTAssertEqual(vm.status, .paused)

        vm.startMode(.longBreak)
        XCTAssertEqual(vm.currentMode, .longBreak)
        XCTAssertEqual(vm.status, .running)

        vm.reset()
    }
}
