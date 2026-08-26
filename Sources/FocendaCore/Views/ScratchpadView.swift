import SwiftUI
import AppKit

public struct ScratchpadView: View {
    @Bindable var viewModel: ScratchpadViewModel
    @State private var showingDeleteConfirmation = false
    @State private var copiedFeedback = false
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

            // Main Master-Detail Area
            HStack(spacing: 0) {
                // Notes List (Left Master Column)
                notesListPane
                    .frame(width: 280)

                Divider()

                // Editor Pane (Right Detail Column)
                editorPane
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 16) {
            // Title
            Text("Scratchpad")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textTertiary)

                TextField("Search notes...", text: $viewModel.searchQuery)
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
            .frame(minWidth: 160, idealWidth: 200, maxWidth: 240)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )

            // Category Chips (All + 5 Categories)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    categoryChip(title: "All", color: nil)
                    ForEach(ScratchpadColor.allCases) { color in
                        categoryChip(title: color.rawValue, color: color)
                    }
                }
                .padding(.vertical, 2)
            }

            Spacer(minLength: 8)

            // + New Note Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    let targetColor = viewModel.selectedFilterColor ?? viewModel.selectedColor
                    _ = viewModel.createNote(color: targetColor)
                    isTitleFocused = true
                }
            } label: {
                Label("New Note", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.deepFocus)
            .controlSize(.regular)
            .help("Create a new note")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.background)
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

    // MARK: - Notes List (Left Pane)
    private var notesListPane: some View {
        VStack(spacing: 0) {
            if viewModel.filteredNotes.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.textTertiary)

                    Text(viewModel.searchQuery.isEmpty ? "No notes found" : "No matching notes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    if !viewModel.searchQuery.isEmpty {
                        Button("Clear Search") {
                            viewModel.searchQuery = ""
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                _ = viewModel.createNote()
                                isTitleFocused = true
                            }
                        } label: {
                            Label("New Note", systemImage: "plus")
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.filteredNotes) { note in
                            noteCardRow(for: note)
                        }
                    }
                    .padding(10)
                }
            }

            Divider()

            // List Footer
            HStack {
                Text("\(viewModel.filteredNotes.count) \(viewModel.filteredNotes.count == 1 ? "note" : "notes")")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.cardBackgroundSubtle)
        }
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
                HStack(alignment: .center, spacing: 8) {
                    Circle()
                        .fill(note.color.color)
                        .frame(width: 8, height: 8)
                        .shadow(color: note.color.color.opacity(0.3), radius: 1, x: 0, y: 1)

                    Text(note.displayTitle)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textPrimary.opacity(0.85))
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(note.color.color)
                    }
                }

                // Snippet text preview
                Text(note.snippet)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Footer: relative timestamp + word count
                HStack {
                    Text(note.relativeFormattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)

                    Spacer()

                    Text("\(note.wordCount)w")
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? note.color.color.opacity(0.12) : AppTheme.cardBackgroundSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isSelected ? note.color.color.opacity(0.4) : AppTheme.subtleBorder,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
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
            HStack(spacing: 12) {
                // Color Category Picker Menu
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
                            .frame(width: 10, height: 10)
                        Text(viewModel.currentNote.color.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Change category color")

                // Inline Editable Title
                TextField("Untitled Note", text: $viewModel.currentTitle)
                    .font(.system(size: 18, weight: .bold))
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .focused($isTitleFocused)
                    .onChange(of: viewModel.currentTitle) { _, _ in
                        viewModel.saveToUserDefaults()
                    }

                Spacer()

                // Pin Toggle Button
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        viewModel.togglePin(for: viewModel.currentNote)
                    }
                } label: {
                    Image(systemName: viewModel.currentNote.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 13))
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
                .help(viewModel.currentNote.isPinned ? "Unpin Note" : "Pin Note")

                // Copy Button
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
                .help("Copy note content")

                // Delete Button
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
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
                .help("Delete note")
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            // Main TextEditor Container
            ZStack(alignment: .topLeading) {
                if viewModel.currentContent.isEmpty && !isEditorFocused {
                    Text("Jot down quick thoughts, ideas, or snippets while staying in deep focus...")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.currentContent)
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(6)
                    .focused($isEditorFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .onChange(of: viewModel.currentContent) { _, _ in
                        viewModel.saveToUserDefaults()
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)

            Divider()

            // Status Bar Footer
            footerStatusBar
        }
        .background(AppTheme.background)
    }

    // MARK: - Footer Status Bar
    private var footerStatusBar: some View {
        HStack(spacing: 16) {
            // Category tag
            HStack(spacing: 5) {
                Circle()
                    .fill(viewModel.currentNote.color.color)
                    .frame(width: 7, height: 7)

                Text(viewModel.currentNote.color.rawValue + " Note")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // Edit time
            Text("Edited " + viewModel.currentNote.relativeFormattedDate)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)

            Spacer()

            // Metrics
            HStack(spacing: 12) {
                Text("\(viewModel.wordCount) \(viewModel.wordCount == 1 ? "word" : "words")")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)

                Text("\(viewModel.characterCount) characters")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)

                Text("\(viewModel.lineCount) \(viewModel.lineCount == 1 ? "line" : "lines")")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // Saved indicator
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.success)

                Text("Saved")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(AppTheme.cardBackgroundSubtle)
    }
}
