import SwiftUI
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif

public struct SettingsView: View {
    @Bindable var appState: AppState
    var timerVM: FocusTimerViewModel
    var updateManager: AppUpdateManager

    @State private var isTestingSound: Bool = false
    @State private var testingTask: Task<Void, Never>?

    public init(
        appState: AppState,
        timerVM: FocusTimerViewModel,
        updateManager: AppUpdateManager = AppUpdateManager()
    ) {
        self.appState = appState
        self.timerVM = timerVM
        self.updateManager = updateManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let error = appState.persistenceErrorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Appearance & Theme Picker
                themePickerSection

                // App Updates
                appUpdateSection

                // Reminder Sounds & Chimes
                reminderSoundSection

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

                // Global Keyboard Shortcuts
                keyboardShortcutsSection

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
                        HStack(spacing: 14) {
                            OwlMascotView(size: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focenda for Mac")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Version \(AppRuntime.currentReleaseIdentifier) • 100% Free & Open Source")
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
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationTitle("Settings")
        .onDisappear {
            stopAudioPreview()
        }
    }

    // MARK: - App Updates Section
    private var appUpdateSection: some View {
        GroupBox(label: Label("App Updates", systemImage: "arrow.down.circle").foregroundStyle(AppTheme.textPrimary)) {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $appState.automaticUpdateChecksEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Check for updates automatically")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Check GitHub Releases once a day while Focenda is open and notify you when a new version is ready.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(AppTheme.accent)
                .onChange(of: appState.automaticUpdateChecksEnabled) { _, isEnabled in
                    updateManager.setAutomaticChecksEnabled(isEnabled)
                }

                Divider()

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: updateStatusIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(updateStatusColor)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(updateStatusTitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        if let lastCheckedAt = updateManager.lastCheckedAt {
                            Text("Last checked \(lastCheckedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }

                    Spacer()

                    Button {
                        updateManager.checkForUpdates()
                    } label: {
                        Label(updateManager.status == .checking ? "Checking..." : "Check Now", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(updateManager.status.isBusy)
                }

                if let update = updateManager.availableUpdate {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(AppTheme.accent)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Version \(update.version.description) is available")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(update.displayName)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }

                        HStack {
                            Button("Update Now") {
                                updateManager.installAvailableUpdate()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accent)
                            .controlSize(.small)
                            .disabled(updateManager.status.isBusy)

                            Button("Later") {
                                updateManager.dismissAvailableUpdate()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(updateManager.status.isBusy)

                            Spacer()
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
                    )
                }

                if case .failed(let message) = updateManager.status {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Privacy: Tasks, notes, reminders, bookmarks, productivity profiles, and preferences stay on this Mac in encrypted local storage. Focenda contacts only GitHub's public release service for update metadata and the selected app archive. macOS may display reminder content in its notification system. See docs/PRIVACY.md for details.")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
        }
    }

    private var updateStatusTitle: String {
        switch updateManager.status {
        case .idle:
            return "Updates are ready to check"
        case .checking:
            return "Checking GitHub Releases..."
        case .available:
            return "A new version is ready"
        case .upToDate:
            return "Focenda is up to date"
        case .installing:
            return "Installing update..."
        case .failed:
            return "Update check could not be completed"
        }
    }

    private var updateStatusIcon: String {
        switch updateManager.status {
        case .idle:
            return "arrow.down.circle"
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .available:
            return "checkmark.seal.fill"
        case .upToDate:
            return "checkmark.circle.fill"
        case .installing:
            return "shippingbox.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var updateStatusColor: Color {
        switch updateManager.status {
        case .failed:
            return .orange
        case .available, .installing:
            return AppTheme.accent
        case .upToDate:
            return AppTheme.success
        case .idle, .checking:
            return AppTheme.textTertiary
        }
    }

    // MARK: - Reminder Sounds Section
    private var reminderSoundSection: some View {
        GroupBox(label: Label("Reminder & Pomodoro Sound Chimes", systemImage: "bell.and.waves.left.and.right").foregroundStyle(AppTheme.textPrimary)) {
            VStack(alignment: .leading, spacing: 16) {
                // Master Toggle
                Toggle(isOn: $appState.reminderSoundEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Sound for Reminders")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Plays an audible alert chime whenever a timed task or recurring reminder is due.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(AppTheme.accent)

                if appState.reminderSoundEnabled {
                    Divider()

                    // Sound Type Picker (System sounds or Custom)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Alert Chime Sound:")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Choose the chime for reminders and Pomodoro completions, or upload your own audio file.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Picker("", selection: $appState.reminderSoundType) {
                            ForEach(ReminderSoundType.allCases) { sound in
                                Text(sound.displayName).tag(sound)
                            }
                        }
                        .frame(maxWidth: 220)
                    }

                    // Custom Audio File Selector (if .custom)
                    if appState.reminderSoundType == .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.accent)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appState.reminderCustomSoundName.isEmpty ? "No custom audio file selected" : appState.reminderCustomSoundName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    if !appState.reminderCustomSoundPath.isEmpty {
                                        Text(appState.reminderCustomSoundPath)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(AppTheme.textTertiary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                }

                                Spacer()

                                Button {
                                    chooseCustomAudioFile()
                                } label: {
                                    Label(appState.reminderCustomSoundPath.isEmpty ? "Browse File..." : "Change File...", systemImage: "folder")
                                        .font(.caption.weight(.medium))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                if !appState.reminderCustomSoundPath.isEmpty {
                                    Button {
                                        appState.reminderCustomSoundPath = ""
                                        appState.reminderCustomSoundName = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AppTheme.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Clear selected audio file")
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppTheme.cardBackgroundSubtle.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                        }
                    }

                    Divider()

                    // Sound Repetition Stepper
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Chime Repetitions:")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Repeat the chime 1 to 5 times so you don't miss reminders or Pomodoro alerts.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Stepper("\(appState.reminderSoundRepeatCount)x", value: $appState.reminderSoundRepeatCount, in: ReminderSoundType.minRepeatCount...ReminderSoundType.maxRepeatCount, step: 1)
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Divider()

                    // Test Audio Preview Button
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sound Preview:")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Test how the alert chime will sound with \(appState.reminderSoundRepeatCount) repetitions.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Button {
                            toggleAudioPreview()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isTestingSound ? "stop.fill" : "speaker.wave.3.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isTestingSound ? "Stop Sound" : "Test Alert Sound")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isTestingSound ? Color.red.opacity(0.8) : AppTheme.accent)
                    }
                }
            }
            .padding(12)
        }
    }

    private func chooseCustomAudioFile() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.title = "Select Notification Sound"
        panel.prompt = "Choose Sound"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .audio,
            .aiff,
            .wav,
            .mp3,
            .mpeg4Audio
        ]

        if panel.runModal() == .OK, let url = panel.url {
            appState.reminderCustomSoundPath = url.path
            appState.reminderCustomSoundName = url.lastPathComponent
            appState.reminderCustomSoundBookmarkData = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        }
        #endif
    }

    private func toggleAudioPreview() {
        if isTestingSound {
            stopAudioPreview()
        } else {
            let soundName = appState.reminderSoundType.rawValue
            let customPath = appState.reminderSoundType == .custom ? appState.reminderCustomSoundPath : nil
            let count = appState.reminderSoundRepeatCount
            let interval: TimeInterval = 0.85

            isTestingSound = true
            NotificationManager.shared.playReminderAlertChime(
                soundName: soundName,
                customFilePath: customPath,
                repeatCount: count,
                interval: interval
            )

            testingTask?.cancel()
            let totalEstimatedDuration = Double(count) * interval + 0.5
            testingTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(totalEstimatedDuration * 1_000_000_000))
                if !Task.isCancelled {
                    isTestingSound = false
                }
            }
        }
    }

    private func stopAudioPreview() {
        NotificationManager.shared.stopActiveSound()
        testingTask?.cancel()
        testingTask = nil
        isTestingSound = false
    }

    // MARK: - Theme Picker Section
    private var themePickerSection: some View {
        GroupBox(label: Label("Appearance & Theme", systemImage: "paintpalette").foregroundStyle(AppTheme.textPrimary)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select your preferred workspace aesthetic. The chosen theme maintains consistent colors throughout the app without random mode switches.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)

                VStack(spacing: 8) {
                    ForEach(AppThemeOption.allCases) { theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: appState.selectedTheme == theme
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                appState.selectedTheme = theme
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    // MARK: - Global Keyboard Shortcuts Section
    private var keyboardShortcutsSection: some View {
        GroupBox(label: Label("Global Keyboard Shortcuts", systemImage: "keyboard").foregroundStyle(AppTheme.textPrimary)) {
            VStack(alignment: .leading, spacing: 16) {
                // Master Toggle
                Toggle(isOn: $appState.globalShortcutsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable System-Wide Global Shortcuts")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Control your focus timer anywhere in macOS even when Focenda is in the background or menu bar.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(AppTheme.accent)

                if appState.globalShortcutsEnabled {
                    Divider()

                    // Preset Picker with responsive layout protection
                    ViewThatFits(in: .horizontal) {
                        // Wide Horizontal Layout
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Shortcut Scheme:")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Select modifier combination for focus shortcuts.")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Picker("", selection: $appState.shortcutPreset) {
                                ForEach(GlobalShortcutPreset.allCases) { preset in
                                    Text(preset.displayName).tag(preset)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 320)
                        }

                        // Compact Vertical Layout (avoids overflowing right card edge)
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Shortcut Scheme:")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Select modifier combination for focus shortcuts.")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Picker("", selection: $appState.shortcutPreset) {
                                ForEach(GlobalShortcutPreset.allCases) { preset in
                                    Text(preset.displayName).tag(preset)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: .infinity)
                        }
                    }

                    Divider()

                    // Shortcut List Cards
                    VStack(spacing: 8) {
                        let combinations = ShortcutKeyCombination.defaultCombinations(for: appState.shortcutPreset)
                        ForEach(combinations) { combo in
                            ShortcutRowView(combination: combo)
                        }
                    }

                    Divider()

                    // Audio Confirmation Feedback Toggle
                    Toggle("Play subtle confirmation sound when shortcut is triggered", isOn: $appState.showShortcutFeedback)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Shortcut Row View

private struct ShortcutRowView: View {
    let combination: ShortcutKeyCombination

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: combination.action.iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(combination.action.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(combination.action.description)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            // Keycap Badges
            HStack(spacing: 4) {
                ForEach(combination.keyBadges, id: \.self) { badge in
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(AppTheme.cardBackgroundSubtle)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.cardBackgroundSubtle.opacity(0.35))
        )
    }
}

// MARK: - Theme Option Row with Live Preview Swatches

private struct ThemeOptionRow: View {
    let theme: AppThemeOption
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.accent : AppTheme.subtleBorder, lineWidth: 2)
                        .frame(width: 18, height: 18)

                    if isSelected {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 10, height: 10)
                    }
                }

                // Theme Title and Description
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.subheadline.weight(isSelected ? .bold : .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(theme.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Live Preview Color Swatches
                HStack(spacing: 5) {
                    ForEach(Array(theme.previewSwatches.enumerated()), id: \.offset) { _, swatchColor in
                        Circle()
                            .fill(swatchColor)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.12), lineWidth: 0.8)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 0.5)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppTheme.cardBackgroundSubtle.opacity(0.8))
                )
                .overlay(
                    Capsule()
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? AppTheme.accent.opacity(0.08) : (isHovered ? AppTheme.cardBackgroundSubtle : AppTheme.cardBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? AppTheme.accent : (isHovered ? AppTheme.border : AppTheme.subtleBorder),
                        lineWidth: isSelected ? 1.5 : 1.0
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
    }
}
