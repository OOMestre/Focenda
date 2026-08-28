import Foundation
import UserNotifications
#if canImport(AppKit)
import AppKit
#endif

/// Protocol defining notification operations for focus sessions, timed task reminders, and recurring reminders
public protocol NotificationManagerProtocol: AnyObject {
    func requestAuthorization(completion: ((Bool, Error?) -> Void)?)
    func notifySessionCompleted(mode: FocusMode)
    func scheduleTaskReminder(task: TaskItem)
    func cancelTaskReminder(task: TaskItem)
    func scheduleRecurringReminder(reminder: RecurringReminder)
    func cancelRecurringReminder(reminder: RecurringReminder)
    func notifyUpdateAvailable(version: String)
    func playReminderAlertChime(soundName: String, customFilePath: String?, repeatCount: Int, interval: TimeInterval)
    func stopActiveSound()
    func snoozeReminder(title: String, subtitle: String, notes: String, minutes: Int)
}

public extension NotificationManagerProtocol {
    func notifyUpdateAvailable(version: String) {}
    func playReminderAlertChime(soundName: String = "Hero", customFilePath: String? = nil, repeatCount: Int = 3, interval: TimeInterval = 0.85) {}
    func stopActiveSound() {}
    func snoozeReminder(title: String, subtitle: String = "Snoozed Reminder", notes: String = "", minutes: Int = 5) {}
}

/// Service managing native macOS system notifications, rich audible alerts, and in-app banner broadcasts
public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, NotificationManagerProtocol {
    public static let shared = NotificationManager()

    public static let taskReminderFiredNotification = Notification.Name("FocendaTaskReminderFired")
    public static let recurringReminderFiredNotification = Notification.Name("FocendaRecurringReminderFired")
    public static let reminderAlertBannerNotification = Notification.Name("FocendaReminderAlertBanner")
    public static let openRemindersTabNotification = Notification.Name("FocendaOpenRemindersTab")
    public static let reminderSnoozedNotification = Notification.Name("FocendaReminderSnoozed")
    public static let reminderAlertDismissedNotification = Notification.Name("FocendaReminderAlertDismissed")
    public static let openSettingsNotification = Notification.Name("FocendaOpenSettings")
    public static let openFocusTabNotification = Notification.Name("FocendaOpenFocusTab")
    public static let standardNotificationSoundName = ReminderSoundType.defaultSound.rawValue

    private let center: UNUserNotificationCenter?
    public private(set) var lastNotifiedMode: FocusMode?
    public private(set) var lastScheduledTask: TaskItem?
    public private(set) var lastFiredTask: TaskItem?
    public private(set) var lastScheduledRecurringReminder: RecurringReminder?
    public private(set) var lastFiredRecurringReminder: RecurringReminder?
    public private(set) var lastNotifiedUpdateVersion: String?

    /// Active sound playback task for repeated chimes
    private var activeSoundTask: Task<Void, Never>?

    #if canImport(AppKit)
    private var activeSound: NSSound?
    #endif

    public private(set) var isPlayingSound: Bool = false

    /// Active in-app fallback timers for scheduled task reminders
    private var inAppTimers: [UUID: Timer] = [:]

    /// Active in-app fallback timers for recurring reminders
    private var recurringInAppTimers: [UUID: Timer] = [:]

    /// Optional callback invoked when a task reminder fires
    public var onTaskReminderFired: ((TaskItem) -> Void)?

    /// Optional callback invoked when a recurring reminder fires
    public var onRecurringReminderFired: ((RecurringReminder) -> Void)?

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

    private static var isRunningUnitTests: Bool {
        NSClassFromString("XCTestCase") != nil ||
        NSClassFromString("XCTest") != nil ||
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
        ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
        ProcessInfo.processInfo.arguments.contains(where: { $0.contains("xctest") || $0.contains("test") })
    }

    private static var isNotificationAvailable: Bool {
        guard !isRunningUnitTests,
              let bundleId = Bundle.main.bundleIdentifier,
              bundleId != "com.apple.dt.xctest.tool",
              bundleId != "FocendaPackageTests",
              !bundleId.isEmpty else {
            return false
        }
        return true
    }

    private static var isAudioPlaybackAvailable: Bool {
        !isRunningUnitTests || ProcessInfo.processInfo.environment["ENABLE_TEST_AUDIO"] == "1"
    }

    // MARK: - Rich Audible Alerts

    /// Plays a single rich native macOS alert chime sequence (e.g. Hero, Ping, Glass) with fallback
    public func playRichAlertChime(soundName: String = "Hero") {
        #if canImport(AppKit)
        // Guard against playing sound in headless unit test environments unless explicitly enabled
        guard Self.isAudioPlaybackAvailable else {
            return
        }
        stopActiveSound()
        playSoundOnce(soundName: soundName, customFilePath: nil)
        #endif
    }

    /// Plays a reminder alert chime sequence repeated a specified number of times (e.g. 3 to 5 times)
    public func playReminderAlertChime(
        soundName: String = "Hero",
        customFilePath: String? = nil,
        repeatCount: Int = 3,
        interval: TimeInterval = 0.85
    ) {
        #if canImport(AppKit)
        stopActiveSound()

        guard Self.isAudioPlaybackAvailable else {
            return
        }

        let repeats = max(1, min(10, repeatCount))
        isPlayingSound = true

        activeSoundTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            for index in 0..<repeats {
                if Task.isCancelled { break }
                self.playSoundOnce(soundName: soundName, customFilePath: customFilePath)

                if index < repeats - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                }
            }
            if !Task.isCancelled {
                self.isPlayingSound = false
            }
        }
        #endif
    }

    /// Stops any currently playing alert sound or repetition sequence
    public func stopActiveSound() {
        activeSoundTask?.cancel()
        activeSoundTask = nil
        #if canImport(AppKit)
        activeSound?.stop()
        activeSound = nil
        #endif
        isPlayingSound = false
    }

    /// Plays user-configured reminder sound with configured repetition count
    public func playUserReminderSound() {
        let isEnabled = UserDefaults.standard.object(forKey: "reminderSoundEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "reminderSoundEnabled")
        guard isEnabled else { return }

        let soundTypeRaw = UserDefaults.standard.string(forKey: "reminderSoundType") ?? "Hero"
        let customPath = UserDefaults.standard.string(forKey: "reminderCustomSoundPath")
        let savedRepeatCount = UserDefaults.standard.integer(forKey: "reminderSoundRepeatCount")
        let repeatCount = savedRepeatCount == 0 ? 3 : max(1, min(5, savedRepeatCount))

        if soundTypeRaw == ReminderSoundType.custom.rawValue, let customPath = customPath, !customPath.isEmpty {
            playReminderAlertChime(soundName: "Hero", customFilePath: customPath, repeatCount: repeatCount)
        } else {
            playReminderAlertChime(soundName: soundTypeRaw, customFilePath: nil, repeatCount: repeatCount)
        }
    }

    private func playSoundOnce(soundName: String, customFilePath: String?) {
        #if canImport(AppKit)
        if let customPath = customFilePath,
           !customPath.isEmpty,
           FileManager.default.fileExists(atPath: customPath),
           let sound = NSSound(contentsOfFile: customPath, byReference: true) {
            self.activeSound = sound
            sound.stop()
            if sound.play() {
                return
            }
            self.activeSound = nil
        }

        if let sound = NSSound(named: NSSound.Name(soundName)) {
            self.activeSound = sound
            sound.stop()
            if sound.play() {
                return
            }
            self.activeSound = nil
        }

        if let fallbackSound = NSSound(named: NSSound.Name("Ping")) {
            self.activeSound = fallbackSound
            fallbackSound.stop()
            if fallbackSound.play() {
                return
            }
            self.activeSound = nil
        }

        // Keep an audible fallback even when a named system sound cannot start.
        NSSound.beep()
        #endif
    }

    // MARK: - Authorization

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

    // MARK: - Notification Titles & Bodies

    public static func notificationTitle(for mode: FocusMode) -> String {
        switch mode {
        case .work:
            return "Focus Session Completed"
        case .shortBreak:
            return "Short Break Finished"
        case .longBreak:
            return "Long Break Ended"
        }
    }

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

    public static func taskReminderTitle(for task: TaskItem) -> String {
        "Task Reminder: \(task.title)"
    }

    public static func taskReminderBody(for task: TaskItem) -> String {
        if !task.notes.isEmpty {
            return task.notes
        } else {
            return "Time to focus on '\(task.title)'."
        }
    }

    public static func recurringReminderTitle(for reminder: RecurringReminder) -> String {
        "Reminder (\(reminder.repeatFrequency.rawValue)): \(reminder.title)"
    }

    public static func recurringReminderBody(for reminder: RecurringReminder) -> String {
        if !reminder.notes.isEmpty {
            return "\(reminder.notes) • Scheduled for \(reminder.formattedTime)"
        } else {
            return "Scheduled recurring reminder at \(reminder.formattedTime)."
        }
    }

    /// Builds the local notification content for a completed Pomodoro session.
    /// The system notification owns playback when a notification center is available,
    /// which keeps the banner and its sound in sync without playing the alert twice.
    static func sessionCompletionNotificationContent(
        for mode: FocusMode,
        soundEnabled: Bool
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = Self.notificationTitle(for: mode)
        content.body = Self.notificationBody(for: mode)
        content.sound = soundEnabled ? .default : nil
        return content
    }

    // MARK: - Focus Session Completed

    /// Presents the focus completion alert without activating Focenda in front of the user's current app.
    public func notifySessionCompleted(mode: FocusMode) {
        self.lastNotifiedMode = mode

        let soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "soundEnabled")

        // The native notification owns playback when available. If it is unavailable,
        // retain an in-app fallback so a standalone executable still produces a chime.
        if center == nil && soundEnabled {
            playRichAlertChime(soundName: Self.standardNotificationSoundName)
        }

        #if canImport(AppKit)
        DispatchQueue.main.async { [weak self] in
            ReminderAlertHUDPanel.shared.show(
                title: Self.notificationTitle(for: mode),
                subtitle: "Pomodoro • \(mode.rawValue)",
                notes: Self.notificationBody(for: mode),
                type: "pomodoro",
                timeoutSeconds: 25.0,
                onComplete: {
                    self?.stopActiveSound()
                },
                onOpenApp: {
                    self?.stopActiveSound()
                    NotificationCenter.default.post(name: Self.openFocusTabNotification, object: mode)
                }
            )
        }
        #endif

        guard let center = center else {
            return
        }

        let content = Self.sessionCompletionNotificationContent(for: mode, soundEnabled: soundEnabled)

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

    // MARK: - App Updates

    /// Delivers a native macOS notification for a release discovered by the local updater.
    public func notifyUpdateAvailable(version: String) {
        lastNotifiedUpdateVersion = version

        guard let center = center else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Focenda Update Available"
        content.body = "Version \(version) is ready. Open Settings to install it."
        content.sound = .default
        content.threadIdentifier = "focenda-updates"
        content.userInfo = ["action": "openSettings", "version": version]

        let request = UNNotificationRequest(
            identifier: "focenda-update-\(version.replacingOccurrences(of: ".", with: "-"))",
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule update notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Task Reminders

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

    /// Triggers the in-app alert and sound fallback when task reminder time is reached
    public func triggerInAppReminderFallback(for task: TaskItem) {
        self.lastFiredTask = task
        self.inAppTimers.removeValue(forKey: task.id)

        playUserReminderSound()

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeStr = task.reminderDate != nil ? formatter.string(from: task.reminderDate!) : ""

        NotificationCenter.default.post(
            name: Self.taskReminderFiredNotification,
            object: task,
            userInfo: [
                "taskId": task.id.uuidString,
                "taskTitle": task.title,
                "formattedTitle": Self.taskReminderTitle(for: task),
                "timeString": timeStr
            ]
        )

        NotificationCenter.default.post(
            name: Self.reminderAlertBannerNotification,
            object: task,
            userInfo: [
                "title": task.title,
                "subtitle": task.notes.isEmpty ? "Task Reminder" : task.notes,
                "time": timeStr,
                "type": "task"
            ]
        )

        #if canImport(AppKit)
        DispatchQueue.main.async { [weak self] in
            ReminderAlertHUDPanel.shared.show(
                title: task.title,
                subtitle: timeStr.isEmpty ? "Task Reminder" : "\(timeStr) • Task",
                notes: task.notes,
                type: "task",
                timeoutSeconds: 25.0,
                onSnooze: {
                    self?.snoozeReminder(
                        title: task.title,
                        subtitle: "Task Reminder",
                        notes: task.notes,
                        minutes: 5
                    )
                },
                onComplete: {
                    self?.stopActiveSound()
                },
                onOpenApp: {
                    self?.stopActiveSound()
                    NotificationCenter.default.post(name: Self.openRemindersTabNotification, object: task)
                }
            )
        }
        #endif

        onTaskReminderFired?(task)
    }

    // MARK: - Recurring Reminders

    /// Schedules recurring calendar notification triggers for a recurring reminder
    public func scheduleRecurringReminder(reminder: RecurringReminder) {
        self.lastScheduledRecurringReminder = reminder

        guard reminder.isEnabled else {
            cancelRecurringReminder(reminder: reminder)
            return
        }

        // Cancel previous timers and notifications
        cancelRecurringReminder(reminder: reminder)

        // Setup in-app fallback timer for the next occurrence
        if let nextDate = reminder.nextFireDate() {
            let interval = nextDate.timeIntervalSinceNow
            if interval > 0 {
                let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
                    self?.triggerInAppRecurringReminderFallback(for: reminder)
                }
                RunLoop.main.add(timer, forMode: .common)
                recurringInAppTimers[reminder.id] = timer
            }
        }

        guard let center = center else { return }

        let content = UNMutableNotificationContent()
        content.title = Self.recurringReminderTitle(for: reminder)
        content.body = Self.recurringReminderBody(for: reminder)
        content.sound = .default

        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return }

        switch reminder.repeatFrequency {
        case .daily:
            var match = DateComponents()
            match.hour = hour
            match.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: match, repeats: true)
            let request = UNNotificationRequest(
                identifier: "recurring-reminder-\(reminder.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)

        case .weekdays:
            // Schedule individual recurring requests for Monday through Friday (weekday 2..6)
            for weekday in 2...6 {
                var match = DateComponents()
                match.weekday = weekday
                match.hour = hour
                match.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: match, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "recurring-reminder-\(reminder.id.uuidString)-wd\(weekday)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }

        case .weekly:
            let reminderWeekday = Calendar.current.component(.weekday, from: reminder.time)
            var match = DateComponents()
            match.weekday = reminderWeekday
            match.hour = hour
            match.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: match, repeats: true)
            let request = UNNotificationRequest(
                identifier: "recurring-reminder-\(reminder.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)

        case .monthly:
            let reminderDay = Calendar.current.component(.day, from: reminder.time)
            var match = DateComponents()
            match.day = reminderDay
            match.hour = hour
            match.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: match, repeats: true)
            let request = UNNotificationRequest(
                identifier: "recurring-reminder-\(reminder.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// Cancels all scheduled notification triggers and in-app fallback timers for a recurring reminder
    public func cancelRecurringReminder(reminder: RecurringReminder) {
        recurringInAppTimers[reminder.id]?.invalidate()
        recurringInAppTimers.removeValue(forKey: reminder.id)

        guard let center = center else { return }

        var identifiers = ["recurring-reminder-\(reminder.id.uuidString)"]
        for weekday in 2...6 {
            identifiers.append("recurring-reminder-\(reminder.id.uuidString)-wd\(weekday)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Triggers the in-app alert, banner, and rich sound when a recurring reminder fires
    public func triggerInAppRecurringReminderFallback(for reminder: RecurringReminder) {
        self.lastFiredRecurringReminder = reminder
        self.recurringInAppTimers.removeValue(forKey: reminder.id)

        playUserReminderSound()

        NotificationCenter.default.post(
            name: Self.recurringReminderFiredNotification,
            object: reminder,
            userInfo: [
                "reminderId": reminder.id.uuidString,
                "title": reminder.title,
                "formattedTitle": Self.recurringReminderTitle(for: reminder),
                "timeString": reminder.formattedTime,
                "repeatFrequency": reminder.repeatFrequency.rawValue
            ]
        )

        NotificationCenter.default.post(
            name: Self.reminderAlertBannerNotification,
            object: reminder,
            userInfo: [
                "title": reminder.title,
                "subtitle": "\(reminder.repeatFrequency.rawValue) Reminder",
                "time": reminder.formattedTime,
                "type": "recurring"
            ]
        )

        #if canImport(AppKit)
        DispatchQueue.main.async { [weak self] in
            ReminderAlertHUDPanel.shared.show(
                title: reminder.title,
                subtitle: "\(reminder.formattedTime) • \(reminder.repeatFrequency.rawValue)",
                notes: reminder.notes,
                type: "recurring",
                timeoutSeconds: 25.0,
                onSnooze: {
                    self?.snoozeReminder(
                        title: reminder.title,
                        subtitle: "\(reminder.formattedTime) • \(reminder.repeatFrequency.rawValue)",
                        notes: reminder.notes,
                        minutes: 5
                    )
                },
                onComplete: {
                    self?.stopActiveSound()
                },
                onOpenApp: {
                    self?.stopActiveSound()
                    NotificationCenter.default.post(name: Self.openRemindersTabNotification, object: reminder)
                }
            )
        }
        #endif

        onRecurringReminderFired?(reminder)

        // Reschedule next occurrence timer
        if reminder.isEnabled {
            if let nextDate = reminder.nextFireDate() {
                let interval = nextDate.timeIntervalSinceNow
                if interval > 0 {
                    let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
                        self?.triggerInAppRecurringReminderFallback(for: reminder)
                    }
                    RunLoop.main.add(timer, forMode: .common)
                    recurringInAppTimers[reminder.id] = timer
                }
            }
        }
    }

    // MARK: - Snooze & Test Reminders

    /// Snoozes a reminder for a specified duration in minutes, re-triggering sound and screen alert
    public func snoozeReminder(
        title: String,
        subtitle: String = "Snoozed Reminder",
        notes: String = "",
        minutes: Int = 5
    ) {
        stopActiveSound()

        let interval = TimeInterval(max(1, minutes) * 60)
        let snoozeTimer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.playUserReminderSound()

            NotificationCenter.default.post(
                name: Self.reminderAlertBannerNotification,
                object: nil,
                userInfo: [
                    "title": title,
                    "subtitle": subtitle,
                    "time": "Snoozed (\(minutes)m)",
                    "type": "snooze"
                ]
            )

            #if canImport(AppKit)
            DispatchQueue.main.async {
                ReminderAlertHUDPanel.shared.show(
                    title: title,
                    subtitle: subtitle,
                    notes: notes,
                    type: "snooze",
                    timeoutSeconds: 25.0,
                    onSnooze: { [weak self] in
                        self?.snoozeReminder(title: title, subtitle: subtitle, notes: notes, minutes: minutes)
                    },
                    onComplete: { [weak self] in
                        self?.stopActiveSound()
                    },
                    onOpenApp: { [weak self] in
                        self?.stopActiveSound()
                        NotificationCenter.default.post(name: Self.openRemindersTabNotification, object: nil)
                    }
                )
            }
            #endif
        }
        RunLoop.main.add(snoozeTimer, forMode: .common)

        NotificationCenter.default.post(
            name: Self.reminderSnoozedNotification,
            object: nil,
            userInfo: [
                "title": title,
                "minutes": minutes
            ]
        )
    }

    /// Triggers an immediate screen HUD alert and chime sequence for testing
    public func testReminderAlertHUD(
        title: String = "Daily Standup",
        subtitle: String = "Daily Reminder • 6:00 PM",
        notes: String = "Time to review your daily accomplishments and plan ahead!"
    ) {
        playUserReminderSound()

        NotificationCenter.default.post(
            name: Self.reminderAlertBannerNotification,
            object: nil,
            userInfo: [
                "title": title,
                "subtitle": subtitle,
                "time": "Now",
                "type": "test"
            ]
        )

        #if canImport(AppKit)
        DispatchQueue.main.async { [weak self] in
            ReminderAlertHUDPanel.shared.show(
                title: title,
                subtitle: subtitle,
                notes: notes,
                type: "test",
                timeoutSeconds: 25.0,
                onSnooze: {
                    self?.snoozeReminder(title: title, subtitle: subtitle, notes: notes, minutes: 5)
                },
                onComplete: {
                    self?.stopActiveSound()
                },
                onOpenApp: {
                    self?.stopActiveSound()
                    NotificationCenter.default.post(name: Self.openRemindersTabNotification, object: nil)
                }
            )
        }
        #endif
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

    /// Takes the user to Settings when they click the update notification.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let action = response.notification.request.content.userInfo["action"] as? String,
           action == "openSettings" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.openSettingsNotification, object: nil)
            }
        }
        completionHandler()
    }
}
