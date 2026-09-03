import Foundation
import Observation

/// Coordinates the lifecycle, installation state, and memory allocation of modular Focenda features.
///
/// When a module is uninstalled:
/// - Its navigation entries are removed from the Sidebar and Menu Bar.
/// - Its active ViewModel is deallocated (`nil`), releasing memory (RAM).
/// - All user data in `SecureStore` remains untouched and safely preserved.
///
/// When a module is reinstalled:
/// - Its ViewModel is re-instantiated, loading previously saved user data.
@Observable
public final class AppModuleManager {
    public static let storageKey = "focenda_installed_modules"

    private let secureStore: SecureStore

    /// The set of currently active/installed modular features.
    public private(set) var installedModules: Set<AppModule>

    // MARK: - Dynamic ViewModels (released from RAM when module is uninstalled)
    public private(set) var taskVM: TaskListViewModel?
    public private(set) var scratchpadVM: ScratchpadViewModel?
    public private(set) var bookmarkVM: BookmarkViewModel?
    public private(set) var recurringReminderVM: RecurringReminderViewModel?

    public init(secureStore: SecureStore = .shared) {
        self.secureStore = secureStore

        if let rawSaved = secureStore.stringArray(forKey: Self.storageKey) {
            let parsed = rawSaved.compactMap { AppModule(rawValue: $0) }
            self.installedModules = Set(parsed)
        } else {
            // Fresh installations start with all modules installed by default.
            self.installedModules = Set(AppModule.allCases)
        }

        // Allocate ViewModels only for currently installed modules
        if installedModules.contains(.kanban) {
            self.taskVM = TaskListViewModel(secureStore: secureStore)
        }
        if installedModules.contains(.scratchpad) {
            self.scratchpadVM = ScratchpadViewModel(secureStore: secureStore)
        }
        if installedModules.contains(.bookmarks) {
            self.bookmarkVM = BookmarkViewModel(secureStore: secureStore)
        }
        if installedModules.contains(.reminders) {
            self.recurringReminderVM = RecurringReminderViewModel(secureStore: secureStore)
        }
    }

    /// Checks if a given feature module is currently installed.
    public func isInstalled(_ module: AppModule) -> Bool {
        installedModules.contains(module)
    }

    /// Convenience alias for checking module installation status.
    public func isModuleInstalled(_ module: AppModule) -> Bool {
        isInstalled(module)
    }

    /// Installs a feature module, re-allocating its ViewModel and restoring preserved data.
    public func installModule(_ module: AppModule) {
        guard !installedModules.contains(module) else { return }
        installedModules.insert(module)
        saveInstalledModules()

        switch module {
        case .kanban:
            if taskVM == nil {
                taskVM = TaskListViewModel(secureStore: secureStore)
            }
        case .scratchpad:
            if scratchpadVM == nil {
                scratchpadVM = ScratchpadViewModel(secureStore: secureStore)
            }
        case .bookmarks:
            if bookmarkVM == nil {
                bookmarkVM = BookmarkViewModel(secureStore: secureStore)
            }
        case .reminders:
            if recurringReminderVM == nil {
                recurringReminderVM = RecurringReminderViewModel(secureStore: secureStore)
            }
        case .calendar:
            // Calendar relies on taskVM and recurringReminderVM if available;
            // its view state is bound on navigation.
            break
        }
    }

    /// Uninstalls a feature module, releasing its ViewModel from RAM while preserving data on disk.
    public func uninstallModule(_ module: AppModule) {
        guard installedModules.contains(module) else { return }
        installedModules.remove(module)
        saveInstalledModules()

        switch module {
        case .kanban:
            taskVM = nil
        case .scratchpad:
            scratchpadVM = nil
        case .bookmarks:
            bookmarkVM = nil
        case .reminders:
            if let reminders = recurringReminderVM?.reminders {
                for reminder in reminders {
                    NotificationManager.shared.cancelRecurringReminder(reminder: reminder)
                }
            }
            recurringReminderVM = nil
        case .calendar:
            break
        }
    }

    /// Toggles installation state for the specified module.
    public func toggleModule(_ module: AppModule) {
        if isInstalled(module) {
            uninstallModule(module)
        } else {
            installModule(module)
        }
    }

    /// Checks if a navigation tab should appear based on module installation and feature flags.
    public func isTabAvailable(_ tab: AppTab) -> Bool {
        switch tab {
        case .dashboard, .timer, .settings, .support:
            return true
        case .profiles:
            return ProductivityProfilesFeature.isEnabled
        case .kanban:
            return isInstalled(.kanban)
        case .calendar:
            return isInstalled(.calendar)
        case .reminders:
            return isInstalled(.reminders)
        case .scratchpad:
            return isInstalled(.scratchpad)
        case .bookmarks:
            return isInstalled(.bookmarks)
        }
    }

    /// List of tabs currently available in the app.
    public var availableTabs: [AppTab] {
        AppTab.allCases.filter { isTabAvailable($0) }
    }

    /// Checks if a Menu Bar section is available based on installed modules.
    public func isMenuBarSectionAvailable(_ section: MenuBarSection) -> Bool {
        switch section {
        case .focus:
            return true
        case .quickNote:
            return isInstalled(.scratchpad)
        case .quickTask:
            return isInstalled(.kanban)
        case .reminders:
            return isInstalled(.reminders)
        case .quickLinks:
            return isInstalled(.bookmarks)
        }
    }

    /// List of sections currently available in the Menu Bar popover.
    public var availableMenuBarSections: [MenuBarSection] {
        MenuBarSection.allCases.filter { isMenuBarSectionAvailable($0) }
    }

    private func saveInstalledModules() {
        let rawValues = installedModules.map { $0.rawValue }
        secureStore.set(rawValues, forKey: Self.storageKey)
    }
}
