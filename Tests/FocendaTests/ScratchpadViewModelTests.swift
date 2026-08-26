import XCTest
@testable import FocendaCore

final class ScratchpadViewModelTests: XCTestCase {

    var testDefaults: UserDefaults!
    private let testKey = "test_focenda_scratchpads_isolated"

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults.standard
        testDefaults.removeObject(forKey: testKey)
        testDefaults.removeObject(forKey: ScratchpadViewModel.userDefaultsKey)
        testDefaults.removeObject(forKey: ScratchpadViewModel.foldersUserDefaultsKey)
    }

    override func tearDown() {
        testDefaults.removeObject(forKey: testKey)
        testDefaults.removeObject(forKey: ScratchpadViewModel.userDefaultsKey)
        testDefaults.removeObject(forKey: ScratchpadViewModel.foldersUserDefaultsKey)
        testDefaults = nil
        super.tearDown()
    }

    func testInitializationCreatesFiveColors() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)

        XCTAssertEqual(viewModel.notes.count, 5)
        XCTAssertEqual(viewModel.selectedColor, .amber)
        XCTAssertEqual(viewModel.selectedNoteId, viewModel.notes.first?.id)

        let expectedColors: [ScratchpadColor] = [.amber, .lavender, .sky, .emerald, .rose]
        for (index, color) in expectedColors.enumerated() {
            XCTAssertEqual(viewModel.notes[index].color, color)
            XCTAssertTrue(viewModel.notes[index].content.isEmpty)
            XCTAssertEqual(viewModel.notes[index].title, "\(color.rawValue) Scratchpad")
            XCTAssertEqual(viewModel.notes[index].folder, "General")
        }
    }

    func testSelectColorChangesActiveNote() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)

        viewModel.selectColor(.lavender)
        XCTAssertEqual(viewModel.selectedColor, .lavender)
        XCTAssertEqual(viewModel.currentNote.color, .lavender)

        viewModel.selectColor(.emerald)
        XCTAssertEqual(viewModel.selectedColor, .emerald)
        XCTAssertEqual(viewModel.currentNote.color, .emerald)
    }

    func testUpdateContentAndPersistence() {
        let viewModel1 = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel1.selectColor(.amber)
        viewModel1.updateContent("Amber test content")

        viewModel1.selectColor(.sky)
        viewModel1.updateContent("Sky test ideas")

        // Create new viewmodel instance backed by same UserDefaults to verify persistence
        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.note(for: .amber)?.content, "Amber test content")
        XCTAssertEqual(viewModel2.note(for: .sky)?.content, "Sky test ideas")
        XCTAssertEqual(viewModel2.note(for: .rose)?.content, "")
    }

    func testKeystrokePersistence() {
        let viewModel1 = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel1.currentTitle = "Instant Title"
        viewModel1.currentContent = "Keystroke character 1"

        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.currentTitle, "Instant Title")
        XCTAssertEqual(viewModel2.currentContent, "Keystroke character 1")

        // Simulate typing keystroke by keystroke
        viewModel1.currentContent = "Keystroke character 12"
        let viewModel3 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel3.currentContent, "Keystroke character 12")
    }

    func testWordAndCharacterAndLineCount() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)

        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertEqual(viewModel.wordCount, 0)
        XCTAssertEqual(viewModel.lineCount, 1)

        viewModel.updateContent("Focus produces deep quality work.")
        XCTAssertEqual(viewModel.wordCount, 5)
        XCTAssertEqual(viewModel.characterCount, 33)
        XCTAssertEqual(viewModel.lineCount, 1)

        // Multiple spaces and newlines
        viewModel.updateContent("  One   Two  \n Three   \n\n Four ")
        XCTAssertEqual(viewModel.wordCount, 4)
        XCTAssertEqual(viewModel.lineCount, 4)
    }

    func testCreateNewNote() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let initialCount = viewModel.notes.count

        let newNote = viewModel.createNote(color: .rose, title: "Sprint Backlog", content: "Refactor engine", folder: "Projects")
        XCTAssertEqual(viewModel.notes.count, initialCount + 1)
        XCTAssertEqual(viewModel.selectedNoteId, newNote.id)
        XCTAssertEqual(viewModel.selectedColor, .rose)
        XCTAssertEqual(viewModel.currentNote.title, "Sprint Backlog")
        XCTAssertEqual(viewModel.currentNote.content, "Refactor engine")
        XCTAssertEqual(viewModel.currentNote.folder, "Projects")

        // Check persistence
        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.notes.count, initialCount + 1)
        XCTAssertEqual(viewModel2.notes.first?.title, "Sprint Backlog")
        XCTAssertEqual(viewModel2.notes.first?.folder, "Projects")
    }

    func testDeleteNote() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let initialCount = viewModel.notes.count

        let targetNote = viewModel.notes[1]
        viewModel.deleteNote(id: targetNote.id)
        XCTAssertEqual(viewModel.notes.count, initialCount - 1)
        XCTAssertNil(viewModel.notes.first(where: { $0.id == targetNote.id }))

        // Delete notes until single note remains, then delete it to test graceful fallback
        let notesToDelete = viewModel.notes
        for note in notesToDelete {
            viewModel.deleteNote(id: note.id)
        }
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertNotNil(viewModel.selectedNoteId)
    }

    func testClearCurrentNote() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.selectColor(.emerald)
        viewModel.updateContent("Temporary scratch note")
        XCTAssertFalse(viewModel.isNoteEmpty(for: .emerald))

        viewModel.clearCurrentNote()
        XCTAssertTrue(viewModel.isNoteEmpty(for: .emerald))
        XCTAssertEqual(viewModel.currentContent, "")
    }

    func testUpdateTitle() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.selectColor(.rose)
        viewModel.updateTitle("Meeting Notes")

        XCTAssertEqual(viewModel.currentNote.title, "Meeting Notes")

        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.note(for: .rose)?.title, "Meeting Notes")
    }

    func testUpdateColor() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel.currentNote.color, .amber)

        viewModel.updateColor(.lavender)
        XCTAssertEqual(viewModel.currentNote.color, .lavender)
        XCTAssertEqual(viewModel.selectedColor, .lavender)

        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.notes.first?.color, .lavender)
    }

    func testSearchAndFilterNotes() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.notes[0].title = "Swift Architecture"
        viewModel.notes[0].content = "Explore Observation framework"

        viewModel.notes[1].title = "Grocery List"
        viewModel.notes[1].content = "Apples and oranges"

        viewModel.searchQuery = "Architecture"
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.title, "Swift Architecture")

        viewModel.searchQuery = "apples"
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.title, "Grocery List")

        viewModel.searchQuery = ""
        viewModel.selectedFilterColor = .amber
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.color, .amber)
    }

    func testTogglePin() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let lastNote = viewModel.notes.last!
        XCTAssertFalse(lastNote.isPinned)

        viewModel.togglePin(for: lastNote)
        XCTAssertTrue(viewModel.notes.first(where: { $0.id == lastNote.id })?.isPinned == true)
        XCTAssertEqual(viewModel.filteredNotes.first?.id, lastNote.id)
    }

    func testRelativeFormattedDate() {
        var note = ScratchpadNote(color: .sky, title: "Quick Note", content: "Content")
        note.updatedAt = Date()
        XCTAssertEqual(note.relativeFormattedDate, "Just now")

        note.updatedAt = Date().addingTimeInterval(-120) // 2 mins ago
        XCTAssertEqual(note.relativeFormattedDate, "2m ago")

        note.updatedAt = Date().addingTimeInterval(-7200) // 2 hours ago
        XCTAssertEqual(note.relativeFormattedDate, "2h ago")

        note.updatedAt = Date().addingTimeInterval(-172800) // 2 days ago
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        XCTAssertEqual(note.relativeFormattedDate, formatter.string(from: note.updatedAt))
    }

    func testDisplayTitleAndSnippet() {
        var note = ScratchpadNote(color: .emerald, title: "", content: "")
        XCTAssertEqual(note.displayTitle, "Emerald Note")

        note.content = "First line header\nSecond line content"
        XCTAssertEqual(note.displayTitle, "First line header")

        note.title = "Explicit Title"
        XCTAssertEqual(note.displayTitle, "Explicit Title")
        XCTAssertEqual(note.snippet, "First line header Second line content")
    }

    func testBackwardsCompatibilityDecoding() throws {
        // Mock legacy JSON without UUID id or folder
        let legacyJson = """
        [
            {"color": "Amber", "title": "Old Amber", "content": "Legacy content", "updatedAt": 1724630000},
            {"color": "Lavender", "title": "Old Lavender", "content": "", "updatedAt": 1724630000}
        ]
        """.data(using: .utf8)!

        testDefaults.set(legacyJson, forKey: ScratchpadViewModel.userDefaultsKey)

        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel.notes.count, 2)
        XCTAssertEqual(viewModel.notes[0].color, .amber)
        XCTAssertEqual(viewModel.notes[0].title, "Old Amber")
        XCTAssertEqual(viewModel.notes[0].content, "Legacy content")
        XCTAssertEqual(viewModel.notes[0].folder, "General")
    }

    func testTimerAdjustTime() {
        let timerVM = FocusTimerViewModel()
        let initialTime = timerVM.timeRemainingSeconds

        timerVM.adjustTime(byMinutes: 5)
        XCTAssertEqual(timerVM.timeRemainingSeconds, initialTime + 300)

        timerVM.adjustTime(byMinutes: -5)
        XCTAssertEqual(timerVM.timeRemainingSeconds, initialTime)

        // Test clamping to minimum 60 seconds
        timerVM.adjustTime(byMinutes: -100)
        XCTAssertEqual(timerVM.timeRemainingSeconds, 60)
    }

    // MARK: - Folder & Notebook Organization Tests

    func testDefaultFoldersInitialization() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel.folders, ["General", "Projects", "Work", "Personal", "Ideas"])
        XCTAssertEqual(viewModel.selectedFolder, ScratchpadViewModel.allNotesFolder)
        XCTAssertEqual(viewModel.noteCount(for: "General"), 5)
        XCTAssertEqual(viewModel.noteCount(for: "Projects"), 0)
    }

    func testCreateNewFolder() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let created = viewModel.createFolder("Design System")
        XCTAssertTrue(created)
        XCTAssertTrue(viewModel.folders.contains("Design System"))
        XCTAssertEqual(viewModel.selectedFolder, "Design System")

        // Creating note now creates it directly in Design System
        let note = viewModel.createNote(title: "Typography Scale")
        XCTAssertEqual(note.folder, "Design System")
        XCTAssertEqual(viewModel.noteCount(for: "Design System"), 1)

        // Duplicate folder creation selects existing without adding duplicate
        let countBefore = viewModel.folders.count
        let createdDuplicate = viewModel.createFolder("design system")
        XCTAssertTrue(createdDuplicate)
        XCTAssertEqual(viewModel.folders.count, countBefore)
    }

    func testDeleteFolderReassignsNotes() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.createFolder("Sprint 42")
        let note = viewModel.createNote(title: "Sprint Tasks", folder: "Sprint 42")
        XCTAssertEqual(viewModel.noteCount(for: "Sprint 42"), 1)

        viewModel.deleteFolder("Sprint 42")
        XCTAssertFalse(viewModel.folders.contains("Sprint 42"))
        XCTAssertEqual(viewModel.selectedFolder, ScratchpadViewModel.allNotesFolder)

        // The note should be reassigned to General
        let reassignedNote = viewModel.notes.first(where: { $0.id == note.id })
        XCTAssertEqual(reassignedNote?.folder, "General")
        XCTAssertEqual(viewModel.noteCount(for: "General"), 6)
    }

    func testMoveNoteToFolder() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let note = viewModel.notes[0]
        XCTAssertEqual(note.folder, "General")

        viewModel.moveNote(note, to: "Work")
        let updatedNote = viewModel.notes.first(where: { $0.id == note.id })
        XCTAssertEqual(updatedNote?.folder, "Work")
        XCTAssertEqual(viewModel.noteCount(for: "Work"), 1)
        XCTAssertEqual(viewModel.noteCount(for: "General"), 4)

        // Verify persistence
        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.notes.first(where: { $0.id == note.id })?.folder, "Work")
    }

    func testFilterNotesByActiveFolder() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.createNote(title: "Work Doc", content: "Meeting", folder: "Work")
        viewModel.createNote(title: "Personal Habit", content: "Gym", folder: "Personal")

        // In All Notes, both are visible
        viewModel.selectFolder(ScratchpadViewModel.allNotesFolder)
        XCTAssertEqual(viewModel.filteredNotes.count, 7)

        // In Work, only Work notes are visible
        viewModel.selectFolder("Work")
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.title, "Work Doc")

        // In Personal, only Personal notes are visible
        viewModel.selectFolder("Personal")
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.title, "Personal Habit")
    }

    func testFolderIcons() {
        XCTAssertEqual(ScratchpadViewModel.iconForFolder("All Notes"), "tray.full")
        XCTAssertEqual(ScratchpadViewModel.iconForFolder("General"), "doc.text")
        XCTAssertEqual(ScratchpadViewModel.iconForFolder("Projects"), "briefcase")
        XCTAssertEqual(ScratchpadViewModel.iconForFolder("Work"), "building.2")
        XCTAssertEqual(ScratchpadViewModel.iconForFolder("Personal"), "person")
        XCTAssertEqual(ScratchpadViewModel.iconForFolder("Ideas"), "lightbulb")
        XCTAssertEqual(ScratchpadViewModel.iconForFolder("CustomXYZ"), "folder")
    }
}
