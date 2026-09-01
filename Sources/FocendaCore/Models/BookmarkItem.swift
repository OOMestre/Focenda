import Foundation
import SwiftUI

/// Represents a Quick Link / Focus Hub bookmark item
public struct BookmarkItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var url: String
    public var iconName: String
    public var category: String
    public var createdAt: Date
    public var isPinned: Bool
    public var clickCount: Int

    public init(
        id: UUID = UUID(),
        title: String,
        url: String,
        iconName: String = "globe",
        category: String = "General",
        createdAt: Date = Date(),
        isPinned: Bool = false,
        clickCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.iconName = iconName
        self.category = category
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.clickCount = clickCount
    }

    /// Normalized URL for browser opening (ensures standard web protocol)
    public var validURL: URL? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://" + trimmed)
    }

    /// Clean display domain without protocol prefix or www
    public var displayHost: String {
        guard let valid = validURL, let host = valid.host else {
            return url
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
