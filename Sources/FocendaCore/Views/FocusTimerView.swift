import SwiftUI

public struct FocusTimerView: View {
    var timerVM: FocusTimerViewModel

    public init(timerVM: FocusTimerViewModel) {
        self.timerVM = timerVM
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Mode selectors
                HStack(spacing: 12) {
                    ForEach(FocusMode.allCases) { mode in
                        ModeSelectorButton(
                            mode: mode,
                            isSelected: timerVM.currentMode == mode
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                timerVM.switchMode(to: mode)
                            }
                        }
                    }
                }
                .padding(.top, 12)

                // Circular progress ring with calm organic depth
                CircularProgressView(
                    progress: timerVM.progress,
                    formattedTime: timerVM.formattedTimeRemaining,
                    subtitle: timerVM.currentMode.rawValue,
                    themeColor: timerVM.currentMode.themeColor,
                    isRunning: timerVM.status == .running
                )
                .padding(.vertical, 8)

                // Motivational message
                Text(timerVM.currentMode.motivationalMessage)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .id(timerVM.currentMode)

                // Pomodoro cycle dots
                HStack(spacing: 8) {
                    Text("Pomodoro Cycle:")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    ForEach(0..<4) { index in
                        let isCompleted = (timerVM.completedWorkSessionsCount % 4) > index
                        Circle()
                            .fill(
                                isCompleted
                                    ? timerVM.currentMode.themeColor
                                    : AppTheme.border
                            )
                            .frame(width: isCompleted ? 9 : 7, height: isCompleted ? 9 : 7)
                            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: timerVM.completedWorkSessionsCount)
                    }
                }

                // Controls with interactive hover scale feedback
                HStack(spacing: 24) {
                    HoverScaleButton(
                        icon: "arrow.counterclockwise",
                        size: 48,
                        fontSize: 18,
                        helpText: "Reset current session"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            timerVM.reset()
                        }
                    }

                    PrimaryPlayPauseButton(
                        isRunning: timerVM.status == .running,
                        themeColor: timerVM.currentMode.themeColor
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            if timerVM.status == .running {
                                timerVM.pause()
                            } else {
                                timerVM.start()
                            }
                        }
                    }

                    HoverScaleButton(
                        icon: "forward.fill",
                        size: 48,
                        fontSize: 18,
                        helpText: "Skip to next cycle"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            timerVM.skip()
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .background(AppTheme.background)
        .navigationTitle("Focus Timer")
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: timerVM.currentMode)
    }
}

// MARK: - Subviews

private struct ModeSelectorButton: View {
    let mode: FocusMode
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mode.iconName)
                    .symbolEffect(.bounce, value: isSelected)
                Text(mode.rawValue)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? mode.themeColor
                    : (isHovered ? AppTheme.cardBackgroundSubtle : AppTheme.cardBackground)
            )
            .foregroundStyle(
                isSelected
                    ? .white
                    : (isHovered ? AppTheme.textPrimary : AppTheme.textSecondary)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : (isHovered ? AppTheme.border : AppTheme.subtleBorder), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .shadow(
                color: isSelected ? Color.black.opacity(0.08) : Color.clear,
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isHovered = hovering
            }
        }
    }
}

private struct PrimaryPlayPauseButton: View {
    let isRunning: Bool
    let themeColor: Color
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(
                    Circle()
                        .fill(themeColor)
                        .shadow(
                            color: Color.black.opacity(isHovered ? 0.16 : 0.10),
                            radius: isHovered ? 8 : 5,
                            x: 0,
                            y: isHovered ? 3 : 2
                        )
                )
                .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .help(isRunning ? "Pause timer" : "Start timer")
    }
}

private struct HoverScaleButton: View {
    let icon: String
    let size: CGFloat
    let fontSize: CGFloat
    let helpText: String
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(isHovered ? AppTheme.textPrimary : AppTheme.textSecondary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isHovered ? AppTheme.cardBackgroundSubtle : AppTheme.cardBackground)
                        .shadow(
                            color: Color.black.opacity(isHovered ? 0.06 : 0.02),
                            radius: 3,
                            x: 0,
                            y: 1
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            isHovered ? AppTheme.border : AppTheme.subtleBorder,
                            lineWidth: 1
                        )
                )
                .scaleEffect(isHovered ? 1.06 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .help(helpText)
    }
}
