import SwiftUI

public struct FocusTimerView: View {
    var timerVM: FocusTimerViewModel

    public var body: some View {
        VStack(spacing: 20) {
            // Mode selectors
            HStack(spacing: 12) {
                ForEach(FocusMode.allCases) { mode in
                    Button {
                        timerVM.switchMode(to: mode)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.iconName)
                            Text(mode.rawValue)
                        }
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            timerVM.currentMode == mode
                                ? mode.themeColor
                                : Color.primary.opacity(0.06)
                        )
                        .foregroundStyle(
                            timerVM.currentMode == mode
                                ? .white
                                : .primary
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)

            Spacer()

            // Circular progress ring
            CircularProgressView(
                progress: timerVM.progress,
                formattedTime: timerVM.formattedTimeRemaining,
                subtitle: timerVM.currentMode.rawValue,
                themeColor: timerVM.currentMode.themeColor
            )

            // Motivational message
            Text(timerVM.currentMode.motivationalMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Pomodoro cycle dots
            HStack(spacing: 8) {
                Text("Pomodoro Cycle:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(0..<4) { index in
                    Circle()
                        .fill(
                            (timerVM.completedWorkSessionsCount % 4) > index
                                ? timerVM.currentMode.themeColor
                                : Color.secondary.opacity(0.25)
                        )
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            // Controls
            HStack(spacing: 20) {
                Button {
                    timerVM.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .help("Reset current session")

                Button {
                    if timerVM.status == .running {
                        timerVM.pause()
                    } else {
                        timerVM.start()
                    }
                } label: {
                    Image(systemName: timerVM.status == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .frame(width: 68, height: 68)
                }
                .buttonStyle(.borderedProminent)
                .tint(timerVM.currentMode.themeColor)
                .clipShape(Circle())
                .shadow(color: timerVM.currentMode.themeColor.opacity(0.3), radius: 8, x: 0, y: 3)

                Button {
                    timerVM.skip()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .help("Skip to next cycle")
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .navigationTitle("Focus Timer")
    }
}
