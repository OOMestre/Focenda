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

    /// Staging builds can receive beta releases, while production builds stay on stable releases.
    public static var focenda: AppUpdateConfiguration {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let embeddedReleaseTag = Bundle.main.object(forInfoDictionaryKey: "FocendaReleaseTag") as? String
        let hasBetaTag = embeddedReleaseTag.flatMap(AppVersion.init)?.isPrerelease == true
        let includePrerelease = embeddedReleaseTag?.isEmpty == false ? hasBetaTag : bundleIdentifier.hasSuffix(".staging")

        return AppUpdateConfiguration(
            repositoryOwner: "OOMestre",
            repositoryName: "Focenda",
            includePrerelease: includePrerelease
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

public enum AppUpdateError: LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case rateLimited
    case invalidDownloadURL
    case invalidArchive
    case noCompatibleApp
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

    private let provider: AppUpdateProviding
    private let currentReleaseIdentifier: String
    private let userDefaults: UserDefaults
    private let notificationManager: NotificationManagerProtocol

    private var checkTask: Task<Void, Never>?
    private var automaticTask: Task<Void, Never>?
    private var isCheckInFlight = false

    public init(
        provider: AppUpdateProviding = AppUpdateService.shared,
        currentReleaseIdentifier: String = AppRuntime.currentReleaseIdentifier,
        userDefaults: UserDefaults = .standard,
        notificationManager: NotificationManagerProtocol = NotificationManager.shared
    ) {
        self.provider = provider
        self.currentReleaseIdentifier = currentReleaseIdentifier
        self.userDefaults = userDefaults
        self.notificationManager = notificationManager
        self.lastCheckedAt = userDefaults.object(forKey: AppUpdatePreferences.lastCheckDateKey) as? Date
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
            userDefaults.removeObject(forKey: AppUpdatePreferences.lastAutomaticCheckDateKey)
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
        status = .installing
        errorMessage = nil

        checkTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await self.provider.install(update: update)
                self.availableUpdate = nil
                self.status = .idle
                self.userDefaults.removeObject(forKey: AppUpdatePreferences.pendingUpdateTagKey)
            } catch is CancellationError {
                self.status = .available
            } catch {
                self.errorMessage = error.localizedDescription
                self.status = .failed(error.localizedDescription)
            }
        }
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
            userDefaults.set(now, forKey: AppUpdatePreferences.lastCheckDateKey)
            if isAutomatic {
                userDefaults.set(now, forKey: AppUpdatePreferences.lastAutomaticCheckDateKey)
            }

            if let update {
                availableUpdate = update
                status = .available
                userDefaults.set(update.release.tagName, forKey: AppUpdatePreferences.pendingUpdateTagKey)
                notifyIfNeeded(for: update)
            } else {
                availableUpdate = nil
                status = .upToDate
                userDefaults.removeObject(forKey: AppUpdatePreferences.pendingUpdateTagKey)
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
        let lastNotifiedVersion = userDefaults.string(forKey: AppUpdatePreferences.lastNotifiedVersionKey)
        guard lastNotifiedVersion != update.release.tagName else { return }

        notificationManager.notifyUpdateAvailable(version: update.version.description)
        userDefaults.set(update.release.tagName, forKey: AppUpdatePreferences.lastNotifiedVersionKey)
    }

    private var isAutomaticCheckDue: Bool {
        if availableUpdate == nil,
           userDefaults.string(forKey: AppUpdatePreferences.pendingUpdateTagKey) != nil {
            return true
        }

        guard let lastDate = userDefaults.object(forKey: AppUpdatePreferences.lastAutomaticCheckDateKey) as? Date else {
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
                  (configuration.includePrerelease || !release.prerelease),
                  let version = release.version,
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
        try installer.install(update: update, downloadedFile: downloadedFile)
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

public final class AppUpdateInstaller: AppUpdateInstalling {
    private let fileManager: FileManager
    private let applicationURL: URL?
    private let expectedBundleIdentifier: String?
    private let relaunchAfterInstall: Bool

    public init(
        applicationURL: URL? = nil,
        expectedBundleIdentifier: String? = AppRuntime.currentBundleIdentifier,
        relaunchAfterInstall: Bool = true,
        fileManager: FileManager = .default
    ) {
        self.applicationURL = applicationURL
        self.expectedBundleIdentifier = expectedBundleIdentifier
        self.relaunchAfterInstall = relaunchAfterInstall
        self.fileManager = fileManager
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
            try extract(downloadedFile, to: extractionDirectory)

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

        if let application = NSApp {
            DispatchQueue.main.async {
                application.terminate(nil)
            }
        }
        #else
        throw AppUpdateError.notRunningFromApplicationBundle
        #endif
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
