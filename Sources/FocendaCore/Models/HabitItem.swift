import Foundation
import SwiftUI

/// Represents a daily recurring habit and consistency streak item in Focenda
public struct HabitItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var iconName: String
    public var colorHex: String
    public var streakCount: Int
    public var completedDates: [Date]
    public var targetDaysPerWeek: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        iconName: String = "flame.fill",
        colorHex: String = "#FF9500",
        streakCount: Int = 0,
        completedDates: [Date] = [],
        targetDaysPerWeek: Int = 7,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.colorHex = colorHex
        self.streakCount = streakCount
        self.completedDates = completedDates
        self.targetDaysPerWeek = targetDaysPerWeek
        self.createdAt = createdAt
    }

    /// Checks whether the habit was completed today
    public var isCompletedToday: Bool {
        isCompleted(on: Date())
    }

    /// Checks whether the habit was completed on a specific date
    public func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    /// Returns a SwiftUI Color representation derived from the hex code
    public var color: Color {
        Color(hex: colorHex)
    }

    /// Calculates the current active consecutive streak based on recorded completion dates
    public static func calculateStreak(from completedDates: [Date], on referenceDate: Date = Date(), calendar: Calendar = .current) -> Int {
        guard !completedDates.isEmpty else { return 0 }

        let normalizedDates = Set(completedDates.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: referenceDate)

        var streak = 0
        var checkDate = today

        if normalizedDates.contains(today) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: today) else { return streak }
            checkDate = previousDay
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            if normalizedDates.contains(yesterday) {
                streak += 1
                guard let dayBeforeYesterday = calendar.date(byAdding: .day, value: -1, to: yesterday) else { return streak }
                checkDate = dayBeforeYesterday
            } else {
                return 0
            }
        }

        while normalizedDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }
}

// MARK: - Color Hex Initializer

extension Color {
    public init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 149, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
