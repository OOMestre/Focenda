import Foundation
import SwiftUI
import Observation
import AppKit

/// Default categories for Focus Hub bookmarks
public enum BookmarkPresetCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case focus = "Focus & Flow"
    case dev = "Development"
    case docs = "Documentation"
    case design = "Design & UI"
    case reference = "Reference"
    case utilities = "Utilities"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .focus: return "brain.head.profile"
        case .dev: return "chevron.left.forwardslash.chevron.right"
        case .docs: return "book.closed.fill"
        case .design: return "paintpalette.fill"
        case .reference: return "bookmark.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        }
    }
}

/// Manages quick reference links and focus bookmarks with persistence and 1-click browser launching
@Observable
public final class BookmarkViewModel {
    public static let userDefaultsKey = "focenda_bookmarks"

    public var bookmarks: [BookmarkItem] = []
    public var searchQuery: String = ""
    public var selectedCategory: String = "All"
    public var selectedBookmarkId: UUID?

    private let secureStore: SecureStore

    public init(userDefaults: UserDefaults = .standard, secureStore: SecureStore? = nil) {
        self.secureStore = secureStore ?? SecureStore(defaults: userDefaults)
        loadFromUserDefaults()
    }

    /// Pre-populated default bookmarks for developer focus and productivity
    public static let defaultBookmarks: [BookmarkItem] = [
        BookmarkItem(
            title: "Apple Developer Documentation",
            url: "https://developer.apple.com/documentation",
            iconName: "apple.logo",
            category: "Documentation",
            isPinned: true,
            clickCount: 12
        ),
        BookmarkItem(
            title: "Swift.org Reference",
            url: "https://www.swift.org/documentation/",
            iconName: "swift",
            category: "Documentation",
            isPinned: true,
            clickCount: 9
        ),
        BookmarkItem(
            title: "GitHub Repositories",
            url: "https://github.com",
            iconName: "chevron.left.forwardslash.chevron.right",
            category: "Development",
            isPinned: true,
            clickCount: 15
        ),
        BookmarkItem(
            title: "Human Interface Guidelines",
            url: "https://developer.apple.com/design/human-interface-guidelines",
            iconName: "macwindow.on.rectangle",
            category: "Design & UI",
            isPinned: false,
            clickCount: 5
        ),
        BookmarkItem(
            title: "Brain.fm Focus Audio",
            url: "https://brain.fm",
            iconName: "headphones",
            category: "Focus & Flow",
            isPinned: false,
            clickCount: 7
        ),
        BookmarkItem(
            title: "Lofi Cafe Stream",
            url: "https://lofi.cafe",
            iconName: "music.note",
            category: "Focus & Flow",
            isPinned: false,
            clickCount: 4
        ),
        BookmarkItem(
            title: "Excalidraw Whiteboard",
            url: "https://excalidraw.com",
            iconName: "pencil.and.ruler.fill",
            category: "Design & UI",
            isPinned: false,
            clickCount: 3
        ),
        BookmarkItem(
            title: "Raycast Store & Script Commands",
            url: "https://www.raycast.com/store",
            iconName: "command",
            category: "Utilities",
            isPinned: false,
            clickCount: 2
        )
    ]

    /// Dynamic list of all available categories including presets and custom ones
    public var allCategories: [String] {
        var categories = ["All", "Focus & Flow", "Development", "Documentation", "Design & UI", "Reference", "Utilities"]
        for bookmark in bookmarks {
            let cat = bookmark.category.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cat.isEmpty && !categories.contains(where: { $0.caseInsensitiveCompare(cat) == .orderedSame }) {
                categories.append(cat)
            }
        }
        return categories
    }

    /// Number of bookmarks matching a specific category
    public func categoryCount(for category: String) -> Int {
        if category == "All" {
            return bookmarks.count
        }
        return bookmarks.filter { $0.category.caseInsensitiveCompare(category) == .orderedSame }.count
    }

    /// Filtered and sorted bookmarks
    public var filteredBookmarks: [BookmarkItem] {
        bookmarks.filter { bookmark in
            let matchesCategory: Bool
            if selectedCategory == "All" {
                matchesCategory = true
            } else {
                matchesCategory = bookmark.category.caseInsensitiveCompare(selectedCategory) == .orderedSame
            }

            let matchesSearch: Bool
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchQuery.lowercased()
                matchesSearch = bookmark.title.lowercased().contains(query) ||
                    bookmark.url.lowercased().contains(query) ||
                    bookmark.displayHost.lowercased().contains(query) ||
                    bookmark.category.lowercased().contains(query)
            }

            return matchesCategory && matchesSearch
        }
        .sorted { (lhs: BookmarkItem, rhs: BookmarkItem) -> Bool in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            if lhs.clickCount != rhs.clickCount {
                return lhs.clickCount > rhs.clickCount
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    /// Adds a new bookmark item
    @discardableResult
    public func addBookmark(
        title: String,
        url: String,
        iconName: String = "globe",
        category: String = "General",
        isPinned: Bool = false
    ) -> BookmarkItem {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCat = category.trimmingCharacters(in: .whitespacesAndNewlines)

        let newBookmark = BookmarkItem(
            title: cleanTitle.isEmpty ? (cleanUrl.isEmpty ? "Quick Link" : cleanUrl) : cleanTitle,
            url: cleanUrl,
            iconName: iconName.isEmpty ? "globe" : iconName,
            category: cleanCat.isEmpty ? "General" : cleanCat,
            isPinned: isPinned
        )

        bookmarks.insert(newBookmark, at: 0)
        saveToUserDefaults()
        return newBookmark
    }

    /// Updates an existing bookmark item
    public func updateBookmark(_ bookmark: BookmarkItem) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index] = bookmark
            saveToUserDefaults()
        }
    }

    /// Deletes a bookmark by ID
    public func deleteBookmark(id: UUID) {
        bookmarks.removeAll(where: { $0.id == id })
        if selectedBookmarkId == id {
            selectedBookmarkId = nil
        }
        saveToUserDefaults()
    }

    /// Deletes a bookmark item
    public func deleteBookmark(_ bookmark: BookmarkItem) {
        deleteBookmark(id: bookmark.id)
    }

    /// Toggles the pinned status of a bookmark
    public func togglePin(for bookmark: BookmarkItem) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index].isPinned.toggle()
            saveToUserDefaults()
        }
    }

    /// Increments visit click count and optionally opens the URL in default browser
    public func openBookmark(_ bookmark: BookmarkItem, openInBrowser: Bool = true) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index].clickCount += 1
            saveToUserDefaults()
        }

        let isRunningInTest = NSClassFromString("XCTestCase") != nil ||
                              NSClassFromString("XCTest") != nil ||
                              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                              ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
                              ProcessInfo.processInfo.arguments.contains(where: { $0.contains("xctest") || $0.contains("test") })

        if openInBrowser && !isRunningInTest, let validURL = bookmark.validURL {
            NSWorkspace.shared.open(validURL)
        }
    }

    /// Resets bookmarks back to default preset list
    public func resetToDefaults() {
        self.bookmarks = Self.defaultBookmarks
        self.selectedCategory = "All"
        self.searchQuery = ""
        saveToUserDefaults()
    }

    /// Loads bookmarks from persistent storage or initializes default seed
    public func loadFromUserDefaults() {
        if let data = secureStore.data(forKey: Self.userDefaultsKey),
           let decoded = try? JSONDecoder().decode([BookmarkItem].self, from: data),
           !decoded.isEmpty {
            self.bookmarks = decoded
        } else {
            self.bookmarks = Self.defaultBookmarks
        }
    }

    /// Saves bookmarks to persistent storage
    public func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            secureStore.setData(data, forKey: Self.userDefaultsKey)
        }
    }
}
