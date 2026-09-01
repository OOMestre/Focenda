import XCTest
import CryptoKit
import Security
@testable import FocendaCore

final class SecureStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var keyFileURL: URL!
    private var store: SecureStore!

    override func setUp() {
        super.setUp()
        suiteName = "Focenda.SecureStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        keyFileURL = makeTemporaryKeyFileURL()
        store = SecureStore(
            defaults: defaults,
            encryptionKey: SymmetricKey(data: Data(repeating: 0x42, count: 32)),
            keyFileURL: keyFileURL
        )
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        if let keyFileURL {
            try? FileManager.default.removeItem(at: keyFileURL.deletingLastPathComponent())
        }
        store = nil
        defaults = nil
        keyFileURL = nil
        suiteName = nil
        super.tearDown()
    }

    func testValuesAreEncryptedBeforeTheyReachUserDefaults() {
        let secret = Data("private task notes".utf8)

        store.setData(secret, forKey: "focenda_saved_tasks")

        let storedValue = defaults.data(forKey: "focenda_saved_tasks")
        XCTAssertNotNil(storedValue)
        XCTAssertNotEqual(storedValue, secret)
        XCTAssertFalse(storedValue?.elementsEqual(secret) == true)
        XCTAssertEqual(store.data(forKey: "focenda_saved_tasks"), secret)
    }

    func testLegacyDataIsMigratedInPlace() throws {
        let legacyPayload = try JSONEncoder().encode(["legacy note"])
        defaults.set(legacyPayload, forKey: "focenda_scratchpads")

        XCTAssertEqual(store.data(forKey: "focenda_scratchpads"), legacyPayload)
        XCTAssertNotEqual(defaults.data(forKey: "focenda_scratchpads"), legacyPayload)
    }

    func testLegacyScalarIsMigratedInPlace() {
        defaults.set("Forest Matcha", forKey: "focenda_selected_theme")

        XCTAssertEqual(store.string(forKey: "focenda_selected_theme"), "Forest Matcha")
        XCTAssertNil(defaults.string(forKey: "focenda_selected_theme"))
        XCTAssertNotNil(defaults.data(forKey: "focenda_selected_theme"))
    }

    func testTamperedEnvelopeIsRejected() {
        store.set("confidential", forKey: "focenda_note")
        var envelope = try! XCTUnwrap(defaults.data(forKey: "focenda_note"))
        envelope[envelope.index(before: envelope.endIndex)] ^= 0x01
        defaults.set(envelope, forKey: "focenda_note")

        XCTAssertNil(store.string(forKey: "focenda_note"))
    }

    func testTamperedDataEnvelopeIsRejectedWithoutBeingRewritten() {
        let secret = Data("private task notes".utf8)
        store.setData(secret, forKey: "focenda_saved_tasks")
        var envelope = try! XCTUnwrap(defaults.data(forKey: "focenda_saved_tasks"))
        envelope[envelope.index(before: envelope.endIndex)] ^= 0x01
        defaults.set(envelope, forKey: "focenda_saved_tasks")

        XCTAssertNil(store.data(forKey: "focenda_saved_tasks"))
        XCTAssertEqual(defaults.data(forKey: "focenda_saved_tasks"), envelope)
    }

    func testEnvelopeCannotBeMovedToAnotherKey() {
        store.set("private note", forKey: "focenda_note")
        let envelope = try! XCTUnwrap(defaults.data(forKey: "focenda_note"))
        defaults.set(envelope, forKey: "focenda_other_note")

        XCTAssertNil(store.string(forKey: "focenda_other_note"))
    }

    func testSecureStoreInitializationUsesLocalKeyInsteadOfKeychain() throws {
        let isolatedSuite = "Focenda.SecureStoreIsolated.\(UUID().uuidString)"
        let isolatedDefaults = UserDefaults(suiteName: isolatedSuite)!
        let isolatedKeyFileURL = makeTemporaryKeyFileURL()
        let service = "com.oomestre.focenda.test-store-\(UUID().uuidString)"
        defer {
            isolatedDefaults.removePersistentDomain(forName: isolatedSuite)
            try? FileManager.default.removeItem(at: isolatedKeyFileURL.deletingLastPathComponent())
            deleteKeychainItem(service: service)
        }

        let isolatedStore = SecureStore(
            defaults: isolatedDefaults,
            keychainService: service,
            keyFileURL: isolatedKeyFileURL
        )
        isolatedStore.set("test-payload", forKey: "test-key")
        XCTAssertEqual(isolatedStore.string(forKey: "test-key"), "test-payload")
        XCTAssertTrue(FileManager.default.fileExists(atPath: isolatedKeyFileURL.path))
        let keyFileAttributes = try FileManager.default.attributesOfItem(atPath: isolatedKeyFileURL.path)
        XCTAssertEqual((keyFileAttributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
        XCTAssertNil(readKeychainItem(service: service))
    }

    func testLocalKeyIsReusedAcrossStoreInstances() throws {
        let isolatedSuite = "Focenda.SecureStoreLocalKey.\(UUID().uuidString)"
        let isolatedDefaults = try XCTUnwrap(UserDefaults(suiteName: isolatedSuite))
        let isolatedKeyFileURL = makeTemporaryKeyFileURL()
        let payload = Data("data survives an app update".utf8)
        defer {
            isolatedDefaults.removePersistentDomain(forName: isolatedSuite)
            try? FileManager.default.removeItem(at: isolatedKeyFileURL.deletingLastPathComponent())
        }

        SecureStore(defaults: isolatedDefaults, keyFileURL: isolatedKeyFileURL)
            .setData(payload, forKey: "test-key")

        let relaunchedStore = SecureStore(defaults: isolatedDefaults, keyFileURL: isolatedKeyFileURL)

        XCTAssertEqual(relaunchedStore.data(forKey: "test-key"), payload)
    }

    func testValuesMigrateFromAnOlderBundlePreferenceDomainIntoTheStableDomain() throws {
        let legacySuite = "Focenda.SecureStoreLegacyDomain.\(UUID().uuidString)"
        let currentSuite = "Focenda.SecureStoreCurrentDomain.\(UUID().uuidString)"
        let stableSuite = "Focenda.SecureStoreStableDomain.\(UUID().uuidString)"
        let legacyDefaults = try XCTUnwrap(UserDefaults(suiteName: legacySuite))
        let currentDefaults = try XCTUnwrap(UserDefaults(suiteName: currentSuite))
        let stableDefaults = try XCTUnwrap(UserDefaults(suiteName: stableSuite))
        let key = SymmetricKey(data: Data(repeating: 0x24, count: 32))
        let payload = Data("profile saved before the bundle update".utf8)

        defer {
            legacyDefaults.removePersistentDomain(forName: legacySuite)
            currentDefaults.removePersistentDomain(forName: currentSuite)
            stableDefaults.removePersistentDomain(forName: stableSuite)
        }

        let legacyStore = SecureStore(defaults: legacyDefaults, encryptionKey: key)
        legacyStore.setData(payload, forKey: "focenda_productivity_profiles")

        let updatedStore = SecureStore(
            defaults: currentDefaults,
            encryptionKey: key,
            sharedDefaults: stableDefaults,
            legacyDefaults: [legacyDefaults]
        )

        XCTAssertEqual(updatedStore.data(forKey: "focenda_productivity_profiles"), payload)
        XCTAssertNotEqual(stableDefaults.data(forKey: "focenda_productivity_profiles"), payload)
        XCTAssertEqual(currentDefaults.data(forKey: "focenda_productivity_profiles"), stableDefaults.data(forKey: "focenda_productivity_profiles"))

        let relaunchedStore = SecureStore(
            defaults: currentDefaults,
            encryptionKey: key,
            sharedDefaults: stableDefaults,
            legacyDefaults: [legacyDefaults]
        )
        XCTAssertEqual(relaunchedStore.data(forKey: "focenda_productivity_profiles"), payload)
    }

    func testLegacyKeychainValueIsMigratedToLocalFile() throws {
        let oldService = "Focenda.SecureStoreOldKeychain.\(UUID().uuidString)"
        let newService = "Focenda.SecureStoreNewKeychain.\(UUID().uuidString)"
        let oldSuite = "Focenda.SecureStoreOldKeychainDomain.\(UUID().uuidString)"
        let newSuite = "Focenda.SecureStoreNewKeychainDomain.\(UUID().uuidString)"
        let keyFileURL = makeTemporaryKeyFileURL()
        let oldDefaults = try XCTUnwrap(UserDefaults(suiteName: oldSuite))
        let newDefaults = try XCTUnwrap(UserDefaults(suiteName: newSuite))
        let payload = Data("profile encrypted before the keychain service rename".utf8)
        let key = SymmetricKey(size: .bits256)

        defer {
            oldDefaults.removePersistentDomain(forName: oldSuite)
            newDefaults.removePersistentDomain(forName: newSuite)
            deleteKeychainItem(service: oldService)
            deleteKeychainItem(service: newService)
            try? FileManager.default.removeItem(at: keyFileURL.deletingLastPathComponent())
        }

        addKeychainItem(key.withUnsafeBytes { Data($0) }, service: oldService)

        let oldStore = SecureStore(defaults: oldDefaults, encryptionKey: key)
        oldStore.setData(payload, forKey: "focenda_productivity_profiles")

        let updatedStore = SecureStore(
            defaults: newDefaults,
            keychainService: newService,
            legacyDefaults: [oldDefaults],
            legacyKeychainServices: [oldService],
            keyFileURL: keyFileURL
        )

        XCTAssertEqual(updatedStore.data(forKey: "focenda_productivity_profiles"), payload)
        XCTAssertTrue(FileManager.default.fileExists(atPath: keyFileURL.path))
        deleteKeychainItem(service: oldService)
        XCTAssertEqual(
            SecureStore(
                defaults: newDefaults,
                keychainService: newService,
                legacyDefaults: [oldDefaults],
                legacyKeychainServices: [oldService],
                keyFileURL: keyFileURL
            ).data(forKey: "focenda_productivity_profiles"),
            payload
        )
    }

    private func deleteKeychainItem(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "master-key-v1"
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func addKeychainItem(_ data: Data, service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "master-key-v1",
            kSecValueData as String: data
        ]
        XCTAssertEqual(SecItemAdd(query as CFDictionary, nil), errSecSuccess)
    }

    private func readKeychainItem(service: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "master-key-v1",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else {
            return nil
        }
        return result as? Data
    }

    private func makeTemporaryKeyFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FocendaSecureStoreTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent(".vault_key")
    }
}
