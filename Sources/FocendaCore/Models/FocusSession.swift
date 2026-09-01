import Foundation

/// Records a completed focus session for historical statistics.
public struct FocusSession: Identifiable, Codable, Equatable {
    public let id: UUID
    public let mode: FocusMode
    public let durationSeconds: Int
    public let completedAt: Date
    public let associatedTaskId: UUID?

    public init(
        id: UUID = UUID(),
        mode: FocusMode,
        durationSeconds: Int,
        completedAt: Date = Date(),
        associatedTaskId: UUID? = nil
    ) {
        self.id = id
        self.mode = mode
        self.durationSeconds = durationSeconds
        self.completedAt = completedAt
        self.associatedTaskId = associatedTaskId
    }
}
