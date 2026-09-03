import XCTest
@testable import FocendaCore

final class AppModuleManagerTests: XCTestCase {

    var testSuiteName: String!
    var testDefaults: UserDefaults!
    var testStore: SecureStore!

    override func setUp() {
        super.setUp()
        testSuiteName = "test_focenda_modules_\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)!
        testStore = SecureStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: testSuiteName)
        testDefaults = nil
        testStore = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialInstalledModules() {
        let manager = AppModuleManager(secureStore: testStore)

        // All 5 modules must be installed by default
        XCTAssertTrue(manager.isModuleInstalled(.kanban))
        XCTAssertTrue(manager.isModuleInstalled(.calendar))
        XCTAssertTrue(manager.isModuleInstalled(.reminders))
        XCTAssertTrue(manager.isModuleInstalled(.scratchpad))
        XCTAssertTrue(manager.isModuleInstalled(.bookmarks))
        XCTAssertEqual(manager.installedModules.count, 5)

        // All ViewModels must be actively allocated
        XCTAssertNotNil(manager.taskVM)
        XCTAssertNotNil(manager.scratchpadVM)
        XCTAssertNotNil(manager.bookmarkVM)
        XCTAssertNotNil(manager.recurringReminderVM)

        // All tabs must be available
        XCTAssertTrue(manager.isTabAvailable(.kanban))
        XCTAssertTrue(manager.isTabAvailable(.calendar))
        XCTAssertTrue(manager.isTabAvailable(.reminders))
        XCTAssertTrue(manager.isTabAvailable(.scratchpad))
        XCTAssertTrue(manager.isTabAvailable(.bookmarks))

        // Fixed core tabs must always be available
        XCTAssertTrue(manager.isTabAvailable(.dashboard))
        XCTAssertTrue(manager.isTabAvailable(.timer))
        XCTAssertTrue(manager.isTabAvailable(.settings))
        XCTAssertTrue(manager.isTabAvailable(.support))

        // All menu bar sections must be available
        XCTAssertTrue(manager.isMenuBarSectionAvailable(.focus))
        XCTAssertTrue(manager.isMenuBarSectionAvailable(.quickNote))
        XCTAssertTrue(manager.isMenuBarSectionAvailable(.quickTask))
        XCTAssertTrue(manager.isMenuBarSectionAvailable(.reminders))
        XCTAssertTrue(manager.isMenuBarSectionAvailable(.quickLinks))
    }

    // MARK: - Memory Deallocation (RAM Release) Tests

    func testUninstallModuleReleasesRAM() {
        let manager = AppModuleManager(secureStore: testStore)

        // Uninstall Kanban -> taskVM must be released to nil
        XCTAssertNotNil(manager.taskVM)
        manager.uninstallModule(.kanban)
        XCTAssertFalse(manager.isModuleInstalled(.kanban))
        XCTAssertNil(manager.taskVM, "taskVM must be released to nil to free RAM upon uninstalling Kanban")

        // Uninstall Scratchpad -> scratchpadVM must be released to nil
        XCTAssertNotNil(manager.scratchpadVM)
        manager.uninstallModule(.scratchpad)
        XCTAssertFalse(manager.isModuleInstalled(.scratchpad))
        XCTAssertNil(manager.scratchpadVM, "scratchpadVM must be released to nil to free RAM upon uninstalling Scratchpad")

        // Uninstall Bookmarks -> bookmarkVM must be released to nil
        XCTAssertNotNil(manager.bookmarkVM)
        manager.uninstallModule(.bookmarks)
        XCTAssertFalse(manager.isModuleInstalled(.bookmarks))
        XCTAssertNil(manager.bookmarkVM, "bookmarkVM must be released to nil to free RAM upon uninstalling Bookmarks")

        // Uninstall Reminders -> recurringReminderVM must be released to nil
        XCTAssertNotNil(manager.recurringReminderVM)
        manager.uninstallModule(.reminders)
        XCTAssertFalse(manager.isModuleInstalled(.reminders))
        XCTAssertNil(manager.recurringReminderVM, "recurringReminderVM must be released to nil to free RAM upon uninstalling Reminders")

        // Uninstall Calendar
        manager.uninstallModule(.calendar)
        XCTAssertFalse(manager.isModuleInstalled(.calendar))
        XCTAssertTrue(manager.installedModules.isEmpty)
    }

    // MARK: - UI Visibility & Dynamic Filtering Tests

    func testUninstallRemovesFromSidebarAndMenuBar() {
        let manager = AppModuleManager(secureStore: testStore)

        // Initially all are available
        XCTAssertTrue(manager.availableTabs.contains(.kanban))
        XCTAssertTrue(manager.availableMenuBarSections.contains(.quickTask))

        // Uninstall Kanban
        manager.uninstallModule(.kanban)
        XCTAssertFalse(manager.availableTabs.contains(.kanban), "Sidebar must not show Kanban when uninstalled")
        XCTAssertFalse(manager.availableMenuBarSections.contains(.quickTask), "Menu Bar must not show Quick Task section when Kanban is uninstalled")

        // Uninstall Scratchpad
        manager.uninstallModule(.scratchpad)
        XCTAssertFalse(manager.availableTabs.contains(.scratchpad), "Sidebar must not show Scratchpad when uninstalled")
        XCTAssertFalse(manager.availableMenuBarSections.contains(.quickNote), "Menu Bar must not show Quick Note section when Scratchpad is uninstalled")

        // Uninstall Reminders
        manager.uninstallModule(.reminders)
        XCTAssertFalse(manager.availableTabs.contains(.reminders), "Sidebar must not show Reminders when uninstalled")
        XCTAssertFalse(manager.availableMenuBarSections.contains(.reminders), "Menu Bar must not show Reminders section when uninstalled")

        // Uninstall Bookmarks
        manager.uninstallModule(.bookmarks)
        XCTAssertFalse(manager.availableTabs.contains(.bookmarks), "Sidebar must not show Bookmarks when uninstalled")
        XCTAssertFalse(manager.availableMenuBarSections.contains(.quickLinks), "Menu Bar must not show Quick Links section when Bookmarks is uninstalled")

        // Focus section and core tabs must ALWAYS remain
        XCTAssertTrue(manager.availableMenuBarSections.contains(.focus))
        XCTAssertTrue(manager.availableTabs.contains(.dashboard))
        XCTAssertTrue(manager.availableTabs.contains(.timer))
        XCTAssertTrue(manager.availableTabs.contains(.settings))
    }

    // MARK: - Data Preservation Tests

    func testTaskDataPreservedAcrossUninstallAndReinstall() {
        let manager = AppModuleManager(secureStore: testStore)

        // Create tasks
        guard let taskVM = manager.taskVM else {
            XCTFail("taskVM must be present")
            return
        }
        taskVM.addTask(title: "Persistent Project Plan", priority: .high)
        taskVM.addTask(title: "Review PRs", priority: .medium)
        XCTAssertEqual(taskVM.tasks.count, 2)

        // Uninstall Kanban -> ViewModel is released from RAM
        manager.uninstallModule(.kanban)
        XCTAssertNil(manager.taskVM)

        // Reinstall Kanban -> New ViewModel is instantiated
        manager.installModule(.kanban)
        guard let reloadedVM = manager.taskVM else {
            XCTFail("taskVM must be re-instantiated")
            return
        }

        // Verify tasks were completely preserved from disk/store
        XCTAssertEqual(reloadedVM.tasks.count, 2)
        XCTAssertTrue(reloadedVM.tasks.contains(where: { $0.title == "Persistent Project Plan" }))
        XCTAssertTrue(reloadedVM.tasks.contains(where: { $0.title == "Review PRs" }))
    }

    func testScratchpadDataPreservedAcrossUninstallAndReinstall() {
        let manager = AppModuleManager(secureStore: testStore)

        // Create note and folder
        guard let scratchpadVM = manager.scratchpadVM else {
            XCTFail("scratchpadVM must be present")
            return
        }
        _ = scratchpadVM.createFolder("Sprint 42")
        _ = scratchpadVM.createNote(title: "Architecture Decisions", content: "Use modular components", folder: "Sprint 42")
        XCTAssertTrue(scratchpadVM.folders.contains("Sprint 42"))

        // Uninstall Scratchpad
        manager.uninstallModule(.scratchpad)
        XCTAssertNil(manager.scratchpadVM)

        // Reinstall Scratchpad
        manager.installModule(.scratchpad)
        guard let reloadedVM = manager.scratchpadVM else {
            XCTFail("scratchpadVM must be re-instantiated")
            return
        }

        // Verify folder and note were preserved
        XCTAssertTrue(reloadedVM.folders.contains("Sprint 42"))
        XCTAssertTrue(reloadedVM.notes.contains(where: { $0.title == "Architecture Decisions" }))
    }

    func testBookmarkDataPreservedAcrossUninstallAndReinstall() {
        let manager = AppModuleManager(secureStore: testStore)

        // Add bookmark
        guard let bookmarkVM = manager.bookmarkVM else {
            XCTFail("bookmarkVM must be present")
            return
        }
        bookmarkVM.addBookmark(title: "Swift Evolution", url: "https://github.com/swiftlang/swift-evolution", iconName: "swift")
        XCTAssertTrue(bookmarkVM.bookmarks.contains(where: { $0.title == "Swift Evolution" }))

        // Uninstall Bookmarks
        manager.uninstallModule(.bookmarks)
        XCTAssertNil(manager.bookmarkVM)

        // Reinstall Bookmarks
        manager.installModule(.bookmarks)
        guard let reloadedVM = manager.bookmarkVM else {
            XCTFail("bookmarkVM must be re-instantiated")
            return
        }

        // Verify bookmark is preserved
        XCTAssertTrue(reloadedVM.bookmarks.contains(where: { $0.title == "Swift Evolution" }))
    }

    func testRecurringReminderDataPreservedAcrossUninstallAndReinstall() {
        let manager = AppModuleManager(secureStore: testStore)

        // Add recurring reminder
        guard let reminderVM = manager.recurringReminderVM else {
            XCTFail("recurringReminderVM must be present")
            return
        }
        reminderVM.addReminder(title: "Team Standup", time: Date(), repeatFrequency: .weekdays)
        XCTAssertEqual(reminderVM.reminders.count, 1)

        // Uninstall Reminders
        manager.uninstallModule(.reminders)
        XCTAssertNil(manager.recurringReminderVM)

        // Reinstall Reminders
        manager.installModule(.reminders)
        guard let reloadedVM = manager.recurringReminderVM else {
            XCTFail("recurringReminderVM must be re-instantiated")
            return
        }

        // Verify reminder is preserved
        XCTAssertEqual(reloadedVM.reminders.count, 1)
        XCTAssertEqual(reloadedVM.reminders.first?.title, "Team Standup")
    }

    // MARK: - AppState Tab Redirection Tests

    func testAppStateTabRedirectionOnUninstall() {
        let appState = AppState(secureStore: testStore)

        // Set selected tab to .kanban
        appState.selectedTab = .kanban
        XCTAssertEqual(appState.selectedTab, .kanban)

        // Uninstall Kanban -> appState must redirect away from uninstalled tab
        appState.uninstallModule(.kanban)
        XCTAssertEqual(appState.selectedTab, .dashboard, "Selecting an uninstalled tab must redirect to .dashboard")

        // Try setting selectedTab directly to uninstalled .kanban
        appState.selectedTab = .kanban
        XCTAssertEqual(appState.selectedTab, .dashboard, "Setting selectedTab to an uninstalled module must be prevented and redirect to .dashboard")
    }

    // MARK: - State Persistence Across Launches Tests

    func testModuleConfigurationPersistence() {
        // Launch 1: user uninstalls Scratchpad and Bookmarks
        let manager1 = AppModuleManager(secureStore: testStore)
        manager1.uninstallModule(.scratchpad)
        manager1.uninstallModule(.bookmarks)

        XCTAssertFalse(manager1.isModuleInstalled(.scratchpad))
        XCTAssertFalse(manager1.isModuleInstalled(.bookmarks))
        XCTAssertTrue(manager1.isModuleInstalled(.kanban))

        // Launch 2: app reboots, new manager reads from the same store
        let manager2 = AppModuleManager(secureStore: testStore)
        XCTAssertFalse(manager2.isModuleInstalled(.scratchpad), "Uninstalled modules must remain uninstalled across app relaunches")
        XCTAssertFalse(manager2.isModuleInstalled(.bookmarks), "Uninstalled modules must remain uninstalled across app relaunches")
        XCTAssertTrue(manager2.isModuleInstalled(.kanban), "Installed modules must remain installed")
        XCTAssertTrue(manager2.isModuleInstalled(.calendar))
        XCTAssertTrue(manager2.isModuleInstalled(.reminders))

        XCTAssertNil(manager2.scratchpadVM)
        XCTAssertNil(manager2.bookmarkVM)
        XCTAssertNotNil(manager2.taskVM)
    }

    // MARK: - Essential Modules Contract Test

    func testEssentialModulesContract() {
        let essentials = EssentialModule.allCases
        XCTAssertEqual(essentials.count, 3)
        XCTAssertTrue(essentials.contains(.timer))
        XCTAssertTrue(essentials.contains(.dashboard))
        XCTAssertTrue(essentials.contains(.settings))

        for essential in essentials {
            XCTAssertFalse(essential.displayName.isEmpty)
            XCTAssertFalse(essential.description.isEmpty)
            XCTAssertFalse(essential.iconName.isEmpty)
        }
    }
}
