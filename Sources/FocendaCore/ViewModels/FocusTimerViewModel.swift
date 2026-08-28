import Foundation
import SwiftUI
import AppKit
import Observation

public enum TimerStatus: String, Equatable {
    case idle
    case running
    case paused
}

@Observable
public final class FocusTimerViewModel {
    public var currentMode: FocusMode = .work
    public var status: TimerStatus = .idle
    public var timeRemainingSeconds: Int = 25 * 60
    public var totalDurationSeconds: Int = 25 * 60
    public var completedSessionsCount: Int = 0
    public var completedWorkSessionsCount: Int = 0
    public var completedSessions: [FocusSession] = []
    public var onSessionCompleted: ((FocusMode) -> Void)?
    /// Optional explicit opt-in for callers that want to open Focenda after completion.
    /// The app leaves this disabled so the completion HUD can notify without stealing focus.
    public var autoOpenOnCompletion: Bool = false


    // Interval durations (in minutes)
    public var workDurationMinutes: Int = 25 {
        didSet { if status == .idle && currentMode == .work { resetToCurrentMode() } }
    }
    public var shortBreakDurationMinutes: Int = 5 {
        didSet { if status == .idle && currentMode == .shortBreak { resetToCurrentMode() } }
    }
    public var longBreakDurationMinutes: Int = 15 {
        didSet { if status == .idle && currentMode == .longBreak { resetToCurrentMode() } }
    }

    private var timer: Timer?
    // Timer callbacks refresh the UI; ContinuousClock is the source of truth for elapsed time.
    private var runningSegmentStartedAt: ContinuousClock.Instant?
    private var timeRemainingAtSegmentStart = 0
    private let now: () -> ContinuousClock.Instant

    public init() {
        self.now = { ContinuousClock.now }
        resetToCurrentMode()
    }

    init(now: @escaping () -> ContinuousClock.Instant) {
        self.now = now
        resetToCurrentMode()
    }

    public var progress: Double {
        guard totalDurationSeconds > 0 else { return 0 }
        let elapsed = totalDurationSeconds - timeRemainingSeconds
        return Double(elapsed) / Double(totalDurationSeconds)
    }

    public var formattedTimeRemaining: String {
        let minutes = timeRemainingSeconds / 60
        let seconds = timeRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    public var todayFocusMinutes: Int {
        let calendar = Calendar.current
        let todaySessions = completedSessions.filter {
            $0.mode == .work && calendar.isDateInToday($0.completedAt)
        }
        let totalSeconds = todaySessions.reduce(0) { $0 + $1.durationSeconds }
        return totalSeconds / 60
    }

    public func start() {
        guard status != .running else { return }
        status = .running
        runningSegmentStartedAt = now()
        timeRemainingAtSegmentStart = timeRemainingSeconds

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    public func pause() {
        guard status == .running else { return }
        updateRemainingTime()
        guard status == .running else { return }

        status = .paused
        timer?.invalidate()
        timer = nil
        runningSegmentStartedAt = nil
        timeRemainingAtSegmentStart = 0
    }

    public func resume() {
        start()
    }

    public func reset() {
        pause()
        status = .idle
        resetToCurrentMode()
    }

    public func skip() {
        pause()
        status = .idle
        advanceToNextMode()
    }

    public func toggleStartPause() {
        if status == .running {
            pause()
        } else {
            start()
        }
    }

    public func switchMode(to mode: FocusMode) {
        pause()
        currentMode = mode
        status = .idle
        resetToCurrentMode()
    }

    public func startMode(_ mode: FocusMode) {
        switchMode(to: mode)
        start()
    }

    /// Adjust remaining time by a delta in seconds (clamped to minimum 60s)
    public func adjustTime(bySeconds seconds: Int) {
        if status == .running {
            updateRemainingTime()
            guard status == .running else { return }
        }

        let updated = max(60, timeRemainingSeconds + seconds)
        timeRemainingSeconds = updated
        if updated > totalDurationSeconds {
            totalDurationSeconds = updated
        }

        if status == .running {
            runningSegmentStartedAt = now()
            timeRemainingAtSegmentStart = timeRemainingSeconds
        }
    }

    /// Convenience method to adjust remaining time by minutes (e.g. +5 or -5)
    public func adjustTime(byMinutes minutes: Int) {
        adjustTime(bySeconds: minutes * 60)
    }

    public func tick() {
        guard status == .running else { return }

        updateRemainingTime()
    }

    public func completeCurrentSession() {
        timer?.invalidate()
        timer = nil
        runningSegmentStartedAt = nil
        timeRemainingAtSegmentStart = 0
        status = .idle

        let finishedMode = currentMode
        let session = FocusSession(
            mode: finishedMode,
            durationSeconds: totalDurationSeconds,
            completedAt: Date()
        )
        completedSessions.append(session)
        completedSessionsCount += 1

        if finishedMode == .work {
            completedWorkSessionsCount += 1
        }

        NotificationManager.shared.notifySessionCompleted(mode: finishedMode)

        if autoOpenOnCompletion {
            bringAppToFront()
        }

        NotificationCenter.default.post(
            name: .focusSessionCompleted,
            object: self,
            userInfo: ["mode": finishedMode]
        )

        onSessionCompleted?(finishedMode)

        advanceToNextMode()
    }

    public func bringAppToFront() {
        let isRunningInTest = NSClassFromString("XCTestCase") != nil ||
                              NSClassFromString("XCTest") != nil ||
                              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                              ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
                              ProcessInfo.processInfo.arguments.contains(where: { $0.contains("xctest") || $0.contains("test") })

        guard !isRunningInTest else { return }

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func advanceToNextMode() {
        if currentMode == .work {
            if completedWorkSessionsCount > 0 && completedWorkSessionsCount % 4 == 0 {
                currentMode = .longBreak
            } else {
                currentMode = .shortBreak
            }
        } else {
            currentMode = .work
        }
        resetToCurrentMode()
    }

    public func resetToCurrentMode() {
        runningSegmentStartedAt = nil
        timeRemainingAtSegmentStart = 0

        let durationMinutes: Int
        switch currentMode {
        case .work:
            durationMinutes = workDurationMinutes
        case .shortBreak:
            durationMinutes = shortBreakDurationMinutes
        case .longBreak:
            durationMinutes = longBreakDurationMinutes
        }
        totalDurationSeconds = durationMinutes * 60
        timeRemainingSeconds = totalDurationSeconds
    }

    deinit {
        timer?.invalidate()
    }

    private func updateRemainingTime() {
        guard status == .running else { return }

        guard let startedAt = runningSegmentStartedAt else {
            runningSegmentStartedAt = now()
            timeRemainingAtSegmentStart = timeRemainingSeconds
            return
        }

        let elapsed = max(0, Int((now() - startedAt) / .seconds(1)))
        let updatedRemaining = timeRemainingAtSegmentStart - elapsed
        timeRemainingSeconds = max(0, updatedRemaining)

        if updatedRemaining <= 0 {
            completeCurrentSession()
        }
    }
}


extension Notification.Name {
    public static let focusSessionCompleted = Notification.Name("FocendaFocusSessionCompletedNotification")
}
