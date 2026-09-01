import Foundation
import CryptoKit
import Security

/// Encrypted local persistence for Focenda-owned values.
///
/// The encrypted payload remains in UserDefaults so existing preference domains
/// and the app's lightweight persistence model keep working. The AES-GCM key is
/// stored in a private local file instead of the macOS Keychain so app updates do
/// not trigger Keychain authorization prompts.
public final class SecureStore {
    public static let shared = SecureStore()

    /// Keychain service used by releases that stored the local encryption key in
    /// the Keychain. It is retained only as a one-time migration source.
    public static let defaultKeychainService = "com.oomestre.focenda.secure-store"

    /// Keychain service used by the first encrypted Focenda release. It is
    /// retained only as a one-time migration source.
    ///
    /// Keep this identifier in the migration path. Changing a Keychain service
    /// creates a new encryption key and makes previously encrypted UserDefaults
    /// values look like they disappeared.
    public static let legacyKeychainService = "com.oomestre.focenda.secure-storage"

    /// Stable preference suite shared by staging and production bundles.
    ///
    /// The app's bundle identifier changes between beta and production builds,
    /// so `UserDefaults.standard` alone would split the user's data across two
    /// preference domains. This suite is intentionally independent of the app
    /// bundle and is used as the canonical local store in production.
    public static let sharedDefaultsSuiteName = "com.oomestre.focenda.shared-storage"

    private static let supportedBundleIdentifiers = [
        "com.oomestre.focenda",
        "com.oomestre.focenda.staging"
    ]

    private static let keychainAccount = "master-key-v1"
    private static let localKeyFileName = ".vault_key"
    private static let envelopeMarker = Data("FocendaSecureStoreV1".utf8)
    private static let previewKey = SymmetricKey(data: Data(repeating: 0x42, count: 32))

    private let defaults: UserDefaults
    private let sharedDefaults: UserDefaults?
    private let legacyDefaults: [UserDefaults]
    private let encryptionKey: SymmetricKey

    private static var isRunningForPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private static var isRunningInTests: Bool {
        NSClassFromString("XCTestCase") != nil ||
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
    }

    /// Creates a store backed by the supplied defaults domain.
    ///
    /// `encryptionKey` is injectable so tests can use an isolated key without
    /// touching the user's local key file or the legacy Keychain migration path.
    /// `keyFileURL` is injectable for isolated persistence tests.
    public init(
        defaults: UserDefaults = .standard,
        encryptionKey: SymmetricKey? = nil,
        keychainService: String = SecureStore.defaultKeychainService,
        sharedDefaults: UserDefaults? = nil,
        legacyDefaults: [UserDefaults]? = nil,
        legacyKeychainServices: [String]? = nil,
        keyFileURL: URL? = nil
    ) {
        self.defaults = defaults
        let useStableProductionStorage = sharedDefaults != nil || Self.shouldUseSharedStorage(
            defaults: defaults,
            encryptionKey: encryptionKey,
            keychainService: keychainService
        )
        self.sharedDefaults = sharedDefaults ?? (useStableProductionStorage ? UserDefaults(suiteName: Self.sharedDefaultsSuiteName) : nil)
        self.legacyDefaults = legacyDefaults ?? (useStableProductionStorage ? Self.makeLegacyDefaults(excluding: defaults) : [])

        let migrationServices = Self.keychainServices(
            service: keychainService,
            legacyServices: legacyKeychainServices
        )
        if let encryptionKey {
            self.encryptionKey = encryptionKey
        } else {
            self.encryptionKey = Self.loadOrCreateKey(
                keyFileURL: keyFileURL ?? Self.fallbackKeyURL,
                keychainServices: migrationServices
            )
        }
    }

    /// Stores an encodable value as authenticated ciphertext.
    public func set<Value: Encodable>(_ value: Value, forKey key: String) {
        guard let encoded = try? JSONEncoder().encode(value),
              let encrypted = encrypt(encoded, forKey: key) else {
            return
        }

        write(encrypted, forKey: key)
    }

    /// Stores raw data as authenticated ciphertext.
    public func setData(_ data: Data, forKey key: String) {
        guard let encrypted = encrypt(data, forKey: key) else { return }
        write(encrypted, forKey: key)
    }

    /// Reads and decrypts an encodable value, migrating a legacy cleartext value
    /// in place when one is found.
    public func value<Value: Codable>(_ type: Value.Type, forKey key: String) -> Value? {
        for object in storedObjects(forKey: key) {
            if let encryptedData = object as? Data,
               isEnvelope(encryptedData) {
                guard let plaintext = decrypt(encryptedData, forKey: key),
                      let decoded = try? JSONDecoder().decode(type, from: plaintext) else {
                    continue
                }

                // Re-encrypt every successfully read value with the current
                // key and copy it to the stable suite. This repairs values
                // written by older keychain services and older bundle IDs.
                setData(plaintext, forKey: key)
                return decoded
            }

            if let legacyValue = legacyValue(type, from: object) {
                set(legacyValue, forKey: key)
                return legacyValue
            }
        }

        return nil
    }

    /// Reads raw data and migrates a legacy cleartext data value in place.
    public func data(forKey key: String) -> Data? {
        for object in storedObjects(forKey: key) {
            guard let rawData = object as? Data else { continue }

            if isEnvelope(rawData) {
                guard let plaintext = decrypt(rawData, forKey: key) else { continue }
                // Existing encrypted values may use the previous Keychain
                // service or live in a previous bundle's preference domain.
                // Rewriting a valid value is safe and makes the migration
                // durable before the next app update.
                setData(plaintext, forKey: key)
                return plaintext
            }

            // Existing Focenda payloads were stored as JSON data directly.
            setData(rawData, forKey: key)
            return rawData
        }

        return nil
    }

    public func string(forKey key: String) -> String? {
        value(String.self, forKey: key)
    }

    public func bool(forKey key: String) -> Bool? {
        value(Bool.self, forKey: key)
    }

    public func integer(forKey key: String) -> Int? {
        value(Int.self, forKey: key)
    }

    public func date(forKey key: String) -> Date? {
        value(Date.self, forKey: key)
    }

    public func stringArray(forKey key: String) -> [String]? {
        value([String].self, forKey: key)
    }

    public func removeObject(forKey key: String) {
        for store in allDefaultsStores {
            store.removeObject(forKey: key)
        }
    }

    public func containsValue(forKey key: String) -> Bool {
        allDefaultsStores.contains { $0.object(forKey: key) != nil }
    }

    private var allDefaultsStores: [UserDefaults] {
        var stores: [UserDefaults] = []
        if let sharedDefaults {
            stores.append(sharedDefaults)
        }
        stores.append(defaults)
        stores.append(contentsOf: legacyDefaults)

        return stores.reduce(into: []) { result, store in
            guard !result.contains(where: { $0 === store }) else { return }
            result.append(store)
        }
    }

    private func storedObjects(forKey key: String) -> [Any] {
        allDefaultsStores.compactMap { $0.object(forKey: key) }
    }

    private func write(_ value: Any, forKey key: String) {
        if let sharedDefaults, sharedDefaults !== defaults {
            sharedDefaults.set(value, forKey: key)
        }
        defaults.set(value, forKey: key)
    }

    private func encrypt(_ plaintext: Data, forKey key: String) -> Data? {
        let associatedData = Data(key.utf8)
        guard let sealedBox = try? AES.GCM.seal(
            plaintext,
            using: encryptionKey,
            authenticating: associatedData
        ) else {
            return nil
        }

        guard let combined = sealedBox.combined else { return nil }
        return Self.envelopeMarker + combined
    }

    private func decrypt(_ envelope: Data, forKey key: String) -> Data? {
        guard isEnvelope(envelope) else { return nil }

        let combined = envelope.dropFirst(Self.envelopeMarker.count)
        guard let sealedBox = try? AES.GCM.SealedBox(combined: Data(combined)) else {
            return nil
        }

        return try? AES.GCM.open(
            sealedBox,
            using: encryptionKey,
            authenticating: Data(key.utf8)
        )
    }

    private func isEnvelope(_ data: Data) -> Bool {
        data.starts(with: Self.envelopeMarker)
    }

    private func legacyValue<Value: Codable>(_ type: Value.Type, from object: Any) -> Value? {
        if let value = object as? Value {
            return value
        }

        if let data = object as? Data,
           let decoded = try? JSONDecoder().decode(type, from: data) {
            return decoded
        }

        // UserDefaults bridges integer and boolean values through NSNumber.
        if type == Int.self,
           let number = object as? NSNumber {
            return number.intValue as? Value
        }

        if type == Bool.self,
           let number = object as? NSNumber {
            return number.boolValue as? Value
        }

        return nil
    }

    private static func loadOrCreateKey(keyFileURL: URL?, keychainServices: [String]) -> SymmetricKey {
        if isRunningForPreviews {
            return previewKey
        }

        if let localKeyData = readLocalKeyData(from: keyFileURL) {
            return SymmetricKey(data: localKeyData)
        }

        // Older releases stored this key in the Keychain. Read those entries
        // only when the local key has not been created yet, then persist the
        // result locally so future launches and app updates never query the
        // Keychain again.
        for service in keychainServices {
            if let legacyKeyData = readKeychainData(service: service),
                legacyKeyData.count == 32 {
                saveLocalKeyData(legacyKeyData, to: keyFileURL)
                return SymmetricKey(data: legacyKeyData)
            }
        }

        let generatedKey = SymmetricKey(size: .bits256)
        let keyData = generatedKey.withUnsafeBytes { Data($0) }
        saveLocalKeyData(keyData, to: keyFileURL)
        return generatedKey
    }

    private static func keychainServices(service: String, legacyServices: [String]?) -> [String] {
        let configuredLegacyServices = legacyServices ?? (
            service == defaultKeychainService ? [legacyKeychainService] : []
        )

        return ([service] + configuredLegacyServices).reduce(into: []) { result, candidate in
            guard !result.contains(candidate) else { return }
            result.append(candidate)
        }
    }

    private static func shouldUseSharedStorage(
        defaults: UserDefaults,
        encryptionKey: SymmetricKey?,
        keychainService: String
    ) -> Bool {
        defaults === UserDefaults.standard &&
            encryptionKey == nil &&
            keychainService == defaultKeychainService &&
            !isRunningInTests
    }

    private static func makeLegacyDefaults(excluding defaults: UserDefaults) -> [UserDefaults] {
        supportedBundleIdentifiers.compactMap { bundleIdentifier in
            guard let legacyDefaults = UserDefaults(suiteName: bundleIdentifier),
                  legacyDefaults !== defaults else {
                return nil
            }
            return legacyDefaults
        }
    }

    private static func readKeychainData(service: String) -> Data? {
        let query = keychainReadQuery(service: service)

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// Builds the one-time migration query without allowing macOS to show an
    /// authentication prompt for a legacy Keychain item.
    static func keychainReadQuery(service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]
    }

    private static var fallbackKeyURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let baseDirectory = isRunningInTests ? FileManager.default.temporaryDirectory : appSupport
        let folderName = isRunningInTests ? "FocendaTests-\(ProcessInfo.processInfo.processIdentifier)" : "com.oomestre.Focenda"
        let folder = baseDirectory.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o700
            ])
        }
        return folder.appendingPathComponent(localKeyFileName)
    }

    private static func readLocalKeyData(from url: URL?) -> Data? {
        guard let url,
              let data = try? Data(contentsOf: url),
              data.count == 32 else {
            return nil
        }
        return data
    }

    private static func saveLocalKeyData(_ data: Data, to url: URL?) {
        guard let url else { return }

        let folder = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path)
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}
