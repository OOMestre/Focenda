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

    public init() {
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

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    public func pause() {
        guard status == .running else { return }
        status = .paused
        timer?.invalidate()
        timer = nil
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

    public func switchMode(to mode: FocusMode) {
        pause()
        currentMode = mode
        status = .idle
        resetToCurrentMode()
    }

    /// Adjust remaining time by a delta in seconds (clamped to minimum 60s)
    public func adjustTime(bySeconds seconds: Int) {
        let updated = max(60, timeRemainingSeconds + seconds)
        timeRemainingSeconds = updated
        if updated > totalDurationSeconds {
            totalDurationSeconds = updated
        }
    }

    /// Convenience method to adjust remaining time by minutes (e.g. +5 or -5)
    public func adjustTime(byMinutes minutes: Int) {
        adjustTime(bySeconds: minutes * 60)
    }

    public func tick() {
        guard status == .running else { return }

        if timeRemainingSeconds > 0 {
            timeRemainingSeconds -= 1
        } else {
            completeCurrentSession()
        }
    }

    public func completeCurrentSession() {
        timer?.invalidate()
        timer = nil
        status = .idle

        let session = FocusSession(
            mode: currentMode,
            durationSeconds: totalDurationSeconds,
            completedAt: Date()
        )
        completedSessions.append(session)
        completedSessionsCount += 1

        if currentMode == .work {
            completedWorkSessionsCount += 1
        }

        NotificationManager.shared.notifySessionCompleted(mode: currentMode)
        playCompletionSound()
        advanceToNextMode()
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

    private func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }

    deinit {
        timer?.invalidate()
    }
}
