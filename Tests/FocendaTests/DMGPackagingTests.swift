import XCTest
import Foundation

final class DMGPackagingTests: XCTestCase {

    func testCreateDmgScriptExistsAndIsExecutable() throws {
        let fileManager = FileManager.default
        let currentFilePath = URL(fileURLWithPath: #file)
        let repositoryRoot = currentFilePath
            .deletingLastPathComponent() // Tests/FocendaTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Root
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/create-dmg.sh")

        XCTAssertTrue(fileManager.fileExists(atPath: scriptURL.path), "scripts/create-dmg.sh must exist")
        XCTAssertTrue(fileManager.isExecutableFile(atPath: scriptURL.path), "scripts/create-dmg.sh must be executable")
    }

    func testCreateDmgScriptFailsGracefullyWithMissingArguments() throws {
        let currentFilePath = URL(fileURLWithPath: #file)
        let repositoryRoot = currentFilePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/create-dmg.sh")

        let process = Process()
        process.executableURL = scriptURL
        process.arguments = []

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        XCTAssertNotEqual(process.terminationStatus, 0, "Script should exit with non-zero code on missing arguments")
    }

    func testStagingBuildUsesStableDesignatedRequirementForAdHocSigning() throws {
        let currentFilePath = URL(fileURLWithPath: #file)
        let repositoryRoot = currentFilePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/build-staging.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("LOCAL_DESIGNATED_REQUIREMENT"))
        XCTAssertTrue(script.contains("--requirements \"$LOCAL_DESIGNATED_REQUIREMENT\""))
    }
}
