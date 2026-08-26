import SwiftUI
import AppKit

/// An interactive card view designed for MenuBarExtra popover style
public struct MenuBarCardView: View {
    public var timerVM: FocusTimerViewModel
    public var appState: AppState?

    @State private var isPresented: Bool = false
    @State private var isHovered: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero

    public init(
        timerVM: FocusTimerViewModel,
        appState: AppState? = nil
    ) {
        self.timerVM = timerVM
        self.appState = appState
    }

    public var body: some View {
        cardBody
            .padding(18)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        timerVM.currentMode.themeColor.opacity(isHovered ? 0.45 : 0.20),
                        lineWidth: 1.0
                    )
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.12 : 0.05),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 3 : 1
            )
            .offset(dragOffset)
            .scaleEffect(y: isPresented ? 1.0 : 0.88, anchor: .top)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isHovered)
            .animation(.spring(response: 0.32, dampingFraction: 0.76), value: isPresented)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: dragOffset)
            .gesture(dragGesture)
            .onHover { hovering in
                isHovered = hovering
            }
            .onAppear {
                isPresented = false
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                        isPresented = true
                    }
                }
            }
            .onDisappear {
                isPresented = false
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = CGSize(
                    width: accumulatedOffset.width + value.translation.width,
                    height: accumulatedOffset.height + value.translation.height
                )
            }
            .onEnded { value in
                dragOffset = CGSize(
                    width: accumulatedOffset.width + value.translation.width,
                    height: accumulatedOffset.height + value.translation.height
                )
                accumulatedOffset = dragOffset
            }
    }

    private var cardBody: some View {
        VStack(spacing: 14) {
            // Drag handle pill at the top of the card
            dragHandleSection

            // Header: Title & Active Mode Tag
            headerSection

            // Mode Selector Pills
            modeSelectorSection

            // Mini Circular Progress & Countdown
            miniProgressRingSection

            // Quick Preset Buttons (-5m, +5m)
            quickPresetSection

            // Cycle progress dots
            cycleDotsSection

            // Control buttons
            controlsSection

            // Footer actions
            footerSection
        }
    }

    // MARK: - Drag Handle
    private var dragHandleSection: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .help("Drag to move")
            Spacer()
        }
        .padding(.top, -4)
        .padding(.bottom, 2)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            snapToDefaultPosition()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundStyle(timerVM.currentMode.themeColor)
                    .font(.headline)
                Text("Focenda")
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            // Active Mode Tag
            HStack(spacing: 4) {
                Image(systemName: timerVM.currentMode.iconName)
                    .font(.caption2)
                Text(timerVM.currentMode.rawValue)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(timerVM.currentMode.themeColor.opacity(0.12))
            .foregroundStyle(timerVM.currentMode.themeColor)
            .clipShape(Capsule())
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            snapToDefaultPosition()
        }
    }

    private func snapToDefaultPosition() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            dragOffset = .zero
            accumulatedOffset = .zero
        }
    }

    // MARK: - Mode Selectors
    private var modeSelectorSection: some View {
        HStack(spacing: 6) {
            ForEach(FocusMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        timerVM.switchMode(to: mode)
                    }
                } label: {
                    Text(shortModeTitle(for: mode))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(
                            timerVM.currentMode == mode
                                ? mode.themeColor
                                : AppTheme.cardBackgroundSubtle
                        )
                        .foregroundStyle(
                            timerVM.currentMode == mode
                                ? .white
                                : AppTheme.textSecondary
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(SpringScaleButtonStyle())
            }
        }
    }

    public func shortModeTitle(for mode: FocusMode) -> String {
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
                    lineWidth: 9
                )

            // Dynamic progress ring
            Circle()
                .trim(from: 0.0, to: CGFloat(min(timerVM.progress, 1.0)))
                .stroke(
                    timerVM.currentMode.themeColor,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: timerVM.progress)

            // Center Countdown Readout
            VStack(spacing: 2) {
                Text(timerVM.formattedTimeRemaining)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.textPrimary)

                Text(statusText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(timerVM.currentMode.themeColor)
            }
        }
        .frame(width: 130, height: 130)
        .padding(.vertical, 2)
    }

    public var statusText: String {
        switch timerVM.status {
        case .running:
            return "RUNNING"
        case .paused:
            return "PAUSED"
        case .idle:
            return "READY"
        }
    }

    // MARK: - Quick Presets
    private var quickPresetSection: some View {
        HStack(spacing: 12) {
            // -5m Preset Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    timerVM.adjustTime(byMinutes: -5)
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                    Text("5m")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppTheme.cardBackgroundSubtle)
                )
                .overlay(
                    Capsule()
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
                .foregroundStyle(AppTheme.textSecondary)
            }
            .buttonStyle(SpringScaleButtonStyle())
            .help("Subtract 5 minutes")

            Spacer()

            // Mode Label
            Text(timerVM.currentMode.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            // +5m Preset Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    timerVM.adjustTime(byMinutes: 5)
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                    Text("5m")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppTheme.cardBackgroundSubtle)
                )
                .overlay(
                    Capsule()
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
                .foregroundStyle(AppTheme.textSecondary)
            }
            .buttonStyle(SpringScaleButtonStyle())
            .help("Add 5 minutes")
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Cycle Dots
    private var cycleDotsSection: some View {
        HStack(spacing: 6) {
            Text("Cycle:")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)

            ForEach(0..<4) { index in
                Circle()
                    .fill(
                        (timerVM.completedWorkSessionsCount % 4) > index
                            ? timerVM.currentMode.themeColor
                            : AppTheme.border
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .help("Reset session")

            // Play / Pause Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    if timerVM.status == .running {
                        timerVM.pause()
                    } else {
                        timerVM.start()
                    }
                }
            } label: {
                Image(systemName: timerVM.status == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(timerVM.currentMode.themeColor)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            .help(timerVM.status == .running ? "Pause timer" : "Start timer")

            // Skip Button
            Button {
                timerVM.skip()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
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
                .foregroundStyle(AppTheme.accent)

                Spacer()

                // Quit Button
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
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

// MARK: - Spring Scale Button Style

private struct SpringScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
