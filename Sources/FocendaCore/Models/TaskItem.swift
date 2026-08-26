import Foundation
import SwiftUI

/// Priority levels for tasks
public enum TaskPriority: String, CaseIterable, Identifiable, Codable, Comparable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    public var id: String { rawValue }

    public var rank: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }

    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        return lhs.rank < rhs.rank
    }

    public var color: Color {
        switch self {
        case .low: return AppTheme.riverSlate
        case .medium: return AppTheme.sandstone
        case .high: return AppTheme.terracotta
        }
    }

    public var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "exclamationmark"
        }
    }
}

/// Represents a productivity task in Focenda
public struct TaskItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var priority: TaskPriority
    public var isCompleted: Bool
    public var createdAt: Date
    public var completedAt: Date?
    public var tags: [String]
    public var estimatedPomodoros: Int
    public var completedPomodoros: Int

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        priority: TaskPriority = .medium,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        tags: [String] = [],
        estimatedPomodoros: Int = 1,
        completedPomodoros: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.tags = tags
        self.estimatedPomodoros = estimatedPomodoros
        self.completedPomodoros = completedPomodoros
    }
}
