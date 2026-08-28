import Foundation
import SwiftUI
import Observation
import AppKit

/// Five color-coded scratchpad categories in calm organic tones
public enum ScratchpadColor: String, CaseIterable, Identifiable, Codable, Sendable {
    case amber = "Amber"
    case lavender = "Lavender"
    case sky = "Sky"
    case emerald = "Emerald"
    case rose = "Rose"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .amber:
            return Color(red: 0.72, green: 0.52, blue: 0.28)
        case .lavender:
            return Color(red: 0.48, green: 0.45, blue: 0.56)
        case .sky:
            return Color(red: 0.33, green: 0.48, blue: 0.56)
        case .emerald:
            return Color(red: 0.28, green: 0.45, blue: 0.36)
        case .rose:
            return Color(red: 0.68, green: 0.38, blue: 0.32)
        }
    }

    public var iconName: String {
        switch self {
        case .amber: return "sun.max.fill"
        case .lavender: return "sparkles"
        case .sky: return "cloud.fill"
        case .emerald: return "leaf.fill"
        case .rose: return "heart.fill"
        }
    }
}

/// Represents an individual scratchpad note item with folder organization
public struct ScratchpadNote: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var color: ScratchpadColor
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isPinned: Bool
    public var folder: String

    public init(
        id: UUID = UUID(),
        color: ScratchpadColor = .amber,
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        folder: String = "General"
    ) {
        self.id = id
        self.color = color
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.folder = folder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "General" : folder
    }

    enum CodingKeys: String, CodingKey {
        case id, color, title, content, createdAt, updatedAt, isPinned, folder
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = try container.decode(ScratchpadColor.self, forKey: .color)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? updatedAt
        self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        self.folder = try container.decodeIfPresent(String.self, forKey: .folder) ?? "General"

        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let idString = try? container.decode(String.self, forKey: .id), let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID()
        }
    }

    public var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        let firstLine = content
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
            .trimmingCharacters(in: .whitespaces) ?? ""
        if !firstLine.isEmpty {
            return String(firstLine.prefix(40))
        }
        return "\(color.rawValue) Note"
    }

    public var snippet: String {
        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if lines.isEmpty {
            return "No additional text"
        }
        return lines.joined(separator: " ")
    }

    public var wordCount: Int {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return 0 }
        return trimmed.split { $0.isWhitespace || $0.isNewline }.count
    }

    public var characterCount: Int {
        content.count
    }

    public var lineCount: Int {
        if content.isEmpty { return 1 }
        return content.components(separatedBy: .newlines).count
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(updatedAt) {
            formatter.dateFormat = "HH:mm"
            return "Today, " + formatter.string(from: updatedAt)
        } else if calendar.isDateInYesterday(updatedAt) {
            formatter.dateFormat = "HH:mm"
            return "Yesterday, " + formatter.string(from: updatedAt)
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
            return formatter.string(from: updatedAt)
        }
    }

    public var relativeFormattedDate: String {
        let now = Date()
        let interval = now.timeIntervalSince(updatedAt)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = max(1, Int(interval / 60))
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = max(1, Int(interval / 3600))
            return "\(hours)h ago"
        } else if Calendar.current.isDateInYesterday(updatedAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: updatedAt)
        }
    }
}

/// Manages quick distraction-free scratchpads with folders/notebooks, color coding, and multi-note persistence
@Observable
public final class ScratchpadViewModel {
    public static let userDefaultsKey = "focenda_scratchpads"
    public static let foldersUserDefaultsKey = "focenda_scratchpad_folders"

    public static let defaultFolders = ["General", "Projects", "Work", "Personal", "Ideas"]
    public static let allNotesFolder = "All Notes"

    public var folders: [String] = ScratchpadViewModel.defaultFolders
    public var selectedFolder: String = ScratchpadViewModel.allNotesFolder
    public var notes: [ScratchpadNote] = []
    public var selectedNoteId: UUID?
    public var selectedColor: ScratchpadColor = .amber
    public var searchQuery: String = ""
    public var selectedFilterColor: ScratchpadColor?
    public var showFoldersSidebar: Bool = true
    public var showNotesSidebar: Bool = true

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFromUserDefaults()
    }

    /// SF Symbol icon associated with folder name
    public static func iconForFolder(_ folder: String) -> String {
        switch folder.lowercased() {
        case "all notes": return "tray.full"
        case "general": return "doc.text"
        case "projects": return "briefcase"
        case "work": return "building.2"
        case "personal": return "person"
        case "ideas": return "lightbulb"
        case "archive": return "archivebox"
        case "study", "learning": return "book"
        case "journal": return "book.closed"
        default: return "folder"
        }
    }

    /// Number of notes inside a specific folder
    public func noteCount(for folder: String) -> Int {
        if folder == Self.allNotesFolder {
            return notes.count
        }
        return notes.filter { $0.folder.caseInsensitiveCompare(folder) == .orderedSame }.count
    }

    /// Notes filtered by active folder, color category, and search query
    public var filteredNotes: [ScratchpadNote] {
        notes.filter { note in
            let matchesFolder: Bool
            if selectedFolder == Self.allNotesFolder {
                matchesFolder = true
            } else {
                matchesFolder = note.folder.caseInsensitiveCompare(selectedFolder) == .orderedSame
            }

            let matchesColor = selectedFilterColor == nil || note.color == selectedFilterColor
            let matchesSearch: Bool
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchQuery.lowercased()
                matchesSearch = note.title.lowercased().contains(query) ||
                    note.content.lowercased().contains(query) ||
                    note.folder.lowercased().contains(query) ||
                    note.color.rawValue.lowercased().contains(query)
            }
            return matchesFolder && matchesColor && matchesSearch
        }
        .sorted { (lhs: ScratchpadNote, rhs: ScratchpadNote) -> Bool in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    /// The currently selected note, or a graceful fallback
    public var currentNote: ScratchpadNote {
        get {
            if let selectedId = selectedNoteId,
               let note = notes.first(where: { $0.id == selectedId }),
               (selectedFolder == Self.allNotesFolder || note.folder.caseInsensitiveCompare(selectedFolder) == .orderedSame) {
                return note
            }
            if let firstFiltered = filteredNotes.first {
                return firstFiltered
            }
            if selectedFolder == Self.allNotesFolder {
                if let note = notes.first(where: { $0.color == selectedColor }) {
                    return note
                }
                if let first = notes.first {
                    return first
                }
            }
            let activeFolder = selectedFolder == Self.allNotesFolder ? "General" : selectedFolder
            return ScratchpadNote(color: selectedColor, folder: activeFolder)
        }
        set {
            if let index = notes.firstIndex(where: { $0.id == newValue.id }) {
                notes[index] = newValue
                selectedColor = newValue.color
                saveToUserDefaults()
            } else if let index = notes.firstIndex(where: { $0.color == selectedColor }) {
                notes[index] = newValue
                saveToUserDefaults()
            } else {
                notes.insert(newValue, at: 0)
                selectedNoteId = newValue.id
                selectedColor = newValue.color
                saveToUserDefaults()
            }
        }
    }

    public var currentContent: String {
        get {
            currentNote.content
        }
        set {
            updateContent(newValue)
        }
    }

    public var currentTitle: String {
        get {
            currentNote.title
        }
        set {
            updateTitle(newValue)
        }
    }

    public var characterCount: Int {
        currentNote.characterCount
    }

    public var wordCount: Int {
        currentNote.wordCount
    }

    public var lineCount: Int {
        currentNote.lineCount
    }

    // MARK: - Folder Management

    public func selectFolder(_ folder: String) {
        selectedFolder = folder
        if let firstInFolder = filteredNotes.first {
            selectedNoteId = firstInFolder.id
            selectedColor = firstInFolder.color
        } else {
            selectedNoteId = nil
        }
    }

    @discardableResult
    public func createFolder(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.caseInsensitiveCompare(Self.allNotesFolder) == .orderedSame { return false }
        if folders.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            selectedFolder = trimmed
            return true
        }

        folders.append(trimmed)
        selectedFolder = trimmed
        saveFoldersToUserDefaults()
        return true
    }

    public func deleteFolder(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.caseInsensitiveCompare(Self.allNotesFolder) != .orderedSame else { return }

        // Reassign any notes in this folder to General
        let fallbackFolder = folders.first(where: { $0 != trimmed }) ?? "General"
        for i in 0..<notes.count {
            if notes[i].folder.caseInsensitiveCompare(trimmed) == .orderedSame {
                notes[i].folder = fallbackFolder
                notes[i].updatedAt = Date()
            }
        }

        folders.removeAll(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        if folders.isEmpty {
            folders = ["General"]
        }

        if selectedFolder.caseInsensitiveCompare(trimmed) == .orderedSame {
            selectedFolder = Self.allNotesFolder
        }

        saveToUserDefaults()
        saveFoldersToUserDefaults()
    }

    public func moveNote(id: UUID, to folder: String) {
        let targetFolder = folder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !targetFolder.isEmpty && targetFolder != Self.allNotesFolder else { return }

        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].folder = targetFolder
            notes[index].updatedAt = Date()
            saveToUserDefaults()
        }
    }

    public func moveNote(_ note: ScratchpadNote, to folder: String) {
        moveNote(id: note.id, to: folder)
    }

    public func moveCurrentNote(to folder: String) {
        moveNote(id: currentNote.id, to: folder)
    }

    // MARK: - Note Selection & Management

    public func selectNote(_ note: ScratchpadNote) {
        selectedNoteId = note.id
        selectedColor = note.color
    }

    public func selectNote(id: UUID) {
        selectedNoteId = id
        if let note = notes.first(where: { $0.id == id }) {
            selectedColor = note.color
        }
    }

    public func selectColor(_ color: ScratchpadColor) {
        selectedColor = color
        if let note = notes.first(where: { $0.color == color }) {
            selectedNoteId = note.id
        } else {
            let newNote = createNote(color: color)
            selectedNoteId = newNote.id
        }
    }

    @discardableResult
    public func createNote(
        color: ScratchpadColor? = nil,
        title: String = "",
        content: String = "",
        folder: String? = nil
    ) -> ScratchpadNote {
        let noteColor = color ?? selectedFilterColor ?? selectedColor
        let targetFolder: String
        if let folder = folder, !folder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            targetFolder = folder
        } else if selectedFolder != Self.allNotesFolder {
            targetFolder = selectedFolder
        } else {
            targetFolder = "General"
        }

        let newTitle = title.isEmpty ? "\(noteColor.rawValue) Scratchpad" : title
        let note = ScratchpadNote(
            color: noteColor,
            title: newTitle,
            content: content,
            folder: targetFolder
        )
        notes.insert(note, at: 0)
        selectedNoteId = note.id
        selectedColor = noteColor
        saveToUserDefaults()
        return note
    }

    public func deleteNote(id: UUID) {
        notes.removeAll(where: { $0.id == id })
        if notes.isEmpty {
            let activeFolder = selectedFolder == Self.allNotesFolder ? "General" : selectedFolder
            let fallback = ScratchpadNote(
                color: selectedColor,
                title: "\(selectedColor.rawValue) Scratchpad",
                folder: activeFolder
            )
            notes.append(fallback)
            selectedNoteId = fallback.id
        } else if selectedNoteId == id {
            selectedNoteId = filteredNotes.first?.id ?? notes.first?.id
            if let selected = notes.first(where: { $0.id == selectedNoteId }) {
                selectedColor = selected.color
            }
        }
        saveToUserDefaults()
    }

    public func deleteNote(_ note: ScratchpadNote) {
        deleteNote(id: note.id)
    }

    public func deleteCurrentNote() {
        deleteNote(id: currentNote.id)
    }

    public func togglePin(for note: ScratchpadNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            notes[index].updatedAt = Date()
            saveToUserDefaults()
        }
    }

    public func updateContent(_ text: String) {
        let targetId = currentNote.id
        if let index = notes.firstIndex(where: { $0.id == targetId }) {
            notes[index].content = text
            notes[index].updatedAt = Date()
            saveToUserDefaults()
        } else if selectedFolder == Self.allNotesFolder, let index = notes.firstIndex(where: { $0.color == selectedColor }) {
            notes[index].content = text
            notes[index].updatedAt = Date()
            saveToUserDefaults()
        } else {
            let activeFolder = selectedFolder == Self.allNotesFolder ? "General" : selectedFolder
            var newNote = ScratchpadNote(
                color: selectedColor,
                title: "\(selectedColor.rawValue) Scratchpad",
                content: text,
                folder: activeFolder
            )
            newNote.updatedAt = Date()
            notes.insert(newNote, at: 0)
            selectedNoteId = newNote.id
            saveToUserDefaults()
        }
    }

    public func updateTitle(_ title: String) {
        let targetId = currentNote.id
        if let index = notes.firstIndex(where: { $0.id == targetId }) {
            notes[index].title = title
            notes[index].updatedAt = Date()
            saveToUserDefaults()
        } else if selectedFolder == Self.allNotesFolder, let index = notes.firstIndex(where: { $0.color == selectedColor }) {
            notes[index].title = title
            notes[index].updatedAt = Date()
            saveToUserDefaults()
        } else {
            let activeFolder = selectedFolder == Self.allNotesFolder ? "General" : selectedFolder
            var newNote = ScratchpadNote(color: selectedColor, title: title, folder: activeFolder)
            newNote.updatedAt = Date()
            notes.insert(newNote, at: 0)
            selectedNoteId = newNote.id
            saveToUserDefaults()
        }
    }

    public func updateColor(_ color: ScratchpadColor) {
        let targetId = currentNote.id
        if let index = notes.firstIndex(where: { $0.id == targetId }) {
            notes[index].color = color
            notes[index].updatedAt = Date()
            selectedColor = color
            saveToUserDefaults()
        } else {
            selectedColor = color
        }
    }

    public func clearCurrentNote() {
        updateContent("")
    }

    public func copyCurrentNoteToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentContent, forType: .string)
    }

    public func note(for color: ScratchpadColor) -> ScratchpadNote? {
        notes.first(where: { $0.color == color })
    }

    public func isNoteEmpty(for color: ScratchpadColor) -> Bool {
        guard let note = note(for: color) else { return true }
        return note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Persistence

    public func loadFromUserDefaults() {
        // Load folders
        if let savedFolders = userDefaults.stringArray(forKey: Self.foldersUserDefaultsKey), !savedFolders.isEmpty {
            self.folders = savedFolders
        } else {
            self.folders = Self.defaultFolders
        }

        // Load notes
        if let data = userDefaults.data(forKey: Self.userDefaultsKey),
           let decoded = try? JSONDecoder().decode([ScratchpadNote].self, from: data),
           !decoded.isEmpty {
            self.notes = decoded
            self.selectedNoteId = decoded.first?.id
            if let firstColor = decoded.first?.color {
                self.selectedColor = firstColor
            }
        } else {
            self.notes = ScratchpadColor.allCases.map {
                ScratchpadNote(color: $0, title: "\($0.rawValue) Scratchpad", folder: "General")
            }
            self.selectedNoteId = self.notes.first?.id
            self.selectedColor = .amber
        }
    }

    public func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(notes) {
            userDefaults.set(data, forKey: Self.userDefaultsKey)
        }
    }

    public func saveFoldersToUserDefaults() {
        userDefaults.set(folders, forKey: Self.foldersUserDefaultsKey)
    }
}
