import Foundation
import Observation
import AppKit

/// Represents an individual scratchpad note item with folder organization.
///
/// Older versions stored a color category alongside each note. The custom
/// decoder intentionally ignores that legacy field so existing note content
/// remains readable after categories are removed.
public struct ScratchpadNote: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isPinned: Bool
    public var folder: String

    public init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        folder: String = "General"
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.folder = folder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "General" : folder
    }

    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, updatedAt, isPinned, folder
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
        return "Untitled Note"
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

/// Manages quick distraction-free scratchpads with folders/notebooks and multi-note persistence.
@Observable
public final class ScratchpadViewModel {
    public static let userDefaultsKey = "focenda_scratchpads"
    public static let foldersUserDefaultsKey = "focenda_scratchpad_folders"

    public static let defaultFolders = ["General", "Projects", "Work", "Personal", "Ideas"]
    public static let allNotesFolder = "All Notes"
    private static let legacyGeneratedTitles = [
        "Amber Scratchpad",
        "Lavender Scratchpad",
        "Sky Scratchpad",
        "Emerald Scratchpad",
        "Rose Scratchpad"
    ]

    public var folders: [String] = ScratchpadViewModel.defaultFolders
    public var selectedFolder: String = ScratchpadViewModel.allNotesFolder
    public var notes: [ScratchpadNote] = []
    public var selectedNoteId: UUID?
    public var searchQuery: String = ""
    public var showFoldersSidebar: Bool = true
    public var showNotesSidebar: Bool = true

    private let secureStore: SecureStore
    private var notesPersistenceReady = false
    private var foldersPersistenceReady = false

    public init(userDefaults: UserDefaults = .standard, secureStore: SecureStore? = nil) {
        self.secureStore = secureStore ?? SecureStore(defaults: userDefaults)
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

    /// Notes filtered by active folder and search query
    public var filteredNotes: [ScratchpadNote] {
        notes.filter { note in
            let matchesFolder: Bool
            if selectedFolder == Self.allNotesFolder {
                matchesFolder = true
            } else {
                matchesFolder = note.folder.caseInsensitiveCompare(selectedFolder) == .orderedSame
            }

            let matchesSearch: Bool
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchQuery.lowercased()
                matchesSearch = note.title.lowercased().contains(query) ||
                    note.content.lowercased().contains(query) ||
                    note.folder.lowercased().contains(query)
            }
            return matchesFolder && matchesSearch
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
            let activeFolder = selectedFolder == Self.allNotesFolder ? "General" : selectedFolder
            return ScratchpadNote(folder: activeFolder)
        }
        set {
            if let index = notes.firstIndex(where: { $0.id == newValue.id }) {
                notes[index] = newValue
                saveToUserDefaults()
            } else {
                notes.insert(newValue, at: 0)
                selectedNoteId = newValue.id
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
    }

    public func selectNote(id: UUID) {
        selectedNoteId = id
    }

    @discardableResult
    public func createNote(
        title: String = "",
        content: String = "",
        folder: String? = nil
    ) -> ScratchpadNote {
        let targetFolder: String
        if let folder = folder, !folder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            targetFolder = folder
        } else if selectedFolder != Self.allNotesFolder {
            targetFolder = selectedFolder
        } else {
            targetFolder = "General"
        }

        let newTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : title
        let note = ScratchpadNote(
            title: newTitle,
            content: content,
            folder: targetFolder
        )
        notes.insert(note, at: 0)
        selectedNoteId = note.id
        saveToUserDefaults()
        return note
    }

    public func deleteNote(id: UUID) {
        notes.removeAll(where: { $0.id == id })
        if selectedNoteId == id {
            selectedNoteId = filteredNotes.first?.id ?? notes.first?.id
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
        } else {
            let activeFolder = selectedFolder == Self.allNotesFolder ? "General" : selectedFolder
            var newNote = ScratchpadNote(
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
        } else {
            let activeFolder = selectedFolder == Self.allNotesFolder ? "General" : selectedFolder
            var newNote = ScratchpadNote(title: title, folder: activeFolder)
            newNote.updatedAt = Date()
            notes.insert(newNote, at: 0)
            selectedNoteId = newNote.id
            saveToUserDefaults()
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

    // MARK: - Persistence

    public func loadFromUserDefaults() {
        // Load folders
        if !secureStore.containsValue(forKey: Self.foldersUserDefaultsKey) {
            self.folders = Self.defaultFolders
            foldersPersistenceReady = true
        } else if let savedFolders = secureStore.stringArray(forKey: Self.foldersUserDefaultsKey), !savedFolders.isEmpty {
            self.folders = savedFolders
            foldersPersistenceReady = true
        } else {
            // Keep the visible defaults when the saved folder payload is
            // unreadable, but do not allow them to overwrite the payload.
            self.folders = Self.defaultFolders
            foldersPersistenceReady = false
        }

        // Load notes. An explicitly saved empty array is a valid state: the
        // Scratchpad should remain empty until the user creates a note.
        if !secureStore.containsValue(forKey: Self.userDefaultsKey) {
            self.notes = []
            self.selectedNoteId = nil
            notesPersistenceReady = true
        } else if let data = secureStore.data(forKey: Self.userDefaultsKey),
                  let decoded = try? JSONDecoder().decode([ScratchpadNote].self, from: data) {
            let migrated = Self.migrateLegacyNotes(decoded)
            self.notes = migrated
            self.selectedNoteId = migrated.first?.id
            notesPersistenceReady = true

            if migrated != decoded {
                saveToUserDefaults()
            }
        } else {
            self.notes = []
            self.selectedNoteId = nil
            notesPersistenceReady = false
        }
    }

    private static func migrateLegacyNotes(_ notes: [ScratchpadNote]) -> [ScratchpadNote] {
        notes.compactMap { note in
            guard legacyGeneratedTitles.contains(note.title) else {
                return note
            }

            // The original five empty placeholders were categories, not user
            // notes. Remove them during migration. If a user wrote content in
            // one before upgrading, keep the content but discard the generic
            // generated title.
            if note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return nil
            }

            var migratedNote = note
            migratedNote.title = ""
            return migratedNote
        }
    }

    public func saveToUserDefaults() {
        guard notesPersistenceReady else { return }
        if let data = try? JSONEncoder().encode(notes) {
            secureStore.setData(data, forKey: Self.userDefaultsKey)
        }
    }

    public func saveFoldersToUserDefaults() {
        guard foldersPersistenceReady else { return }
        secureStore.set(folders, forKey: Self.foldersUserDefaultsKey)
    }
}
