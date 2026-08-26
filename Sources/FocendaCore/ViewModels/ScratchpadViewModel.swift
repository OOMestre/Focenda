import Foundation
import SwiftUI
import Observation
import AppKit

/// Five color-coded scratchpad categories in calm organic tones
public enum ScratchpadColor: String, CaseIterable, Identifiable, Codable {
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

/// Represents an individual scratchpad note item
public struct ScratchpadNote: Identifiable, Codable, Equatable {
    public var id: UUID
    public var color: ScratchpadColor
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isPinned: Bool

    public init(
        id: UUID = UUID(),
        color: ScratchpadColor = .amber,
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.color = color
        self.title = title.isEmpty ? color.rawValue : title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }

    enum CodingKeys: String, CodingKey {
        case id, color, title, content, createdAt, updatedAt, isPinned
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.color = try container.decode(ScratchpadColor.self, forKey: .color)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? updatedAt
        self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false

        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let idString = try? container.decode(String.self, forKey: .id), let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID()
        }

        if self.title.isEmpty {
            self.title = self.color.rawValue
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
}

/// Manages quick distraction-free scratchpads with multi-tab persistence and notes list
@Observable
public final class ScratchpadViewModel {
    public static let userDefaultsKey = "focenda_scratchpads"

    public var notes: [ScratchpadNote] = []
    public var selectedNoteId: UUID?
    public var selectedColor: ScratchpadColor = .amber
    public var searchQuery: String = ""
    public var selectedFilterColor: ScratchpadColor?
    public var showNotesSidebar: Bool = true

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFromUserDefaults()
    }

    public var filteredNotes: [ScratchpadNote] {
        notes.filter { note in
            let matchesColor = selectedFilterColor == nil || note.color == selectedFilterColor
            let matchesSearch: Bool
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchQuery.lowercased()
                matchesSearch = note.title.lowercased().contains(query) ||
                    note.content.lowercased().contains(query) ||
                    note.color.rawValue.lowercased().contains(query)
            }
            return matchesColor && matchesSearch
        }
        .sorted { (lhs: ScratchpadNote, rhs: ScratchpadNote) -> Bool in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    public var currentNote: ScratchpadNote {
        get {
            if let selectedId = selectedNoteId, let note = notes.first(where: { $0.id == selectedId }) {
                return note
            }
            if let note = notes.first(where: { $0.color == selectedColor }) {
                return note
            }
            if let first = notes.first {
                return first
            }
            return ScratchpadNote(color: selectedColor)
        }
        set {
            if let index = notes.firstIndex(where: { $0.id == newValue.id }) {
                notes[index] = newValue
                selectedColor = newValue.color
                saveToUserDefaults()
            } else if let index = notes.firstIndex(where: { $0.color == selectedColor }) {
                notes[index] = newValue
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
    public func createNote(color: ScratchpadColor? = nil, title: String = "", content: String = "") -> ScratchpadNote {
        let noteColor = color ?? selectedColor
        let newTitle = title.isEmpty ? "\(noteColor.rawValue) Scratchpad" : title
        let note = ScratchpadNote(
            color: noteColor,
            title: newTitle,
            content: content
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
            let fallback = ScratchpadNote(color: selectedColor)
            notes.append(fallback)
            selectedNoteId = fallback.id
        } else if selectedNoteId == id {
            selectedNoteId = notes.first?.id
            if let first = notes.first {
                selectedColor = first.color
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
        } else if let index = notes.firstIndex(where: { $0.color == selectedColor }) {
            notes[index].content = text
            notes[index].updatedAt = Date()
            saveToUserDefaults()
        }
    }

    public func updateTitle(_ title: String) {
        let targetId = currentNote.id
        if let index = notes.firstIndex(where: { $0.id == targetId }) {
            notes[index].title = title
            notes[index].updatedAt = Date()
            saveToUserDefaults()
        } else if let index = notes.firstIndex(where: { $0.color == selectedColor }) {
            notes[index].title = title
            notes[index].updatedAt = Date()
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

    public func loadFromUserDefaults() {
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
                ScratchpadNote(color: $0, title: "\($0.rawValue) Scratchpad")
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
}
