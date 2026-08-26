import SwiftUI
import AppKit

public struct ScratchpadView: View {
    @Bindable var viewModel: ScratchpadViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var copiedFeedback = false
    @FocusState private var isEditorFocused: Bool
    @FocusState private var isTitleFocused: Bool

    public init(viewModel: ScratchpadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider()

            // Main Workspace (Sidebar + Editor)
            HStack(spacing: 0) {
                // Notes List / Selector Sidebar
                if viewModel.showNotesSidebar {
                    notesSidebar
                        .frame(width: 260)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    Divider()
                }

                // Editor Panel
                editorPanel
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Bottom Status & Stats Bar
            bottomStatusBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
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
            "Clear Note Contents?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Text", role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    viewModel.clearCurrentNote()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will erase all content in this scratchpad note.")
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 14) {
            // Sidebar Toggle & Title Info
            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.showNotesSidebar.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(viewModel.showNotesSidebar ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(viewModel.showNotesSidebar ? "Hide Notes List" : "Show Notes List")

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(viewModel.selectedColor.color)
                        Text("Quick Scratchpad")
                            .font(.headline.bold())
                    }
                    Text("Distraction-free thoughts and scratch notes.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 16)

            // 5 Color Tab Pills (Horizontal Dots with Halo Selection Rings)
            HStack(spacing: 8) {
                ForEach(ScratchpadColor.allCases) { color in
                    colorTabButton(for: color)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.04))
            )
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 16)

            // Header Action Buttons
            HStack(spacing: 8) {
                // New Note Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        _ = viewModel.createNote()
                        isTitleFocused = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Note")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Create a new note in the selected category")

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
                        Text(copiedFeedback ? "Copied!" : "Copy")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(copiedFeedback ? Color.green : Color.primary)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Copy current note content to clipboard")

                // Delete Button
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Delete current note")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Color Tab Button (Clean Horizontal Dots with Halo Ring)
    private func colorTabButton(for color: ScratchpadColor) -> some View {
        let isSelected = viewModel.selectedColor == color
        let hasContent = !viewModel.isNoteEmpty(for: color)

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                viewModel.selectColor(color)
            }
        } label: {
            HStack(spacing: 7) {
                // Color Dot with Halo Ring
                ZStack {
                    if isSelected {
                        Circle()
                            .strokeBorder(color.color.opacity(0.7), lineWidth: 2)
                            .frame(width: 20, height: 20)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Circle()
                        .fill(color.color)
                        .frame(width: isSelected ? 12 : 12, height: isSelected ? 12 : 12)
                        .shadow(color: isSelected ? color.color.opacity(0.4) : .clear, radius: 2, x: 0, y: 1)

                    if hasContent && !isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 3.5, height: 3.5)
                    }
                }
                .frame(width: 20, height: 20)

                // Horizontal Label
                Text(color.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? color.color : Color.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? color.color.opacity(0.14) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color.color.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("\(color.rawValue) Category")
    }

    // MARK: - Notes Sidebar (List / Selector)
    private var notesSidebar: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                TextField("Search notes...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Color Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    filterChip(title: "All", color: nil)
                    ForEach(ScratchpadColor.allCases) { color in
                        filterChip(title: color.rawValue, color: color)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }

            Divider()

            // Saved Notes Scroll List
            if viewModel.filteredNotes.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text(viewModel.searchQuery.isEmpty ? "No notes found" : "No matching notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !viewModel.searchQuery.isEmpty {
                        Button("Clear Search") {
                            viewModel.searchQuery = ""
                        }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.filteredNotes) { note in
                            noteCardRow(for: note)
                        }
                    }
                    .padding(8)
                }
            }

            Divider()

            // Sidebar Footer
            HStack {
                Text("\(viewModel.filteredNotes.count) \(viewModel.filteredNotes.count == 1 ? "note" : "notes")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        _ = viewModel.createNote()
                        isTitleFocused = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(viewModel.selectedColor.color)
                }
                .buttonStyle(.plain)
                .help("Add new note")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.7))
    }

    // MARK: - Color Filter Chip
    private func filterChip(title: String, color: ScratchpadColor?) -> some View {
        let isSelected = viewModel.selectedFilterColor == color

        return Button {
            withAnimation(.spring(response: 0.25)) {
                viewModel.selectedFilterColor = color
            }
        } label: {
            HStack(spacing: 4) {
                if let color = color {
                    Circle()
                        .fill(color.color)
                        .frame(width: 7, height: 7)
                }
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? (color?.color ?? Color.primary) : Color.secondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isSelected ? (color?.color.opacity(0.15) ?? Color.primary.opacity(0.1)) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? (color?.color.opacity(0.3) ?? Color.primary.opacity(0.2)) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note Card Row
    private func noteCardRow(for note: ScratchpadNote) -> some View {
        let isSelected = viewModel.selectedNoteId == note.id

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                viewModel.selectNote(note)
            }
        } label: {
            HStack(alignment: .top, spacing: 8) {
                // Color Accent Strip
                RoundedRectangle(cornerRadius: 2)
                    .fill(note.color.color)
                    .frame(width: 3.5)
                    .padding(.vertical, 2)

                // Note Details
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(note.displayTitle)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.85))
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(note.color.color)
                        }
                    }

                    Text(note.snippet)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack {
                        Text(note.formattedDate)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)

                        Spacer()

                        Text("\(note.wordCount)w")
                            .font(.system(size: 10).monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? note.color.color.opacity(0.14) : Color.primary.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? note.color.color.opacity(0.35) : Color.primary.opacity(0.04), lineWidth: 1)
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

    // MARK: - Editor Panel
    private var editorPanel: some View {
        VStack(spacing: 0) {
            // Note Title & Meta Bar
            HStack(spacing: 12) {
                // Color Picker Menu
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
                    Circle()
                        .fill(viewModel.currentNote.color.color)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Change category color")

                // Editable Title
                TextField("Untitled Note", text: $viewModel.currentTitle)
                    .font(.title3.weight(.bold))
                    .textFieldStyle(.plain)
                    .focused($isTitleFocused)
                    .onChange(of: viewModel.currentTitle) { _, _ in
                        viewModel.saveToUserDefaults()
                    }

                Spacer()

                // Pin Button
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        viewModel.togglePin(for: viewModel.currentNote)
                    }
                } label: {
                    Image(systemName: viewModel.currentNote.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 13))
                        .foregroundStyle(viewModel.currentNote.isPinned ? viewModel.selectedColor.color : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(viewModel.currentNote.isPinned ? "Unpin Note" : "Pin Note")

                // Last Updated Timestamp
                Text("Edited " + viewModel.currentNote.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .padding(.bottom, 6)

            // Main TextEditor Container
            ZStack(alignment: .topLeading) {
                // Background tint matching category
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                viewModel.selectedColor.color.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                // TextEditor with real-time keystroke saving
                TextEditor(text: $viewModel.currentContent)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .lineSpacing(5)
                    .focused($isEditorFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                    .onChange(of: viewModel.currentContent) { _, _ in
                        viewModel.saveToUserDefaults()
                    }

                // Placeholder
                if viewModel.currentContent.isEmpty {
                    Text("Jot down quick thoughts, ideas, or snippets while staying in deep focus...")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 32)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Bottom Status Bar
    private var bottomStatusBar: some View {
        HStack(spacing: 16) {
            // Active Tab Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.selectedColor.color)
                    .frame(width: 8, height: 8)
                Text("\(viewModel.selectedColor.rawValue) Category")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Word, Character, and Line Counts
            HStack(spacing: 12) {
                Text("\(viewModel.wordCount) \(viewModel.wordCount == 1 ? "word" : "words")")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text("\(viewModel.characterCount) \(viewModel.characterCount == 1 ? "character" : "characters")")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text("\(viewModel.lineCount) \(viewModel.lineCount == 1 ? "line" : "lines")")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Auto-saved Status Indicator
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("Saved")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.9))
    }
}
