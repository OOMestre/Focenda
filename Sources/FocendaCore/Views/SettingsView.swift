import SwiftUI

public struct SettingsView: View {
    @Bindable var appState: AppState
    var timerVM: FocusTimerViewModel

    public init(
        appState: AppState,
        timerVM: FocusTimerViewModel
    ) {
        self.appState = appState
        self.timerVM = timerVM
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Focus Intervals
                GroupBox(label: Label("Focus Intervals (Minutes)", systemImage: "timer").foregroundStyle(AppTheme.textPrimary)) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Deep Focus:")
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Stepper("\(timerVM.workDurationMinutes) min", value: Bindable(timerVM).workDurationMinutes, in: 5...90, step: 5)
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        Divider()

                        HStack {
                            Text("Short Break:")
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Stepper("\(timerVM.shortBreakDurationMinutes) min", value: Bindable(timerVM).shortBreakDurationMinutes, in: 1...30, step: 1)
                                .foregroundStyle(AppTheme.textPrimary)
                        }

                        Divider()

                        HStack {
                            Text("Long Break:")
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Stepper("\(timerVM.longBreakDurationMinutes) min", value: Bindable(timerVM).longBreakDurationMinutes, in: 5...60, step: 5)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    .padding(12)
                }

                // General Preferences
                GroupBox(label: Label("General Preferences", systemImage: "slider.horizontal.3").foregroundStyle(AppTheme.textPrimary)) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Daily Focus Goal:")
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Stepper("\(appState.dailyFocusGoalMinutes) min", value: $appState.dailyFocusGoalMinutes, in: 30...600, step: 30)
                                .foregroundStyle(AppTheme.textPrimary)
                                .onChange(of: appState.dailyFocusGoalMinutes) { _, _ in
                                    appState.savePreferences()
                                }
                        }

                        Divider()

                        Toggle("Play sound chime when session completes", isOn: $appState.soundEnabled)
                            .foregroundStyle(AppTheme.textPrimary)
                            .onChange(of: appState.soundEnabled) { _, _ in
                                appState.savePreferences()
                            }
                    }
                    .padding(12)
                }

                // About Focenda
                GroupBox(label: Label("About Focenda", systemImage: "info.circle").foregroundStyle(AppTheme.textPrimary)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focenda for Mac")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Version 0.1.0 • 100% Free & Open Source")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                        }

                        Text("Built natively with Swift and SwiftUI for a lightweight, distraction-free productivity experience.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)

                        Divider()

                        HStack(spacing: 12) {
                            if let url = URL(string: "https://github.com/OOMestre/Focenda") {
                                Link(destination: url) {
                                    Label("GitHub Repository", systemImage: "link")
                                }
                                .foregroundStyle(AppTheme.accent)
                            }

                            Spacer()

                            Text("MIT License")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .padding(12)
                }
            }
            .padding(28)
        }
        .background(AppTheme.background)
        .navigationTitle("Settings")
    }
}
