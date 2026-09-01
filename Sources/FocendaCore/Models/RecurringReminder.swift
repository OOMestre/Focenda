import Foundation

/// Repeat frequency options for recurring reminders
public enum RepeatFrequency: String, CaseIterable, Identifiable, Codable, Equatable, Sendable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekly = "Weekly"
    case monthly = "Monthly"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .daily: return "repeat"
        case .weekdays: return "briefcase.fill"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }

    /// Evaluates if this recurrence pattern occurs on the given date
    public func matches(date: Date, reminderTime: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .daily:
            return true
        case .weekdays:
            return !calendar.isDateInWeekend(date)
        case .weekly:
            let reminderWeekday = calendar.component(.weekday, from: reminderTime)
            let targetWeekday = calendar.component(.weekday, from: date)
            return reminderWeekday == targetWeekday
        case .monthly:
            let reminderDay = calendar.component(.day, from: reminderTime)
            let targetDay = calendar.component(.day, from: date)
            return reminderDay == targetDay
        }
    }
}

/// Model representing a user-defined recurring notification reminder
public struct RecurringReminder: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var time: Date
    public var repeatFrequency: RepeatFrequency
    public var isEnabled: Bool
    public var createdAt: Date
    public var notes: String

    public init(
        id: UUID = UUID(),
        title: String,
        time: Date,
        repeatFrequency: RepeatFrequency = .daily,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.repeatFrequency = repeatFrequency
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.notes = notes
    }

    /// Formatted time string (e.g. "9:00 AM")
    public var formattedTime: String {
        AppDateFormatter.time12.string(from: time)
    }

    /// Checks if this recurring reminder is scheduled on a given calendar date
    public func matches(date: Date, calendar: Calendar = .current) -> Bool {
        repeatFrequency.matches(date: date, reminderTime: time, calendar: calendar)
    }

    /// Computes the next scheduled date for this recurring reminder after a reference date
    public func nextFireDate(after referenceDate: Date = Date(), calendar: Calendar = .current) -> Date? {
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return nil }

        var targetComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        targetComponents.hour = hour
        targetComponents.minute = minute
        targetComponents.second = 0

        guard var candidate = calendar.date(from: targetComponents) else { return nil }

        // If today's occurrence has already elapsed, start checking tomorrow
        if candidate <= referenceDate {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: candidate) else { return nil }
            candidate = nextDay
        }

        // Search forward up to 366 days for the next matching calendar day
        for offset in 0..<366 {
            if let testDate = calendar.date(byAdding: .day, value: offset, to: candidate),
               matches(date: testDate, calendar: calendar) {
                var comp = calendar.dateComponents([.year, .month, .day], from: testDate)
                comp.hour = hour
                comp.minute = minute
                comp.second = 0
                return calendar.date(from: comp)
            }
        }
        return nil
    }
}
