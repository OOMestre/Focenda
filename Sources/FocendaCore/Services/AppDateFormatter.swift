import Foundation

/// Centralized and thread-safe cache for shared `DateFormatter` instances.
/// Eliminates repeated allocations of DateFormatter during UI rendering, scrolling, and computed property evaluations.
public enum AppDateFormatter {
    /// Date format "yyyy-MM-dd" (e.g. "2026-09-01")
    public static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Date format "MMM d" (e.g. "Sep 1")
    public static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// Date format "MMMM yyyy" (e.g. "September 2026")
    public static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    /// Date format "EEEE" (e.g. "Tuesday")
    public static let dayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    /// Date format "MMMM d, yyyy" (e.g. "September 1, 2026")
    public static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    /// Time format "h:mm a" (e.g. "2:30 PM")
    public static let time12: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// Time format "HH:mm" (e.g. "14:30")
    public static let time24: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// Date format "EEE, MMM d" (e.g. "Tue, Sep 1")
    public static let weekdayMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    /// Date format "'Today,' h:mm a" (e.g. "Today, 2:30 PM")
    public static let todayTime12: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "'Today,' h:mm a"
        return formatter
    }()

    /// Date format "'Tmrw,' h:mm a" (e.g. "Tmrw, 2:30 PM")
    public static let tomorrowTime12: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "'Tmrw,' h:mm a"
        return formatter
    }()

    /// Date format "MMM d, h:mm a" (e.g. "Sep 1, 2:30 PM")
    public static let monthDayTime12: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()

    /// Date format "MMM d, HH:mm" (e.g. "Sep 1, 14:30")
    public static let monthDayTime24: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()

    /// Localized short time format (timeStyle = .short)
    public static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Localized short date and time format (dateStyle = .short, timeStyle = .short)
    public static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

public extension DateFormatter {
    /// Cached date formatters for common app patterns.
    static let focenda = AppDateFormatter.self
}
