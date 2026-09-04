import SwiftUI
import AppKit

public struct ScratchpadView: View {
    private static let compactWorkspaceThreshold: CGFloat = 720

    @Bindable var viewModel: ScratchpadViewModel
    private let taskVM: TaskListViewModel?
    @State private var showingDeleteConfirmation = false
    @State private var copiedFeedback = false
    @State private var taskCreatedFeedback = false
    @State private var selectedLine: String?
    @State private var showingNewFolderSheet = false
    @State private var showingFolderDeleteConfirmation = false
    @State private var showingCompactFolderPicker = false
    @State private var showingSidebarFolderPicker = false
    @State private var isCompactWorkspace = false
    @State private var newFolderName = ""
    @State private var folderEditorIcon = "folder"
    @State private var editingFolderName: String?
    @State private var folderNameToDelete = ""
    @State private var isEditorFocused = false
    @FocusState private var isTitleFocused: Bool

    public init(viewModel: ScratchpadViewModel, taskVM: TaskListViewModel? = nil) {
        self.viewModel = viewModel
        self.taskVM = taskVM
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Header Bar
            headerBar

            Divider()

            // Main 3-Pane Area (Folders Sidebar + Notes List + Editor)
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                // The app's minimum window leaves roughly 550pt for the detail area.
                // At that width a permanent three-pane layout makes the editor unusable,
                // so the folder list becomes a menu in the notes pane instead.
                let usesCompactWorkspace = availableWidth < Self.compactWorkspaceThreshold
                let showFolders = viewModel.showFoldersSidebar && !usesCompactWorkspace
                let foldersWidth: CGFloat = showFolders ? min(200, max(150, availableWidth * 0.24)) : 0
                let notesListWidth: CGFloat = usesCompactWorkspace
                    ? min(220, max(170, availableWidth * 0.34))
                    : showFolders
                        ? min(280, max(180, (availableWidth - foldersWidth) * 0.40))
                        : min(320, max(210, availableWidth * 0.38))

                HStack(spacing: 0) {
                    // Folder / Notebook Sidebar (Leftmost Column)
                    if showFolders {
                        foldersSidebarPane
                            .frame(width: foldersWidth)

                        Divider()
                    }

                    // Notes List (Middle Master Column)
                    notesListPane(showFolderPicker: !showFolders)
                        .frame(width: notesListWidth)

                    Divider()

                    // Editor Pane (Right Detail Column - always visible & directly accessible)
                    editorPane
                        .frame(minWidth: 240, maxWidth: .infinity)
                }
                .frame(width: availableWidth, height: geometry.size.height, alignment: .leading)
                .onAppear {
                    isCompactWorkspace = usesCompactWorkspace
                }
                .onChange(of: availableWidth) { _, newWidth in
                    isCompactWorkspace = newWidth < Self.compactWorkspaceThreshold
                }
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
        .confirmationDialog(
            "Delete Folder?",
            isPresented: $showingFolderDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Folder", role: .destructive) {
                let folder = folderNameToDelete
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    _ = viewModel.deleteFolder(folder)
                }
                folderNameToDelete = ""
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Notes in \"\(folderNameToDelete)\" will be moved to another folder. This action cannot be undone.")
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            newFolderSheet
        }
        .onChange(of: viewModel.selectedNoteId) { _, _ in
            selectedLine = nil
            taskCreatedFeedback = false
        }
        .onDisappear {
            viewModel.flushPendingSaves()
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

                HStack {
                    searchBarView
                    Spacer(minLength: 0)
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
            if isCompactWorkspace {
                showingSidebarFolderPicker = true
            } else {
                withAnimation(.spring(response: 0.25)) {
                    viewModel.showFoldersSidebar.toggle()
                }
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isCompactWorkspace || viewModel.showFoldersSidebar ? AppTheme.accent : AppTheme.textSecondary)
                .padding(7)
                .background(isCompactWorkspace || viewModel.showFoldersSidebar ? AppTheme.accent.opacity(0.12) : AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isCompactWorkspace || viewModel.showFoldersSidebar ? AppTheme.accent.opacity(0.3) : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .popover(isPresented: $showingSidebarFolderPicker, arrowEdge: .bottom) {
            compactFolderPickerPopover
        }
        .help(isCompactWorkspace ? "Choose a folder" : (viewModel.showFoldersSidebar ? "Hide Folders Sidebar" : "Show Folders Sidebar"))
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

    private var newNoteButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                _ = viewModel.createNote()
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
                    presentNewFolderSheet()
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
                        isDeletable: false,
                        isEditable: false
                    )

                    Divider()
                        .padding(.vertical, 4)

                    // Individual Folder items
                    ForEach(viewModel.folders, id: \.self) { folder in
                        folderRowItem(
                            name: folder,
                            icon: viewModel.iconName(for: folder),
                            count: viewModel.noteCount(for: folder),
                            isDeletable: viewModel.canDeleteFolder(folder),
                            isEditable: true
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }

            Divider()

            // Bottom Add Folder Button
            Button {
                presentNewFolderSheet()
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

    private func folderRowItem(
        name: String,
        icon: String,
        count: Int,
        isDeletable: Bool,
        isEditable: Bool
    ) -> some View {
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
            if isEditable {
                Button {
                    presentFolderEditor(for: name)
                } label: {
                    Label("Edit Folder", systemImage: "pencil")
                }
            }

            if isEditable && isDeletable {
                Divider()

                Button(role: .destructive) {
                    requestDeleteFolder(name)
                } label: {
                    Label("Delete Folder", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Notes List (Middle Column)
    private func notesListPane(showFolderPicker: Bool) -> some View {
        VStack(spacing: 0) {
            // Notes List Header info
            HStack {
                if showFolderPicker {
                    compactFolderPicker
                } else {
                    selectedFolderLabel
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

    private var selectedFolderLabel: some View {
        HStack(spacing: 7) {
            Image(systemName: viewModel.iconName(for: viewModel.selectedFolder))
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.accent)

            Text(viewModel.selectedFolder)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var compactFolderPicker: some View {
        Button {
            showingCompactFolderPicker.toggle()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: viewModel.iconName(for: viewModel.selectedFolder))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.accent)
                Text(viewModel.selectedFolder)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingCompactFolderPicker, arrowEdge: .bottom) {
            compactFolderPickerPopover
        }
        .help("Choose a folder")
    }

    private var compactFolderPickerPopover: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Folders")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(AppTheme.textTertiary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    compactFolderPickerRow(
                        name: ScratchpadViewModel.allNotesFolder,
                        icon: "tray.full"
                    )

                    ForEach(viewModel.folders, id: \.self) { folder in
                        compactFolderPickerRow(
                            name: folder,
                            icon: viewModel.iconName(for: folder)
                        )
                    }
                }
                .padding(6)
            }

            Divider()

            // Keep folder creation available when the full sidebar is replaced by this picker.
            Button {
                presentNewFolderSheet()
            } label: {
                Label("New Folder", systemImage: "folder.badge.plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .background(AppTheme.cardBackgroundSubtle)
        }
        .frame(width: 220, height: 260)
        .background(AppTheme.cardBackground)
    }

    private func compactFolderPickerRow(name: String, icon: String) -> some View {
        let isSelected = viewModel.selectedFolder.caseInsensitiveCompare(name) == .orderedSame

        return Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.selectFolder(name)
            }
            showingCompactFolderPicker = false
            showingSidebarFolderPicker = false
        } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)

                Text(name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppTheme.accent.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if name.caseInsensitiveCompare(ScratchpadViewModel.allNotesFolder) != .orderedSame {
                Button {
                    presentFolderEditor(for: name)
                } label: {
                    Label("Edit Folder", systemImage: "pencil")
                }

                if viewModel.canDeleteFolder(name) {
                    Divider()

                    Button(role: .destructive) {
                        requestDeleteFolder(name)
                    } label: {
                        Label("Delete Folder", systemImage: "trash")
                    }
                }
            }
        }
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
                // Header: Note icon + Title + Pin
                HStack(alignment: .center, spacing: 7) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.accent)

                    Text(note.displayTitle)
                        .font(.system(size: 14.5, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textPrimary.opacity(0.92))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 2)

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                // Folder tag if viewing All Notes
                if viewModel.selectedFolder == ScratchpadViewModel.allNotesFolder {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.iconName(for: note.folder))
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
                    .fill(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.cardBackgroundSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(
                        isSelected ? AppTheme.accent.opacity(0.4) : AppTheme.subtleBorder,
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
                        Label(folder, systemImage: viewModel.iconName(for: folder))
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
                    noteTitleField
                    Spacer(minLength: 4)
                    notePinButton
                    if taskVM != nil {
                        noteCreateTaskButton
                    }
                    noteCopyButton
                    noteDeleteButton
                }

                // Compact two-row toolbar for narrow editor widths
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        noteFolderMenu
                        Spacer(minLength: 4)
                        notePinButton
                        if taskVM != nil {
                            noteCreateTaskButton
                        }
                        noteCopyButton
                        noteDeleteButton
                    }
                    noteTitleField
                }

                // The editor can be narrow when the app is at its minimum width.
                // Use icon-only controls before allowing any toolbar content to overlap.
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        noteFolderIconMenu
                        Spacer(minLength: 4)
                        notePinButton
                        if taskVM != nil {
                            noteCreateTaskIconButton
                        }
                        noteCopyIconButton
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

                ScratchpadTextEditor(
                    text: $viewModel.currentContent,
                    selectedLine: $selectedLine,
                    isFocused: $isEditorFocused
                )
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
                    Label(folder, systemImage: viewModel.iconName(for: folder))
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: viewModel.iconName(for: viewModel.currentNote.folder))
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

    private var noteFolderIconMenu: some View {
        Menu {
            ForEach(viewModel.folders, id: \.self) { folder in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        viewModel.moveCurrentNote(to: folder)
                    }
                } label: {
                    Label(folder, systemImage: viewModel.iconName(for: folder))
                }
            }
        } label: {
            Image(systemName: viewModel.iconName(for: viewModel.currentNote.folder))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28, height: 28)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        }
        .menuStyle(.borderlessButton)
        .help("Move note to another folder")
    }

    private var noteTitleField: some View {
        TextField("Untitled Note", text: $viewModel.currentTitle)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .textFieldStyle(.plain)
            .foregroundStyle(AppTheme.textPrimary)
            .focused($isTitleFocused)
    }

    private var notePinButton: some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.togglePin(for: viewModel.currentNote)
            }
        } label: {
            Image(systemName: viewModel.currentNote.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12))
                .foregroundStyle(viewModel.currentNote.isPinned ? AppTheme.accent : AppTheme.textSecondary)
                .padding(6)
                .background(viewModel.currentNote.isPinned ? AppTheme.accent.opacity(0.15) : AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(viewModel.currentNote.isPinned ? AppTheme.accent.opacity(0.3) : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .disabled(viewModel.selectedNoteId == nil)
        .help(viewModel.currentNote.isPinned ? "Unpin Note" : "Pin Note")
    }

    private var noteCreateTaskButton: some View {
        Button {
            createTaskFromSelectedLine()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: taskCreatedFeedback ? "checkmark" : "checklist")
                Text(taskCreatedFeedback ? "Added" : "Task")
                    .lineLimit(1)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(taskCreatedFeedback ? AppTheme.success : taskActionColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(taskCreatedFeedback ? AppTheme.success.opacity(0.3) : AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
        .disabled(!canCreateTaskFromSelectedLine)
        .help("Create a task from the line containing the cursor or selection")
    }

    private var noteCreateTaskIconButton: some View {
        Button {
            createTaskFromSelectedLine()
        } label: {
            Image(systemName: taskCreatedFeedback ? "checkmark" : "checklist")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(taskCreatedFeedback ? AppTheme.success : taskActionColor)
                .frame(width: 28, height: 28)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(taskCreatedFeedback ? AppTheme.success.opacity(0.3) : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canCreateTaskFromSelectedLine)
        .help("Create a task from the line containing the cursor or selection")
    }

    private var canCreateTaskFromSelectedLine: Bool {
        taskVM != nil &&
            viewModel.selectedNoteId != nil &&
            !(selectedLine?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var taskActionColor: Color {
        canCreateTaskFromSelectedLine ? AppTheme.accent : AppTheme.textTertiary
    }

    private func createTaskFromSelectedLine() {
        guard canCreateTaskFromSelectedLine,
              let taskVM,
              let selectedLine else {
            return
        }

        viewModel.flushPendingSaves()
        guard taskVM.addTask(title: selectedLine) != nil else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            taskCreatedFeedback = true
        }
        isEditorFocused = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                taskCreatedFeedback = false
            }
        }
    }

    private var noteCopyButton: some View {
        Button {
            copyCurrentNote()
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

    private var noteCopyIconButton: some View {
        Button {
            copyCurrentNote()
        } label: {
            Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(copiedFeedback ? AppTheme.success : AppTheme.textSecondary)
                .frame(width: 28, height: 28)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help("Copy note content")
    }

    private func copyCurrentNote() {
        viewModel.copyCurrentNoteToClipboard()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                copiedFeedback = false
            }
        }
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
        .disabled(viewModel.selectedNoteId == nil)
        .help("Delete note")
    }

    // MARK: - Footer Status Bar
    private var footerStatusBar: some View {
        ViewThatFits(in: .horizontal) {
            // Full Status Bar
            HStack(spacing: 10) {
                folderBadge
                editedTimestamp
                Spacer(minLength: 4)
                countersView
                savedIndicator
            }

            // Medium Status Bar
            HStack(spacing: 8) {
                folderBadge
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
            Image(systemName: viewModel.iconName(for: viewModel.currentNote.folder))
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
            if viewModel.hasPendingSaves {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.accent)

                Text("Saving...")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.success)

                Text("Saved")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.hasPendingSaves)
    }

    // MARK: - Folder Management
    private func presentNewFolderSheet() {
        newFolderName = ""
        folderEditorIcon = "folder"
        editingFolderName = nil
        showingCompactFolderPicker = false
        showingSidebarFolderPicker = false
        showingNewFolderSheet = true
    }

    private func presentFolderEditor(for folder: String) {
        newFolderName = folder
        folderEditorIcon = viewModel.iconName(for: folder)
        editingFolderName = folder
        showingCompactFolderPicker = false
        showingSidebarFolderPicker = false
        showingNewFolderSheet = true
    }

    private func requestDeleteFolder(_ folder: String) {
        folderNameToDelete = folder
        showingCompactFolderPicker = false
        showingSidebarFolderPicker = false
        showingFolderDeleteConfirmation = true
    }

    private var trimmedFolderName: String {
        newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFolderNameValid: Bool {
        guard !trimmedFolderName.isEmpty,
              trimmedFolderName.caseInsensitiveCompare(ScratchpadViewModel.allNotesFolder) != .orderedSame else {
            return false
        }

        return !viewModel.folders.contains { folder in
            let isCurrentFolder = editingFolderName?.caseInsensitiveCompare(folder) == .orderedSame
            return !isCurrentFolder && folder.caseInsensitiveCompare(trimmedFolderName) == .orderedSame
        }
    }

    private var folderNameValidationMessage: String? {
        guard !trimmedFolderName.isEmpty else { return nil }
        if trimmedFolderName.caseInsensitiveCompare(ScratchpadViewModel.allNotesFolder) == .orderedSame {
            return "All Notes is reserved for the combined notes view."
        }

        let conflictsWithExistingFolder = viewModel.folders.contains { folder in
            let isCurrentFolder = editingFolderName?.caseInsensitiveCompare(folder) == .orderedSame
            return !isCurrentFolder && folder.caseInsensitiveCompare(trimmedFolderName) == .orderedSame
        }
        return conflictsWithExistingFolder ? "A folder with this name already exists." : nil
    }

    private func saveFolderEditor() {
        let saved: Bool
        if let editingFolderName {
            saved = viewModel.updateFolder(
                editingFolderName,
                to: trimmedFolderName,
                icon: folderEditorIcon
            )
        } else {
            saved = viewModel.createFolder(trimmedFolderName, icon: folderEditorIcon)
        }

        guard saved else { return }
        showingNewFolderSheet = false
        editingFolderName = nil
    }

    private var newFolderSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(editingFolderName == nil ? "Create New Folder" : "Edit Folder")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(editingFolderName == nil
                 ? "Organize your scratchpad notes by project, client, or topic."
                 : "Rename this folder or choose a new icon for it.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            TextField("Folder name (e.g. Design System, Research)", text: $newFolderName)
                .textFieldStyle(.roundedBorder)

            if let folderNameValidationMessage {
                Text(folderNameValidationMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.terracotta)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Icon")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 38, maximum: 52), spacing: 8)],
                        spacing: 8
                    ) {
                        ForEach(ScratchpadViewModel.availableFolderIcons, id: \.self) { icon in
                            Button {
                                folderEditorIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: 15))
                                    .foregroundStyle(folderEditorIcon == icon ? AppTheme.accent : AppTheme.textSecondary)
                                    .frame(width: 34, height: 30)
                                    .background(
                                        folderEditorIcon == icon
                                            ? AppTheme.accent.opacity(0.15)
                                            : AppTheme.cardBackgroundSubtle
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(
                                                folderEditorIcon == icon ? AppTheme.accent : AppTheme.subtleBorder,
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(icon)
                            .accessibilityLabel("Folder icon \(icon)")
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 124)
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    showingNewFolderSheet = false
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button(editingFolderName == nil ? "Create Folder" : "Save Changes") {
                    saveFolderEditor()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.deepFocus)
                .keyboardShortcut(.defaultAction)
                .disabled(!isFolderNameValid)
            }
        }
        .padding(20)
        .frame(width: 380)
        .background(AppTheme.cardBackground)
    }
}
