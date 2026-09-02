import XCTest
@testable import FocendaCore

final class BookmarkViewModelTests: XCTestCase {

    var testDefaults: UserDefaults!
    private let testKey = "test_focenda_bookmarks_isolated"

    private var fixtureBookmarks: [BookmarkItem] {
        [
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
                clickCount: 5
            ),
            BookmarkItem(
                title: "Brain.fm Focus Audio",
                url: "https://brain.fm",
                iconName: "headphones",
                category: "Focus & Flow",
                clickCount: 7
            ),
            BookmarkItem(
                title: "Lofi Cafe Stream",
                url: "https://lofi.cafe",
                iconName: "music.note",
                category: "Focus & Flow",
                clickCount: 4
            ),
            BookmarkItem(
                title: "Excalidraw Whiteboard",
                url: "https://excalidraw.com",
                iconName: "pencil.and.ruler.fill",
                category: "Design & UI",
                clickCount: 3
            ),
            BookmarkItem(
                title: "Raycast Store & Script Commands",
                url: "https://www.raycast.com/store",
                iconName: "command",
                category: "Utilities",
                clickCount: 2
            )
        ]
    }

    private func populatedViewModel() -> BookmarkViewModel {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.bookmarks = fixtureBookmarks
        viewModel.saveToUserDefaults()
        return viewModel
    }

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults.standard
        testDefaults.removeObject(forKey: testKey)
        testDefaults.removeObject(forKey: BookmarkViewModel.userDefaultsKey)
        testDefaults.removeObject(forKey: BookmarkViewModel.legacyQuickLinksStorageKey)
    }

    override func tearDown() {
        testDefaults.removeObject(forKey: testKey)
        testDefaults.removeObject(forKey: BookmarkViewModel.userDefaultsKey)
        testDefaults.removeObject(forKey: BookmarkViewModel.legacyQuickLinksStorageKey)
        testDefaults = nil
        super.tearDown()
    }

    func testInitializationStartsEmpty() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)

        XCTAssertTrue(viewModel.bookmarks.isEmpty)
        XCTAssertTrue(BookmarkViewModel.defaultBookmarks.isEmpty)
        XCTAssertEqual(viewModel.selectedCategory, "All")
    }

    func testAddBookmark() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        let initialCount = viewModel.bookmarks.count

        let newBookmark = viewModel.addBookmark(
            title: "PostgreSQL Docs",
            url: "https://www.postgresql.org/docs/",
            iconName: "server.rack",
            category: "Documentation",
            isPinned: true
        )

        XCTAssertEqual(viewModel.bookmarks.count, initialCount + 1)
        XCTAssertEqual(newBookmark.title, "PostgreSQL Docs")
        XCTAssertEqual(newBookmark.category, "Documentation")
        XCTAssertTrue(newBookmark.isPinned)
        XCTAssertEqual(newBookmark.clickCount, 0)

        // Check persistence
        let viewModel2 = BookmarkViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.bookmarks.count, initialCount + 1)
        XCTAssertEqual(viewModel2.bookmarks.first?.title, "PostgreSQL Docs")
    }

    func testAddBookmarkWithBlankTitleAndCategory() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)

        let item1 = viewModel.addBookmark(
            title: "   ",
            url: "https://example.com/api",
            category: "  "
        )
        XCTAssertEqual(item1.title, "https://example.com/api")
        XCTAssertEqual(item1.category, "General")
        XCTAssertEqual(item1.iconName, "globe")

        let item2 = viewModel.addBookmark(
            title: "",
            url: "   ",
            category: ""
        )
        XCTAssertEqual(item2.title, "Quick Link")
        XCTAssertEqual(item2.category, "General")
    }

    func testUpdateBookmark() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        var firstBookmark = viewModel.addBookmark(
            title: "Original Title",
            url: "https://original.org",
            category: "General"
        )

        firstBookmark.title = "Updated Title"
        firstBookmark.url = "https://updated.org"
        firstBookmark.category = "Utilities"
        viewModel.updateBookmark(firstBookmark)

        XCTAssertEqual(viewModel.bookmarks.first?.title, "Updated Title")
        XCTAssertEqual(viewModel.bookmarks.first?.url, "https://updated.org")
        XCTAssertEqual(viewModel.bookmarks.first?.category, "Utilities")

        let viewModel2 = BookmarkViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.bookmarks.first?.title, "Updated Title")
    }

    func testDeleteBookmark() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.addBookmark(title: "Bookmark to Delete", url: "https://delete.example")
        let initialCount = viewModel.bookmarks.count
        guard let first = viewModel.bookmarks.first else {
            XCTFail("Expected bookmark")
            return
        }

        viewModel.selectedBookmarkId = first.id
        viewModel.deleteBookmark(id: first.id)
        XCTAssertEqual(viewModel.bookmarks.count, initialCount - 1)
        XCTAssertNil(viewModel.bookmarks.first(where: { $0.id == first.id }))
        XCTAssertNil(viewModel.selectedBookmarkId)

        let viewModel2 = BookmarkViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.bookmarks.count, initialCount - 1)
    }

    func testDeleteBookmarkItemInstance() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.addBookmark(title: "Bookmark to Delete", url: "https://delete.example")
        let initialCount = viewModel.bookmarks.count
        guard let first = viewModel.bookmarks.first else {
            XCTFail("Expected bookmark")
            return
        }

        viewModel.deleteBookmark(first)
        XCTAssertEqual(viewModel.bookmarks.count, initialCount - 1)
    }

    func testTogglePin() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.addBookmark(title: "Bookmark to Pin", url: "https://pin.example")
        guard let unpinnedBookmark = viewModel.bookmarks.first(where: { !$0.isPinned }) else {
            XCTFail("Expected unpinned bookmark")
            return
        }

        viewModel.togglePin(for: unpinnedBookmark)
        let updated = viewModel.bookmarks.first(where: { $0.id == unpinnedBookmark.id })
        XCTAssertTrue(updated?.isPinned == true)

        let pinnedList = viewModel.filteredBookmarks.filter { $0.isPinned }
        XCTAssertTrue(pinnedList.contains(where: { $0.id == unpinnedBookmark.id }))
    }

    func testOpenBookmarkIncrementsClickCount() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.addBookmark(title: "Bookmark to Open", url: "https://open.example")
        guard let target = viewModel.bookmarks.first else {
            XCTFail("Expected bookmark")
            return
        }

        let initialClicks = target.clickCount
        viewModel.openBookmark(target, openInBrowser: false)

        let updated = viewModel.bookmarks.first(where: { $0.id == target.id })
        XCTAssertEqual(updated?.clickCount, initialClicks + 1)
    }

    func testFilterBookmarksByCategory() {
        let viewModel = populatedViewModel()

        viewModel.selectedCategory = "Documentation"
        XCTAssertEqual(viewModel.filteredBookmarks.count, 2)
        for bookmark in viewModel.filteredBookmarks {
            XCTAssertEqual(bookmark.category, "Documentation")
        }

        viewModel.selectedCategory = "Focus & Flow"
        XCTAssertEqual(viewModel.filteredBookmarks.count, 2)
        for bookmark in viewModel.filteredBookmarks {
            XCTAssertEqual(bookmark.category, "Focus & Flow")
        }

        viewModel.selectedCategory = "All"
        XCTAssertEqual(viewModel.filteredBookmarks.count, 8)
    }

    func testSearchBookmarks() {
        let viewModel = populatedViewModel()

        viewModel.searchQuery = "GitHub"
        XCTAssertEqual(viewModel.filteredBookmarks.count, 1)
        XCTAssertEqual(viewModel.filteredBookmarks.first?.title, "GitHub Repositories")

        viewModel.searchQuery = "brain.fm"
        XCTAssertEqual(viewModel.filteredBookmarks.count, 1)
        XCTAssertEqual(viewModel.filteredBookmarks.first?.title, "Brain.fm Focus Audio")

        viewModel.searchQuery = "nonexistentquery123"
        XCTAssertTrue(viewModel.filteredBookmarks.isEmpty)
    }

    func testSearchByUrlAndHostAndCategory() {
        let viewModel = populatedViewModel()

        viewModel.searchQuery = "developer.apple.com"
        XCTAssertEqual(viewModel.filteredBookmarks.count, 2)

        viewModel.searchQuery = "lofi.cafe"
        XCTAssertEqual(viewModel.filteredBookmarks.count, 1)
        XCTAssertEqual(viewModel.filteredBookmarks.first?.title, "Lofi Cafe Stream")

        viewModel.searchQuery = "Utilities"
        XCTAssertEqual(viewModel.filteredBookmarks.count, 1)
        XCTAssertEqual(viewModel.filteredBookmarks.first?.title, "Raycast Store & Script Commands")
    }

    func testSortingPinnedAndClicks() {
        let viewModel = populatedViewModel()
        viewModel.selectedCategory = "All"
        viewModel.searchQuery = ""

        let filtered = viewModel.filteredBookmarks
        XCTAssertFalse(filtered.isEmpty)

        // All pinned items must come before any unpinned items
        var seenUnpinned = false
        for bookmark in filtered {
            if bookmark.isPinned {
                XCTAssertFalse(seenUnpinned, "Pinned bookmark appeared after an unpinned bookmark")
            } else {
                seenUnpinned = true
            }
        }
    }

    func testValidURLAndDisplayHost() {
        let item1 = BookmarkItem(title: "Test", url: "https://swift.org/blog/")
        XCTAssertEqual(item1.validURL?.absoluteString, "https://swift.org/blog/")
        XCTAssertEqual(item1.displayHost, "swift.org")

        let item2 = BookmarkItem(title: "Test2", url: "www.google.com/search")
        XCTAssertEqual(item2.validURL?.absoluteString, "https://www.google.com/search")
        XCTAssertEqual(item2.displayHost, "google.com")

        let item3 = BookmarkItem(title: "Test3", url: "http://example.com")
        XCTAssertEqual(item3.validURL?.absoluteString, "http://example.com")
        XCTAssertEqual(item3.displayHost, "example.com")
    }

    func testResetToDefaults() {
        let viewModel = BookmarkViewModel(userDefaults: testDefaults)
        viewModel.addBookmark(title: "User Link", url: "https://example.com")
        XCTAssertEqual(viewModel.bookmarks.count, 1)

        viewModel.resetToDefaults()
        XCTAssertTrue(viewModel.bookmarks.isEmpty)
    }

    func testExplicitlySavedEmptyBookmarkListRemainsEmptyAfterReload() throws {
        let emptyBookmarks = try JSONEncoder().encode([BookmarkItem]())
        testDefaults.set(emptyBookmarks, forKey: BookmarkViewModel.userDefaultsKey)

        let viewModel = BookmarkViewModel(userDefaults: testDefaults)

        XCTAssertTrue(viewModel.bookmarks.isEmpty)
    }

    func testLegacyMenuBarQuickLinksAreMigratedIntoSharedBookmarks() throws {
        let legacyID = UUID()
        let legacyLink = QuickLink(
            id: legacyID,
            title: "Legacy Link",
            urlString: "https://legacy.example",
            iconName: "link"
        )
        testDefaults.set(
            try JSONEncoder().encode([legacyLink]),
            forKey: BookmarkViewModel.legacyQuickLinksStorageKey
        )

        let viewModel = BookmarkViewModel(userDefaults: testDefaults)

        XCTAssertEqual(viewModel.bookmarks.count, 1)
        XCTAssertEqual(viewModel.bookmarks.first?.id, legacyID)
        XCTAssertEqual(viewModel.bookmarks.first?.title, "Legacy Link")
        XCTAssertEqual(viewModel.bookmarks.first?.url, "https://legacy.example")

        let reloadedViewModel = BookmarkViewModel(userDefaults: testDefaults)
        XCTAssertEqual(reloadedViewModel.bookmarks, viewModel.bookmarks)
    }

    func testExplicitBookmarkListTakesPrecedenceOverLegacyMenuBarLinks() throws {
        let savedBookmarks = [BookmarkItem(title: "Current Link", url: "https://current.example")]
        let legacyLink = QuickLink(title: "Legacy Link", urlString: "https://legacy.example")
        testDefaults.set(
            try JSONEncoder().encode(savedBookmarks),
            forKey: BookmarkViewModel.userDefaultsKey
        )
        testDefaults.set(
            try JSONEncoder().encode([legacyLink]),
            forKey: BookmarkViewModel.legacyQuickLinksStorageKey
        )

        let viewModel = BookmarkViewModel(userDefaults: testDefaults)

        XCTAssertEqual(viewModel.bookmarks, savedBookmarks)
    }

    func testCategoryCountsAndAllCategories() {
        let viewModel = populatedViewModel()
        XCTAssertEqual(viewModel.categoryCount(for: "All"), 8)
        XCTAssertEqual(viewModel.categoryCount(for: "Development"), 1)
        XCTAssertEqual(viewModel.categoryCount(for: "Documentation"), 2)

        viewModel.addBookmark(title: "Custom Link", url: "https://custom.xyz", category: "DevOps")
        XCTAssertTrue(viewModel.allCategories.contains("DevOps"))
        XCTAssertEqual(viewModel.categoryCount(for: "DevOps"), 1)
    }

    func testBookmarkPresetCategoryEnumeration() {
        let categories = BookmarkPresetCategory.allCases
        XCTAssertEqual(categories.count, 7)

        for category in categories {
            XCTAssertEqual(category.id, category.rawValue)
            XCTAssertFalse(category.iconName.isEmpty)
        }

        XCTAssertEqual(BookmarkPresetCategory.all.iconName, "square.grid.2x2")
        XCTAssertEqual(BookmarkPresetCategory.focus.iconName, "brain.head.profile")
        XCTAssertEqual(BookmarkPresetCategory.dev.iconName, "chevron.left.forwardslash.chevron.right")
        XCTAssertEqual(BookmarkPresetCategory.docs.iconName, "book.closed.fill")
        XCTAssertEqual(BookmarkPresetCategory.design.iconName, "paintpalette.fill")
        XCTAssertEqual(BookmarkPresetCategory.reference.iconName, "bookmark.fill")
        XCTAssertEqual(BookmarkPresetCategory.utilities.iconName, "wrench.and.screwdriver.fill")
    }
}
