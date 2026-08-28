import Foundation
import CryptoKit
import Security

/// Encrypted local persistence for Focenda-owned values.
///
/// The encrypted payload remains in UserDefaults so existing preference domains
/// and the app's lightweight persistence model keep working. The AES-GCM key is
/// stored separately in the macOS Keychain and never in UserDefaults.
public final class SecureStore {
    public static let shared = SecureStore()
    public static let defaultKeychainService = "com.oomestre.focenda.secure-store"

    private static let keychainAccount = "master-key-v1"
    private static let envelopeMarker = Data("FocendaSecureStoreV1".utf8)
    private static let previewKey = SymmetricKey(data: Data(repeating: 0x42, count: 32))

    private let defaults: UserDefaults
    private let encryptionKey: SymmetricKey

    private static var isRunningForPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    /// Creates a store backed by the supplied defaults domain.
    ///
    /// `encryptionKey` is injectable so tests can use an isolated key without
    /// touching the user's Keychain. Production callers should use the default.
    public init(
        defaults: UserDefaults = .standard,
        encryptionKey: SymmetricKey? = nil,
        keychainService: String = SecureStore.defaultKeychainService
    ) {
        self.defaults = defaults
        self.encryptionKey = encryptionKey ?? Self.loadOrCreateKey(service: keychainService)
    }

    /// Stores an encodable value as authenticated ciphertext.
    public func set<Value: Encodable>(_ value: Value, forKey key: String) {
        guard let encoded = try? JSONEncoder().encode(value),
              let encrypted = encrypt(encoded, forKey: key) else {
            return
        }

        defaults.set(encrypted, forKey: key)
    }

    /// Stores raw data as authenticated ciphertext.
    public func setData(_ data: Data, forKey key: String) {
        guard let encrypted = encrypt(data, forKey: key) else { return }
        defaults.set(encrypted, forKey: key)
    }

    /// Reads and decrypts an encodable value, migrating a legacy cleartext value
    /// in place when one is found.
    public func value<Value: Codable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let object = defaults.object(forKey: key) else { return nil }

        if let encryptedData = object as? Data,
           isEnvelope(encryptedData) {
            guard let plaintext = decrypt(encryptedData, forKey: key) else { return nil }
            return try? JSONDecoder().decode(type, from: plaintext)
        }

        guard let legacyValue = legacyValue(type, from: object) else { return nil }
        set(legacyValue, forKey: key)
        return legacyValue
    }

    /// Reads raw data and migrates a legacy cleartext data value in place.
    public func data(forKey key: String) -> Data? {
        guard let rawData = defaults.data(forKey: key) else { return nil }

        if isEnvelope(rawData) {
            return decrypt(rawData, forKey: key)
        }

        // Existing Focenda payloads were stored as JSON data directly.
        setData(rawData, forKey: key)
        return rawData
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
        defaults.removeObject(forKey: key)
    }

    public func containsValue(forKey key: String) -> Bool {
        defaults.object(forKey: key) != nil
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
        guard let sealedBox = try? AES.GCM.SealedBox(combined: Data(combined)),
              let plaintext = try? AES.GCM.open(
                sealedBox,
                using: encryptionKey,
                authenticating: Data(key.utf8)
              ) else {
            return nil
        }

        return plaintext
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

    private static func loadOrCreateKey(service: String) -> SymmetricKey {
        if isRunningForPreviews {
            return previewKey
        }

        if let keyData = readKeychainData(service: service), keyData.count == 32 {
            return SymmetricKey(data: keyData)
        }

        if let fallbackData = readFallbackKeyData(), fallbackData.count == 32 {
            _ = saveKeychainData(fallbackData, service: service)
            return SymmetricKey(data: fallbackData)
        }

        let generatedKey = SymmetricKey(size: .bits256)
        let keyData = generatedKey.withUnsafeBytes { Data($0) }
        let saveStatus = saveKeychainData(keyData, service: service)
        if saveStatus != errSecSuccess {
            saveFallbackKeyData(keyData)
        }
        return generatedKey
    }

    private static func createOpenAccess(service: String) -> SecAccess? {
        var access: SecAccess?
        let status = SecAccessCreate(service as CFString, (nil as CFArray?), &access)
        guard status == errSecSuccess else { return nil }
        return access
    }

    private static func readKeychainData(service: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    private static func saveKeychainData(_ data: Data, service: String) -> OSStatus {
        var attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]

        if let access = createOpenAccess(service: service) {
            attributes[kSecAttrAccess as String] = access
        }

        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        guard addStatus == errSecDuplicateItem else { return addStatus }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keychainAccount
        ]
        var update: [String: Any] = [kSecValueData as String: data]
        if let access = createOpenAccess(service: service) {
            update[kSecAttrAccess as String] = access
        }
        return SecItemUpdate(query as CFDictionary, update as CFDictionary)
    }

    private static var fallbackKeyURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = appSupport.appendingPathComponent("com.oomestre.Focenda", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o700
            ])
        }
        return folder.appendingPathComponent(".vault_key")
    }

    private static func readFallbackKeyData() -> Data? {
        guard let url = fallbackKeyURL,
              let data = try? Data(contentsOf: url),
              data.count == 32 else {
            return nil
        }
        return data
    }

    private static func saveFallbackKeyData(_ data: Data) {
        guard let url = fallbackKeyURL else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}
