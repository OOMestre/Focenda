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

    /// A fresh installation starts without any preconfigured quick links.
    public static let defaultLinks: [QuickLink] = []
}
