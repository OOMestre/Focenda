import Foundation
import SwiftUI

/// Priority levels for tasks
public enum TaskPriority: String, CaseIterable, Identifiable, Codable, Comparable, Sendable {
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

/// Status lifecycle for tasks on the Kanban board and list view
public enum TaskStatus: String, CaseIterable, Identifiable, Codable, Sendable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "hourglass"
        case .done: return "checkmark.circle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .todo: return AppTheme.riverSlate
        case .inProgress: return AppTheme.sandstone
        case .done: return AppTheme.success
        }
    }
}

/// Represents a productivity task in Focenda
public struct TaskItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var priority: TaskPriority
    public var status: TaskStatus
    public var createdAt: Date
    public var completedAt: Date?
    public var reminderDate: Date?
    public var dueDate: Date?
    public var tags: [String]
    public var estimatedPomodoros: Int
    public var completedPomodoros: Int

    /// Computed property maintaining two-way synchronization with TaskStatus
    public var isCompleted: Bool {
        get { status == .done }
        set {
            if newValue {
                status = .done
                if completedAt == nil {
                    completedAt = Date()
                }
            } else {
                if status == .done {
                    status = .todo
                }
                completedAt = nil
            }
        }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        priority: TaskPriority = .medium,
        status: TaskStatus = .todo,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        reminderDate: Date? = nil,
        dueDate: Date? = nil,
        tags: [String] = [],
        estimatedPomodoros: Int = 1,
        completedPomodoros: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        if isCompleted {
            self.status = .done
        } else {
            self.status = status
        }
        self.createdAt = createdAt
        self.completedAt = completedAt ?? (self.status == .done ? Date() : nil)
        self.reminderDate = reminderDate
        self.dueDate = dueDate
        self.tags = tags
        self.estimatedPomodoros = estimatedPomodoros
        self.completedPomodoros = completedPomodoros
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case notes
        case priority
        case status
        case isCompleted
        case createdAt
        case completedAt
        case reminderDate
        case dueDate
        case tags
        case estimatedPomodoros
        case completedPomodoros
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .medium

        if let decodedStatus = try container.decodeIfPresent(TaskStatus.self, forKey: .status) {
            self.status = decodedStatus
        } else if let completed = try container.decodeIfPresent(Bool.self, forKey: .isCompleted), completed {
            self.status = .done
        } else {
            self.status = .todo
        }

        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        self.reminderDate = try container.decodeIfPresent(Date.self, forKey: .reminderDate)
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.estimatedPomodoros = try container.decodeIfPresent(Int.self, forKey: .estimatedPomodoros) ?? 1
        self.completedPomodoros = try container.decodeIfPresent(Int.self, forKey: .completedPomodoros) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(priority, forKey: .priority)
        try container.encode(status, forKey: .status)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(reminderDate, forKey: .reminderDate)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(tags, forKey: .tags)
        try container.encode(estimatedPomodoros, forKey: .estimatedPomodoros)
        try container.encode(completedPomodoros, forKey: .completedPomodoros)
    }
}
