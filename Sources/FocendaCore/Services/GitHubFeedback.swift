import Foundation

/// The kinds of feedback that Focenda can route to the GitHub issue tracker.
public enum GitHubFeedbackKind: String, CaseIterable, Identifiable, Sendable {
    case bug
    case suggestion

    public var id: String { rawValue }

    public var buttonTitle: String {
        switch self {
        case .bug:
            return "Report a Bug"
        case .suggestion:
            return "Suggest an Improvement"
        }
    }

    public var buttonSubtitle: String {
        switch self {
        case .bug:
            return "Tell us what went wrong so we can investigate it."
        case .suggestion:
            return "Share an idea that could make Focenda better."
        }
    }

    public var formTitle: String {
        switch self {
        case .bug:
            return "Report a bug"
        case .suggestion:
            return "Suggest an improvement"
        }
    }

    public var formDescription: String {
        switch self {
        case .bug:
            return "Give us a short summary and describe what happened. We will add your Focenda environment automatically."
        case .suggestion:
            return "Tell us about the idea or workflow that would make Focenda more useful for you."
        }
    }

    public var titlePrompt: String {
        switch self {
        case .bug:
            return "Short summary of the problem"
        case .suggestion:
            return "Short summary of your idea"
        }
    }

    public var detailsPrompt: String {
        switch self {
        case .bug:
            return "What happened?"
        case .suggestion:
            return "What would you like to see?"
        }
    }

    public var detailsPlaceholder: String {
        switch self {
        case .bug:
            return "Describe what happened, what you expected, and how we can reproduce it."
        case .suggestion:
            return "Describe the problem, use case, or idea behind your suggestion."
        }
    }

    public var systemImageName: String {
        switch self {
        case .bug:
            return "ladybug.fill"
        case .suggestion:
            return "lightbulb.fill"
        }
    }

    public var githubLabel: String {
        switch self {
        case .bug:
            return "bug"
        case .suggestion:
            return "enhancement"
        }
    }

    public var issueTemplateFileName: String {
        switch self {
        case .bug:
            return "bug_report.md"
        case .suggestion:
            return "suggestion.md"
        }
    }

    public var issueTitlePrefix: String {
        switch self {
        case .bug:
            return "[Bug]"
        case .suggestion:
            return "[Suggestion]"
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .bug:
            return "Report a bug on GitHub"
        case .suggestion:
            return "Suggest an improvement on GitHub"
        }
    }

    public var accessibilityIdentifier: String {
        switch self {
        case .bug:
            return "reportBugButton"
        case .suggestion:
            return "suggestImprovementButton"
        }
    }
}

/// Builds pre-filled GitHub issue URLs without requiring an app-owned GitHub token.
public enum GitHubFeedbackURLBuilder {
    public static let repositoryURL = URL(string: "https://github.com/OOMestre/Focenda")!
    public static let issuesURL = URL(string: "https://github.com/OOMestre/Focenda/issues")!
    public static let newIssueURL = URL(string: "https://github.com/OOMestre/Focenda/issues/new")!
    public static let maxTitleLength = 120
    public static let maxDetailsLength = 2_000

    public static func makeIssueURL(
        for kind: GitHubFeedbackKind,
        title: String,
        details: String,
        appVersion: String = AppRuntime.currentReleaseIdentifier,
        operatingSystem: String? = nil,
        architecture: String? = nil
    ) -> URL {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = String(trimmedTitle.prefix(maxTitleLength))
        let normalizedDetails = String(
            details.trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(maxDetailsLength)
        )
        let issueTitle = normalizedTitle.isEmpty
            ? kind.issueTitlePrefix
            : "\(kind.issueTitlePrefix) \(normalizedTitle)"
        let resolvedOperatingSystem = operatingSystem ?? ProcessInfo.processInfo.operatingSystemVersionString
        let resolvedArchitecture = architecture ?? currentHardwareArchitecture

        var components = URLComponents(url: newIssueURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "template", value: kind.issueTemplateFileName),
            URLQueryItem(name: "title", value: issueTitle),
            URLQueryItem(
                name: "body",
                value: issueBody(
                    for: kind,
                    details: normalizedDetails,
                    appVersion: appVersion,
                    operatingSystem: resolvedOperatingSystem,
                    architecture: resolvedArchitecture
                )
            )
        ]
        return components.url!
    }

    public static var currentHardwareArchitecture: String {
        #if arch(arm64)
        return "Apple Silicon (arm64)"
        #elseif arch(x86_64)
        return "Intel (x86_64)"
        #else
        return "Unknown"
        #endif
    }

    private static func issueBody(
        for kind: GitHubFeedbackKind,
        details: String,
        appVersion: String,
        operatingSystem: String,
        architecture: String
    ) -> String {
        switch kind {
        case .bug:
            return """
            ## What happened?

            \(details)

            ## Steps to reproduce

            <!-- Please add the steps that reproduce the problem, if known. -->

            ## Expected behavior

            <!-- What did you expect Focenda to do? -->

            ## Environment

            - Focenda version: \(appVersion)
            - macOS version: \(operatingSystem)
            - Hardware architecture: \(architecture)
            """
        case .suggestion:
            return """
            ## What would you like to see?

            \(details)

            ## Problem or use case

            <!-- What problem would this solve or what workflow would it improve? -->

            ## Environment (optional)

            - Focenda version: \(appVersion)
            - macOS version: \(operatingSystem)
            - Hardware architecture: \(architecture)
            """
        }
    }
}
