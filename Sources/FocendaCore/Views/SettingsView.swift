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
                GroupBox(label: Label("Focus Intervals (Minutes)", systemImage: "timer")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Deep Focus:")
                            Spacer()
                            Stepper("\(timerVM.workDurationMinutes) min", value: Bindable(timerVM).workDurationMinutes, in: 5...90, step: 5)
                        }

                        Divider()

                        HStack {
                            Text("Short Break:")
                            Spacer()
                            Stepper("\(timerVM.shortBreakDurationMinutes) min", value: Bindable(timerVM).shortBreakDurationMinutes, in: 1...30, step: 1)
                        }

                        Divider()

                        HStack {
                            Text("Long Break:")
                            Spacer()
                            Stepper("\(timerVM.longBreakDurationMinutes) min", value: Bindable(timerVM).longBreakDurationMinutes, in: 5...60, step: 5)
                        }
                    }
                    .padding(12)
                }

                // General Preferences
                GroupBox(label: Label("General Preferences", systemImage: "slider.horizontal.3")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Daily Focus Goal:")
                            Spacer()
                            Stepper("\(appState.dailyFocusGoalMinutes) min", value: $appState.dailyFocusGoalMinutes, in: 30...600, step: 30)
                                .onChange(of: appState.dailyFocusGoalMinutes) { _, _ in
                                    appState.savePreferences()
                                }
                        }

                        Divider()

                        Toggle("Play sound chime when session completes", isOn: $appState.soundEnabled)
                            .onChange(of: appState.soundEnabled) { _, _ in
                                appState.savePreferences()
                            }
                    }
                    .padding(12)
                }

                // About Focenda
                GroupBox(label: Label("About Focenda", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focenda for Mac")
                                    .font(.headline)
                                Text("Version 0.1.0 • 100% Free & Open Source")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        Text("Built natively with Swift and SwiftUI for a lightweight, distraction-free productivity experience.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider()

                        HStack(spacing: 12) {
                            if let url = URL(string: "https://github.com/OOMestre/Focenda") {
                                Link(destination: url) {
                                    Label("GitHub Repository", systemImage: "link")
                                }
                            }

                            Spacer()

                            Text("MIT License")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(12)
                }
            }
            .padding(28)
        }
        .navigationTitle("Settings")
    }
}
