import XCTest
@testable import FocendaCore

final class AppUpdateTests: XCTestCase {
    func testUpdateGuideIsTemporarilyHiddenWithoutRemovingItsImplementation() {
        XCTAssertFalse(AppUpdateGuide.isEnabled)
    }

    func testAppVersionComparisonFollowsReleasePrecedence() throws {
        let beta1 = try XCTUnwrap(AppVersion("v1.2.3-beta.1"))
        let beta2 = try XCTUnwrap(AppVersion("1.2.3-beta.2"))
        let release = try XCTUnwrap(AppVersion("1.2.3"))
        let nextPatch = try XCTUnwrap(AppVersion("1.2.4"))

        XCTAssertLessThan(beta1, beta2)
        XCTAssertLessThan(beta2, release)
        XCTAssertLessThan(release, nextPatch)
        XCTAssertEqual(release.coreIdentifier, "1.2.3")
        XCTAssertEqual(beta1.description, "1.2.3-beta.1")
    }

    func testAppVersionRejectsMalformedValues() {
        XCTAssertNil(AppVersion(""))
        XCTAssertNil(AppVersion("1.2"))
        XCTAssertNil(AppVersion("release-latest"))
        XCTAssertNil(AppVersion("1.2.3-"))
    }

    func testOfficialConfigurationAlwaysUsesStableReleaseChannel() {
        XCTAssertFalse(AppUpdateConfiguration.focenda.includePrerelease)
    }

    func testStagingAndProductionBundleIdentifiersShareTheUpdatePath() {
        XCTAssertTrue(
            AppRuntime.bundleIdentifiersAreCompatible(
                "com.oomestre.focenda.staging",
                "com.oomestre.focenda"
            )
        )
        XCTAssertFalse(
            AppRuntime.bundleIdentifiersAreCompatible(
                "com.oomestre.focenda.staging",
                "com.example.other-app"
            )
        )
    }

    func testGitHubClientRejectsInsecureDownloadURL() async throws {
        let client = GitHubReleaseClient(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda")
        )
        let insecureURL = try XCTUnwrap(URL(string: "http://example.com/Focenda-macOS.zip"))

        do {
            _ = try await client.downloadAsset(from: insecureURL)
            XCTFail("An insecure download URL should be rejected before any request is made")
        } catch let error as AppUpdateError {
            XCTAssertEqual(error, .invalidDownloadURL)
        }
    }

    func testServiceSelectsHighestStableReleaseWithSupportedArchive() async throws {
        let olderAsset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.1.0/Focenda-macOS.zip"))
        )
        let newestAsset = AppUpdateAsset(
            name: "focenda-macos.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let betaAsset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.3.0-beta.1/Focenda-macOS.zip"))
        )
        let releases = [
            AppUpdateRelease(tagName: "v1.1.0", assets: [olderAsset]),
            AppUpdateRelease(tagName: "v1.2.0", assets: [newestAsset]),
            AppUpdateRelease(tagName: "v1.3.0-beta.1", prerelease: true, assets: [betaAsset]),
            AppUpdateRelease(tagName: "v2.0.0", draft: true, assets: [newestAsset])
        ]
        let client = StubUpdateClient(releases: releases)
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda"),
            client: client,
            installer: RecordingUpdateInstaller()
        )

        let result = try await service.checkForUpdates(currentReleaseIdentifier: "1.0.0")
        let update = try XCTUnwrap(result)

        XCTAssertEqual(update.version.description, "1.2.0")
        XCTAssertEqual(update.asset.name, "focenda-macos.zip")
        XCTAssertEqual(client.fetchCount, 1)
    }

    func testServiceRejectsPrereleaseTagEvenWhenReleaseMetadataIsMarkedStable() async throws {
        let betaAsset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v9.0.0-beta.1/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(
            tagName: "v9.0.0-beta.1",
            assets: [betaAsset]
        )
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda"),
            client: StubUpdateClient(releases: [release]),
            installer: RecordingUpdateInstaller()
        )

        let result = try await service.checkForUpdates(currentReleaseIdentifier: "1.0.0")

        XCTAssertNil(result)
    }

    func testServiceCanOptIntoPrereleaseUpdates() async throws {
        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0-beta.2/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0-beta.2", prerelease: true, assets: [asset])
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda", includePrerelease: true),
            client: StubUpdateClient(releases: [release]),
            installer: RecordingUpdateInstaller()
        )

        let result = try await service.checkForUpdates(currentReleaseIdentifier: "1.2.0-beta.1")
        let update = try XCTUnwrap(result)

        XCTAssertEqual(update.version.description, "1.2.0-beta.2")
    }

    func testPrereleaseServiceBootstrapsLegacyCoreVersion() async throws {
        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0-beta.1/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0-beta.1", prerelease: true, assets: [asset])
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda", includePrerelease: true),
            client: StubUpdateClient(releases: [release]),
            installer: RecordingUpdateInstaller()
        )

        let result = try await service.checkForUpdates(currentReleaseIdentifier: "1.2.0")

        XCTAssertEqual(result?.version.description, "1.2.0-beta.1")
    }

    func testServiceDoesNotOfferTheCurrentReleaseAgain() async throws {
        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0", assets: [asset])
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda"),
            client: StubUpdateClient(releases: [release]),
            installer: RecordingUpdateInstaller()
        )

        let update = try await service.checkForUpdates(currentReleaseIdentifier: "v1.2.0")

        XCTAssertNil(update)
    }

    func testServiceDownloadsAndPassesArchiveToInstaller() async throws {
        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0", assets: [asset])
        let client = StubUpdateClient(releases: [release])
        let installer = RecordingUpdateInstaller()
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda"),
            client: client,
            installer: installer
        )
        let result = try await service.checkForUpdates(currentReleaseIdentifier: "1.0.0")
        let update = try XCTUnwrap(result)

        try await service.install(update: update)

        XCTAssertEqual(installer.installedUpdate, update)
        XCTAssertEqual(installer.downloadedFile, client.downloadedFile)
        XCTAssertEqual(client.downloadedURL, asset.downloadURL)
    }

    func testUpdateManagerNotifiesOnlyOnceForTheSameRelease() async throws {
        let suiteName = "Focenda.AppUpdateTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0", assets: [asset])
        let update = try XCTUnwrap(AppUpdate(release: release, asset: asset))
        let provider = StubUpdateProvider(update: update)
        let notificationManager = RecordingNotificationManager()
        let manager = AppUpdateManager(
            provider: provider,
            currentReleaseIdentifier: "1.0.0",
            userDefaults: defaults,
            notificationManager: notificationManager
        )

        let firstResult = await manager.checkForUpdatesNow()
        let secondResult = await manager.checkForUpdatesNow()

        XCTAssertEqual(firstResult, update)
        XCTAssertEqual(secondResult, update)
        XCTAssertEqual(manager.status, .available)
        XCTAssertNotNil(manager.lastCheckedAt)
        XCTAssertEqual(notificationManager.updateVersions, ["1.2.0"])
        let secureStore = SecureStore(defaults: defaults)
        XCTAssertEqual(secureStore.string(forKey: AppUpdatePreferences.lastNotifiedVersionKey), "v1.2.0")
        XCTAssertEqual(secureStore.string(forKey: AppUpdatePreferences.pendingUpdateTagKey), "v1.2.0")
    }

    func testUpdateGuideGroupsReleaseNotesAndSkipsInstallationDetails() throws {
        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(
            tagName: "v1.2.0",
            name: "A calmer way to focus",
            body: """
            # Focenda v1.2.0 Release Notes

            - **Release Date:** `2026-08-28`
            - **Target OS:** macOS 14.0+

            ---

            ## What's Changed

            ### Enhancements & Features
            - **Focus history:** See your completed sessions in the dashboard. (`abc123`)
            - Added a [quick calendar preview](https://example.com) for each day.

            ### Bug Fixes & Stability
            - Fixed reminder delivery when the app is already open. (`def456`)

            ---

            ### Installation & Verification
            1. Download the archive.
            2. Run the test suite.

            ### Full Changelog: `v1.1.0...v1.2.0`
            """,
            assets: [asset]
        )
        let update = try XCTUnwrap(AppUpdate(release: release, asset: asset))

        let guide = AppUpdateGuide(update: update)

        XCTAssertEqual(guide.title, "A calmer way to focus")
        XCTAssertEqual(guide.sections.map(\.title), ["Enhancements & Features", "Bug Fixes & Stability"])
        XCTAssertEqual(guide.sections[0].items, [
            "Focus history: See your completed sessions in the dashboard.",
            "Added a quick calendar preview for each day."
        ])
        XCTAssertEqual(guide.sections[1].items, [
            "Fixed reminder delivery when the app is already open."
        ])
    }

    @MainActor
    func testUpdateManagerShowsGuideOnlyAfterMatchingVersionRelaunches() async throws {
        let suiteName = "Focenda.AppUpdateGuideTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let secureStore = SecureStore(defaults: defaults)
        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(
            tagName: "v1.2.0",
            body: """
            ## What's Changed
            ### New
            - A guided tour appears after updating.
            """,
            assets: [asset]
        )
        let update = try XCTUnwrap(AppUpdate(release: release, asset: asset))
        let guide = AppUpdateGuide(update: update)
        let provider = StubUpdateProvider(update: update)
        let manager = AppUpdateManager(
            provider: provider,
            currentReleaseIdentifier: "1.0.0",
            secureStore: secureStore
        )

        XCTAssertNil(manager.completedUpdateGuide)
        _ = await manager.checkForUpdatesNow()
        manager.installAvailableUpdate()

        for _ in 0..<100 where manager.status.isBusy {
            await Task.yield()
        }

        XCTAssertEqual(manager.status, .idle)
        XCTAssertNil(manager.completedUpdateGuide)

        let relaunchedManager = AppUpdateManager(
            provider: provider,
            currentReleaseIdentifier: "v1.2.0",
            secureStore: secureStore
        )
        XCTAssertEqual(relaunchedManager.completedUpdateGuide?.releaseTag, "v1.2.0")
        XCTAssertEqual(relaunchedManager.completedUpdateGuide?.sections.first?.items, [
            "A guided tour appears after updating."
        ])
        XCTAssertEqual(relaunchedManager.lastUpdateGuide, guide)

        relaunchedManager.dismissCompletedUpdateGuide()
        XCTAssertNil(relaunchedManager.completedUpdateGuide)
        XCTAssertEqual(relaunchedManager.lastUpdateGuide, guide)
        XCTAssertNil(secureStore.value(AppUpdateGuide.self, forKey: AppUpdatePreferences.pendingUpdateGuideKey))
        XCTAssertEqual(
            secureStore.value(AppUpdateGuide.self, forKey: AppUpdatePreferences.lastUpdateGuideKey),
            guide
        )

        let replayManager = AppUpdateManager(
            provider: provider,
            currentReleaseIdentifier: "v1.2.0",
            secureStore: secureStore
        )
        XCTAssertNil(replayManager.completedUpdateGuide)
        XCTAssertEqual(replayManager.lastUpdateGuide, guide)
    }

    func testInstallerReplacesOnlyTheCompatibleAppBundle() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("FocendaInstallerTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let installedApp = root.appendingPathComponent("Focenda Staging.app", isDirectory: true)
        let updateApp = root.appendingPathComponent("Focenda Staging Update.app", isDirectory: true)
        let archive = root.appendingPathComponent("Focenda-macOS.zip")
        try makeAppBundle(at: installedApp, releaseTag: "v1.0.0")
        try makeAppBundle(at: updateApp, releaseTag: "v1.2.0")
        try makeArchive(from: updateApp, at: archive)

        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0", assets: [asset])
        let update = try XCTUnwrap(AppUpdate(release: release, asset: asset))
        let installer = AppUpdateInstaller(
            applicationURL: installedApp,
            expectedBundleIdentifier: "com.oomestre.focenda.staging",
            relaunchAfterInstall: false
        )

        try installer.install(update: update, downloadedFile: archive)

        let installedBundle = try XCTUnwrap(Bundle(url: installedApp))
        XCTAssertEqual(installedBundle.bundleIdentifier, "com.oomestre.focenda.staging")
        XCTAssertEqual(installedBundle.object(forInfoDictionaryKey: "FocendaReleaseTag") as? String, "v1.2.0")
    }

    func testInstallerAllowsTheStagingToProductionTransitionWithoutChangingTheDataStore() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("FocendaBundleTransitionTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let installedApp = root.appendingPathComponent("Focenda Staging.app", isDirectory: true)
        let updateApp = root.appendingPathComponent("Focenda.app", isDirectory: true)
        let archive = root.appendingPathComponent("Focenda-macOS.zip")
        try makeAppBundle(
            at: installedApp,
            releaseTag: "v1.0.0",
            bundleIdentifier: "com.oomestre.focenda.staging"
        )
        try makeAppBundle(
            at: updateApp,
            releaseTag: "v1.2.0",
            bundleIdentifier: "com.oomestre.focenda"
        )
        try makeArchive(from: updateApp, at: archive)

        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let update = try XCTUnwrap(AppUpdate(
            release: AppUpdateRelease(tagName: "v1.2.0", assets: [asset]),
            asset: asset
        ))
        let installer = AppUpdateInstaller(
            applicationURL: installedApp,
            expectedBundleIdentifier: "com.oomestre.focenda.staging",
            relaunchAfterInstall: false
        )

        try installer.install(update: update, downloadedFile: archive)

        let installedBundle = try XCTUnwrap(Bundle(url: installedApp))
        XCTAssertEqual(installedBundle.bundleIdentifier, "com.oomestre.focenda")
    }

    func testInstallerAcceptsArchiveWithEmptyReleaseTag() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("FocendaLegacyInstallerTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let installedApp = root.appendingPathComponent("Focenda Staging.app", isDirectory: true)
        let updateApp = root.appendingPathComponent("Focenda Staging Update.app", isDirectory: true)
        let archive = root.appendingPathComponent("Focenda-macOS.zip")
        try makeAppBundle(at: installedApp, releaseTag: "v1.0.0")
        try makeAppBundle(at: updateApp, releaseTag: "", shortVersion: "1.0.1")
        try makeArchive(from: updateApp, at: archive)

        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.0.1/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.0.1", assets: [asset])
        let update = try XCTUnwrap(AppUpdate(release: release, asset: asset))
        let installer = AppUpdateInstaller(
            applicationURL: installedApp,
            expectedBundleIdentifier: "com.oomestre.focenda.staging",
            relaunchAfterInstall: false
        )

        try installer.install(update: update, downloadedFile: archive)

        let installedBundle = try XCTUnwrap(Bundle(url: installedApp))
        XCTAssertEqual(installedBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, "1.0.1")
    }

    func testInstallerRejectsArchiveAboveUncompressedSizeLimit() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("FocendaArchiveSizeTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let installedApp = root.appendingPathComponent("Focenda Staging.app", isDirectory: true)
        let updateApp = root.appendingPathComponent("Focenda Staging Update.app", isDirectory: true)
        let archive = root.appendingPathComponent("Focenda-macOS.zip")
        try makeAppBundle(at: installedApp, releaseTag: "v1.0.0")
        try makeAppBundle(at: updateApp, releaseTag: "v1.2.0")

        let resourcesURL = updateApp.appendingPathComponent("Contents/Resources", isDirectory: true)
        try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 1024).write(to: resourcesURL.appendingPathComponent("large.bin"))
        try makeArchive(from: updateApp, at: archive)

        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0", assets: [asset])
        let update = try XCTUnwrap(AppUpdate(release: release, asset: asset))
        let installer = AppUpdateInstaller(
            applicationURL: installedApp,
            expectedBundleIdentifier: "com.oomestre.focenda.staging",
            relaunchAfterInstall: false,
            archiveLimits: AppUpdateArchiveLimits(maxUncompressedBytes: 128, maxFileCount: 100)
        )

        do {
            try installer.install(update: update, downloadedFile: archive)
            XCTFail("An archive above the uncompressed size limit should be rejected")
        } catch let error as AppUpdateError {
            XCTAssertEqual(error, .archiveTooLarge(limit: 128))
        }

        let installedBundle = try XCTUnwrap(Bundle(url: installedApp))
        XCTAssertEqual(installedBundle.object(forInfoDictionaryKey: "FocendaReleaseTag") as? String, "v1.0.0")
    }

    func testInstallerRejectsArchiveAboveFileCountLimit() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("FocendaArchiveFileCountTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let installedApp = root.appendingPathComponent("Focenda Staging.app", isDirectory: true)
        let updateApp = root.appendingPathComponent("Focenda Staging Update.app", isDirectory: true)
        let archive = root.appendingPathComponent("Focenda-macOS.zip")
        try makeAppBundle(at: installedApp, releaseTag: "v1.0.0")
        try makeAppBundle(at: updateApp, releaseTag: "v1.2.0")
        try makeArchive(from: updateApp, at: archive)

        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0", assets: [asset])
        let update = try XCTUnwrap(AppUpdate(release: release, asset: asset))
        let installer = AppUpdateInstaller(
            applicationURL: installedApp,
            expectedBundleIdentifier: "com.oomestre.focenda.staging",
            relaunchAfterInstall: false,
            archiveLimits: AppUpdateArchiveLimits(maxUncompressedBytes: 10 * 1024 * 1024, maxFileCount: 1)
        )

        do {
            try installer.install(update: update, downloadedFile: archive)
            XCTFail("An archive above the file count limit should be rejected")
        } catch let error as AppUpdateError {
            XCTAssertEqual(error, .archiveTooManyFiles(limit: 1))
        }

        let installedBundle = try XCTUnwrap(Bundle(url: installedApp))
        XCTAssertEqual(installedBundle.object(forInfoDictionaryKey: "FocendaReleaseTag") as? String, "v1.0.0")
    }

    @MainActor
    func testServiceRunsInstallerOffMainThread() async throws {
        let asset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let release = AppUpdateRelease(tagName: "v1.2.0", assets: [asset])
        let update = try XCTUnwrap(AppUpdate(release: release, asset: asset))
        let installer = RecordingUpdateInstaller()
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda"),
            client: StubUpdateClient(releases: [release]),
            installer: installer
        )

        try await service.install(update: update)

        XCTAssertEqual(installer.installedOnMainThread, false)
    }

    private func makeAppBundle(
        at appURL: URL,
        releaseTag: String,
        shortVersion: String? = nil,
        bundleIdentifier: String = "com.oomestre.focenda.staging"
    ) throws {
        let fileManager = FileManager.default
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let executableURL = contentsURL.appendingPathComponent("MacOS/FocendaApp")
        try fileManager.createDirectory(at: executableURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([0x01, 0x02, 0x03]).write(to: executableURL)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableURL.path)

        let info: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleExecutable": "FocendaApp",
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": shortVersion ?? releaseTag.replacingOccurrences(of: "v", with: ""),
            "FocendaReleaseTag": releaseTag
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contentsURL.appendingPathComponent("Info.plist"))
    }

    private func makeArchive(from appURL: URL, at archiveURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--keepParent", appURL.path, archiveURL.path]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
    }

    func testServiceSelectsDMGAssetWhenAvailable() async throws {
        let dmgAsset = AppUpdateAsset(
            name: "Focenda-macOS.dmg",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.dmg"))
        )
        let release = AppUpdateRelease(
            tagName: "v1.2.0",
            assets: [dmgAsset]
        )
        let client = StubUpdateClient(releases: [release])
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda"),
            client: client,
            installer: RecordingUpdateInstaller()
        )

        let result = try await service.checkForUpdates(currentReleaseIdentifier: "1.0.0")
        let update = try XCTUnwrap(result)

        XCTAssertEqual(update.version.description, "1.2.0")
        XCTAssertEqual(update.asset.name, "Focenda-macOS.dmg")
    }

    func testServicePrefersDMGOverZIPWhenBothAvailable() async throws {
        let zipAsset = AppUpdateAsset(
            name: "Focenda-macOS.zip",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.zip"))
        )
        let dmgAsset = AppUpdateAsset(
            name: "Focenda-macOS.dmg",
            downloadURL: try XCTUnwrap(URL(string: "https://github.com/OOMestre/Focenda/releases/download/v1.2.0/Focenda-macOS.dmg"))
        )
        let release = AppUpdateRelease(
            tagName: "v1.2.0",
            assets: [zipAsset, dmgAsset]
        )
        let client = StubUpdateClient(releases: [release])
        let service = AppUpdateService(
            configuration: AppUpdateConfiguration(repositoryOwner: "OOMestre", repositoryName: "Focenda"),
            client: client,
            installer: RecordingUpdateInstaller()
        )

        let result = try await service.checkForUpdates(currentReleaseIdentifier: "1.0.0")
        let update = try XCTUnwrap(result)

        XCTAssertEqual(update.asset.name, "Focenda-macOS.dmg")
    }
}

private final class StubUpdateClient: AppUpdateClient {
    let releases: [AppUpdateRelease]
    let downloadedFile: URL
    private(set) var fetchCount = 0
    private(set) var downloadedURL: URL?

    init(releases: [AppUpdateRelease]) {
        self.releases = releases
        self.downloadedFile = URL(fileURLWithPath: "/tmp/focenda-test-update.zip")
    }

    func fetchReleases() async throws -> [AppUpdateRelease] {
        fetchCount += 1
        return releases
    }

    func downloadAsset(from url: URL) async throws -> URL {
        downloadedURL = url
        return downloadedFile
    }
}

private final class RecordingUpdateInstaller: AppUpdateInstalling {
    private(set) var installedUpdate: AppUpdate?
    private(set) var downloadedFile: URL?
    private(set) var installedOnMainThread: Bool?

    func install(update: AppUpdate, downloadedFile: URL) throws {
        installedUpdate = update
        self.downloadedFile = downloadedFile
        installedOnMainThread = Thread.isMainThread
    }
}

private final class StubUpdateProvider: AppUpdateProviding {
    let update: AppUpdate?

    init(update: AppUpdate?) {
        self.update = update
    }

    func checkForUpdates(currentReleaseIdentifier: String) async throws -> AppUpdate? {
        update
    }

    func install(update: AppUpdate) async throws {}
}

private final class RecordingNotificationManager: NotificationManagerProtocol {
    private(set) var updateVersions: [String] = []

    func requestAuthorization(completion: ((Bool, Error?) -> Void)?) {
        completion?(true, nil)
    }

    func notifySessionCompleted(mode: FocusMode) {}
    func scheduleTaskReminder(task: TaskItem) {}
    func cancelTaskReminder(task: TaskItem) {}
    func scheduleRecurringReminder(reminder: RecurringReminder) {}
    func cancelRecurringReminder(reminder: RecurringReminder) {}
    func notifyUpdateAvailable(version: String) {
        updateVersions.append(version)
    }
}
