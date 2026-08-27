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
                // Appearance & Theme Picker
                themePickerSection

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

                    // Preset Picker
                    HStack {
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
            HStack(spacing: 14) {
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

                    Text(theme.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                // Live Preview Color Swatches
                HStack(spacing: 6) {
                    ForEach(Array(theme.previewSwatches.enumerated()), id: \.offset) { _, swatchColor in
                        Circle()
                            .fill(swatchColor)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.12), lineWidth: 0.8)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 0.5)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(AppTheme.cardBackgroundSubtle.opacity(0.8))
                )
                .overlay(
                    Capsule()
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
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
