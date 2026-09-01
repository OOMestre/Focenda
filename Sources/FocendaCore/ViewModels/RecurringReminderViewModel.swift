import Foundation
import SwiftUI
import Observation

/// ViewModel managing recurring reminders, repeat frequencies, and scheduled notifications
@Observable
public final class RecurringReminderViewModel {
    public var reminders: [RecurringReminder] = []
    public var searchQuery: String = ""

    private let storageKey = "focenda_saved_recurring_reminders"
    private let secureStore: SecureStore
    private var remindersPersistenceReady = false

    public init(secureStore: SecureStore = .shared) {
        self.secureStore = secureStore
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

    /// Persists reminders as encrypted local data.
    public func saveReminders() {
        guard remindersPersistenceReady else { return }
        if let encoded = try? JSONEncoder().encode(reminders) {
            secureStore.setData(encoded, forKey: storageKey)
        }
    }

    /// Loads reminders from encrypted local data, migrating the legacy payload when needed.
    public func loadReminders() {
        guard secureStore.containsValue(forKey: storageKey) else {
            remindersPersistenceReady = true
            return
        }

        guard let data = secureStore.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([RecurringReminder].self, from: data) else {
            // Do not replace an unreadable saved list with a newly encoded
            // empty list after an update or migration.
            reminders = []
            remindersPersistenceReady = false
            return
        }

        self.reminders = decoded
        remindersPersistenceReady = true
    }
}
