import XCTest
import SwiftUI
@testable import FocendaCore

final class HabitViewModelTests: XCTestCase {

    var viewModel: HabitViewModel!
    private let storageKey = "focenda_saved_habits"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: storageKey)
        viewModel = HabitViewModel()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        viewModel = nil
        super.tearDown()
    }

    func testInitialDefaultHabits() {
        XCTAssertEqual(viewModel.habits.count, 3)
        let titles = viewModel.habits.map(\.title)
        XCTAssertTrue(titles.contains("Morning Deep Work"))
        XCTAssertTrue(titles.contains("Hydrate & Stretch"))
        XCTAssertTrue(titles.contains("Daily Task Review"))
        XCTAssertEqual(viewModel.longestStreak, 0)
        XCTAssertEqual(viewModel.totalCompletionsToday, 0)
    }

    func testAddHabit() {
        let countBefore = viewModel.habits.count
        viewModel.addHabit(
            title: "Read 30 Minutes",
            iconName: "book.fill",
            colorHex: "#6366F1",
            targetDaysPerWeek: 5
        )

        XCTAssertEqual(viewModel.habits.count, countBefore + 1)
        guard let newHabit = viewModel.habits.last else {
            XCTFail("Habit should exist")
            return
        }

        XCTAssertEqual(newHabit.title, "Read 30 Minutes")
        XCTAssertEqual(newHabit.iconName, "book.fill")
        XCTAssertEqual(newHabit.colorHex, "#6366F1")
        XCTAssertEqual(newHabit.targetDaysPerWeek, 5)
        XCTAssertEqual(newHabit.streakCount, 0)
    }

    func testAddHabitIgnoresEmptyTitle() {
        let countBefore = viewModel.habits.count
        viewModel.addHabit(title: "   ")
        XCTAssertEqual(viewModel.habits.count, countBefore)
    }

    func testToggleHabitCompletionToday() {
        guard let firstHabit = viewModel.habits.first else {
            XCTFail("Default habit should exist")
            return
        }

        XCTAssertFalse(firstHabit.isCompletedToday)
        XCTAssertEqual(viewModel.totalCompletionsToday, 0)

        viewModel.toggleHabitCompletion(id: firstHabit.id)

        let updatedHabit = viewModel.habits.first { $0.id == firstHabit.id }
        XCTAssertNotNil(updatedHabit)
        XCTAssertTrue(updatedHabit!.isCompletedToday)
        XCTAssertEqual(updatedHabit!.streakCount, 1)
        XCTAssertEqual(viewModel.totalCompletionsToday, 1)

        // Toggle again to uncheck
        viewModel.toggleHabitCompletion(id: firstHabit.id)
        let toggledOff = viewModel.habits.first { $0.id == firstHabit.id }
        XCTAssertFalse(toggledOff!.isCompletedToday)
        XCTAssertEqual(toggledOff!.streakCount, 0)
        XCTAssertEqual(viewModel.totalCompletionsToday, 0)
    }

    func testStreakCalculationConsecutiveDays() {
        let calendar = Calendar.current
        let today = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today),
              let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today) else {
            XCTFail("Calendar date calculation failed")
            return
        }

        // Test 1: Completed today, yesterday, and two days ago -> Streak = 3
        let streak3 = HabitItem.calculateStreak(from: [today, yesterday, twoDaysAgo], on: today, calendar: calendar)
        XCTAssertEqual(streak3, 3)

        // Test 2: Completed yesterday and two days ago, not today -> Streak = 2 (streak maintained from yesterday)
        let streak2 = HabitItem.calculateStreak(from: [yesterday, twoDaysAgo], on: today, calendar: calendar)
        XCTAssertEqual(streak2, 2)

        // Test 3: Completed today and four days ago (missed yesterday) -> Streak = 1
        let streak1 = HabitItem.calculateStreak(from: [today, fourDaysAgo], on: today, calendar: calendar)
        XCTAssertEqual(streak1, 1)

        // Test 4: Empty completions -> Streak = 0
        let streak0 = HabitItem.calculateStreak(from: [], on: today, calendar: calendar)
        XCTAssertEqual(streak0, 0)
    }

    func testLongestStreakAndCompletionRate() {
        let calendar = Calendar.current
        let today = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            XCTFail("Calendar failed")
            return
        }

        viewModel.habits = [
            HabitItem(title: "Habit 1", streakCount: 5, completedDates: [today, yesterday]),
            HabitItem(title: "Habit 2", streakCount: 12, completedDates: [today]),
            HabitItem(title: "Habit 3", streakCount: 2, completedDates: [])
        ]

        XCTAssertEqual(viewModel.longestStreak, 12)
        XCTAssertEqual(viewModel.totalCompletionsToday, 2)
        XCTAssertEqual(viewModel.completionRateToday, 2.0 / 3.0, accuracy: 0.001)
    }

    func testDeleteHabit() {
        guard let habit = viewModel.habits.first else {
            XCTFail("Habit not found")
            return
        }

        let initialCount = viewModel.habits.count
        viewModel.deleteHabit(withId: habit.id)

        XCTAssertEqual(viewModel.habits.count, initialCount - 1)
        XCTAssertFalse(viewModel.habits.contains { $0.id == habit.id })
    }

    func testDeleteHabitByItem() {
        guard let habit = viewModel.habits.first else {
            XCTFail("Habit not found")
            return
        }

        let initialCount = viewModel.habits.count
        viewModel.deleteHabit(habit)

        XCTAssertEqual(viewModel.habits.count, initialCount - 1)
        XCTAssertFalse(viewModel.habits.contains { $0.id == habit.id })
    }

    func testUpdateHabit() {
        guard var habit = viewModel.habits.first else {
            XCTFail("Habit not found")
            return
        }

        habit.title = "Updated Habit Name"
        habit.targetDaysPerWeek = 4
        viewModel.updateHabit(habit)

        let updated = viewModel.habits.first { $0.id == habit.id }
        XCTAssertEqual(updated?.title, "Updated Habit Name")
        XCTAssertEqual(updated?.targetDaysPerWeek, 4)
    }

    func testPersistence() {
        viewModel.addHabit(title: "Persistent Habit", iconName: "star.fill", colorHex: "#EC4899", targetDaysPerWeek: 6)

        // Load new ViewModel instance from same UserDefaults
        let newVM = HabitViewModel()
        XCTAssertEqual(newVM.habits.count, viewModel.habits.count)
        XCTAssertTrue(newVM.habits.contains { $0.title == "Persistent Habit" })
    }

    func testIsCompletedOnDate() {
        let calendar = Calendar.current
        let today = Date()
        guard let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today),
              let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today) else {
            XCTFail("Date generation failed")
            return
        }

        let habit = HabitItem(title: "Test Habit", completedDates: [threeDaysAgo])
        XCTAssertTrue(habit.isCompleted(on: threeDaysAgo, calendar: calendar))
        XCTAssertFalse(habit.isCompleted(on: fiveDaysAgo, calendar: calendar))
        XCTAssertFalse(habit.isCompleted(on: today, calendar: calendar))
    }

    func testColorHexParsing() {
        let habit = HabitItem(title: "Color Test", colorHex: "#6366F1")
        _ = habit.color
        XCTAssertEqual(habit.colorHex, "#6366F1")
    }
}
