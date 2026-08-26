import SwiftUI
import AppKit

public struct BookmarksView: View {
    @Bindable var viewModel: BookmarkViewModel
    @State private var showingAddSheet = false
    @State private var editingBookmark: BookmarkItem?
    @State private var copiedBookmarkId: UUID?

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
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider()

            // Main Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category Filter Pills
                    categoryFilterSection

                    // Quick Stats Cards
                    statsBannerSection

                    // Bookmarks Grid or Empty State
                    if viewModel.filteredBookmarks.isEmpty {
                        emptyStateView
                    } else {
                        bookmarksGridSection
                    }
                }
                .padding(20)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
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
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Focus Hub & Quick Links")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Text("One-click access to essential reference docs, tools, and flow resources.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Search Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary)

                TextField("Search links or domains...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textPrimary)

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
            .frame(minWidth: 140, idealWidth: 180, maxWidth: 240)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )

            // + Add Link Button
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
            .help("Add a new focus link")

            // More actions menu
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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(AppTheme.background)
    }

    // MARK: - Category Filters
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 8) {
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
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    // MARK: - Stats Banner
    private var statsBannerSection: some View {
        let totalCount = viewModel.bookmarks.count
        let pinnedCount = viewModel.bookmarks.filter { $0.isPinned }.count
        let totalClicks = viewModel.bookmarks.reduce(0) { $0 + $1.clickCount }

        return LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 140, maximum: .infinity), spacing: 12)
            ],
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
    private var bookmarksGridSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 220, maximum: .infinity), spacing: 14)
            ],
            spacing: 14
        ) {
            ForEach(viewModel.filteredBookmarks) { bookmark in
                bookmarkCard(bookmark)
            }
        }
    }

    // MARK: - Bookmark Card
    private func bookmarkCard(_ bookmark: BookmarkItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Icon, Title, Pin indicator
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
                    HStack(spacing: 4) {
                        Text(bookmark.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)

                        if bookmark.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.sandstone)
                        }
                    }

                    Text(bookmark.displayHost)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // Category pill
                Text(bookmark.category)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppTheme.cardBackgroundSubtle)
                    .clipShape(Capsule())
                    .lineLimit(1)
            }

            Divider()

            // Bottom Row: Launch button & copy/pin actions
            HStack(spacing: 8) {
                // 1-Click Launch in browser button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.openBookmark(bookmark)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("Open Link")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.deepFocus)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Open in default browser")

                if bookmark.clickCount > 0 {
                    Text("\(bookmark.clickCount) \(bookmark.clickCount == 1 ? "launch" : "launches")")
                        .font(.system(size: 10).monospacedDigit())
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                // Copy URL button
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

                // Pin toggle button
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
                viewModel.deleteBookmark(bookmark)
            } label: {
                Label("Delete Link", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
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

            HStack(spacing: 12) {
                if !viewModel.searchQuery.isEmpty {
                    Button("Clear Search") {
                        viewModel.searchQuery = ""
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        resetForm()
                        showingAddSheet = true
                    } label: {
                        Label("Add Bookmark", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.deepFocus)

                    Button("Reset Default Links") {
                        viewModel.resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(32)
        .background(AppTheme.cardBackgroundSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
