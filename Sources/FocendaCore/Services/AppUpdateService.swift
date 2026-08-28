import Foundation
import Observation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Public release configuration used by the updater.
public struct AppUpdateConfiguration: Equatable, Sendable {
    public let repositoryOwner: String
    public let repositoryName: String
    public let includePrerelease: Bool
    public let supportedAssetNames: [String]

    public init(
        repositoryOwner: String,
        repositoryName: String,
        includePrerelease: Bool = false,
        supportedAssetNames: [String] = ["Focenda-macOS.zip", "Focenda.zip"]
    ) {
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName
        self.includePrerelease = includePrerelease
        self.supportedAssetNames = supportedAssetNames
    }

    public var releasesURL: URL {
        URL(string: "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/releases")!
    }

    /// The distributed Focenda app follows the official stable release channel.
    ///
    /// `includePrerelease` remains configurable for isolated development tooling,
    /// but the app itself must never switch channels based on its bundle name or
    /// embedded release tag.
    public static var focenda: AppUpdateConfiguration {
        return AppUpdateConfiguration(
            repositoryOwner: "OOMestre",
            repositoryName: "Focenda",
            includePrerelease: false
        )
    }
}

/// A small SemVer implementation for comparing GitHub release tags safely.
public struct AppVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prereleaseIdentifiers: [String]

    public init?(_ rawValue: String) {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if value.first == "v" || value.first == "V" {
            value.removeFirst()
        }

        let withoutBuildMetadata = value.split(separator: "+", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? value
        let versionParts = withoutBuildMetadata.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let coreParts = versionParts[0].split(separator: ".", omittingEmptySubsequences: false)
        guard coreParts.count == 3,
              let major = Int(coreParts[0]),
              let minor = Int(coreParts[1]),
              let patch = Int(coreParts[2]),
              major >= 0,
              minor >= 0,
              patch >= 0 else {
            return nil
        }

        let prerelease: [String]
        if versionParts.count == 2 {
            let identifiers = versionParts[1].split(separator: ".", omittingEmptySubsequences: false).map(String.init)
            guard !identifiers.isEmpty, identifiers.allSatisfy({ !$0.isEmpty }) else {
                return nil
            }
            prerelease = identifiers
        } else {
            prerelease = []
        }

        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prerelease
    }

    public static let zero = AppVersion(major: 0, minor: 0, patch: 0, prereleaseIdentifiers: [])

    public var coreIdentifier: String {
        "\(major).\(minor).\(patch)"
    }

    public var isPrerelease: Bool {
        !prereleaseIdentifiers.isEmpty
    }

    public var description: String {
        guard !prereleaseIdentifiers.isEmpty else { return coreIdentifier }
        return "\(coreIdentifier)-\(prereleaseIdentifiers.joined(separator: "."))"
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        // A stable version has higher precedence than a prerelease with the same core.
        switch (lhs.isPrerelease, rhs.isPrerelease) {
        case (false, false), (false, true):
            return false
        case (true, false):
            return true
        case (true, true):
            for (left, right) in zip(lhs.prereleaseIdentifiers, rhs.prereleaseIdentifiers) {
                if left == right { continue }

                let leftNumber = Int(left)
                let rightNumber = Int(right)
                switch (leftNumber, rightNumber) {
                case let (leftNumber?, rightNumber?):
                    return leftNumber < rightNumber
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return left < right
                }
            }
            return lhs.prereleaseIdentifiers.count < rhs.prereleaseIdentifiers.count
        }
    }

    private init(major: Int, minor: Int, patch: Int, prereleaseIdentifiers: [String]) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prereleaseIdentifiers
    }
}

public struct AppUpdateAsset: Codable, Equatable, Identifiable, Sendable {
    public let name: String
    public let downloadURL: URL

    public var id: String { downloadURL.absoluteString }

    public init(name: String, downloadURL: URL) {
        self.name = name
        self.downloadURL = downloadURL
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case downloadURL = "browser_download_url"
    }
}

public struct AppUpdateRelease: Codable, Equatable, Sendable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlURL: URL?
    public let prerelease: Bool
    public let draft: Bool
    public let assets: [AppUpdateAsset]

    public init(
        tagName: String,
        name: String? = nil,
        body: String? = nil,
        htmlURL: URL? = nil,
        prerelease: Bool = false,
        draft: Bool = false,
        assets: [AppUpdateAsset] = []
    ) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlURL = htmlURL
        self.prerelease = prerelease
        self.draft = draft
        self.assets = assets
    }

    public var version: AppVersion? {
        AppVersion(tagName)
    }

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case prerelease
        case draft
        case assets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagName = try container.decode(String.self, forKey: .tagName)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        htmlURL = try container.decodeIfPresent(URL.self, forKey: .htmlURL)
        prerelease = try container.decodeIfPresent(Bool.self, forKey: .prerelease) ?? false
        draft = try container.decodeIfPresent(Bool.self, forKey: .draft) ?? false
        assets = try container.decodeIfPresent([AppUpdateAsset].self, forKey: .assets) ?? []
    }
}

public struct AppUpdate: Equatable, Identifiable, Sendable {
    public let release: AppUpdateRelease
    public let asset: AppUpdateAsset
    public let version: AppVersion

    public var id: String { release.tagName }

    public var displayName: String {
        if let name = release.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return "Focenda \(version.description)"
    }

    public init?(release: AppUpdateRelease, asset: AppUpdateAsset) {
        guard let version = release.version else { return nil }
        self.release = release
        self.asset = asset
        self.version = version
    }
}

public enum AppUpdatePreferences {
    public static let automaticChecksEnabledKey = "automaticUpdateChecksEnabled"
    public static let lastCheckDateKey = "appUpdateLastCheckDate"
    public static let lastAutomaticCheckDateKey = "appUpdateLastAutomaticCheckDate"
    public static let lastNotifiedVersionKey = "appUpdateLastNotifiedVersion"
    public static let pendingUpdateTagKey = "appUpdatePendingTag"
    public static let pendingUpdateGuideKey = "appUpdatePendingGuide"
}

public enum AppRuntime {
    public static let fallbackVersion = "0.1.0"

    public static var currentReleaseIdentifier: String {
        if let releaseTag = Bundle.main.object(forInfoDictionaryKey: "FocendaReleaseTag") as? String,
           !releaseTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return releaseTag
        }

        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return version
        }

        return fallbackVersion
    }

    public static var currentBundleIdentifier: String? {
        Bundle.main.bundleIdentifier
    }
}

/// Safety limits applied to downloaded update archives before they are extracted.
public struct AppUpdateArchiveLimits: Equatable, Sendable {
    public static let defaultMaxUncompressedBytes: UInt64 = 512 * 1024 * 1024
    public static let defaultMaxFileCount: Int = 10_000

    public let maxUncompressedBytes: UInt64
    public let maxFileCount: Int

    public init(
        maxUncompressedBytes: UInt64 = AppUpdateArchiveLimits.defaultMaxUncompressedBytes,
        maxFileCount: Int = AppUpdateArchiveLimits.defaultMaxFileCount
    ) {
        self.maxUncompressedBytes = maxUncompressedBytes
        self.maxFileCount = max(0, maxFileCount)
    }
}

public enum AppUpdateError: LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case rateLimited
    case invalidDownloadURL
    case invalidArchive
    case noCompatibleApp
    case archiveTooLarge(limit: UInt64)
    case archiveTooManyFiles(limit: Int)
    case notRunningFromApplicationBundle
    case bundleIdentifierMismatch(expected: String, actual: String)
    case installedVersionMismatch(expected: String, actual: String)
    case installationFailed(String)
    case processFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "GitHub returned an invalid update response."
        case .httpStatus(let status):
            return "GitHub could not be reached right now (HTTP \(status))."
        case .rateLimited:
            return "GitHub temporarily limited update checks. Please try again later."
        case .invalidDownloadURL:
            return "The GitHub update download URL is not secure."
        case .invalidArchive:
            return "The downloaded update archive could not be opened."
        case .noCompatibleApp:
            return "The downloaded update does not contain a compatible Focenda app."
        case .archiveTooLarge(let limit):
            return "The downloaded update is too large to install (limit: \(limit) uncompressed bytes)."
        case .archiveTooManyFiles(let limit):
            return "The downloaded update contains too many files to install (limit: \(limit))."
        case .notRunningFromApplicationBundle:
            return "Updates are available only when Focenda is running as an installed macOS app."
        case .bundleIdentifierMismatch(let expected, let actual):
            return "The update belongs to a different app (expected \(expected), found \(actual))."
        case .installedVersionMismatch(let expected, let actual):
            return "The downloaded app version did not match the selected release (expected \(expected), found \(actual))."
        case .installationFailed(let message):
            return "Focenda could not replace the installed app: \(message)"
        case .processFailed(let message):
            return "Focenda could not prepare the update: \(message)"
        }
    }
}

public protocol AppUpdateClient: AnyObject {
    func fetchReleases() async throws -> [AppUpdateRelease]
    func downloadAsset(from url: URL) async throws -> URL
}

public protocol AppUpdateInstalling: AnyObject {
    func install(update: AppUpdate, downloadedFile: URL) throws
}

/// GitHub's public Releases client. It sends only the app version and standard HTTP headers.
public final class GitHubReleaseClient: AppUpdateClient {
    public let configuration: AppUpdateConfiguration

    private let session: URLSession
    private let userAgent: String

    public init(
        configuration: AppUpdateConfiguration = .focenda,
        session: URLSession? = nil,
        currentVersion: String = AppRuntime.currentReleaseIdentifier
    ) {
        self.configuration = configuration
        self.session = session ?? Self.makeSession()
        self.userAgent = "Focenda/\(AppVersion(currentVersion)?.description ?? AppRuntime.fallbackVersion)"
    }

    public func fetchReleases() async throws -> [AppUpdateRelease] {
        var request = URLRequest(url: configuration.releasesURL)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        do {
            return try JSONDecoder().decode([AppUpdateRelease].self, from: data)
        } catch {
            throw AppUpdateError.invalidResponse
        }
    }

    public func downloadAsset(from url: URL) async throws -> URL {
        guard Self.isAllowedDownloadURL(url) else {
            throw AppUpdateError.invalidDownloadURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (temporaryURL, response) = try await session.download(for: request)
        try validate(response: response)
        return temporaryURL
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppUpdateError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 403 || httpResponse.statusCode == 429 {
                throw AppUpdateError.rateLimited
            }
            throw AppUpdateError.httpStatus(httpResponse.statusCode)
        }
    }

    private static func isAllowedDownloadURL(_ url: URL) -> Bool {
        guard url.scheme?.lowercased() == "https",
              let host = url.host?.lowercased() else {
            return false
        }

        return host == "github.com" || host.hasSuffix(".githubusercontent.com")
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }
}

public protocol AppUpdateProviding: AnyObject {
    func checkForUpdates(currentReleaseIdentifier: String) async throws -> AppUpdate?
    func install(update: AppUpdate) async throws
}

/// Coordinates release checks, native notifications, automatic scheduling, and installation.
@Observable
public final class AppUpdateManager {
    public enum Status: Equatable {
        case idle
        case checking
        case available
        case upToDate
        case installing
        case failed(String)

        public var isBusy: Bool {
            switch self {
            case .checking, .installing:
                return true
            case .idle, .available, .upToDate, .failed:
                return false
            }
        }
    }

    public static let automaticCheckInterval: TimeInterval = 24 * 60 * 60

    public private(set) var status: Status = .idle
    public private(set) var availableUpdate: AppUpdate?
    public private(set) var lastCheckedAt: Date?
    public private(set) var errorMessage: String?
    public private(set) var completedUpdateGuide: AppUpdateGuide?

    private let provider: AppUpdateProviding
    private let currentReleaseIdentifier: String
    private let secureStore: SecureStore
    private let notificationManager: NotificationManagerProtocol

    private var checkTask: Task<Void, Never>?
    private var automaticTask: Task<Void, Never>?
    private var isCheckInFlight = false

    public init(
        provider: AppUpdateProviding = AppUpdateService.shared,
        currentReleaseIdentifier: String = AppRuntime.currentReleaseIdentifier,
        userDefaults: UserDefaults = .standard,
        secureStore: SecureStore? = nil,
        notificationManager: NotificationManagerProtocol = NotificationManager.shared
    ) {
        self.provider = provider
        self.currentReleaseIdentifier = currentReleaseIdentifier
        let resolvedSecureStore = secureStore ?? SecureStore(defaults: userDefaults)
        self.secureStore = resolvedSecureStore
        self.notificationManager = notificationManager
        self.lastCheckedAt = resolvedSecureStore.date(forKey: AppUpdatePreferences.lastCheckDateKey)
        self.completedUpdateGuide = Self.loadCompletedUpdateGuide(
            currentReleaseIdentifier: currentReleaseIdentifier,
            secureStore: resolvedSecureStore
        )
    }

    /// Starts a manual check without blocking the Settings view.
    public func checkForUpdates() {
        checkTask?.cancel()
        checkTask = Task { @MainActor [weak self] in
            _ = await self?.performCheck(isAutomatic: false)
        }
    }

    /// Async entry point used by tests and app integrations that need the result immediately.
    @discardableResult
    public func checkForUpdatesNow() async -> AppUpdate? {
        checkTask?.cancel()
        return await performCheck(isAutomatic: false)
    }

    public func startAutomaticChecks(enabled: Bool) {
        stopAutomaticChecks()
        guard enabled else { return }

        automaticTask = Task { @MainActor [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                if self.isAutomaticCheckDue {
                    _ = await self.performCheck(isAutomatic: true)
                }

                do {
                    try await Task.sleep(nanoseconds: UInt64(Self.automaticCheckInterval * 1_000_000_000))
                } catch {
                    return
                }
            }
        }
    }

    public func setAutomaticChecksEnabled(_ enabled: Bool) {
        if enabled {
            secureStore.removeObject(forKey: AppUpdatePreferences.lastAutomaticCheckDateKey)
        }
        startAutomaticChecks(enabled: enabled)
    }

    public func stopAutomaticChecks() {
        automaticTask?.cancel()
        automaticTask = nil
    }

    public func installAvailableUpdate() {
        guard let update = availableUpdate, !status.isBusy else { return }

        checkTask?.cancel()
        secureStore.set(
            AppUpdateGuide(update: update),
            forKey: AppUpdatePreferences.pendingUpdateGuideKey
        )
        status = .installing
        errorMessage = nil

        checkTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await self.provider.install(update: update)
                self.availableUpdate = nil
                self.status = .idle
                self.secureStore.removeObject(forKey: AppUpdatePreferences.pendingUpdateTagKey)
            } catch is CancellationError {
                self.secureStore.removeObject(forKey: AppUpdatePreferences.pendingUpdateGuideKey)
                self.status = .available
            } catch {
                self.secureStore.removeObject(forKey: AppUpdatePreferences.pendingUpdateGuideKey)
                self.errorMessage = error.localizedDescription
                self.status = .failed(error.localizedDescription)
            }
        }
    }

    /// Closes the post-update guide and prevents it from appearing again.
    public func dismissCompletedUpdateGuide() {
        completedUpdateGuide = nil
        secureStore.removeObject(forKey: AppUpdatePreferences.pendingUpdateGuideKey)
    }

    public func dismissAvailableUpdate() {
        availableUpdate = nil
        if case .available = status {
            status = .idle
        }
    }

    @MainActor
    private func performCheck(isAutomatic: Bool) async -> AppUpdate? {
        guard !isCheckInFlight else { return availableUpdate }

        isCheckInFlight = true
        status = .checking
        errorMessage = nil
        defer {
            isCheckInFlight = false
        }

        do {
            let update = try await provider.checkForUpdates(currentReleaseIdentifier: currentReleaseIdentifier)
            let now = Date()
            lastCheckedAt = now
            secureStore.set(now, forKey: AppUpdatePreferences.lastCheckDateKey)
            if isAutomatic {
                secureStore.set(now, forKey: AppUpdatePreferences.lastAutomaticCheckDateKey)
            }

            if let update {
                availableUpdate = update
                status = .available
                secureStore.set(update.release.tagName, forKey: AppUpdatePreferences.pendingUpdateTagKey)
                notifyIfNeeded(for: update)
            } else {
                availableUpdate = nil
                status = .upToDate
                secureStore.removeObject(forKey: AppUpdatePreferences.pendingUpdateTagKey)
            }
            return update
        } catch is CancellationError {
            status = availableUpdate == nil ? .idle : .available
            return availableUpdate
        } catch {
            errorMessage = error.localizedDescription
            status = .failed(error.localizedDescription)
            return nil
        }
    }

    @MainActor
    private func notifyIfNeeded(for update: AppUpdate) {
        let lastNotifiedVersion = secureStore.string(forKey: AppUpdatePreferences.lastNotifiedVersionKey)
        guard lastNotifiedVersion != update.release.tagName else { return }

        notificationManager.notifyUpdateAvailable(version: update.version.description)
        secureStore.set(update.release.tagName, forKey: AppUpdatePreferences.lastNotifiedVersionKey)
    }

    private static func loadCompletedUpdateGuide(
        currentReleaseIdentifier: String,
        secureStore: SecureStore
    ) -> AppUpdateGuide? {
        guard let guide = secureStore.value(
            AppUpdateGuide.self,
            forKey: AppUpdatePreferences.pendingUpdateGuideKey
        ) else {
            return nil
        }

        guard let installedVersion = AppVersion(currentReleaseIdentifier),
              let guideVersion = AppVersion(guide.releaseTag) else {
            secureStore.removeObject(forKey: AppUpdatePreferences.pendingUpdateGuideKey)
            return nil
        }

        if installedVersion == guideVersion {
            return guide
        }

        // A newer manual update may have superseded this guide. Do not show
        // notes for an older release, but keep a guide for a not-yet-installed
        // update so an in-progress relaunch can still complete normally.
        if installedVersion > guideVersion {
            secureStore.removeObject(forKey: AppUpdatePreferences.pendingUpdateGuideKey)
        }
        return nil
    }

    private var isAutomaticCheckDue: Bool {
        if availableUpdate == nil,
           secureStore.string(forKey: AppUpdatePreferences.pendingUpdateTagKey) != nil {
            return true
        }

        guard let lastDate = secureStore.date(forKey: AppUpdatePreferences.lastAutomaticCheckDateKey) else {
            return true
        }
        return Date().timeIntervalSince(lastDate) >= Self.automaticCheckInterval
    }
}

public final class AppUpdateService: AppUpdateProviding {
    public static let shared = AppUpdateService()

    public let configuration: AppUpdateConfiguration

    private let client: AppUpdateClient
    private let installer: AppUpdateInstalling

    public init(
        configuration: AppUpdateConfiguration = .focenda,
        client: AppUpdateClient? = nil,
        installer: AppUpdateInstalling? = nil
    ) {
        self.configuration = configuration
        self.client = client ?? GitHubReleaseClient(configuration: configuration)
        self.installer = installer ?? AppUpdateInstaller()
    }

    public func checkForUpdates(currentReleaseIdentifier: String) async throws -> AppUpdate? {
        let parsedCurrentVersion = AppVersion(currentReleaseIdentifier) ?? .zero
        let currentVersion: AppVersion
        if configuration.includePrerelease && !parsedCurrentVersion.isPrerelease {
            // Older staging builds expose only the core version. Treat them as beta.0
            // so they can receive the first tag-aware beta update.
            currentVersion = AppVersion("\(parsedCurrentVersion.coreIdentifier)-beta.0") ?? parsedCurrentVersion
        } else {
            currentVersion = parsedCurrentVersion
        }
        let releases = try await client.fetchReleases()

        let candidates = releases.compactMap { release -> AppUpdate? in
            guard !release.draft,
                  let version = release.version,
                  (configuration.includePrerelease || (!release.prerelease && !version.isPrerelease)),
                  version > currentVersion,
                  let asset = preferredAsset(for: release) else {
                return nil
            }

            return AppUpdate(release: release, asset: asset)
        }

        return candidates.max { left, right in
            left.version < right.version
        }
    }

    public func install(update: AppUpdate) async throws {
        let downloadedFile = try await client.downloadAsset(from: update.asset.downloadURL)
        defer { try? FileManager.default.removeItem(at: downloadedFile) }

        // The installer performs synchronous file-system and Process work. Keep it
        // off the caller's actor so an update started from SwiftUI cannot stall the
        // main thread while the archive is inspected, extracted, or copied.
        let installer = self.installer
        let backgroundInstaller = BackgroundUpdateInstaller(installer: installer)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .utility).async {
                do {
                    try backgroundInstaller.installer.install(update: update, downloadedFile: downloadedFile)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func preferredAsset(for release: AppUpdateRelease) -> AppUpdateAsset? {
        for supportedName in configuration.supportedAssetNames {
            if let asset = release.assets.first(where: { $0.name.caseInsensitiveCompare(supportedName) == .orderedSame }) {
                return asset
            }
        }

        return release.assets.first { $0.name.lowercased().hasSuffix(".zip") }
    }
}

private final class BackgroundUpdateInstaller: @unchecked Sendable {
    let installer: AppUpdateInstalling

    init(installer: AppUpdateInstalling) {
        self.installer = installer
    }
}

public final class AppUpdateInstaller: AppUpdateInstalling {
    private let fileManager: FileManager
    private let applicationURL: URL?
    private let expectedBundleIdentifier: String?
    private let relaunchAfterInstall: Bool
    private let archiveLimits: AppUpdateArchiveLimits

    public init(
        applicationURL: URL? = nil,
        expectedBundleIdentifier: String? = AppRuntime.currentBundleIdentifier,
        relaunchAfterInstall: Bool = true,
        fileManager: FileManager = .default,
        archiveLimits: AppUpdateArchiveLimits = AppUpdateArchiveLimits()
    ) {
        self.applicationURL = applicationURL
        self.expectedBundleIdentifier = expectedBundleIdentifier
        self.relaunchAfterInstall = relaunchAfterInstall
        self.fileManager = fileManager
        self.archiveLimits = archiveLimits
    }

    public func install(update: AppUpdate, downloadedFile: URL) throws {
        guard fileManager.fileExists(atPath: downloadedFile.path) else {
            throw AppUpdateError.invalidArchive
        }

        let targetURL = applicationURL ?? Bundle.main.bundleURL
        guard targetURL.pathExtension.lowercased() == "app",
              fileManager.fileExists(atPath: targetURL.path) else {
            throw AppUpdateError.notRunningFromApplicationBundle
        }

        let expectedIdentifier = expectedBundleIdentifier ?? Bundle(url: targetURL)?.bundleIdentifier
        guard let expectedIdentifier, !expectedIdentifier.isEmpty else {
            throw AppUpdateError.notRunningFromApplicationBundle
        }

        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("FocendaUpdate-\(UUID().uuidString)", isDirectory: true)
        let extractionDirectory = temporaryDirectory.appendingPathComponent("Extracted", isDirectory: true)

        do {
            try fileManager.createDirectory(at: extractionDirectory, withIntermediateDirectories: true)
            try inspectArchive(at: downloadedFile)
            try extract(downloadedFile, to: extractionDirectory)
            try validateExtractedContents(at: extractionDirectory)

            guard let candidateAppURL = findApplication(in: extractionDirectory),
                  let candidateBundle = Bundle(url: candidateAppURL),
                  let candidateIdentifier = candidateBundle.bundleIdentifier else {
                throw AppUpdateError.noCompatibleApp
            }

            guard candidateIdentifier == expectedIdentifier else {
                throw AppUpdateError.bundleIdentifierMismatch(expected: expectedIdentifier, actual: candidateIdentifier)
            }

            try validate(candidateBundle: candidateBundle, against: update)

            let replacementURL = targetURL.deletingLastPathComponent()
                .appendingPathComponent(".\(targetURL.lastPathComponent).update-\(UUID().uuidString)", isDirectory: true)
            do {
                try fileManager.copyItem(at: candidateAppURL, to: replacementURL)
                _ = try fileManager.replaceItemAt(
                    targetURL,
                    withItemAt: replacementURL,
                    backupItemName: nil,
                    options: .usingNewMetadataOnly
                )
            } catch let error as AppUpdateError {
                try? fileManager.removeItem(at: replacementURL)
                throw error
            } catch {
                try? fileManager.removeItem(at: replacementURL)
                throw AppUpdateError.installationFailed(error.localizedDescription)
            }

            if relaunchAfterInstall {
                try scheduleRelaunch(at: targetURL)
            }
        } catch let error as AppUpdateError {
            try? fileManager.removeItem(at: temporaryDirectory)
            throw error
        } catch {
            try? fileManager.removeItem(at: temporaryDirectory)
            throw AppUpdateError.installationFailed(error.localizedDescription)
        }

        try? fileManager.removeItem(at: temporaryDirectory)
    }

    private struct ArchiveMetadata {
        let entryCount: UInt64
        let uncompressedBytes: UInt64
    }

    private func inspectArchive(at archiveURL: URL) throws {
        #if os(macOS)
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: archiveURL)
        } catch {
            throw AppUpdateError.invalidArchive
        }
        defer { try? handle.close() }

        do {
            let archiveSize = try handle.seekToEnd()
            guard archiveSize >= 22 else {
                throw AppUpdateError.invalidArchive
            }

            // The EOCD record is followed by at most a 65,535-byte comment.
            let searchLength = min(archiveSize, UInt64(22 + Int(UInt16.max)))
            let searchStart = archiveSize - searchLength
            try handle.seek(toOffset: searchStart)
            let tail = try readExactly(from: handle, count: Int(searchLength))
            guard let eocdIndex = endOfCentralDirectoryIndex(in: tail) else {
                throw AppUpdateError.invalidArchive
            }

            let eocdOffset = searchStart + UInt64(eocdIndex)
            let eocd = tail.subdata(in: eocdIndex..<(eocdIndex + 22))
            let diskNumber = readUInt16(from: eocd, at: 4)
            let centralDirectoryDisk = readUInt16(from: eocd, at: 6)
            let entriesOnDisk = readUInt16(from: eocd, at: 8)
            let totalEntries = readUInt16(from: eocd, at: 10)
            let centralDirectorySize = readUInt32(from: eocd, at: 12)
            let centralDirectoryOffset = readUInt32(from: eocd, at: 16)

            guard diskNumber == 0, centralDirectoryDisk == 0, entriesOnDisk == totalEntries else {
                throw AppUpdateError.invalidArchive
            }

            let metadata: ArchiveMetadata
            if totalEntries == UInt16.max
                || centralDirectorySize == UInt32.max
                || centralDirectoryOffset == UInt32.max {
                metadata = try readZIP64Metadata(
                    from: handle,
                    archiveSize: archiveSize,
                    eocdOffset: eocdOffset
                )
            } else {
                let entryCount = UInt64(totalEntries)
                guard entryCount <= UInt64(archiveLimits.maxFileCount) else {
                    throw AppUpdateError.archiveTooManyFiles(limit: archiveLimits.maxFileCount)
                }

                let uncompressedBytes = try inspectCentralDirectory(
                    from: handle,
                    archiveSize: archiveSize,
                    entryCount: entryCount,
                    centralDirectoryOffset: UInt64(centralDirectoryOffset),
                    centralDirectorySize: UInt64(centralDirectorySize)
                )
                metadata = ArchiveMetadata(entryCount: entryCount, uncompressedBytes: uncompressedBytes)
            }

            if metadata.entryCount > UInt64(archiveLimits.maxFileCount) {
                throw AppUpdateError.archiveTooManyFiles(limit: archiveLimits.maxFileCount)
            }

            if metadata.uncompressedBytes > archiveLimits.maxUncompressedBytes {
                throw AppUpdateError.archiveTooLarge(limit: archiveLimits.maxUncompressedBytes)
            }
        } catch let error as AppUpdateError {
            throw error
        } catch {
            throw AppUpdateError.invalidArchive
        }
        #else
        throw AppUpdateError.invalidArchive
        #endif
    }

    #if os(macOS)
    private func readZIP64Metadata(
        from handle: FileHandle,
        archiveSize: UInt64,
        eocdOffset: UInt64
    ) throws -> ArchiveMetadata {
        guard eocdOffset >= 20 else {
            throw AppUpdateError.invalidArchive
        }

        try handle.seek(toOffset: eocdOffset - 20)
        let locator = try readExactly(from: handle, count: 20)
        guard readUInt32(from: locator, at: 0) == 0x07064b50,
              readUInt32(from: locator, at: 4) == 0,
              readUInt32(from: locator, at: 16) == 1 else {
            throw AppUpdateError.invalidArchive
        }

        let zip64EOCDOffset = readUInt64(from: locator, at: 8)
        guard zip64EOCDOffset < eocdOffset,
              zip64EOCDOffset <= archiveSize,
              archiveSize - zip64EOCDOffset >= 56 else {
            throw AppUpdateError.invalidArchive
        }

        try handle.seek(toOffset: zip64EOCDOffset)
        let zip64EOCD = try readExactly(from: handle, count: 56)
        guard readUInt32(from: zip64EOCD, at: 0) == 0x06064b50 else {
            throw AppUpdateError.invalidArchive
        }

        let recordSize = readUInt64(from: zip64EOCD, at: 4)
        guard recordSize >= 44,
              recordSize <= archiveSize - zip64EOCDOffset - 12,
              readUInt32(from: zip64EOCD, at: 16) == 0,
              readUInt32(from: zip64EOCD, at: 20) == 0 else {
            throw AppUpdateError.invalidArchive
        }

        let entriesOnDisk = readUInt64(from: zip64EOCD, at: 24)
        let totalEntries = readUInt64(from: zip64EOCD, at: 32)
        guard entriesOnDisk == totalEntries else {
            throw AppUpdateError.invalidArchive
        }
        guard totalEntries <= UInt64(archiveLimits.maxFileCount) else {
            throw AppUpdateError.archiveTooManyFiles(limit: archiveLimits.maxFileCount)
        }

        let centralDirectorySize = readUInt64(from: zip64EOCD, at: 40)
        let centralDirectoryOffset = readUInt64(from: zip64EOCD, at: 48)
        let uncompressedBytes = try inspectCentralDirectory(
            from: handle,
            archiveSize: archiveSize,
            entryCount: totalEntries,
            centralDirectoryOffset: centralDirectoryOffset,
            centralDirectorySize: centralDirectorySize
        )

        return ArchiveMetadata(entryCount: totalEntries, uncompressedBytes: uncompressedBytes)
    }

    @discardableResult
    private func inspectCentralDirectory(
        from handle: FileHandle,
        archiveSize: UInt64,
        entryCount: UInt64,
        centralDirectoryOffset: UInt64,
        centralDirectorySize: UInt64
    ) throws -> UInt64 {
        guard centralDirectoryOffset <= archiveSize,
              centralDirectorySize <= archiveSize - centralDirectoryOffset else {
            throw AppUpdateError.invalidArchive
        }

        let centralDirectoryEnd = centralDirectoryOffset + centralDirectorySize
        try handle.seek(toOffset: centralDirectoryOffset)

        var currentOffset = centralDirectoryOffset
        var totalUncompressedBytes: UInt64 = 0
        var entryIndex: UInt64 = 0

        while entryIndex < entryCount {
            guard centralDirectoryEnd >= currentOffset,
                  centralDirectoryEnd - currentOffset >= 46 else {
                throw AppUpdateError.invalidArchive
            }

            try handle.seek(toOffset: currentOffset)
            let header = try readExactly(from: handle, count: 46)
            guard readUInt32(from: header, at: 0) == 0x02014b50 else {
                throw AppUpdateError.invalidArchive
            }

            let flags = readUInt16(from: header, at: 8)
            guard flags & 0x0001 == 0 else {
                throw AppUpdateError.invalidArchive
            }

            let uncompressedSize = readUInt32(from: header, at: 24)
            let nameLength = Int(readUInt16(from: header, at: 28))
            let extraLength = Int(readUInt16(from: header, at: 30))
            let commentLength = Int(readUInt16(from: header, at: 32))
            let entrySize = UInt64(46 + nameLength + extraLength + commentLength)
            guard entrySize <= centralDirectoryEnd - currentOffset else {
                throw AppUpdateError.invalidArchive
            }

            let nameData = try readExactly(from: handle, count: nameLength)
            let extraData = try readExactly(from: handle, count: extraLength)
            try validateArchiveEntryName(nameData, flags: flags)

            let resolvedUncompressedSize = try resolveUncompressedSize(
                standardSize: uncompressedSize,
                extraData: extraData
            )
            guard resolvedUncompressedSize <= UInt64.max - totalUncompressedBytes else {
                throw AppUpdateError.archiveTooLarge(limit: archiveLimits.maxUncompressedBytes)
            }
            totalUncompressedBytes += resolvedUncompressedSize
            if totalUncompressedBytes > archiveLimits.maxUncompressedBytes {
                throw AppUpdateError.archiveTooLarge(limit: archiveLimits.maxUncompressedBytes)
            }

            currentOffset += entrySize
            entryIndex += 1
        }

        guard currentOffset == centralDirectoryEnd else {
            throw AppUpdateError.invalidArchive
        }

        return totalUncompressedBytes
    }

    private func resolveUncompressedSize(standardSize: UInt32, extraData: Data) throws -> UInt64 {
        guard standardSize == UInt32.max else {
            return UInt64(standardSize)
        }

        var offset = 0
        while offset + 4 <= extraData.count {
            let fieldID = readUInt16(from: extraData, at: offset)
            let fieldSize = Int(readUInt16(from: extraData, at: offset + 2))
            offset += 4
            guard fieldSize <= extraData.count - offset else {
                throw AppUpdateError.invalidArchive
            }

            if fieldID == 0x0001 {
                guard fieldSize >= 8 else {
                    throw AppUpdateError.invalidArchive
                }
                return readUInt64(from: extraData, at: offset)
            }
            offset += fieldSize
        }

        throw AppUpdateError.invalidArchive
    }

    private func validateArchiveEntryName(_ nameData: Data, flags: UInt16) throws {
        let encoding: String.Encoding = flags & 0x0800 == 0 ? .macOSRoman : .utf8
        guard let name = String(data: nameData, encoding: encoding),
              !name.isEmpty,
              !name.unicodeScalars.contains(where: { $0.value == 0 }) else {
            throw AppUpdateError.invalidArchive
        }

        let normalizedName = name.replacingOccurrences(of: "\\", with: "/")
        guard !normalizedName.hasPrefix("/") else {
            throw AppUpdateError.invalidArchive
        }

        let components = normalizedName.split(separator: "/", omittingEmptySubsequences: true)
        guard !components.contains(where: { $0 == ".." }) else {
            throw AppUpdateError.invalidArchive
        }
    }

    private func readExactly(from handle: FileHandle, count: Int) throws -> Data {
        guard count >= 0 else {
            throw AppUpdateError.invalidArchive
        }
        let data = try handle.read(upToCount: count) ?? Data()
        guard data.count == count else {
            throw AppUpdateError.invalidArchive
        }
        return data
    }

    private func endOfCentralDirectoryIndex(in data: Data) -> Int? {
        guard data.count >= 22 else { return nil }

        for index in stride(from: data.count - 22, through: 0, by: -1) {
            guard readUInt32(from: data, at: index) == 0x06054b50 else { continue }
            let commentLength = Int(readUInt16(from: data, at: index + 20))
            guard index + 22 + commentLength == data.count else { continue }
            return index
        }

        return nil
    }

    private func readUInt16(from data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private func readUInt32(from data: Data, at offset: Int) -> UInt32 {
        UInt32(readUInt16(from: data, at: offset))
            | (UInt32(readUInt16(from: data, at: offset + 2)) << 16)
    }

    private func readUInt64(from data: Data, at offset: Int) -> UInt64 {
        var value: UInt64 = 0
        for byteOffset in 0..<8 {
            value |= UInt64(data[offset + byteOffset]) << UInt64(byteOffset * 8)
        }
        return value
    }
    #endif

    private func validateExtractedContents(at directoryURL: URL) throws {
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey],
            options: []
        ) else {
            throw AppUpdateError.invalidArchive
        }

        var fileCount = 0
        var totalUncompressedBytes: UInt64 = 0

        for case let url as URL in enumerator {
            fileCount += 1
            if fileCount > archiveLimits.maxFileCount {
                throw AppUpdateError.archiveTooManyFiles(limit: archiveLimits.maxFileCount)
            }

            do {
                let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey])
                guard values.isSymbolicLink != true else {
                    throw AppUpdateError.invalidArchive
                }

                guard values.isDirectory != true else { continue }
                guard let fileSize = values.fileSize, fileSize >= 0 else {
                    throw AppUpdateError.invalidArchive
                }

                let size = UInt64(fileSize)
                guard size <= UInt64.max - totalUncompressedBytes else {
                    throw AppUpdateError.archiveTooLarge(limit: archiveLimits.maxUncompressedBytes)
                }
                totalUncompressedBytes += size
                if totalUncompressedBytes > archiveLimits.maxUncompressedBytes {
                    throw AppUpdateError.archiveTooLarge(limit: archiveLimits.maxUncompressedBytes)
                }
            } catch let error as AppUpdateError {
                throw error
            } catch {
                throw AppUpdateError.invalidArchive
            }
        }
    }

    private func extract(_ archiveURL: URL, to destinationURL: URL) throws {
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", archiveURL.path, destinationURL.path]
        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw AppUpdateError.processFailed(error.localizedDescription)
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            _ = errorPipe.fileHandleForReading.readDataToEndOfFile()
            throw AppUpdateError.invalidArchive
        }
        #else
        throw AppUpdateError.invalidArchive
        #endif
    }

    private func findApplication(in directoryURL: URL) -> URL? {
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let url as URL in enumerator where url.pathExtension.lowercased() == "app" {
            return url
        }
        return nil
    }

    private func validate(candidateBundle: Bundle, against update: AppUpdate) throws {
        let candidateTag = (candidateBundle.object(forInfoDictionaryKey: "FocendaReleaseTag") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCandidateTag = candidateTag?.isEmpty == false ? candidateTag : nil
        let candidateShortVersion = candidateBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let candidateIdentifier = normalizedCandidateTag ?? candidateShortVersion

        guard let candidateIdentifier,
              let candidateVersion = AppVersion(candidateIdentifier) else {
            throw AppUpdateError.noCompatibleApp
        }

        if normalizedCandidateTag != nil {
            guard candidateVersion == update.version else {
                throw AppUpdateError.installedVersionMismatch(expected: update.version.description, actual: candidateVersion.description)
            }
        } else {
            // Older Focenda artifacts predate FocendaReleaseTag and carry only the core version.
            guard candidateVersion.coreIdentifier == update.version.coreIdentifier else {
                throw AppUpdateError.installedVersionMismatch(expected: update.version.coreIdentifier, actual: candidateVersion.description)
            }
        }
    }

    private func scheduleRelaunch(at targetURL: URL) throws {
        #if os(macOS)
        let helperDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("FocendaRelaunch-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: helperDirectory, withIntermediateDirectories: true)

        let scriptURL = helperDirectory.appendingPathComponent("relaunch.sh")
        let processIdentifier = ProcessInfo.processInfo.processIdentifier
        let script = """
        #!/bin/sh
        set -eu
        target=\(shellQuote(targetURL.path))
        pid=\(processIdentifier)
        while kill -0 "$pid" 2>/dev/null; do
            sleep 0.2
        done
        /usr/bin/open "$target" >/dev/null 2>&1 || true
        /bin/rm -rf \(shellQuote(helperDirectory.path))
        """

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)
        } catch {
            try? fileManager.removeItem(at: helperDirectory)
            throw AppUpdateError.installationFailed(error.localizedDescription)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [scriptURL.path]
        do {
            try process.run()
        } catch {
            try? fileManager.removeItem(at: helperDirectory)
            throw AppUpdateError.processFailed(error.localizedDescription)
        }

        DispatchQueue.main.async {
            NSApp?.terminate(nil)
        }
        #else
        throw AppUpdateError.notRunningFromApplicationBundle
        #endif
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
