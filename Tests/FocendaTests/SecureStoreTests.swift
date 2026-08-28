import XCTest
import CryptoKit
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
}
