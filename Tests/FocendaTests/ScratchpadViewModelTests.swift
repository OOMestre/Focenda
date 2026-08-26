import XCTest
@testable import FocendaCore

final class ScratchpadViewModelTests: XCTestCase {

    var testDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test_scratchpad_\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        if let suiteName = suiteName {
            testDefaults?.removePersistentDomain(forName: suiteName)
        }
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

        let newNote = viewModel.createNote(color: .rose, title: "Sprint Backlog", content: "Refactor engine")
        XCTAssertEqual(viewModel.notes.count, initialCount + 1)
        XCTAssertEqual(viewModel.selectedNoteId, newNote.id)
        XCTAssertEqual(viewModel.selectedColor, .rose)
        XCTAssertEqual(viewModel.currentNote.title, "Sprint Backlog")
        XCTAssertEqual(viewModel.currentNote.content, "Refactor engine")

        // Check persistence
        let viewModel2 = ScratchpadViewModel(userDefaults: testDefaults)
        XCTAssertEqual(viewModel2.notes.count, initialCount + 1)
        XCTAssertEqual(viewModel2.notes.first?.title, "Sprint Backlog")
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

    func testBackwardsCompatibilityDecoding() throws {
        // Mock legacy JSON without UUID id or createdAt
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
}
