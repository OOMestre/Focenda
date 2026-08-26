import SwiftUI
import AppKit

/// An interactive card view designed for MenuBarExtra popover style
public struct MenuBarCardView: View {
    public var timerVM: FocusTimerViewModel
    public var appState: AppState?

    public init(timerVM: FocusTimerViewModel, appState: AppState? = nil) {
        self.timerVM = timerVM
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header: Title & Active Mode Tag
            headerSection

            // Mode Selector Pills
            modeSelectorSection

            // Mini Circular Progress & Countdown
            miniProgressRingSection

            // Cycle progress dots
            cycleDotsSection

            // Control buttons
            controlsSection

            // Footer actions
            footerSection
        }
        .padding(18)
        .frame(width: 290)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundStyle(timerVM.currentMode.themeColor)
                    .font(.headline)
                Text("Focenda")
                    .font(.headline.bold())
            }

            Spacer()

            // Active Mode Tag
            HStack(spacing: 5) {
                Image(systemName: timerVM.currentMode.iconName)
                    .font(.caption2)
                Text(timerVM.currentMode.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(timerVM.currentMode.themeColor.opacity(0.15))
            .foregroundStyle(timerVM.currentMode.themeColor)
            .clipShape(Capsule())
        }
    }

    // MARK: - Mode Selectors
    private var modeSelectorSection: some View {
        HStack(spacing: 6) {
            ForEach(FocusMode.allCases) { mode in
                Button {
                    timerVM.switchMode(to: mode)
                } label: {
                    Text(shortModeTitle(for: mode))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(
                            timerVM.currentMode == mode
                                ? mode.themeColor
                                : Color.primary.opacity(0.06)
                        )
                        .foregroundStyle(
                            timerVM.currentMode == mode
                                ? .white
                                : .secondary
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func shortModeTitle(for mode: FocusMode) -> String {
        switch mode {
        case .work: return "Focus"
        case .shortBreak: return "Short"
        case .longBreak: return "Long"
        }
    }

    // MARK: - Mini Circular Progress Ring
    private var miniProgressRingSection: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    timerVM.currentMode.themeColor.opacity(0.12),
                    lineWidth: 10
                )

            // Dynamic progress ring
            Circle()
                .trim(from: 0.0, to: CGFloat(min(timerVM.progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            timerVM.currentMode.themeColor.opacity(0.7),
                            timerVM.currentMode.themeColor
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: timerVM.progress)

            // Center Countdown Readout
            VStack(spacing: 2) {
                Text(timerVM.formattedTimeRemaining)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(statusText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(timerVM.currentMode.themeColor)
            }
        }
        .frame(width: 140, height: 140)
        .padding(.vertical, 4)
    }

    private var statusText: String {
        switch timerVM.status {
        case .running:
            return "RUNNING"
        case .paused:
            return "PAUSED"
        case .idle:
            return "READY"
        }
    }

    // MARK: - Cycle Dots
    private var cycleDotsSection: some View {
        HStack(spacing: 6) {
            Text("Cycle:")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach(0..<4) { index in
                Circle()
                    .fill(
                        (timerVM.completedWorkSessionsCount % 4) > index
                            ? timerVM.currentMode.themeColor
                            : Color.secondary.opacity(0.25)
                    )
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Interactive Controls
    private var controlsSection: some View {
        HStack(spacing: 16) {
            // Reset Button
            Button {
                timerVM.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .help("Reset session")

            // Play / Pause Button
            Button {
                if timerVM.status == .running {
                    timerVM.pause()
                } else {
                    timerVM.start()
                }
            } label: {
                Image(systemName: timerVM.status == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(timerVM.currentMode.themeColor)
            .clipShape(Circle())
            .shadow(color: timerVM.currentMode.themeColor.opacity(0.35), radius: 6, x: 0, y: 2)
            .help(timerVM.status == .running ? "Pause timer" : "Start timer")

            // Skip Button
            Button {
                timerVM.skip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .help("Skip session")
        }
    }

    // MARK: - Footer Actions
    private var footerSection: some View {
        VStack(spacing: 10) {
            Divider()

            HStack {
                // Open Main App Button
                Button {
                    openMainApp()
                } label: {
                    Label("Open Main App", systemImage: "macwindow")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)

                Spacer()

                // Quit Button
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openMainApp() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
