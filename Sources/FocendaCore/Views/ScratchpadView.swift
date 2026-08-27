import SwiftUI
import AppKit

public struct ScratchpadView: View {
    @Bindable var viewModel: ScratchpadViewModel
    @State private var showingDeleteConfirmation = false
    @State private var copiedFeedback = false
    @State private var showingNewFolderSheet = false
    @State private var newFolderName = ""
    @FocusState private var isEditorFocused: Bool
    @FocusState private var isTitleFocused: Bool

    public init(viewModel: ScratchpadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Header Bar
            headerBar

            Divider()

            // Main 3-Pane Area (Folders Sidebar + Notes List + Editor)
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let showFolders = viewModel.showFoldersSidebar

                // Dynamically calculate responsive pane widths based on available width
                let foldersWidth: CGFloat = showFolders ? min(200, max(140, availableWidth * 0.24)) : 0
                let notesListWidth: CGFloat = showFolders
                    ? min(280, max(165, (availableWidth - foldersWidth) * 0.40))
                    : min(320, max(210, availableWidth * 0.38))

                HStack(spacing: 0) {
                    // Folder / Notebook Sidebar (Leftmost Column)
                    if showFolders {
                        foldersSidebarPane
                            .frame(width: foldersWidth)

                        Divider()
                    }

                    // Notes List (Middle Master Column)
                    notesListPane
                        .frame(width: notesListWidth)

                    Divider()

                    // Editor Pane (Right Detail Column - always visible & directly accessible)
                    editorPane
                        .frame(minWidth: 180, maxWidth: .infinity)
                }
                .frame(width: availableWidth, height: geometry.size.height, alignment: .leading)
            }
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle("Scratchpad")
        .confirmationDialog(
            "Delete Note?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Note", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    viewModel.deleteCurrentNote()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(viewModel.currentNote.displayTitle)\"? This action cannot be undone.")
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            newFolderSheet
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        ViewThatFits(in: .horizontal) {
            // Wide Header Layout
            HStack(spacing: 12) {
                sidebarToggleButton
                titleView
                searchBarView
                categoryChipsView
                Spacer(minLength: 4)
                newNoteButton
            }

            // Compact Header Layout for narrow windows
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    sidebarToggleButton
                    titleView
                    Spacer(minLength: 4)
                    newNoteButton
                }

                HStack(spacing: 8) {
                    searchBarView
                    categoryChipsView
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(AppTheme.background)
    }

    private var sidebarToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.showFoldersSidebar.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(viewModel.showFoldersSidebar ? AppTheme.accent : AppTheme.textSecondary)
                .padding(7)
                .background(viewModel.showFoldersSidebar ? AppTheme.accent.opacity(0.12) : AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(viewModel.showFoldersSidebar ? AppTheme.accent.opacity(0.3) : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .help(viewModel.showFoldersSidebar ? "Hide Folders Sidebar" : "Show Folders Sidebar")
    }

    private var titleView: some View {
        Text("Scratchpad")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.textPrimary)
            .lineLimit(1)
            .layoutPriority(1)
    }

    private var searchBarView: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)

            TextField("Search...", text: $viewModel.searchQuery)
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
        .frame(minWidth: 100, idealWidth: 140, maxWidth: 200)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private var categoryChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                categoryChip(title: "All", color: nil)
                ForEach(ScratchpadColor.allCases) { color in
                    categoryChip(title: color.rawValue, color: color)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var newNoteButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                let targetColor = viewModel.selectedFilterColor ?? viewModel.selectedColor
                _ = viewModel.createNote(color: targetColor)
                isTitleFocused = true
            }
        } label: {
            Label("New Note", systemImage: "plus")
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.deepFocus)
        .controlSize(.regular)
        .fixedSize(horizontal: true, vertical: false)
        .help("Create a new note in active folder")
    }

    // MARK: - Category Chip
    private func categoryChip(title: String, color: ScratchpadColor?) -> some View {
        let isSelected = viewModel.selectedFilterColor == color

        return Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.selectedFilterColor = color
            }
        } label: {
            HStack(spacing: 5) {
                if let color = color {
                    Circle()
                        .fill(color.color)
                        .frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? (color?.color ?? AppTheme.textPrimary) : AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? (color?.color.opacity(0.12) ?? AppTheme.accent.opacity(0.12)) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? (color?.color.opacity(0.35) ?? AppTheme.border) : AppTheme.subtleBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .help(color == nil ? "Show all notes" : "Filter by \(color!.rawValue)")
    }

    // MARK: - Folders Sidebar Pane (Leftmost Column)
    private var foldersSidebarPane: some View {
        VStack(spacing: 0) {
            // Folders Header
            HStack {
                Text("Folders")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTertiary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Spacer()

                Button {
                    newFolderName = ""
                    showingNewFolderSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(5)
                }
                .buttonStyle(.plain)
                .help("Add new folder")
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Folders List
            ScrollView {
                VStack(spacing: 4) {
                    // All Notes item
                    folderRowItem(
                        name: ScratchpadViewModel.allNotesFolder,
                        icon: "tray.full",
                        count: viewModel.noteCount(for: ScratchpadViewModel.allNotesFolder),
                        isDeletable: false
                    )

                    Divider()
                        .padding(.vertical, 4)

                    // Individual Folder items
                    ForEach(viewModel.folders, id: \.self) { folder in
                        folderRowItem(
                            name: folder,
                            icon: ScratchpadViewModel.iconForFolder(folder),
                            count: viewModel.noteCount(for: folder),
                            isDeletable: folder != "General"
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }

            Divider()

            // Bottom Add Folder Button
            Button {
                newFolderName = ""
                showingNewFolderSheet = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 13))
                    Text("New Folder")
                        .font(.system(size: 13.5, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .background(AppTheme.cardBackgroundSubtle)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(AppTheme.sidebarBackground)
    }

    private func folderRowItem(name: String, icon: String, count: Int, isDeletable: Bool) -> some View {
        let isSelected = viewModel.selectedFolder.caseInsensitiveCompare(name) == .orderedSame

        return Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.selectFolder(name)
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 18)

                Text(name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 2)

                Text("\(count)")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textTertiary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(
                        Capsule()
                            .fill(isSelected ? AppTheme.accent.opacity(0.18) : AppTheme.cardBackground)
                    )
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? AppTheme.accent.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isDeletable {
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.25)) {
                        viewModel.deleteFolder(name)
                    }
                } label: {
                    Label("Delete Folder", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Notes List (Middle Column)
    private var notesListPane: some View {
        VStack(spacing: 0) {
            // Notes List Header info
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: ScratchpadViewModel.iconForFolder(viewModel.selectedFolder))
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.accent)

                    Text(viewModel.selectedFolder)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 2)

                Text("\(viewModel.filteredNotes.count)")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.cardBackgroundSubtle)

            Divider()

            if viewModel.filteredNotes.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.textTertiary)

                    Text(viewModel.searchQuery.isEmpty ? "No notes in \(viewModel.selectedFolder)" : "No matching notes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)

                    if !viewModel.searchQuery.isEmpty {
                        Button("Clear Search") {
                            viewModel.searchQuery = ""
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                _ = viewModel.createNote()
                                isTitleFocused = true
                            }
                        } label: {
                            Label("New Note", systemImage: "plus")
                                .font(.system(size: 12.5, weight: .medium))
                                .lineLimit(1)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredNotes) { note in
                            noteCardRow(for: note)
                        }
                    }
                    .padding(10)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(AppTheme.background)
    }

    // MARK: - Note Card Row
    private func noteCardRow(for note: ScratchpadNote) -> some View {
        let isSelected = viewModel.selectedNoteId == note.id

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                viewModel.selectNote(note)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Header: Color dot + Title + Pin
                HStack(alignment: .center, spacing: 7) {
                    Circle()
                        .fill(note.color.color)
                        .frame(width: 9, height: 9)
                        .shadow(color: note.color.color.opacity(0.3), radius: 1.5, x: 0, y: 1)

                    Text(note.displayTitle)
                        .font(.system(size: 14.5, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textPrimary.opacity(0.92))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 2)

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(note.color.color)
                    }
                }

                // Folder tag if viewing All Notes
                if viewModel.selectedFolder == ScratchpadViewModel.allNotesFolder {
                    HStack(spacing: 4) {
                        Image(systemName: ScratchpadViewModel.iconForFolder(note.folder))
                            .font(.system(size: 10))
                        Text(note.folder)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.cardBackground)
                    .clipShape(Capsule())
                }

                // Snippet text preview
                Text(note.snippet)
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Footer: relative timestamp + word count
                HStack {
                    Text(note.relativeFormattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(note.wordCount)w")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? note.color.color.opacity(0.12) : AppTheme.cardBackgroundSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(
                        isSelected ? note.color.color.opacity(0.4) : AppTheme.subtleBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Menu("Move to Folder") {
                ForEach(viewModel.folders, id: \.self) { folder in
                    Button {
                        viewModel.moveNote(note, to: folder)
                    } label: {
                        Label(folder, systemImage: ScratchpadViewModel.iconForFolder(folder))
                    }
                }
            }

            Divider()

            Button {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(note.content, forType: .string)
            } label: {
                Label("Copy Content", systemImage: "doc.on.doc")
            }

            Button {
                viewModel.togglePin(for: note)
            } label: {
                Label(note.isPinned ? "Unpin Note" : "Pin Note", systemImage: note.isPinned ? "pin.slash" : "pin")
            }

            Divider()

            Menu("Change Category") {
                ForEach(ScratchpadColor.allCases) { color in
                    Button {
                        if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                            viewModel.notes[index].color = color
                            viewModel.saveToUserDefaults()
                        }
                    } label: {
                        Label(color.rawValue, systemImage: color.iconName)
                    }
                }
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteNote(note)
            } label: {
                Label("Delete Note", systemImage: "trash")
            }
        }
    }

    // MARK: - Editor Pane (Right Detail Column)
    private var editorPane: some View {
        VStack(spacing: 0) {
            // Note Meta / Action Toolbar Bar
            ViewThatFits(in: .horizontal) {
                // Wide single-row toolbar
                HStack(spacing: 8) {
                    noteFolderMenu
                    noteColorMenu
                    noteTitleField
                    Spacer(minLength: 4)
                    notePinButton
                    noteCopyButton
                    noteDeleteButton
                }

                // Compact two-row toolbar for narrow editor widths
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        noteFolderMenu
                        noteColorMenu
                        Spacer(minLength: 4)
                        notePinButton
                        noteCopyButton
                        noteDeleteButton
                    }
                    noteTitleField
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()

            // Main TextEditor Container
            ZStack(alignment: .topLeading) {
                if viewModel.currentContent.isEmpty && !isEditorFocused {
                    Text("Jot down quick thoughts, ideas, or code snippets while staying in deep focus...")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.currentContent)
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(6)
                    .focused($isEditorFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .onChange(of: viewModel.currentContent) { _, _ in
                        viewModel.saveToUserDefaults()
                    }
            }
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)

            Divider()

            // Status Bar Footer (Protected against text-wrapping with ViewThatFits)
            footerStatusBar
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }

    private var noteFolderMenu: some View {
        Menu {
            ForEach(viewModel.folders, id: \.self) { folder in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        viewModel.moveCurrentNote(to: folder)
                    }
                } label: {
                    Label(folder, systemImage: ScratchpadViewModel.iconForFolder(folder))
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: ScratchpadViewModel.iconForFolder(viewModel.currentNote.folder))
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.accent)
                Text(viewModel.currentNote.folder)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: true, vertical: false)
        .help("Move note to another folder")
    }

    private var noteColorMenu: some View {
        Menu {
            ForEach(ScratchpadColor.allCases) { color in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        viewModel.updateColor(color)
                    }
                } label: {
                    Label(color.rawValue, systemImage: color.iconName)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(viewModel.currentNote.color.color)
                    .frame(width: 9, height: 9)
                Text(viewModel.currentNote.color.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: true, vertical: false)
        .help("Change category color")
    }

    private var noteTitleField: some View {
        TextField("Untitled Note", text: $viewModel.currentTitle)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .textFieldStyle(.plain)
            .foregroundStyle(AppTheme.textPrimary)
            .focused($isTitleFocused)
            .onChange(of: viewModel.currentTitle) { _, _ in
                viewModel.saveToUserDefaults()
            }
    }

    private var notePinButton: some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.togglePin(for: viewModel.currentNote)
            }
        } label: {
            Image(systemName: viewModel.currentNote.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12))
                .foregroundStyle(viewModel.currentNote.isPinned ? viewModel.currentNote.color.color : AppTheme.textSecondary)
                .padding(6)
                .background(viewModel.currentNote.isPinned ? viewModel.currentNote.color.color.opacity(0.15) : AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(viewModel.currentNote.isPinned ? viewModel.currentNote.color.color.opacity(0.3) : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .help(viewModel.currentNote.isPinned ? "Unpin Note" : "Pin Note")
    }

    private var noteCopyButton: some View {
        Button {
            viewModel.copyCurrentNoteToClipboard()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                copiedFeedback = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation {
                    copiedFeedback = false
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                Text(copiedFeedback ? "Copied" : "Copy")
                    .lineLimit(1)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(copiedFeedback ? AppTheme.success : AppTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .help("Copy note content")
    }

    private var noteDeleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(6)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .help("Delete note")
    }

    // MARK: - Footer Status Bar
    private var footerStatusBar: some View {
        ViewThatFits(in: .horizontal) {
            // Full Status Bar
            HStack(spacing: 10) {
                folderBadge
                categoryBadge
                editedTimestamp
                Spacer(minLength: 4)
                countersView
                savedIndicator
            }

            // Medium Status Bar
            HStack(spacing: 8) {
                folderBadge
                categoryBadge
                Spacer(minLength: 4)
                countersView
                savedIndicator
            }

            // Compact Status Bar
            HStack(spacing: 8) {
                folderBadge
                Spacer(minLength: 4)
                countersView
            }

            // Minimal Status Bar
            HStack(spacing: 6) {
                Text("\(viewModel.wordCount)w • \(viewModel.characterCount)c")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer(minLength: 4)
                savedIndicator
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppTheme.cardBackgroundSubtle)
    }

    private var folderBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: ScratchpadViewModel.iconForFolder(viewModel.currentNote.folder))
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.accent)

            Text(viewModel.currentNote.folder)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(AppTheme.cardBackground)
        .clipShape(Capsule())
    }

    private var categoryBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(viewModel.currentNote.color.color)
                .frame(width: 7, height: 7)

            Text(viewModel.currentNote.color.rawValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
    }

    private var editedTimestamp: some View {
        Text("Edited " + viewModel.currentNote.relativeFormattedDate)
            .font(.caption)
            .foregroundStyle(AppTheme.textTertiary)
            .lineLimit(1)
    }

    private var countersView: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.wordCount)w")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)

            Text("•")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)

            Text("\(viewModel.characterCount)c")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)

            Text("•")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)

            Text("\(viewModel.lineCount)L")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
    }

    private var savedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.success)

            Text("Saved")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - New Folder Sheet
    private var newFolderSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Folder")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Organize your scratchpad notes by project, client, or topic.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            TextField("Folder name (e.g. Design System, Research)", text: $newFolderName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()

                Button("Cancel") {
                    showingNewFolderSheet = false
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button("Create Folder") {
                    let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        viewModel.createFolder(trimmed)
                    }
                    showingNewFolderSheet = false
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .keyboardShortcut(.defaultAction)
                .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
        .background(AppTheme.cardBackground)
    }
}
