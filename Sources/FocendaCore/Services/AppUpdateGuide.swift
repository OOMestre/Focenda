import Foundation

/// A short, user-facing section in the guide shown after an update is installed.
public struct AppUpdateGuideSection: Codable, Equatable, Identifiable, Sendable {
    public let title: String
    public let items: [String]

    public var id: String { title }

    public init(title: String, items: [String]) {
        self.title = title
        self.items = items
    }
}

/// Release notes prepared for the first launch after an in-app update.
public struct AppUpdateGuide: Codable, Equatable, Identifiable, Sendable {
    /// Determines whether the post-update guide and About review flow are enabled.
    public static let isEnabled = true

    public let releaseTag: String
    public let version: String
    public let title: String
    public let sections: [AppUpdateGuideSection]

    public var id: String { releaseTag }

    public init(update: AppUpdate) {
        self.init(
            releaseTag: update.release.tagName,
            version: update.version.description,
            title: update.displayName,
            sections: Self.makeSections(from: update.release.body, updateName: update.displayName)
        )
    }

    public init(
        releaseTag: String,
        version: String,
        title: String,
        sections: [AppUpdateGuideSection]
    ) {
        self.releaseTag = releaseTag
        self.version = version
        self.title = title
        self.sections = sections
    }

    public static func defaultGuide(for currentReleaseIdentifier: String) -> AppUpdateGuide {
        let versionDescription = AppVersion(currentReleaseIdentifier)?.description ?? currentReleaseIdentifier
        let normalizedTag = currentReleaseIdentifier.hasPrefix("v") || currentReleaseIdentifier.hasPrefix("V")
            ? currentReleaseIdentifier
            : "v\(currentReleaseIdentifier)"
        return AppUpdateGuide(
            releaseTag: normalizedTag,
            version: versionDescription,
            title: "Focenda \(versionDescription)",
            sections: [
                AppUpdateGuideSection(
                    title: "Custom Scratchpad Folders",
                    items: [
                        "Create custom folders with selectable SF Symbols and folder organization.",
                        "Safe folder renaming and deletion with automatic note reassignment to prevent data loss."
                    ]
                ),
                AppUpdateGuideSection(
                    title: "GitHub Feedback & Diagnostics",
                    items: [
                        "In-app GitHub feedback flow for reporting bugs and suggesting improvements.",
                        "Pre-filled system and architecture diagnostics for streamlined issue submissions.",
                        "Privacy-preserving feedback that opens directly in your default browser."
                    ]
                )
            ]
        )
    }

    private static func makeSections(from body: String?, updateName: String) -> [AppUpdateGuideSection] {
        guard let body,
              !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallbackSections(for: updateName)
        }

        let lines = body.components(separatedBy: .newlines)
        let hasChangesHeading = lines.contains { line in
            guard let heading = headingParts(from: line)?.title else { return false }
            return isChangesHeading(heading)
        }

        var sections: [AppUpdateGuideSection] = []
        var currentTitle: String?
        var currentItems: [String] = []
        var startedChanges = !hasChangesHeading
        var ignoredSection = false
        var insideCodeFence = false

        func flushCurrentSection() {
            guard let title = currentTitle,
                  !ignoredSection,
                  !currentItems.isEmpty else {
                currentTitle = nil
                currentItems = []
                return
            }

            sections.append(AppUpdateGuideSection(title: title, items: currentItems))
            currentTitle = nil
            currentItems = []
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if line.hasPrefix("```") {
                insideCodeFence.toggle()
                continue
            }
            guard !insideCodeFence else { continue }

            if let heading = headingParts(from: line) {
                flushCurrentSection()

                if heading.level == 2, isChangesHeading(heading.title) {
                    startedChanges = true
                    ignoredSection = false
                    continue
                }

                guard startedChanges else { continue }

                ignoredSection = isIgnoredHeading(heading.title)
                if !ignoredSection {
                    currentTitle = cleanMarkdown(heading.title)
                }
                continue
            }

            guard startedChanges, !ignoredSection else { continue }
            guard !line.isEmpty, !isReleaseMetadata(line) else { continue }

            if let item = listItem(from: line) {
                if currentTitle == nil {
                    currentTitle = "Highlights"
                }
                if let cleanedItem = cleanMarkdown(item), !cleanedItem.isEmpty {
                    currentItems.append(cleanedItem)
                }
            } else if currentTitle != nil,
                      !line.hasPrefix("---"),
                      let paragraph = cleanMarkdown(line),
                      !paragraph.isEmpty {
                currentItems.append(paragraph)
            }
        }

        flushCurrentSection()

        return sections.isEmpty ? fallbackSections(for: updateName) : sections
    }

    private static func fallbackSections(for updateName: String) -> [AppUpdateGuideSection] {
        [
            AppUpdateGuideSection(
                title: "Highlights",
                items: ["Enjoy the latest improvements in \(updateName)."]
            )
        ]
    }

    private static func headingParts(from line: String) -> (level: Int, title: String)? {
        let prefix = line.prefix { $0 == "#" }
        guard prefix.count >= 2 else { return nil }

        let title = line.drop(while: { $0 == "#" })
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        return (prefix.count, title)
    }

    private static func listItem(from line: String) -> String? {
        let unorderedPrefixes = ["- ", "* ", "+ "]
        if let prefix = unorderedPrefixes.first(where: { line.hasPrefix($0) }) {
            return String(line.dropFirst(prefix.count))
        }

        let characters = Array(line)
        guard let dotIndex = characters.firstIndex(of: "."),
              dotIndex > 0,
              characters[..<dotIndex].allSatisfy({ $0.isNumber }),
              characters.indices.contains(dotIndex + 1),
              characters[dotIndex + 1] == " " else {
            return nil
        }
        return String(characters[(dotIndex + 2)...])
    }

    private static func isChangesHeading(_ title: String) -> Bool {
        let normalized = title.lowercased()
        return normalized.contains("what's changed")
            || normalized.contains("what’s changed")
            || normalized == "changes"
            || normalized == "highlights"
            || normalized == "release highlights"
    }

    private static func isIgnoredHeading(_ title: String) -> Bool {
        let normalized = title.lowercased()
        return normalized.contains("installation")
            || normalized.contains("verification")
            || normalized.contains("full changelog")
            || normalized.contains("commit log")
            || normalized.contains("technical details")
    }

    private static func isReleaseMetadata(_ line: String) -> Bool {
        let normalized = line.lowercased()
        let metadataLabels = [
            "**release date:**",
            "**release stage:**",
            "**commit range:**",
            "**total commits included:**",
            "**target os:**"
        ]
        return metadataLabels.contains { normalized.hasPrefix($0) }
    }

    private static func cleanMarkdown(_ value: String) -> String? {
        var cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        cleaned = cleaned.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^\)]+\)"#,
            with: "$1",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")
        cleaned = cleaned.replacingOccurrences(
            of: #"\s+\([^\)]*`[^`]+`[^\)]*\)$"#,
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(of: "`", with: "")
        cleaned = cleaned
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        return cleaned.isEmpty ? nil : cleaned
    }
}
