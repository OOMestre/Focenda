import Foundation
import SwiftUI
import Observation

/// ViewModel managing recurring reminders, repeat frequencies, and scheduled notifications
@Observable
public final class RecurringReminderViewModel {
    public var reminders: [RecurringReminder] = []
    public var searchQuery: String = ""

    private let storageKey = "focenda_saved_recurring_reminders"

    public init() {
        loadReminders()
    }

    public var activeReminders: [RecurringReminder] {
        reminders.filter { $0.isEnabled }
    }

    public var filteredReminders: [RecurringReminder] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return reminders
        } else {
            return reminders.filter {
                $0.title.localizedCaseInsensitiveContains(trimmed) ||
                $0.notes.localizedCaseInsensitiveContains(trimmed) ||
                $0.repeatFrequency.rawValue.localizedCaseInsensitiveContains(trimmed)
            }
        }
    }

    /// Returns active recurring reminders scheduled on the specified calendar date
    public func reminders(for date: Date, calendar: Calendar = .current) -> [RecurringReminder] {
        reminders.filter { $0.isEnabled && $0.matches(date: date, calendar: calendar) }
    }

    /// Creates and persists a new recurring reminder with notification scheduling
    @discardableResult
    public func addReminder(
        title: String,
        time: Date,
        repeatFrequency: RepeatFrequency = .daily,
        notes: String = "",
        isEnabled: Bool = true
    ) -> RecurringReminder {
        let reminder = RecurringReminder(
            title: title,
            time: time,
            repeatFrequency: repeatFrequency,
            isEnabled: isEnabled,
            notes: notes
        )
        reminders.append(reminder)
        if reminder.isEnabled {
            NotificationManager.shared.scheduleRecurringReminder(reminder: reminder)
        }
        saveReminders()
        return reminder
    }

    /// Updates an existing recurring reminder and updates its notification schedule
    public func updateReminder(_ reminder: RecurringReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            NotificationManager.shared.cancelRecurringReminder(reminder: reminder)
            if reminder.isEnabled {
                NotificationManager.shared.scheduleRecurringReminder(reminder: reminder)
            }
            saveReminders()
        }
    }

    /// Deletes a recurring reminder and cancels its pending notifications
    public func deleteReminder(id: UUID) {
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            let reminder = reminders[index]
            NotificationManager.shared.cancelRecurringReminder(reminder: reminder)
            reminders.remove(at: index)
            saveReminders()
        }
    }

    /// Toggles the enabled state of a recurring reminder
    public func toggleReminder(id: UUID) {
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            reminders[index].isEnabled.toggle()
            let reminder = reminders[index]
            if reminder.isEnabled {
                NotificationManager.shared.scheduleRecurringReminder(reminder: reminder)
            } else {
                NotificationManager.shared.cancelRecurringReminder(reminder: reminder)
            }
            saveReminders()
        }
    }

    /// Reschedules all active recurring reminder notifications
    public func rescheduleAllNotifications() {
        for reminder in reminders where reminder.isEnabled {
            NotificationManager.shared.scheduleRecurringReminder(reminder: reminder)
        }
    }

    /// Persists reminders to standard UserDefaults
    public func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    /// Loads reminders from standard UserDefaults
    public func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([RecurringReminder].self, from: data) {
            self.reminders = decoded
        }
    }
}
