import XCTest
import CryptoKit
import Security
@testable import FocendaCore

final class SecureStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: SecureStore!

    override func setUp() {
        super.setUp()
        suiteName = "Focenda.SecureStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        store = SecureStore(
            defaults: defaults,
            encryptionKey: SymmetricKey(data: Data(repeating: 0x42, count: 32))
        )
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        store = nil
        defaults = nil
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

    func testSecureStoreInitializationWithDefaultKey() {
        let isolatedSuite = "Focenda.SecureStoreIsolated.\(UUID().uuidString)"
        let isolatedDefaults = UserDefaults(suiteName: isolatedSuite)!
        defer { isolatedDefaults.removePersistentDomain(forName: isolatedSuite) }

        let isolatedStore = SecureStore(defaults: isolatedDefaults, keychainService: "com.oomestre.focenda.test-store-\(UUID().uuidString)")
        isolatedStore.set("test-payload", forKey: "test-key")
        XCTAssertEqual(isolatedStore.string(forKey: "test-key"), "test-payload")
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

    func testValuesEncryptedWithThePreviousKeychainServiceRemainReadable() throws {
        let oldService = "Focenda.SecureStoreOldKeychain.\(UUID().uuidString)"
        let newService = "Focenda.SecureStoreNewKeychain.\(UUID().uuidString)"
        let oldSuite = "Focenda.SecureStoreOldKeychainDomain.\(UUID().uuidString)"
        let newSuite = "Focenda.SecureStoreNewKeychainDomain.\(UUID().uuidString)"
        let oldDefaults = try XCTUnwrap(UserDefaults(suiteName: oldSuite))
        let newDefaults = try XCTUnwrap(UserDefaults(suiteName: newSuite))
        let payload = Data("profile encrypted before the keychain service rename".utf8)

        defer {
            oldDefaults.removePersistentDomain(forName: oldSuite)
            newDefaults.removePersistentDomain(forName: newSuite)
            deleteKeychainItem(service: oldService)
            deleteKeychainItem(service: newService)
        }

        let oldStore = SecureStore(defaults: oldDefaults, keychainService: oldService)
        oldStore.setData(payload, forKey: "focenda_productivity_profiles")

        let updatedStore = SecureStore(
            defaults: newDefaults,
            keychainService: newService,
            legacyDefaults: [oldDefaults],
            legacyKeychainServices: [oldService]
        )

        XCTAssertEqual(updatedStore.data(forKey: "focenda_productivity_profiles"), payload)
        XCTAssertEqual(
            SecureStore(
                defaults: newDefaults,
                keychainService: newService,
                legacyDefaults: [oldDefaults],
                legacyKeychainServices: [oldService]
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
}
