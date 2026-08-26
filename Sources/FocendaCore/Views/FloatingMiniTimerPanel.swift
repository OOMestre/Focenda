import SwiftUI
import AppKit

/// A native draggable floating HUD panel that stays on top of all windows anywhere on the screen
public final class FloatingMiniTimerPanel: NSPanel {
    public static let shared = FloatingMiniTimerPanel()

    public init() {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 260, height: 110),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isReleasedWhenClosed = false
    }

    public func show(timerVM: FocusTimerViewModel) {
        let view = FloatingMiniTimerView(
            timerVM: timerVM,
            onClose: { [weak self] in
                self?.orderOut(nil)
            }
        )
        self.contentView = NSHostingView(rootView: view)
        if self.frame.origin.x == 100 && self.frame.origin.y == 100 {
            self.center()
        }
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
    }

    public func toggle(timerVM: FocusTimerViewModel) {
        if isVisible {
            orderOut(nil)
        } else {
            show(timerVM: timerVM)
        }
    }
}

/// SwiftUI View content embedded within the FloatingMiniTimerPanel
public struct FloatingMiniTimerView: View {
    public var timerVM: FocusTimerViewModel
    public var onClose: (() -> Void)?

    @State private var isHovered: Bool = false

    public init(
        timerVM: FocusTimerViewModel,
        onClose: (() -> Void)? = nil
    ) {
        self.timerVM = timerVM
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Header: Mode tag, drag affordance, and close button
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: timerVM.currentMode.iconName)
                        .font(.caption2.weight(.bold))
                    Text(timerVM.currentMode.rawValue)
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(timerVM.currentMode.themeColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(timerVM.currentMode.themeColor.opacity(0.15))
                .clipShape(Capsule())

                Spacer()

                // Drag indicator pill
                Capsule()
                    .fill(AppTheme.textTertiary.opacity(0.4))
                    .frame(width: 24, height: 3.5)
                    .help("Drag to reposition floating widget")

                Spacer()

                // Close Button
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Close floating mini timer")
            }

            // Main Row: Progress circle, countdown readout, and controls
            HStack(spacing: 12) {
                // Mini Circular Progress
                ZStack {
                    Circle()
                        .stroke(timerVM.currentMode.themeColor.opacity(0.18), lineWidth: 4.5)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(timerVM.progress, 1.0)))
                        .stroke(timerVM.currentMode.themeColor, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: timerVM.progress)

                    Image(systemName: timerVM.status == .running ? "flame.fill" : "timer")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(timerVM.currentMode.themeColor)
                }
                .frame(width: 32, height: 32)

                // Countdown Readout
                VStack(alignment: .leading, spacing: 1) {
                    Text(timerVM.formattedTimeRemaining)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(timerVM.status == .running ? "FOCUSING" : (timerVM.status == .paused ? "PAUSED" : "READY"))
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(timerVM.currentMode.themeColor)
                }

                Spacer()

                // Quick -5m / +5m adjustments
                HStack(spacing: 4) {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            timerVM.adjustTime(byMinutes: -5)
                        }
                    } label: {
                        Text("-5m")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(AppTheme.cardBackgroundSubtle)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Subtract 5 minutes")

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            timerVM.adjustTime(byMinutes: 5)
                        }
                    } label: {
                        Text("+5m")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(AppTheme.cardBackgroundSubtle)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Add 5 minutes")
                }

                // Play / Pause Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if timerVM.status == .running {
                            timerVM.pause()
                        } else {
                            timerVM.start()
                        }
                    }
                } label: {
                    Image(systemName: timerVM.status == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(timerVM.currentMode.themeColor)
                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                        )
                }
                .buttonStyle(.plain)
                .help(timerVM.status == .running ? "Pause timer" : "Start timer")

                // Skip Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        timerVM.skip()
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(AppTheme.cardBackgroundSubtle)
                        )
                }
                .buttonStyle(.plain)
                .help("Skip to next mode")
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    timerVM.currentMode.themeColor.opacity(isHovered ? 0.5 : 0.25),
                    lineWidth: 1.2
                )
        )
        .shadow(
            color: Color.black.opacity(0.20),
            radius: 12,
            x: 0,
            y: 6
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// Visual effect backdrop wrapper for NSVisualEffectView
public struct VisualEffectBackground: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode

    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
