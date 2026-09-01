import Foundation
import Observation

/// Owns productivity profiles, encrypted persistence, and profile activation.
@Observable
public final class ProductivityProfileViewModel {
    public static let storageKey = "focenda_productivity_profiles"

    public var profiles: [ProductivityProfile] = []
    public var selectedProfileID: UUID?
    public private(set) var activeProfileID: UUID?
    public private(set) var isActivatingProfileID: UUID?
    public private(set) var lastActivationResult: ProductivityProfileActivationResult?
    public private(set) var lastErrorMessage: String?
    public private(set) var persistenceErrorMessage: String?
    public private(set) var isAccessibilityTrusted: Bool

    private let secureStore: SecureStore
    private let windowManager: ProductivityWindowManagerProtocol
    private let activationService: ProductivityProfileActivationServiceProtocol
    private let shortcutManager: GlobalShortcutManagerProtocol
    private var profilesPersistenceReady = false

    public init(
        secureStore: SecureStore = .shared,
        windowManager: ProductivityWindowManagerProtocol = AccessibilityWindowManager(),
        activationService: ProductivityProfileActivationServiceProtocol? = nil,
        shortcutManager: GlobalShortcutManagerProtocol = GlobalShortcutManager.shared
    ) {
        self.secureStore = secureStore
        self.windowManager = windowManager
        self.activationService = activationService ?? ProductivityProfileActivationService(windowManager: windowManager)
        self.shortcutManager = shortcutManager
        self.isAccessibilityTrusted = windowManager.isAccessibilityTrusted
        loadProfiles()
        selectedProfileID = profiles.first?.id
        syncGlobalShortcuts()
    }

    public var selectedProfile: ProductivityProfile? {
        guard let selectedProfileID else { return nil }
        return profiles.first(where: { $0.id == selectedProfileID })
    }

    public var activeProfile: ProductivityProfile? {
        guard let activeProfileID else { return nil }
        return profiles.first(where: { $0.id == activeProfileID })
    }

    public var availableScreens: [ProductivityScreenDescriptor] {
        windowManager.availableScreens()
    }

    /// Refreshes the cached Accessibility state after the user changes it in System Settings.
    @discardableResult
    public func refreshAccessibilityStatus() -> Bool {
        let trusted = windowManager.isAccessibilityTrusted
        if isAccessibilityTrusted != trusted {
            isAccessibilityTrusted = trusted
        }
        return trusted
    }

    @discardableResult
    public func addProfile(name: String = ProductivityProfile.defaultName) -> ProductivityProfile {
        let profile = ProductivityProfile(
            name: normalizedProfileName(name, fallbackIndex: profiles.count + 1)
        )
        profiles.append(profile)
        selectedProfileID = profile.id
        saveProfiles()
        syncGlobalShortcuts()
        return profile
    }

    public func updateProfile(_ profile: ProductivityProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        var updatedProfile = profile
        updatedProfile.name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let shortcutChanged = profiles[index].globalShortcut != updatedProfile.globalShortcut
        profiles[index] = updatedProfile
        saveProfiles()
        if shortcutChanged {
            syncGlobalShortcuts()
        }
    }

    public func deleteProfile(id: UUID) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles.remove(at: index)

        if activeProfileID == id {
            activeProfileID = nil
        }
        if selectedProfileID == id {
            selectedProfileID = profiles.indices.contains(index) ? profiles[index].id : profiles.last?.id
        }

        saveProfiles()
        syncGlobalShortcuts()
    }

    public func selectProfile(id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        selectedProfileID = id
    }

    public func addApplication(
        to profileID: UUID,
        bundleIdentifier: String,
        name: String,
        applicationPath: String,
        applicationBookmarkData: Data? = nil
    ) {
        guard let profileIndex = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        let trimmedBundleIdentifier = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBundleIdentifier.isEmpty else {
            lastErrorMessage = "This application does not have a valid bundle identifier."
            return
        }

        if profiles[profileIndex].applications.contains(where: { $0.bundleIdentifier == trimmedBundleIdentifier }) {
            lastErrorMessage = "That application is already in this profile."
            return
        }

        let application = ProductivityProfileApplication(
            bundleIdentifier: trimmedBundleIdentifier,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? trimmedBundleIdentifier : name,
            applicationPath: applicationPath,
            windowLayout: windowManager.defaultWindowLayout(),
            applicationBookmarkData: applicationBookmarkData
        )
        profiles[profileIndex].applications.append(application)
        lastErrorMessage = nil
        saveProfiles()
    }

    public func updateApplication(
        _ application: ProductivityProfileApplication,
        in profileID: UUID
    ) {
        guard let profileIndex = profiles.firstIndex(where: { $0.id == profileID }),
              let applicationIndex = profiles[profileIndex].applications.firstIndex(where: { $0.id == application.id }) else {
            return
        }

        profiles[profileIndex].applications[applicationIndex] = application
        saveProfiles()
    }

    public func removeApplication(applicationID: UUID, from profileID: UUID) {
        guard let profileIndex = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[profileIndex].applications.removeAll(where: { $0.id == applicationID })
        saveProfiles()
    }

    public func captureWindowLayout(applicationID: UUID, in profileID: UUID) {
        guard let profileIndex = profiles.firstIndex(where: { $0.id == profileID }),
              let applicationIndex = profiles[profileIndex].applications.firstIndex(where: { $0.id == applicationID }) else {
            return
        }

        let application = profiles[profileIndex].applications[applicationIndex]
        guard let capturedLayout = windowManager.captureWindowLayout(for: application) else {
            lastErrorMessage = isAccessibilityTrusted
                ? "Focenda could not find a visible window for \(application.name)."
                : "Allow Focenda to control your Mac in System Settings, then capture the window again."
            return
        }

        profiles[profileIndex].applications[applicationIndex].windowLayout = capturedLayout
        lastErrorMessage = nil
        saveProfiles()
    }

    public func setScreen(
        _ screen: ProductivityScreenDescriptor,
        for applicationID: UUID,
        in profileID: UUID
    ) {
        guard let profileIndex = profiles.firstIndex(where: { $0.id == profileID }),
              let applicationIndex = profiles[profileIndex].applications.firstIndex(where: { $0.id == applicationID }) else {
            return
        }

        profiles[profileIndex].applications[applicationIndex].windowLayout.screenID = screen.id
        profiles[profileIndex].applications[applicationIndex].windowLayout.screenName = screen.name
        saveProfiles()
    }

    public func activateProfile(id: UUID) {
        guard isActivatingProfileID == nil,
              let profile = profiles.first(where: { $0.id == id }) else {
            return
        }

        isActivatingProfileID = id
        lastActivationResult = nil
        lastErrorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            let result = await self.activationService.activate(profile)
            await MainActor.run {
                self.activeProfileID = id
                self.isActivatingProfileID = nil
                self.lastActivationResult = result
            }
        }
    }

    /// Async variant used by tests and by callers that need the activation result immediately.
    @discardableResult
    public func activateProfileAndWait(id: UUID) async -> ProductivityProfileActivationResult? {
        guard isActivatingProfileID == nil,
              let profile = profiles.first(where: { $0.id == id }) else {
            return nil
        }

        isActivatingProfileID = id
        lastActivationResult = nil
        lastErrorMessage = nil
        let result = await activationService.activate(profile)
        activeProfileID = id
        isActivatingProfileID = nil
        lastActivationResult = result
        return result
    }

    public func requestAccessibilityAccess() {
        windowManager.requestAccessibilityAccess()
        refreshAccessibilityStatus()
    }

    public func hasShortcutConflict(for profileID: UUID) -> Bool {
        guard let profile = profiles.first(where: { $0.id == profileID }),
              let shortcut = profile.globalShortcut,
              shortcut.isUsable else {
            return false
        }

        return hasBuiltInShortcutConflict(for: profileID) || profiles.contains { otherProfile in
            guard otherProfile.id != profileID,
                  let otherShortcut = otherProfile.globalShortcut,
                  otherShortcut.isUsable else {
                return false
            }
            return otherShortcut == shortcut
        }
    }

    public func hasBuiltInShortcutConflict(for profileID: UUID) -> Bool {
        guard let profile = profiles.first(where: { $0.id == profileID }),
              let shortcut = profile.globalShortcut,
              shortcut.isUsable else {
            return false
        }

        return ShortcutKeyCombination.defaultCombinations(for: shortcutManager.preset).contains {
            $0.keyCode == shortcut.keyCode && $0.modifiers == shortcut.modifiers
        }
    }

    public func saveProfiles() {
        guard profilesPersistenceReady else { return }
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        secureStore.setData(data, forKey: Self.storageKey)
    }

    public func loadProfiles() {
        guard secureStore.containsValue(forKey: Self.storageKey) else {
            profiles = []
            profilesPersistenceReady = true
            persistenceErrorMessage = nil
            return
        }

        guard let data = secureStore.data(forKey: Self.storageKey),
              let decodedProfiles = try? JSONDecoder().decode([ProductivityProfile].self, from: data) else {
            // Never turn an unreadable saved payload into a new empty payload.
            // The original value remains in SecureStore so a later migration
            // or a repaired keychain can still recover it.
            profiles = []
            profilesPersistenceReady = false
            let message = "Saved profiles could not be read. They were left untouched."
            lastErrorMessage = message
            persistenceErrorMessage = message
            return
        }

        profiles = decodedProfiles
        profilesPersistenceReady = true
        lastErrorMessage = nil
        persistenceErrorMessage = nil
    }

    private func syncGlobalShortcuts() {
        shortcutManager.setProductivityProfileShortcuts(profiles)
    }

    private func normalizedProfileName(_ name: String, fallbackIndex: Int) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Profile \(fallbackIndex)" : trimmedName
    }
}
