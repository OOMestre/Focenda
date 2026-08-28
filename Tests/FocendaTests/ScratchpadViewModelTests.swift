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

    func testInitializationStartsWithoutNotes() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)

        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertNil(viewModel.selectedNoteId)
        XCTAssertEqual(viewModel.filteredNotes.count, 0)
        XCTAssertEqual(viewModel.currentNote.displayTitle, "Untitled Note")
    }

    func testUpdateContentAndPersistence() {
        let viewModel1 = ScratchpadViewModel(userDefaults: testDefaults)
        let focusNote = viewModel1.createNote(title: "Focus Notes")
        viewModel1.selectNote(focusNote)
        viewModel1.updateContent("Amber test content")

        let ideasNote = viewModel1.createNote(title: "Ideas")
        viewModel1.selectNote(ideasNote)
        viewModel1.updateContent("Sky test ideas")

        // Create new viewmodel instance backed by same UserDefaults to verify persistence
        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.notes.first(where: { $0.title == "Focus Notes" })?.content, "Amber test content")
        XCTAssertEqual(viewModel2.notes.first(where: { $0.title == "Ideas" })?.content, "Sky test ideas")
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

        let newNote = viewModel.createNote(title: "Sprint Backlog", content: "Refactor engine", folder: "Projects")
        XCTAssertEqual(viewModel.notes.count, initialCount + 1)
        XCTAssertEqual(viewModel.selectedNoteId, newNote.id)
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
        let firstNote = viewModel.createNote(title: "First")
        let targetNote = viewModel.createNote(title: "Target")
        _ = viewModel.createNote(title: "Last")
        let initialCount = viewModel.notes.count

        viewModel.deleteNote(id: targetNote.id)
        XCTAssertEqual(viewModel.notes.count, initialCount - 1)
        XCTAssertNil(viewModel.notes.first(where: { $0.id == targetNote.id }))

        // Deleting the final note leaves the Scratchpad empty.
        let notesToDelete = viewModel.notes
        for note in notesToDelete {
            viewModel.deleteNote(id: note.id)
        }
        XCTAssertTrue(viewModel.notes.isEmpty)
        XCTAssertNil(viewModel.selectedNoteId)
        XCTAssertEqual(viewModel.currentNote.displayTitle, "Untitled Note")
        XCTAssertFalse(viewModel.notes.contains(where: { $0.id == firstNote.id }))

        let reloadedViewModel = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertTrue(reloadedViewModel.notes.isEmpty)
    }

    func testClearCurrentNote() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        _ = viewModel.createNote(title: "Temporary")
        viewModel.updateContent("Temporary scratch note")
        XCTAssertEqual(viewModel.currentContent, "Temporary scratch note")

        viewModel.clearCurrentNote()
        XCTAssertEqual(viewModel.currentContent, "")
    }

    func testUpdateTitle() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.updateTitle("Meeting Notes")

        XCTAssertEqual(viewModel.currentNote.title, "Meeting Notes")

        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.notes.first?.title, "Meeting Notes")
    }

    func testNewNotesUseUntitledTitleUntilNamed() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let note = viewModel.createNote()

        XCTAssertEqual(note.title, "")
        XCTAssertEqual(note.displayTitle, "Untitled Note")
        XCTAssertFalse(note.title.contains("Amber"))
        XCTAssertFalse(note.title.contains("Lavender"))
    }

    func testSearchAndFilterNotes() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        _ = viewModel.createNote(title: "Swift Architecture", content: "Explore Observation framework")
        _ = viewModel.createNote(title: "Grocery List", content: "Apples and oranges")

        viewModel.searchQuery = "Architecture"
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.title, "Swift Architecture")

        viewModel.searchQuery = "apples"
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.title, "Grocery List")

        viewModel.searchQuery = ""
        XCTAssertEqual(viewModel.filteredNotes.count, 2)

        viewModel.searchQuery = "Amber"
        XCTAssertTrue(viewModel.filteredNotes.isEmpty)
    }

    func testTogglePin() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let lastNote = viewModel.createNote(title: "Pinned Note")
        XCTAssertFalse(lastNote.isPinned)

        viewModel.togglePin(for: lastNote)
        XCTAssertTrue(viewModel.notes.first(where: { $0.id == lastNote.id })?.isPinned == true)
        XCTAssertEqual(viewModel.filteredNotes.first?.id, lastNote.id)
    }

    func testRelativeFormattedDate() {
        var note = ScratchpadNote(title: "Quick Note", content: "Content")
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
        var note = ScratchpadNote(title: "", content: "")
        XCTAssertEqual(note.displayTitle, "Untitled Note")

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
        XCTAssertEqual(viewModel.notes[0].title, "Old Amber")
        XCTAssertEqual(viewModel.notes[0].content, "Legacy content")
        XCTAssertEqual(viewModel.notes[0].folder, "General")
    }

    func testLegacyColorCategoryPlaceholdersAreRemoved() throws {
        let legacyJson = """
        [
            {"color": "Amber", "title": "Amber Scratchpad", "content": "", "updatedAt": 1724630000},
            {"color": "Lavender", "title": "Lavender Scratchpad", "content": "", "updatedAt": 1724630000},
            {"color": "Sky", "title": "Sky Scratchpad", "content": "Keep this note", "updatedAt": 1724630000}
        ]
        """.data(using: .utf8)!

        testDefaults.set(legacyJson, forKey: ScratchpadViewModel.userDefaultsKey)

        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes.first?.content, "Keep this note")
        XCTAssertEqual(viewModel.notes.first?.title, "")
        XCTAssertEqual(viewModel.notes.first?.displayTitle, "Keep this note")

        let savedData = try XCTUnwrap(testDefaults.data(forKey: ScratchpadViewModel.userDefaultsKey))
        let savedJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: savedData) as? [[String: Any]])
        XCTAssertNil(savedJSON.first?["color"])
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
        XCTAssertEqual(viewModel.noteCount(for: "General"), 0)
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
        XCTAssertEqual(viewModel.noteCount(for: "General"), 1)
    }

    func testMoveNoteToFolder() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let note = viewModel.createNote(title: "Move Me")
        XCTAssertEqual(note.folder, "General")

        viewModel.moveNote(note, to: "Work")
        let updatedNote = viewModel.notes.first(where: { $0.id == note.id })
        XCTAssertEqual(updatedNote?.folder, "Work")
        XCTAssertEqual(viewModel.noteCount(for: "Work"), 1)
        XCTAssertEqual(viewModel.noteCount(for: "General"), 0)

        // Verify persistence
        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.notes.first(where: { $0.id == note.id })?.folder, "Work")
    }

    func testFilterNotesByActiveFolder() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.createNote(title: "Work Doc", content: "Meeting", folder: "Work")
        viewModel.createNote(title: "Personal Routine", content: "Gym", folder: "Personal")

        // In All Notes, both are visible
        viewModel.selectFolder(ScratchpadViewModel.allNotesFolder)
        XCTAssertEqual(viewModel.filteredNotes.count, 2)

        // In Work, only Work notes are visible
        viewModel.selectFolder("Work")
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.title, "Work Doc")

        // In Personal, only Personal notes are visible
        viewModel.selectFolder("Personal")
        XCTAssertEqual(viewModel.filteredNotes.count, 1)
        XCTAssertEqual(viewModel.filteredNotes.first?.title, "Personal Routine")
    }

    func testCreateNoteInSpecificFolderDirectly() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.createFolder("Research")

        let note = viewModel.createNote(title: "AI Survey", content: "Transformer analysis", folder: "Research")
        XCTAssertEqual(note.folder, "Research")
        XCTAssertEqual(viewModel.noteCount(for: "Research"), 1)
        XCTAssertEqual(viewModel.notes.first?.id, note.id)
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

    func testSelectingEmptyFolderYieldsCleanFallbackNote() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.createFolder("NewEmptyFolder")

        viewModel.selectFolder("NewEmptyFolder")
        XCTAssertEqual(viewModel.selectedFolder, "NewEmptyFolder")
        XCTAssertNil(viewModel.selectedNoteId)
        XCTAssertEqual(viewModel.filteredNotes.count, 0)
        XCTAssertEqual(viewModel.currentNote.folder, "NewEmptyFolder")
        XCTAssertEqual(viewModel.currentContent, "")

        // Now typing in this empty folder should create note in NewEmptyFolder
        viewModel.updateContent("Initial note in new folder")
        XCTAssertEqual(viewModel.noteCount(for: "NewEmptyFolder"), 1)
        XCTAssertEqual(viewModel.currentNote.folder, "NewEmptyFolder")
        XCTAssertEqual(viewModel.currentContent, "Initial note in new folder")
    }
}
