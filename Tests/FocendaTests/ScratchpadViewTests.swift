import XCTest
import SwiftUI
@testable import FocendaCore

final class ScratchpadViewTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private let testKey = "test_focenda_scratchpads_view_tests"

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

    func testScratchpadViewInitialization() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let view = ScratchpadView(viewModel: viewModel)

        XCTAssertNotNil(view)
        XCTAssertNotNil(view.body)
    }

    func testScratchpadViewWithCustomNotes() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        let note = viewModel.createNote(folder: "Projects")
        viewModel.selectNote(note)
        viewModel.updateContent("Important project notes with deep detail")
        viewModel.updateTitle("Project Alpha")

        let view = ScratchpadView(viewModel: viewModel)
        XCTAssertNotNil(view.body)
        XCTAssertEqual(viewModel.currentTitle, "Project Alpha")
        XCTAssertEqual(viewModel.currentContent, "Important project notes with deep detail")
    }

    func testScratchpadViewFolderFilterAndNotesCount() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.createFolder("Personal")
        let note1 = viewModel.createNote(title: "Personal Note 1", folder: "Personal")
        let note2 = viewModel.createNote(title: "Personal Note 2", folder: "Personal")

        viewModel.selectFolder("Personal")
        XCTAssertEqual(viewModel.filteredNotes.count, 2)
        XCTAssertTrue(viewModel.filteredNotes.contains(where: { $0.id == note1.id }))
        XCTAssertTrue(viewModel.filteredNotes.contains(where: { $0.id == note2.id }))

        let view = ScratchpadView(viewModel: viewModel)
        XCTAssertNotNil(view.body)
    }

    func testScratchpadViewSearchFilter() {
        let viewModel = ScratchpadViewModel(userDefaults: testDefaults)
        viewModel.currentTitle = "SwiftUI Architectures"
        viewModel.currentContent = "Exploring NavigationSplitView layout"
        viewModel.saveToUserDefaults()

        viewModel.searchQuery = "Architectures"
        XCTAssertEqual(viewModel.filteredNotes.count, 1)

        viewModel.searchQuery = "NonExistentTerm123"
        XCTAssertEqual(viewModel.filteredNotes.count, 0)

        let view = ScratchpadView(viewModel: viewModel)
        XCTAssertNotNil(view.body)
    }
}
