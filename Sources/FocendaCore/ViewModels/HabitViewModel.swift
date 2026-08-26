import Foundation
import SwiftUI
import Observation

/// ViewModel managing daily habit tracking, streak computations, and persistence
@Observable
public final class HabitViewModel {
    public var habits: [HabitItem] = []

    private let storageKey = "focenda_saved_habits"

    public init() {
        loadHabits()
        if habits.isEmpty {
            loadDefaultHabits()
        }
    }

    /// Longest current streak among all active habits
    public var longestStreak: Int {
        habits.map(\.streakCount).max() ?? 0
    }

    /// Total number of habits completed today
    public var totalCompletionsToday: Int {
        habits.filter(\.isCompletedToday).count
    }

    /// Percentage completion rate for today (0.0 to 1.0)
    public var completionRateToday: Double {
        habits.isEmpty ? 0.0 : Double(totalCompletionsToday) / Double(habits.count)
    }

    /// Adds a new habit with specified configuration
    public func addHabit(
        title: String,
        iconName: String = "flame.fill",
        colorHex: String = "#FF9500",
        targetDaysPerWeek: Int = 7
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let clampedTarget = max(1, min(7, targetDaysPerWeek))
        let newHabit = HabitItem(
            title: trimmedTitle,
            iconName: iconName,
            colorHex: colorHex,
            streakCount: 0,
            completedDates: [],
            targetDaysPerWeek: clampedTarget
        )
        habits.append(newHabit)
        saveHabits()
    }

    /// Toggles habit completion state for a given date
    public func toggleHabitCompletion(id: UUID, on date: Date = Date(), calendar: Calendar = .current) {
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }

        if habits[index].isCompleted(on: date, calendar: calendar) {
            habits[index].completedDates.removeAll { calendar.isDate($0, inSameDayAs: date) }
        } else {
            habits[index].completedDates.append(date)
        }

        habits[index].streakCount = HabitItem.calculateStreak(
            from: habits[index].completedDates,
            on: Date(),
            calendar: calendar
        )
        saveHabits()
    }

    /// Deletes a habit matching the specified ID
    public func deleteHabit(withId id: UUID) {
        habits.removeAll { $0.id == id }
        saveHabits()
    }

    /// Convenience method to delete a habit item
    public func deleteHabit(_ habit: HabitItem) {
        deleteHabit(withId: habit.id)
    }

    /// Updates an existing habit item
    public func updateHabit(_ habit: HabitItem) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        var updated = habit
        updated.streakCount = HabitItem.calculateStreak(from: updated.completedDates)
        habits[index] = updated
        saveHabits()
    }

    /// Encodes and saves habits to UserDefaults
    public func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    /// Decodes and loads habits from UserDefaults
    public func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([HabitItem].self, from: data) {
            self.habits = decoded.map { habit in
                var item = habit
                item.streakCount = HabitItem.calculateStreak(from: item.completedDates)
                return item
            }
        }
    }

    /// Initializes default habits for new users
    public func loadDefaultHabits() {
        self.habits = [
            HabitItem(
                title: "Morning Deep Work",
                iconName: "brain.head.profile",
                colorHex: "#6366F1",
                streakCount: 0,
                completedDates: [],
                targetDaysPerWeek: 5
            ),
            HabitItem(
                title: "Hydrate & Stretch",
                iconName: "drop.fill",
                colorHex: "#06B6D4",
                streakCount: 0,
                completedDates: [],
                targetDaysPerWeek: 7
            ),
            HabitItem(
                title: "Daily Task Review",
                iconName: "checklist",
                colorHex: "#10B981",
                streakCount: 0,
                completedDates: [],
                targetDaysPerWeek: 7
            )
        ]
        saveHabits()
    }
}
