import SwiftUI
import AppKit

/// Layout thresholds for the Focus Hub that keep every interactive control reachable in narrow detail panes.
enum BookmarksResponsiveLayout {
    static let compactControlsWidth: CGFloat = 580
    static let regularHorizontalPadding: CGFloat = 20
    static let compactHorizontalPadding: CGFloat = 12
    static let bookmarkColumnMaximumWidth: CGFloat = 320

    static func horizontalPadding(for availableWidth: CGFloat) -> CGFloat {
        availableWidth < compactControlsWidth ? compactHorizontalPadding : regularHorizontalPadding
    }

    /// Flexible grid columns avoid giving the detail pane an artificial minimum
    /// width. The split view can therefore shrink before each card switches to
    /// its compact actions.
    static func bookmarkGridColumns(for availableWidth: CGFloat, horizontalPadding: CGFloat) -> [GridItem] {
        let contentWidth = max(0, availableWidth - (horizontalPadding * 2))
        let columnCount: Int

        switch contentWidth {
        case 660...:
            columnCount = 3
        case 400...:
            columnCount = 2
        default:
            columnCount = 1
        }

        return Array(
            repeating: GridItem(.flexible(minimum: 0, maximum: bookmarkColumnMaximumWidth), spacing: 14),
            count: columnCount
        )
    }

    static func statisticsGridColumns(for availableWidth: CGFloat, horizontalPadding: CGFloat) -> [GridItem] {
        let contentWidth = max(0, availableWidth - (horizontalPadding * 2))
        let columnCount: Int

        switch contentWidth {
        case 480...:
            columnCount = 3
        case 280...:
            columnCount = 2
        default:
            columnCount = 1
        }

        return Array(
            repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 12),
            count: columnCount
        )
    }
}

public struct BookmarksView: View {
    @Bindable var viewModel: BookmarkViewModel
    @State private var showingAddSheet = false
    @State private var editingBookmark: BookmarkItem?
    @State private var copiedBookmarkId: UUID?
    @State private var bookmarkToDelete: BookmarkItem?

    // Add / Edit form fields
    @State private var formTitle: String = ""
    @State private var formUrl: String = ""
    @State private var formCategory: String = "General"
    @State private var formIconName: String = "globe"
    @State private var formIsPinned: Bool = false

    private let availableIcons = [
        "globe", "link", "apple.logo", "swift", "chevron.left.forwardslash.chevron.right",
        "book.closed.fill", "macwindow.on.rectangle", "paintpalette.fill", "headphones",
        "music.note", "pencil.and.ruler.fill", "command", "terminal.fill", "cpu",
        "sparkles", "chart.line.uptrend.xyaxis", "bolt.fill", "folder.fill", "tray.full.fill"
    ]

    public init(viewModel: BookmarkViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let horizontalPadding = BookmarksResponsiveLayout.horizontalPadding(for: availableWidth)
            let contentWidth = max(0, availableWidth - (horizontalPadding * 2))

            VStack(spacing: 0) {
                headerBar(availableWidth: availableWidth)

                Divider()

                // Keep the page vertically scrollable. The category filter wraps naturally with FlowLayout.
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 20) {
                        categoryFilterSection(contentWidth: contentWidth)

                        statsBannerSection(
                            availableWidth: availableWidth,
                            horizontalPadding: horizontalPadding
                        )

                        if viewModel.filteredBookmarks.isEmpty {
                            emptyStateView(availableWidth: availableWidth)
                        } else {
                            bookmarksGridSection(
                                availableWidth: availableWidth,
                                horizontalPadding: horizontalPadding
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(horizontalPadding)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle("Focus Hub")
        .sheet(isPresented: $showingAddSheet) {
            bookmarkEditorSheet(isEditing: false)
        }
        .sheet(item: $editingBookmark) { bookmark in
            bookmarkEditorSheet(isEditing: true, existing: bookmark)
        }
        .alert(
            "Delete Bookmark?",
            isPresented: Binding(
                get: { bookmarkToDelete != nil },
                set: { if !$0 { bookmarkToDelete = nil } }
            ),
            presenting: bookmarkToDelete
        ) { bookmark in
            Button("Delete Link", role: .destructive) {
                withAnimation(.spring(response: 0.25)) {
                    viewModel.deleteBookmark(bookmark)
                }
                bookmarkToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                bookmarkToDelete = nil
            }
        } message: { bookmark in
            Text("Are you sure you want to delete \"\(bookmark.title)\"? This action cannot be undone.")
        }
    }

    // MARK: - Header Bar
    private func headerBar(availableWidth: CGFloat) -> some View {
        let usesCompactControls = availableWidth < BookmarksResponsiveLayout.compactControlsWidth
        let horizontalPadding = BookmarksResponsiveLayout.horizontalPadding(for: availableWidth)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                headerTitle

                Spacer(minLength: 8)

                moreActionsMenu
            }

            if usesCompactControls {
                VStack(alignment: .leading, spacing: 8) {
                    searchField

                    addBookmarkButton
                }
            } else {
                HStack(spacing: 10) {
                    searchField

                    addBookmarkButton
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.background)
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Focus Hub & Quick Links")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("One-click access to essential reference docs, tools, and flow resources.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .layoutPriority(1)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)

            TextField("Search links or domains...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var addBookmarkButton: some View {
        Button {
            resetForm()
            showingAddSheet = true
        } label: {
            Label("Add Link", systemImage: "plus")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.deepFocus)
        .controlSize(.regular)
        .fixedSize(horizontal: true, vertical: false)
        .help("Add a new focus link")
    }

    private var moreActionsMenu: some View {
        Menu {
            Button {
                viewModel.resetToDefaults()
            } label: {
                Label("Reset Default Links", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(6)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("More options")
    }

    // MARK: - Category Filters
    private func categoryFilterSection(contentWidth: CGFloat) -> some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(viewModel.allCategories, id: \.self) { category in
                let isSelected = viewModel.selectedCategory.caseInsensitiveCompare(category) == .orderedSame
                let count = viewModel.categoryCount(for: category)

                Button {
                    withAnimation(.spring(response: 0.25)) {
                        viewModel.selectedCategory = category
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(category)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textPrimary)
                            .lineLimit(1)

                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold).monospacedDigit())
                            .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? AppTheme.accent.opacity(0.18) : AppTheme.cardBackgroundSubtle)
                            )
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? AppTheme.accent.opacity(0.35) : AppTheme.subtleBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: contentWidth, alignment: .leading)
    }

    // MARK: - Stats Banner
    private func statsBannerSection(availableWidth: CGFloat, horizontalPadding: CGFloat) -> some View {
        let totalCount = viewModel.bookmarks.count
        let pinnedCount = viewModel.bookmarks.filter { $0.isPinned }.count
        let totalClicks = viewModel.bookmarks.reduce(0) { $0 + $1.clickCount }

        return LazyVGrid(
            columns: BookmarksResponsiveLayout.statisticsGridColumns(
                for: availableWidth,
                horizontalPadding: horizontalPadding
            ),
            spacing: 12
        ) {
            statCard(
                title: "Total Bookmarks",
                value: "\(totalCount)",
                icon: "bookmark.fill",
                color: AppTheme.deepFocus
            )

            statCard(
                title: "Pinned Quick Access",
                value: "\(pinnedCount)",
                icon: "pin.fill",
                color: AppTheme.sandstone
            )

            statCard(
                title: "Total Launches",
                value: "\(totalClicks)",
                icon: "arrow.up.right.circle.fill",
                color: AppTheme.success
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Bookmarks Grid
    private func bookmarksGridSection(availableWidth: CGFloat, horizontalPadding: CGFloat) -> some View {
        LazyVGrid(
            columns: BookmarksResponsiveLayout.bookmarkGridColumns(
                for: availableWidth,
                horizontalPadding: horizontalPadding
            ),
            spacing: 14
        ) {
            ForEach(viewModel.filteredBookmarks) { bookmark in
                bookmarkCard(bookmark)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bookmark Card
    private func bookmarkCard(_ bookmark: BookmarkItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // The category has its own row so a long title/category combination
            // never squeezes the card wider than its grid column.
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: bookmark.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(bookmark.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(bookmark.displayHost)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
                .layoutPriority(1)

                Spacer(minLength: 4)

                if bookmark.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.sandstone)
                }
            }

            Text(bookmark.category)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(Capsule())
                .lineLimit(1)

            Divider()

            bookmarkActions(for: bookmark)
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(bookmark.isPinned ? AppTheme.sandstone.opacity(0.35) : AppTheme.border, lineWidth: 1)
        )
        .contextMenu {
            Button {
                viewModel.openBookmark(bookmark)
            } label: {
                Label("Open in Browser", systemImage: "arrow.up.right")
            }

            Button {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(bookmark.url, forType: .string)
            } label: {
                Label("Copy URL", systemImage: "doc.on.doc")
            }

            Button {
                viewModel.togglePin(for: bookmark)
            } label: {
                Label(bookmark.isPinned ? "Unpin Link" : "Pin Link", systemImage: bookmark.isPinned ? "pin.slash" : "pin")
            }

            Divider()

            Button {
                startEditing(bookmark)
            } label: {
                Label("Edit Link", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                bookmarkToDelete = bookmark
            } label: {
                Label("Delete Link", systemImage: "trash")
            }
        }
    }

    private func bookmarkActions(for bookmark: BookmarkItem) -> some View {
        ViewThatFits(in: .horizontal) {
            regularBookmarkActions(for: bookmark)
                .fixedSize(horizontal: true, vertical: false)

            compactBookmarkActions(for: bookmark)
                .fixedSize(horizontal: true, vertical: false)

            iconOnlyBookmarkActions(for: bookmark)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private func regularBookmarkActions(for bookmark: BookmarkItem) -> some View {
        HStack(spacing: 8) {
            openBookmarkButton(for: bookmark, title: "Open Link", usesIconOnlyLabel: false)

            if bookmark.clickCount > 0 {
                Text("\(bookmark.clickCount) \(bookmark.clickCount == 1 ? "launch" : "launches")")
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            copyURLButton(for: bookmark)
            pinButton(for: bookmark)
            deleteBookmarkButton(for: bookmark)
        }
    }

    private func compactBookmarkActions(for bookmark: BookmarkItem) -> some View {
        HStack(spacing: 8) {
            openBookmarkButton(for: bookmark, title: "Open", usesIconOnlyLabel: false)

            if bookmark.clickCount > 0 {
                Text("\(bookmark.clickCount)")
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer(minLength: 2)

            copyURLButton(for: bookmark)
            pinButton(for: bookmark)
            deleteBookmarkButton(for: bookmark)
        }
    }

    private func iconOnlyBookmarkActions(for bookmark: BookmarkItem) -> some View {
        HStack(spacing: 8) {
            openBookmarkButton(for: bookmark, title: "Open Link", usesIconOnlyLabel: true)
            Spacer(minLength: 2)
            copyURLButton(for: bookmark)
            pinButton(for: bookmark)
            deleteBookmarkButton(for: bookmark)
        }
    }

    private func openBookmarkButton(
        for bookmark: BookmarkItem,
        title: String,
        usesIconOnlyLabel: Bool
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.openBookmark(bookmark)
            }
        } label: {
            Group {
                if usesIconOnlyLabel {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                } else {
                    Label(title, systemImage: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, usesIconOnlyLabel ? 8 : 12)
            .padding(.vertical, 6)
            .background(AppTheme.deepFocus)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(bookmark.title) in default browser")
        .help("Open in default browser")
    }

    private func copyURLButton(for bookmark: BookmarkItem) -> some View {
        Button {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(bookmark.url, forType: .string)

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                copiedBookmarkId = bookmark.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation {
                    if copiedBookmarkId == bookmark.id {
                        copiedBookmarkId = nil
                    }
                }
            }
        } label: {
            Image(systemName: copiedBookmarkId == bookmark.id ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12))
                .foregroundStyle(copiedBookmarkId == bookmark.id ? AppTheme.success : AppTheme.textSecondary)
                .padding(6)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help("Copy URL")
    }

    private func pinButton(for bookmark: BookmarkItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.togglePin(for: bookmark)
            }
        } label: {
            Image(systemName: bookmark.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12))
                .foregroundStyle(bookmark.isPinned ? AppTheme.sandstone : AppTheme.textSecondary)
                .padding(6)
                .background(bookmark.isPinned ? AppTheme.sandstone.opacity(0.15) : AppTheme.cardBackgroundSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(bookmark.isPinned ? "Unpin from favorites" : "Pin to favorites")
    }

    private func deleteBookmarkButton(for bookmark: BookmarkItem) -> some View {
        Button(role: .destructive) {
            bookmarkToDelete = bookmark
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(6)
                .background(AppTheme.cardBackgroundSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help("Delete bookmark")
        .accessibilityLabel("Delete \(bookmark.title)")
    }

    // MARK: - Empty State View
    private func emptyStateView(availableWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bookmark.slash")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTertiary)

            VStack(spacing: 4) {
                Text(viewModel.searchQuery.isEmpty ? "No bookmarks in this category" : "No matching bookmarks")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(viewModel.searchQuery.isEmpty ? "Add your most frequented documentation, tools, or music streams for quick 1-click access." : "Try adjusting your search terms or category filter.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            ViewThatFits(in: .horizontal) {
                emptyStateActions(stacksButtons: false)
                    .fixedSize(horizontal: true, vertical: false)

                emptyStateActions(stacksButtons: true)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(availableWidth < BookmarksResponsiveLayout.compactControlsWidth ? 20 : 32)
        .background(AppTheme.cardBackgroundSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func emptyStateActions(stacksButtons: Bool) -> some View {
        if !viewModel.searchQuery.isEmpty {
            Button("Clear Search") {
                viewModel.searchQuery = ""
            }
            .buttonStyle(.bordered)
        } else if stacksButtons {
            VStack(spacing: 8) {
                addBookmarkEmptyStateButton
                resetDefaultBookmarksButton
            }
        } else {
            HStack(spacing: 12) {
                addBookmarkEmptyStateButton
                resetDefaultBookmarksButton
            }
        }
    }

    private var addBookmarkEmptyStateButton: some View {
        Button {
            resetForm()
            showingAddSheet = true
        } label: {
            Label("Add Bookmark", systemImage: "plus")
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.deepFocus)
    }

    private var resetDefaultBookmarksButton: some View {
        Button("Reset Default Links") {
            viewModel.resetToDefaults()
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Bookmark Editor Sheet
    private func bookmarkEditorSheet(isEditing: Bool, existing: BookmarkItem? = nil) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Sheet Header
            HStack {
                Text(isEditing ? "Edit Bookmark" : "Add Focus Bookmark")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Button {
                    if isEditing {
                        editingBookmark = nil
                    } else {
                        showingAddSheet = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    TextField("e.g. Apple Documentation, Brain.fm", text: $formTitle)
                        .textFieldStyle(.roundedBorder)
                }

                // URL
                VStack(alignment: .leading, spacing: 4) {
                    Text("URL")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    TextField("https://...", text: $formUrl)
                        .textFieldStyle(.roundedBorder)
                }

                // Category
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 8) {
                        TextField("e.g. Documentation, Focus & Flow, Dev", text: $formCategory)
                            .textFieldStyle(.roundedBorder)

                        Menu {
                            ForEach(viewModel.allCategories.filter { $0 != "All" }, id: \.self) { cat in
                                Button(cat) {
                                    formCategory = cat
                                }
                            }
                        } label: {
                            Text("Presets")
                                .font(.caption)
                        }
                        .fixedSize()
                    }
                }

                // Icon selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("Icon")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 8) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    formIconName = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 14))
                                        .foregroundStyle(formIconName == icon ? AppTheme.accent : AppTheme.textSecondary)
                                        .frame(width: 32, height: 32)
                                        .background(formIconName == icon ? AppTheme.accent.opacity(0.15) : AppTheme.cardBackgroundSubtle)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(formIconName == icon ? AppTheme.accent : AppTheme.subtleBorder, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Pin toggle
                Toggle("Pin to Favorites", isOn: $formIsPinned)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Divider()

            // Sheet Action Buttons
            HStack {
                if isEditing, let existing = existing {
                    Button(role: .destructive) {
                        editingBookmark = nil
                        bookmarkToDelete = existing
                    } label: {
                        Label("Delete Link", systemImage: "trash")
                            .foregroundStyle(AppTheme.terracotta)
                    }
                    .buttonStyle(.bordered)
                    .help("Delete this bookmark")
                }

                Spacer()

                Button("Cancel") {
                    if isEditing {
                        editingBookmark = nil
                    } else {
                        showingAddSheet = false
                    }
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button(isEditing ? "Save Changes" : "Add Link") {
                    saveFormData(isEditing: isEditing, existing: existing)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .keyboardShortcut(.defaultAction)
                .disabled(formUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
        .background(AppTheme.cardBackground)
    }

    private func resetForm() {
        formTitle = ""
        formUrl = ""
        formCategory = viewModel.selectedCategory == "All" ? "General" : viewModel.selectedCategory
        formIconName = "globe"
        formIsPinned = false
    }

    private func startEditing(_ bookmark: BookmarkItem) {
        formTitle = bookmark.title
        formUrl = bookmark.url
        formCategory = bookmark.category
        formIconName = bookmark.iconName
        formIsPinned = bookmark.isPinned
        editingBookmark = bookmark
    }

    private func saveFormData(isEditing: Bool, existing: BookmarkItem?) {
        let cleanTitle = formTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUrl = formUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCat = formCategory.trimmingCharacters(in: .whitespacesAndNewlines)

        if isEditing, var bookmark = existing {
            bookmark.title = cleanTitle.isEmpty ? cleanUrl : cleanTitle
            bookmark.url = cleanUrl
            bookmark.category = cleanCat.isEmpty ? "General" : cleanCat
            bookmark.iconName = formIconName
            bookmark.isPinned = formIsPinned
            viewModel.updateBookmark(bookmark)
            editingBookmark = nil
        } else {
            viewModel.addBookmark(
                title: cleanTitle,
                url: cleanUrl,
                iconName: formIconName,
                category: cleanCat.isEmpty ? "General" : cleanCat,
                isPinned: formIsPinned
            )
            showingAddSheet = false
        }
    }
}
