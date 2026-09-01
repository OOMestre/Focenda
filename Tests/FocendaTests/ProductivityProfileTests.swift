import XCTest
import CryptoKit
import SwiftUI
@testable import FocendaCore

final class ProductivityProfileTests: XCTestCase {
    private var defaults: UserDefaults!
    private var secureStore: SecureStore!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "Focenda.ProductivityProfileTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        secureStore = SecureStore(
            defaults: defaults,
            encryptionKey: SymmetricKey(size: .bits256),
            keychainService: "Focenda.ProductivityProfileTests.\(UUID().uuidString)"
        )
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        secureStore = nil
        suiteName = nil
        super.tearDown()
    }

    func testProfileModelRoundTripsAndSanitizesWindowDimensions() throws {
        let shortcut = ProductivityProfileShortcut(
            keyCode: CarbonKeyCode.p,
            keyCharacter: "p",
            modifiers: [.option, .command]
        )
        let application = ProductivityProfileApplication(
            bundleIdentifier: "com.example.Editor",
            name: "Editor",
            applicationPath: "/Applications/Editor.app",
            windowLayout: ProductivityWindowLayout(
                x: 24,
                y: 36,
                width: 1200,
                height: 800,
                screenID: 42,
                screenName: "Studio Display",
                position: .topRight
            )
        )
        let profile = ProductivityProfile(
            name: "Deep Work",
            applications: [application],
            globalShortcut: shortcut
        )

        let encoded = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(ProductivityProfile.self, from: encoded)

        XCTAssertEqual(decoded, profile)
        XCTAssertEqual(decoded.applications.first?.windowLayout.position, .topRight)
        XCTAssertEqual(shortcut.displayString, "⌥ ⌘ P")
        XCTAssertEqual(ProductivityWindowLayout(width: 1, height: 2).sanitized.width, ProductivityWindowLayout.minimumWidth)
        XCTAssertEqual(ProductivityWindowLayout(width: 1, height: 2).sanitized.height, ProductivityWindowLayout.minimumHeight)
    }

    func testSemanticWindowPositionsMapToSimpleScreenAnchors() {
        let visibleFrame = CGRect(x: 100, y: 50, width: 1000, height: 800)
        let windowSize = CGSize(width: 400, height: 300)

        XCTAssertEqual(
            ProductivityWindowPosition.topLeft.origin(in: visibleFrame, windowSize: windowSize),
            CGPoint(x: 124, y: 526)
        )
        XCTAssertEqual(
            ProductivityWindowPosition.center.origin(in: visibleFrame, windowSize: windowSize),
            CGPoint(x: 400, y: 300)
        )
        XCTAssertEqual(
            ProductivityWindowPosition.bottomRight.origin(in: visibleFrame, windowSize: windowSize),
            CGPoint(x: 676, y: 74)
        )
        XCTAssertEqual(
            ProductivityWindowPosition.nearest(
                to: CGRect(x: 675, y: 525, width: windowSize.width, height: windowSize.height),
                in: visibleFrame
            ),
            .topRight
        )
    }

    func testLegacyWindowLayoutsDecodeWithoutSemanticPosition() throws {
        let legacyData = Data(
            #"{"x":24,"y":36,"width":1200,"height":800,"screenID":42,"screenName":"Studio Display"}"#.utf8
        )

        let decoded = try JSONDecoder().decode(ProductivityWindowLayout.self, from: legacyData)

        XCTAssertNil(decoded.position)
        XCTAssertEqual(decoded.x, 24)
        XCTAssertEqual(decoded.y, 36)
        XCTAssertEqual(decoded.screenName, "Studio Display")
    }

    func testActivationOpensOnlyClosedAppsAndArrangesEveryConfiguredWindow() async {
        let windowManager = FakeProductivityWindowManager()
        windowManager.runningBundleIdentifiers = ["com.example.Editor"]
        let activationService = ProductivityProfileActivationService(windowManager: windowManager)
        let profile = sampleProfile()

        let result = await activationService.activate(profile)

        XCTAssertEqual(result.launchedApplicationNames, ["Browser"])
        XCTAssertEqual(result.arrangedApplicationNames, ["Editor", "Browser"])
        XCTAssertTrue(result.failedApplicationNames.isEmpty)
        XCTAssertFalse(result.requiresAccessibilityPermission)
        XCTAssertEqual(windowManager.launchedApplications.map(\.name), ["Browser"])
        XCTAssertEqual(windowManager.arrangedApplications.map(\.name), ["Editor", "Browser"])
    }

    func testActivationReportsAccessibilityRequirement() async {
        let windowManager = FakeProductivityWindowManager()
        windowManager.isAccessibilityTrusted = false
        let activationService = ProductivityProfileActivationService(windowManager: windowManager)

        let result = await activationService.activate(sampleProfile())

        XCTAssertTrue(windowManager.didRequestAccessibilityAccess)
        XCTAssertTrue(result.requiresAccessibilityPermission)
        XCTAssertEqual(result.failedApplicationNames, ["Editor", "Browser"])
        XCTAssertFalse(result.succeeded)
        XCTAssertTrue(windowManager.launchedApplications.isEmpty)
        XCTAssertTrue(windowManager.arrangedApplications.isEmpty)
        XCTAssertEqual(
            result.summary,
            "Allow Focenda in Accessibility, then activate this profile again. Editor, Browser were not opened, so their window layout stays intact."
        )
    }

    func testActivationLaunchesEveryMissingAppBeforeArrangingAnyWindow() async {
        let windowManager = FakeProductivityWindowManager()
        let activationService = ProductivityProfileActivationService(windowManager: windowManager)

        _ = await activationService.activate(sampleProfile())

        XCTAssertEqual(
            windowManager.operations,
            ["launch:Editor", "launch:Browser", "arrange:Editor", "arrange:Browser"]
        )
    }

    func testAccessibilityStatusRefreshesAfterPermissionChanges() {
        let windowManager = FakeProductivityWindowManager()
        windowManager.isAccessibilityTrusted = false
        let viewModel = ProductivityProfileViewModel(
            secureStore: secureStore,
            windowManager: windowManager,
            shortcutManager: FakeGlobalShortcutManager()
        )

        XCTAssertFalse(viewModel.isAccessibilityTrusted)

        windowManager.isAccessibilityTrusted = true

        XCTAssertTrue(viewModel.refreshAccessibilityStatus())
        XCTAssertTrue(viewModel.isAccessibilityTrusted)
    }

    func testViewModelPersistsProfilesAndRegistersProfileShortcuts() async throws {
        let windowManager = FakeProductivityWindowManager()
        let shortcutManager = FakeGlobalShortcutManager()
        let viewModel = ProductivityProfileViewModel(
            secureStore: secureStore,
            windowManager: windowManager,
            shortcutManager: shortcutManager
        )

        let profile = viewModel.addProfile(name: "  Deep Work  ")
        XCTAssertEqual(profile.displayName, "Deep Work")
        XCTAssertEqual(viewModel.selectedProfileID, profile.id)

        viewModel.addApplication(
            to: profile.id,
            bundleIdentifier: "com.example.Editor",
            name: "Editor",
            applicationPath: "/Applications/Editor.app"
        )

        var updatedProfile = try XCTUnwrap(viewModel.selectedProfile)
        updatedProfile.globalShortcut = ProductivityProfileShortcut(
            keyCode: CarbonKeyCode.p,
            keyCharacter: "P",
            modifiers: [.option, .command]
        )
        viewModel.updateProfile(updatedProfile)

        let reloaded = ProductivityProfileViewModel(
            secureStore: secureStore,
            windowManager: windowManager,
            shortcutManager: FakeGlobalShortcutManager()
        )

        XCTAssertEqual(reloaded.profiles.count, 1)
        XCTAssertEqual(reloaded.profiles.first?.displayName, "Deep Work")
        XCTAssertEqual(reloaded.profiles.first?.applications.count, 1)
        XCTAssertEqual(reloaded.profiles.first?.globalShortcut?.displayString, "⌥ ⌘ P")
        XCTAssertEqual(shortcutManager.lastProfiles.count, 1)

        let reloadedProfileID = try XCTUnwrap(reloaded.profiles.first?.id)
        let result = await reloaded.activateProfileAndWait(id: reloadedProfileID)
        XCTAssertEqual(result?.arrangedApplicationNames, ["Editor"])
    }

    func testUnreadableSavedProfilesAreNeverOverwrittenByAUserAction() throws {
        let corruptedPayload = Data("profile payload from an older incompatible build".utf8)
        defaults.set(corruptedPayload, forKey: ProductivityProfileViewModel.storageKey)

        let viewModel = ProductivityProfileViewModel(
            secureStore: secureStore,
            windowManager: FakeProductivityWindowManager(),
            shortcutManager: FakeGlobalShortcutManager()
        )
        let encryptedPayloadBeforeAction = try XCTUnwrap(defaults.data(forKey: ProductivityProfileViewModel.storageKey))

        _ = viewModel.addProfile(name: "A profile that must not erase the old payload")

        XCTAssertEqual(viewModel.lastErrorMessage, "Saved profiles could not be read. They were left untouched.")
        XCTAssertEqual(defaults.data(forKey: ProductivityProfileViewModel.storageKey), encryptedPayloadBeforeAction)
        XCTAssertEqual(secureStore.data(forKey: ProductivityProfileViewModel.storageKey), corruptedPayload)
    }

    func testDuplicateShortcutIsDetectedAndRemovingProfileUpdatesSelection() throws {
        let shortcutManager = FakeGlobalShortcutManager()
        let viewModel = ProductivityProfileViewModel(
            secureStore: secureStore,
            windowManager: FakeProductivityWindowManager(),
            shortcutManager: shortcutManager
        )
        let shortcut = ProductivityProfileShortcut(
            keyCode: CarbonKeyCode.p,
            keyCharacter: "P",
            modifiers: [.option, .command]
        )

        let first = viewModel.addProfile(name: "First")
        let second = viewModel.addProfile(name: "Second")
        var firstWithShortcut = try XCTUnwrap(viewModel.profiles.first(where: { $0.id == first.id }))
        firstWithShortcut.globalShortcut = shortcut
        viewModel.updateProfile(firstWithShortcut)
        var secondWithShortcut = try XCTUnwrap(viewModel.profiles.first(where: { $0.id == second.id }))
        secondWithShortcut.globalShortcut = shortcut
        viewModel.updateProfile(secondWithShortcut)

        XCTAssertTrue(viewModel.hasShortcutConflict(for: first.id))
        XCTAssertTrue(viewModel.hasShortcutConflict(for: second.id))
        XCTAssertFalse(viewModel.hasBuiltInShortcutConflict(for: first.id))

        viewModel.deleteProfile(id: second.id)
        XCTAssertEqual(viewModel.selectedProfileID, first.id)
        XCTAssertFalse(viewModel.hasShortcutConflict(for: first.id))
        XCTAssertEqual(viewModel.profiles.count, 1)
    }

    func testGlobalShortcutManagerPublishesProfileActivation() {
        let manager = GlobalShortcutManager()
        let profileID = UUID()
        let expectation = expectation(forNotification: .productivityProfileShortcutTriggered, object: manager)

        manager.triggerProductivityProfile(profileID)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(manager.lastTriggeredProfileID, profileID)
    }

    func testProfilesTabAndViewAreAvailable() {
        XCTAssertTrue(AppTab.allCases.contains(.profiles))
        XCTAssertEqual(AppTab.profiles.rawValue, "Profiles")
        XCTAssertEqual(AppTab.profiles.iconName, "rectangle.3.group")

        let viewModel = ProductivityProfileViewModel(
            secureStore: secureStore,
            windowManager: FakeProductivityWindowManager(),
            shortcutManager: FakeGlobalShortcutManager()
        )
        let profilesView = ProductivityProfilesView(viewModel: viewModel)

        XCTAssertNotNil(profilesView.body)
    }

    private func sampleProfile() -> ProductivityProfile {
        ProductivityProfile(
            name: "Focus",
            applications: [
                ProductivityProfileApplication(
                    bundleIdentifier: "com.example.Editor",
                    name: "Editor",
                    applicationPath: "/Applications/Editor.app"
                ),
                ProductivityProfileApplication(
                    bundleIdentifier: "com.example.Browser",
                    name: "Browser",
                    applicationPath: "/Applications/Browser.app"
                )
            ]
        )
    }
}

private final class FakeProductivityWindowManager: ProductivityWindowManagerProtocol {
    var isAccessibilityTrusted = true
    var runningBundleIdentifiers: Set<String> = []
    var didRequestAccessibilityAccess = false
    var launchedApplications: [ProductivityProfileApplication] = []
    var arrangedApplications: [ProductivityProfileApplication] = []
    var operations: [String] = []

    func requestAccessibilityAccess() {
        didRequestAccessibilityAccess = true
    }

    func availableScreens() -> [ProductivityScreenDescriptor] {
        [ProductivityScreenDescriptor(id: 42, name: "Studio Display")]
    }

    func defaultWindowLayout() -> ProductivityWindowLayout {
        ProductivityWindowLayout(screenID: 42, screenName: "Studio Display", position: .center)
    }

    func isApplicationRunning(_ application: ProductivityProfileApplication) -> Bool {
        runningBundleIdentifiers.contains(application.bundleIdentifier)
    }

    func launch(application: ProductivityProfileApplication) async -> Bool {
        launchedApplications.append(application)
        operations.append("launch:\(application.name)")
        runningBundleIdentifiers.insert(application.bundleIdentifier)
        return true
    }

    func arrange(
        application: ProductivityProfileApplication,
        layout: ProductivityWindowLayout
    ) async -> ProductivityWindowArrangementResult {
        guard isAccessibilityTrusted else { return .accessibilityDenied }
        guard isApplicationRunning(application) else { return .applicationNotRunning }
        arrangedApplications.append(application)
        operations.append("arrange:\(application.name)")
        return .arranged
    }

    func captureWindowLayout(for application: ProductivityProfileApplication) -> ProductivityWindowLayout? {
        ProductivityWindowLayout(
            x: 100,
            y: 120,
            width: 1100,
            height: 720,
            screenID: 42,
            screenName: "Studio Display",
            position: .bottomLeft
        )
    }
}

private final class FakeGlobalShortcutManager: GlobalShortcutManagerProtocol {
    var isEnabled = true
    var preset: GlobalShortcutPreset = .standard
    var registeredCombinations: [ShortcutKeyCombination] = []
    var lastTriggeredAction: FocusShortcutAction?
    var lastTriggeredProfileID: UUID?
    var lastProfiles: [ProductivityProfile] = []

    func setup(timerVM: FocusTimerViewModel, appState: AppState?) {}
    func setProductivityProfileShortcuts(_ profiles: [ProductivityProfile]) {
        lastProfiles = profiles
    }
    func registerAll() {}
    func unregisterAll() {}
    func triggerAction(_ action: FocusShortcutAction) {
        lastTriggeredAction = action
    }
    func triggerProductivityProfile(_ profileID: UUID) {
        lastTriggeredProfileID = profileID
    }
}
