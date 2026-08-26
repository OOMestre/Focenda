import Foundation

/// Represents a quick-launch bookmark link in the Menu Bar Control Center
public struct QuickLink: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var urlString: String
    public var iconName: String

    public init(
        id: UUID = UUID(),
        title: String,
        urlString: String,
        iconName: String = "link"
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.iconName = iconName
    }

    public var url: URL? {
        URL(string: urlString)
    }

    public static let defaultLinks: [QuickLink] = [
        QuickLink(title: "GitHub", urlString: "https://github.com", iconName: "chevron.left.forwardslash.chevron.right"),
        QuickLink(title: "Notion", urlString: "https://notion.so", iconName: "doc.text"),
        QuickLink(title: "Linear", urlString: "https://linear.app", iconName: "target"),
        QuickLink(title: "Calendar", urlString: "https://calendar.google.com", iconName: "calendar"),
        QuickLink(title: "Figma", urlString: "https://figma.com", iconName: "paintbrush.pointed")
    ]
}
