import Foundation
import UserNotifications
#if canImport(AppKit)
import AppKit
#endif

/// Protocol defining notification operations for focus sessions and timed task reminders
public protocol NotificationManagerProtocol: AnyObject {
    func requestAuthorization(completion: ((Bool, Error?) -> Void)?)
    func notifySessionCompleted(mode: FocusMode)
    func scheduleTaskReminder(task: TaskItem)
    func cancelTaskReminder(task: TaskItem)
}

/// Service managing native macOS system notifications and in-app fallback alerts for Focenda
public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, NotificationManagerProtocol {
    public static let shared = NotificationManager()

    public static let taskReminderFiredNotification = Notification.Name("FocendaTaskReminderFired")

    private let center: UNUserNotificationCenter?
    public private(set) var lastNotifiedMode: FocusMode?
    public private(set) var lastScheduledTask: TaskItem?
    public private(set) var lastFiredTask: TaskItem?

    /// Active in-app fallback timers for scheduled reminders
    private var inAppTimers: [UUID: Timer] = [:]

    /// Optional callback invoked when a task reminder fires (in-app fallback or notification presentation)
    public var onTaskReminderFired: ((TaskItem) -> Void)?

    public init(center: UNUserNotificationCenter? = nil) {
        if let center = center {
            self.center = center
        } else if Self.isNotificationAvailable {
            self.center = UNUserNotificationCenter.current()
        } else {
            self.center = nil
        }
        super.init()
        self.center?.delegate = self
    }

    private static var isNotificationAvailable: Bool {
        guard NSClassFromString("XCTestCase") == nil,
              NSClassFromString("XCTest") == nil,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
              ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil,
              !ProcessInfo.processInfo.arguments.contains(where: { $0.contains("xctest") || $0.contains("test") }),
              let bundleId = Bundle.main.bundleIdentifier,
              bundleId != "com.apple.dt.xctest.tool",
              bundleId != "FocendaPackageTests",
              !bundleId.isEmpty else {
            return false
        }
        return true
    }

    /// Requests authorization to display native macOS banners, sounds, and badges
    public func requestAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
        guard let center = center else {
            completion?(false, nil)
            return
        }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion?(granted, error)
        }
    }

    /// Async variant for requesting authorization
    @discardableResult
    public func requestAuthorization() async throws -> Bool {
        guard let center = center else {
            return false
        }
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Friendly English notification title for a given focus mode completion
    public static func notificationTitle(for mode: FocusMode) -> String {
        switch mode {
        case .work:
            return "Focus Session Completed! 🎯"
        case .shortBreak:
            return "Short Break Finished! ⚡"
        case .longBreak:
            return "Long Break Ended! 🚀"
        }
    }

    /// Friendly English notification body copy for a given focus mode completion
    public static func notificationBody(for mode: FocusMode) -> String {
        switch mode {
        case .work:
            return "Great job! Time to take a well-deserved break."
        case .shortBreak:
            return "Ready to jump back into deep focus?"
        case .longBreak:
            return "Feeling refreshed? Let's get back to work!"
        }
    }

    /// Friendly reminder title copy for a given task
    public static func taskReminderTitle(for task: TaskItem) -> String {
        "⏰ Task Reminder: \(task.title)"
    }

    /// Friendly reminder body copy for a given task
    public static func taskReminderBody(for task: TaskItem) -> String {
        if !task.notes.isEmpty {
            return task.notes
        } else {
            return "Time to focus on '\(task.title)'."
        }
    }

    /// Posts a native macOS banner alert and sound when a focus session or break completes
    public func notifySessionCompleted(mode: FocusMode) {
        self.lastNotifiedMode = mode

        #if canImport(AppKit)
        NSSound.beep()
        #endif

        guard let center = center else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = Self.notificationTitle(for: mode)
        content.body = Self.notificationBody(for: mode)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    /// Schedules a timed calendar notification reminder for a task with fallback in-app alert timer
    public func scheduleTaskReminder(task: TaskItem) {
        self.lastScheduledTask = task

        guard let reminderDate = task.reminderDate, reminderDate > Date() else {
            return
        }

        // Cancel any previous fallback timer for this task
        inAppTimers[task.id]?.invalidate()
        inAppTimers.removeValue(forKey: task.id)

        // Set up in-app timer fallback
        let timeInterval = reminderDate.timeIntervalSinceNow
        if timeInterval > 0 {
            let timer = Timer(timeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.triggerInAppReminderFallback(for: task)
            }
            RunLoop.main.add(timer, forMode: .common)
            inAppTimers[task.id] = timer
        }

        guard let center = center else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = Self.taskReminderTitle(for: task)
        content.body = Self.taskReminderBody(for: task)
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task-reminder-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule task reminder: \(error.localizedDescription)")
            }
        }
    }

    /// Cancels a pending task reminder notification and its in-app fallback timer
    public func cancelTaskReminder(task: TaskItem) {
        inAppTimers[task.id]?.invalidate()
        inAppTimers.removeValue(forKey: task.id)

        guard let center = center else { return }
        center.removePendingNotificationRequests(withIdentifiers: ["task-reminder-\(task.id.uuidString)"])
    }

    /// Triggers the in-app alert and sound fallback when reminder time is reached
    public func triggerInAppReminderFallback(for task: TaskItem) {
        self.lastFiredTask = task
        self.inAppTimers.removeValue(forKey: task.id)

        #if canImport(AppKit)
        NSSound.beep()
        #endif

        NotificationCenter.default.post(
            name: Self.taskReminderFiredNotification,
            object: task,
            userInfo: [
                "taskTitle": task.title,
                "formattedTitle": Self.taskReminderTitle(for: task)
            ]
        )

        onTaskReminderFired?(task)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Ensures notification banners and sounds are delivered even when Focenda is in the active foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }
}
