import XCTest
import SwiftUI
@testable import FocendaCore

final class RecurringReminderTests: XCTestCase {

    func testRecurringReminderInitialization() {
        let reminderTime = Date()
        let reminder = RecurringReminder(
            title: "Team Standup",
            time: reminderTime,
            repeatFrequency: .weekdays,
            isEnabled: true,
            notes: "Prepare sprint update"
        )

        XCTAssertEqual(reminder.title, "Team Standup")
        XCTAssertEqual(reminder.repeatFrequency, .weekdays)
        XCTAssertTrue(reminder.isEnabled)
        XCTAssertEqual(reminder.notes, "Prepare sprint update")
        XCTAssertFalse(reminder.formattedTime.isEmpty)
    }

    func testRepeatFrequencyDailyMatches() {
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 8
        comp.day = 26 // Wednesday
        comp.hour = 10
        let time = calendar.date(from: comp)!

        comp.day = 29 // Saturday (Weekend)
        let saturday = calendar.date(from: comp)!

        let daily = RepeatFrequency.daily
        XCTAssertTrue(daily.matches(date: time, reminderTime: time, calendar: calendar))
        XCTAssertTrue(daily.matches(date: saturday, reminderTime: time, calendar: calendar))
    }

    func testRepeatFrequencyWeekdaysMatches() {
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 8
        comp.day = 26 // Wednesday (Weekday)
        comp.hour = 9
        let wednesday = calendar.date(from: comp)!

        comp.day = 29 // Saturday (Weekend)
        let saturday = calendar.date(from: comp)!

        comp.day = 30 // Sunday (Weekend)
        let sunday = calendar.date(from: comp)!

        let weekdays = RepeatFrequency.weekdays
        XCTAssertTrue(weekdays.matches(date: wednesday, reminderTime: wednesday, calendar: calendar))
        XCTAssertFalse(weekdays.matches(date: saturday, reminderTime: wednesday, calendar: calendar))
        XCTAssertFalse(weekdays.matches(date: sunday, reminderTime: wednesday, calendar: calendar))
    }

    func testRepeatFrequencyWeeklyMatches() {
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 8
        comp.day = 24 // Monday
        comp.hour = 14
        let monday1 = calendar.date(from: comp)!

        comp.day = 31 // Next Monday
        let monday2 = calendar.date(from: comp)!

        comp.day = 25 // Tuesday
        let tuesday = calendar.date(from: comp)!

        let weekly = RepeatFrequency.weekly
        XCTAssertTrue(weekly.matches(date: monday1, reminderTime: monday1, calendar: calendar))
        XCTAssertTrue(weekly.matches(date: monday2, reminderTime: monday1, calendar: calendar))
        XCTAssertFalse(weekly.matches(date: tuesday, reminderTime: monday1, calendar: calendar))
    }

    func testRepeatFrequencyMonthlyMatches() {
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 8
        comp.day = 15
        comp.hour = 11
        let august15 = calendar.date(from: comp)!

        comp.month = 9
        comp.day = 15
        let september15 = calendar.date(from: comp)!

        comp.month = 9
        comp.day = 16
        let september16 = calendar.date(from: comp)!

        let monthly = RepeatFrequency.monthly
        XCTAssertTrue(monthly.matches(date: august15, reminderTime: august15, calendar: calendar))
        XCTAssertTrue(monthly.matches(date: september15, reminderTime: august15, calendar: calendar))
        XCTAssertFalse(monthly.matches(date: september16, reminderTime: august15, calendar: calendar))
    }

    func testNextFireDateCalculation() {
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 8
        comp.day = 26
        comp.hour = 12
        comp.minute = 0
        comp.second = 0
        let refDate = calendar.date(from: comp)!

        // Reminder scheduled at 15:00 today
        comp.hour = 15
        let futureToday = calendar.date(from: comp)!

        let dailyReminder = RecurringReminder(
            title: "Afternoon Check",
            time: futureToday,
            repeatFrequency: .daily
        )

        let nextDate = dailyReminder.nextFireDate(after: refDate, calendar: calendar)
        XCTAssertNotNil(nextDate)
        if let next = nextDate {
            XCTAssertEqual(calendar.component(.hour, from: next), 15)
            XCTAssertEqual(calendar.component(.minute, from: next), 0)
            XCTAssertEqual(calendar.component(.day, from: next), 26)
        }
    }

    func testNextFireDatePastTimeAdvancesToNextOccurrence() {
        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 8
        comp.day = 26
        comp.hour = 17
        comp.minute = 0
        comp.second = 0
        let refDate = calendar.date(from: comp)!

        // Reminder was set for 9:00 AM (already passed for today)
        comp.hour = 9
        let morningTime = calendar.date(from: comp)!

        let dailyReminder = RecurringReminder(
            title: "Morning Routine",
            time: morningTime,
            repeatFrequency: .daily
        )

        let nextDate = dailyReminder.nextFireDate(after: refDate, calendar: calendar)
        XCTAssertNotNil(nextDate)
        if let next = nextDate {
            XCTAssertEqual(calendar.component(.hour, from: next), 9)
            XCTAssertEqual(calendar.component(.minute, from: next), 0)
            XCTAssertEqual(calendar.component(.day, from: next), 27) // Tomorrow
        }
    }

    func testRecurringReminderViewModelCRUD() {
        let viewModel = RecurringReminderViewModel()
        viewModel.reminders = []

        let time = Date()
        let added = viewModel.addReminder(
            title: "Sprint Retro",
            time: time,
            repeatFrequency: .weekly,
            notes: "Review milestones",
            isEnabled: true
        )

        XCTAssertEqual(viewModel.reminders.count, 1)
        XCTAssertEqual(viewModel.reminders.first?.title, "Sprint Retro")
        XCTAssertEqual(viewModel.activeReminders.count, 1)

        // Update
        var updated = added
        updated.title = "Sprint Retrospective & Demo"
        viewModel.updateReminder(updated)

        XCTAssertEqual(viewModel.reminders.first?.title, "Sprint Retrospective & Demo")

        // Toggle
        viewModel.toggleReminder(id: added.id)
        XCTAssertEqual(viewModel.reminders.first?.isEnabled, false)
        XCTAssertEqual(viewModel.activeReminders.count, 0)

        viewModel.toggleReminder(id: added.id)
        XCTAssertEqual(viewModel.reminders.first?.isEnabled, true)
        XCTAssertEqual(viewModel.activeReminders.count, 1)

        // Delete
        viewModel.deleteReminder(id: added.id)
        XCTAssertTrue(viewModel.reminders.isEmpty)
    }

    func testRemindersForDateFiltering() {
        let viewModel = RecurringReminderViewModel()
        viewModel.reminders = []

        let calendar = Calendar.current
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 8
        comp.day = 26 // Wednesday
        comp.hour = 9
        let wednesday = calendar.date(from: comp)!

        comp.day = 29 // Saturday
        let saturday = calendar.date(from: comp)!

        let weekdayReminder = RecurringReminder(
            title: "Weekday Planning",
            time: wednesday,
            repeatFrequency: .weekdays,
            isEnabled: true
        )

        let dailyReminder = RecurringReminder(
            title: "Daily Journal",
            time: wednesday,
            repeatFrequency: .daily,
            isEnabled: true
        )

        let disabledReminder = RecurringReminder(
            title: "Disabled Alert",
            time: wednesday,
            repeatFrequency: .daily,
            isEnabled: false
        )

        viewModel.reminders = [weekdayReminder, dailyReminder, disabledReminder]

        let wednesdayMatches = viewModel.reminders(for: wednesday, calendar: calendar)
        XCTAssertEqual(wednesdayMatches.count, 2)
        XCTAssertTrue(wednesdayMatches.contains(where: { $0.title == "Weekday Planning" }))
        XCTAssertTrue(wednesdayMatches.contains(where: { $0.title == "Daily Journal" }))

        let saturdayMatches = viewModel.reminders(for: saturday, calendar: calendar)
        XCTAssertEqual(saturdayMatches.count, 1)
        XCTAssertEqual(saturdayMatches.first?.title, "Daily Journal")
    }

    func testSearchAndFilterReminders() {
        let viewModel = RecurringReminderViewModel()
        let r1 = RecurringReminder(title: "Hydration Check", time: Date(), repeatFrequency: .daily, notes: "Drink water")
        let r2 = RecurringReminder(title: "Code Review", time: Date(), repeatFrequency: .weekdays, notes: "Check PR queue")
        viewModel.reminders = [r1, r2]

        viewModel.searchQuery = "water"
        XCTAssertEqual(viewModel.filteredReminders.count, 1)
        XCTAssertEqual(viewModel.filteredReminders.first?.title, "Hydration Check")

        viewModel.searchQuery = "weekdays"
        XCTAssertEqual(viewModel.filteredReminders.count, 1)
        XCTAssertEqual(viewModel.filteredReminders.first?.title, "Code Review")

        viewModel.searchQuery = ""
        XCTAssertEqual(viewModel.filteredReminders.count, 2)
    }

    func testCodableRoundTrip() {
        let original = RecurringReminder(
            title: "Night Reflection",
            time: Date(),
            repeatFrequency: .daily,
            isEnabled: true,
            notes: "Gratitude list"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(RecurringReminder.self, from: data)

            XCTAssertEqual(original.id, decoded.id)
            XCTAssertEqual(original.title, decoded.title)
            XCTAssertEqual(original.repeatFrequency, decoded.repeatFrequency)
            XCTAssertEqual(original.isEnabled, decoded.isEnabled)
            XCTAssertEqual(original.notes, decoded.notes)
        } catch {
            XCTFail("Codable round-trip failed: \(error)")
        }
    }

    func testRescheduleAllNotifications() {
        let viewModel = RecurringReminderViewModel()
        let r1 = RecurringReminder(title: "Active Reminder", time: Date(), repeatFrequency: .daily, isEnabled: true)
        let r2 = RecurringReminder(title: "Disabled Reminder", time: Date(), repeatFrequency: .daily, isEnabled: false)
        viewModel.reminders = [r1, r2]

        viewModel.rescheduleAllNotifications()
    }

    func testNotificationManagerNotificationStrings() {
        let reminder = RecurringReminder(
            title: "Focus Block",
            time: Date(),
            repeatFrequency: .daily,
            notes: "Deep work session"
        )

        let title = NotificationManager.recurringReminderTitle(for: reminder)
        let body = NotificationManager.recurringReminderBody(for: reminder)

        XCTAssertTrue(title.contains("Daily"))
        XCTAssertTrue(title.contains("Focus Block"))
        XCTAssertTrue(body.contains("Deep work session"))
    }
}
