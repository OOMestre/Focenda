import Foundation
import SwiftUI

/// Represents the active focus mode (Deep Focus, Short Break, Long Break).
public enum FocusMode: String, CaseIterable, Identifiable, Codable {
    case work = "Deep Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    public var id: String { rawValue }

    /// Default duration in minutes
    public var defaultDurationMinutes: Int {
        switch self {
        case .work:
            return 25
        case .shortBreak:
            return 5
        case .longBreak:
            return 15
        }
    }

    /// SF Symbol icon
    public var iconName: String {
        switch self {
        case .work:
            return "brain.head.profile"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "figure.walk"
        }
    }

    /// Associated theme color
    public var themeColor: Color {
        switch self {
        case .work:
            return AppTheme.deepFocus
        case .shortBreak:
            return AppTheme.shortBreak
        case .longBreak:
            return AppTheme.longBreak
        }
    }

    /// Friendly motivational message
    public var motivationalMessage: String {
        switch self {
        case .work:
            return "Stay focused. One task at a time!"
        case .shortBreak:
            return "Take a breath, stretch, and relax your mind."
        case .longBreak:
            return "Great progress! Time to recharge your energy."
        }
    }
}
