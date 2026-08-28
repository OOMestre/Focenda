import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Floating system-wide HUD panel that appears on top of all windows and spaces when a reminder fires
public final class ReminderAlertHUDPanel: NSPanel {
    public static let shared = ReminderAlertHUDPanel()

    private var autoDismissTimer: Timer?
    public private(set) var isShowingAlert: Bool = false
    public private(set) var currentTitle: String = ""
    public private(set) var currentSubtitle: String = ""
    public private(set) var currentNotes: String = ""

    public init() {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 380, height: 165),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isReleasedWhenClosed = false
    }

    /// Presents the floating reminder HUD banner on the active screen with smooth entrance
    public func show(
        title: String,
        subtitle: String = "",
        notes: String = "",
        type: String = "recurring",
        timeoutSeconds: TimeInterval = 25.0,
        onSnooze: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil,
        onOpenApp: (() -> Void)? = nil
    ) {
        self.currentTitle = title
        self.currentSubtitle = subtitle
        self.currentNotes = notes
        self.isShowingAlert = true

        autoDismissTimer?.invalidate()
        autoDismissTimer = nil

        let view = ReminderAlertHUDView(
            title: title,
            subtitle: subtitle,
            notes: notes,
            timeoutSeconds: timeoutSeconds,
            onSnooze: { [weak self] in
                self?.dismiss()
                onSnooze?()
            },
            onComplete: { [weak self] in
                self?.dismiss()
                onComplete?()
            },
            onOpenApp: { [weak self] in
                self?.dismiss()
                onOpenApp?()
            },
            onClose: { [weak self] in
                self?.dismiss()
            }
        )

        self.contentView = NSHostingView(rootView: view)

        // Calculate top-right position on the primary screen below the menu bar
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panelWidth: CGFloat = 380
        let panelHeight: CGFloat = notes.isEmpty ? 150 : 175

        self.setContentSize(NSSize(width: panelWidth, height: panelHeight))

        let xPos = screenFrame.maxX - panelWidth - 24
        let yPos = screenFrame.maxY - panelHeight - 16
        self.setFrameOrigin(NSPoint(x: xPos, y: yPos))

        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()

        if timeoutSeconds > 0 {
            let timer = Timer(timeInterval: timeoutSeconds, repeats: false) { [weak self] _ in
                self?.dismiss()
            }
            RunLoop.main.add(timer, forMode: .common)
            self.autoDismissTimer = timer
        }
    }

    /// Dismisses the floating HUD panel
    public func dismiss() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        isShowingAlert = false
        self.orderOut(nil)
    }
}

/// SwiftUI View rendering the floating reminder HUD banner with rich visuals and actions
public struct ReminderAlertHUDView: View {
    public var title: String
    public var subtitle: String
    public var notes: String
    public var timeoutSeconds: TimeInterval
    public var onSnooze: (() -> Void)?
    public var onComplete: (() -> Void)?
    public var onOpenApp: (() -> Void)?
    public var onClose: (() -> Void)?

    @State private var isHovered: Bool = false
    @State private var isPulsing: Bool = false
    @State private var timeRemainingRatio: CGFloat = 1.0

    public init(
        title: String,
        subtitle: String = "",
        notes: String = "",
        timeoutSeconds: TimeInterval = 25.0,
        onSnooze: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil,
        onOpenApp: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.notes = notes
        self.timeoutSeconds = timeoutSeconds
        self.onSnooze = onSnooze
        self.onComplete = onComplete
        self.onOpenApp = onOpenApp
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Bar
            HStack(spacing: 8) {
                // Pulsing Alert Badge
                HStack(spacing: 5) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 11, weight: .bold))
                        .scaleEffect(isPulsing ? 1.15 : 0.95)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)

                    Text("Opa, deu a hora!")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.red.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Close Button
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Fechar aviso")
            }

            // Main Content: Reminder Title & Notes
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .opacity(0.3)

            // Action Buttons
            HStack(spacing: 8) {
                // Done / Complete Button
                Button {
                    onComplete?()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Entendido")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.85))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)

                // Snooze 5 Min Button
                Button {
                    onSnooze?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Adiar 5m")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppTheme.cardBackgroundSubtle)
                    .foregroundStyle(AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Adiar lembrete por 5 minutos")

                Spacer()

                // Open App Button
                Button {
                    onOpenApp?()
                } label: {
                    HStack(spacing: 4) {
                        Text("Abrir")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
                .help("Abrir Focenda na aba de Lembretes")
            }

            // Countdown Progress Bar
            if timeoutSeconds > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.cardBackgroundSubtle)
                            .frame(height: 2.5)

                        Capsule()
                            .fill(LinearGradient(colors: [Color.orange, Color.green], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, geo.size.width * timeRemainingRatio), height: 2.5)
                            .animation(.linear(duration: timeoutSeconds), value: timeRemainingRatio)
                    }
                }
                .frame(height: 2.5)
            }
        }
        .padding(12)
        .background(
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.orange.opacity(isHovered ? 0.8 : 0.4), Color.accentColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            isPulsing = true
            timeRemainingRatio = 1.0
            withAnimation(.linear(duration: timeoutSeconds)) {
                timeRemainingRatio = 0.0
            }
        }
    }
}
