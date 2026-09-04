import XCTest
import SwiftUI
@testable import FocendaCore

final class SupportViewTests: XCTestCase {

    func testSupportTabIsAvailableInNavigation() {
        XCTAssertTrue(AppTab.allCases.contains(.support))
        XCTAssertEqual(AppTab.support.rawValue, "Support")
        XCTAssertEqual(AppTab.support.iconName, "heart.fill")
    }

    func testSupportURLPointsToBuyMeACoffee() {
        XCTAssertEqual(SupportView.supportURL.absoluteString, "https://buymeacoffee.com/omestre")
    }

    func testGitHubURLPointsToFocendaRepository() {
        XCTAssertEqual(SupportView.githubURL.absoluteString, "https://github.com/OOMestre/Focenda")
    }

    func testFeedbackKindsUseDistinctGitHubTemplatesAndLabels() {
        XCTAssertEqual(GitHubFeedbackKind.bug.issueTemplateFileName, "bug_report.md")
        XCTAssertEqual(GitHubFeedbackKind.bug.githubLabel, "bug")
        XCTAssertEqual(GitHubFeedbackKind.bug.issueTitlePrefix, "[Bug]")

        XCTAssertEqual(GitHubFeedbackKind.suggestion.issueTemplateFileName, "suggestion.md")
        XCTAssertEqual(GitHubFeedbackKind.suggestion.githubLabel, "enhancement")
        XCTAssertEqual(GitHubFeedbackKind.suggestion.issueTitlePrefix, "[Suggestion]")
    }

    func testBugIssueURLIsPreFilledWithClassificationAndEnvironment() {
        let url = GitHubFeedbackURLBuilder.makeIssueURL(
            for: .bug,
            title: "Timer stops & resets",
            details: "The timer resets after waking the Mac.",
            appVersion: "v1.1.0",
            operatingSystem: "macOS 15.6",
            architecture: "Apple Silicon"
        )

        XCTAssertEqual(url.host, "github.com")
        XCTAssertEqual(url.path, "/OOMestre/Focenda/issues/new")
        XCTAssertEqual(queryValue("template", in: url), "bug_report.md")
        XCTAssertNil(queryValue("labels", in: url))
        XCTAssertEqual(queryValue("title", in: url), "[Bug] Timer stops & resets")

        let body = queryValue("body", in: url)
        XCTAssertTrue(body?.contains("The timer resets after waking the Mac.") == true)
        XCTAssertTrue(body?.contains("Focenda version: v1.1.0") == true)
        XCTAssertTrue(body?.contains("macOS version: macOS 15.6") == true)
        XCTAssertTrue(body?.contains("Hardware architecture: Apple Silicon") == true)
    }

    func testSuggestionIssueURLUsesSuggestionClassification() {
        let url = GitHubFeedbackURLBuilder.makeIssueURL(
            for: .suggestion,
            title: "Add weekly focus goals",
            details: "A weekly view would help me plan realistic focus time.",
            appVersion: "1.1.0",
            operatingSystem: "macOS 14.5",
            architecture: "Intel"
        )

        XCTAssertEqual(queryValue("template", in: url), "suggestion.md")
        XCTAssertNil(queryValue("labels", in: url))
        XCTAssertEqual(queryValue("title", in: url), "[Suggestion] Add weekly focus goals")
        XCTAssertTrue(queryValue("body", in: url)?.contains("A weekly view would help me plan realistic focus time.") == true)
    }

    func testIssueURLBoundsLongInputForGitHubPrefill() {
        let url = GitHubFeedbackURLBuilder.makeIssueURL(
            for: .bug,
            title: String(repeating: "T", count: GitHubFeedbackURLBuilder.maxTitleLength + 20),
            details: String(repeating: "D", count: GitHubFeedbackURLBuilder.maxDetailsLength + 20),
            appVersion: "1.1.0",
            operatingSystem: "macOS 14.5",
            architecture: "Intel"
        )

        XCTAssertEqual(
            queryValue("title", in: url),
            "[Bug] \(String(repeating: "T", count: GitHubFeedbackURLBuilder.maxTitleLength))"
        )
        let body = queryValue("body", in: url) ?? ""
        XCTAssertTrue(body.contains(String(repeating: "D", count: GitHubFeedbackURLBuilder.maxDetailsLength)))
        XCTAssertFalse(body.contains(String(repeating: "D", count: GitHubFeedbackURLBuilder.maxDetailsLength + 1)))
    }

    func testFeedbackFormViewInitialization() {
        let bugForm = GitHubFeedbackFormView(kind: .bug)
        let suggestionForm = GitHubFeedbackFormView(kind: .suggestion)

        XCTAssertEqual(bugForm.kind, .bug)
        XCTAssertEqual(suggestionForm.kind, .suggestion)
        XCTAssertNotNil(bugForm.body)
        XCTAssertNotNil(suggestionForm.body)
    }

    func testSupportViewInitialization() {
        let supportView = SupportView()

        XCTAssertNotNil(supportView)
        XCTAssertNotNil(supportView.body)
    }

    func testSupportViewRendersWithEveryTheme() {
        let originalTheme = AppTheme.current
        defer { AppTheme.current = originalTheme }

        for theme in AppThemeOption.allCases {
            AppTheme.current = theme
            let supportView = SupportView()

            XCTAssertNotNil(supportView.body)
        }
    }

    private func queryValue(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }
}
