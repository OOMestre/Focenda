import SwiftUI

public struct FocusTimerView: View {
    var timerVM: FocusTimerViewModel

    public init(timerVM: FocusTimerViewModel) {
        self.timerVM = timerVM
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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

                // Circular progress ring with running pulse effect
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
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .id(timerVM.currentMode)

                // Pomodoro cycle dots
                HStack(spacing: 8) {
                    Text("Pomodoro Cycle:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(0..<4) { index in
                        let isCompleted = (timerVM.completedWorkSessionsCount % 4) > index
                        Circle()
                            .fill(
                                isCompleted
                                    ? timerVM.currentMode.themeColor
                                    : Color.secondary.opacity(0.25)
                            )
                            .frame(width: isCompleted ? 10 : 8, height: isCompleted ? 10 : 8)
                            .shadow(
                                color: isCompleted ? timerVM.currentMode.themeColor.opacity(0.4) : .clear,
                                radius: 4,
                                x: 0,
                                y: 1
                            )
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
                    : (isHovered ? Color.primary.opacity(0.1) : Color.primary.opacity(0.05))
            )
            .foregroundStyle(
                isSelected
                    ? .white
                    : .primary
            )
            .clipShape(Capsule())
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .shadow(
                color: isSelected ? mode.themeColor.opacity(0.3) : .clear,
                radius: 6,
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
                            color: themeColor.opacity(isHovered ? 0.45 : 0.28),
                            radius: isHovered ? 12 : 8,
                            x: 0,
                            y: isHovered ? 5 : 3
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
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isHovered ? Color(nsColor: .controlBackgroundColor) : Color.primary.opacity(0.04))
                        .shadow(
                            color: Color.black.opacity(isHovered ? 0.08 : 0.0),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            Color.primary.opacity(isHovered ? 0.15 : 0.06),
                            lineWidth: 1
                        )
                )
                .scaleEffect(isHovered ? 1.08 : 1.0)
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
