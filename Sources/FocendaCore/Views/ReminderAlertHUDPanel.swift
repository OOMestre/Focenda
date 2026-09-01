import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Floating system-wide HUD panel that appears on top of all windows and spaces when a reminder fires
public final class ReminderAlertHUDPanel: NSPanel {
    public static let shared = ReminderAlertHUDPanel()

    private var autoDismissTimer: Timer?
    private var hostingView: NSHostingView<ReminderAlertHUDView>?
    public private(set) var isShowingAlert: Bool = false
    public private(set) var currentTitle: String = ""
    public private(set) var currentSubtitle: String = ""
    public private(set) var currentNotes: String = ""
    public private(set) var currentType: String = ""

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
        self.currentType = type
        self.isShowingAlert = true

        autoDismissTimer?.invalidate()
        autoDismissTimer = nil

        let view = ReminderAlertHUDView(
            title: title,
            subtitle: subtitle,
            notes: notes,
            type: type,
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

        if let hostingView {
            hostingView.rootView = view
        } else {
            let newHostingView = NSHostingView(rootView: view)
            self.hostingView = newHostingView
            self.contentView = newHostingView
        }

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
        guard isShowingAlert else { return }

        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        isShowingAlert = false
        self.orderOut(nil)

        NotificationCenter.default.post(
            name: NotificationManager.reminderAlertDismissedNotification,
            object: nil
        )
    }
}

/// SwiftUI View rendering the floating reminder HUD banner with rich visuals and actions
public struct ReminderAlertHUDView: View {
    public var title: String
    public var subtitle: String
    public var notes: String
    public var type: String
    public var timeoutSeconds: TimeInterval
    public var onSnooze: (() -> Void)?
    public var onComplete: (() -> Void)?
    public var onOpenApp: (() -> Void)?
    public var onClose: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered: Bool = false
    @State private var timeRemainingRatio: CGFloat = 1.0
    @State private var isCardPresented: Bool = false
    @State private var isCardPulseActive: Bool = false
    private let presentationID = UUID()

    public init(
        title: String,
        subtitle: String = "",
        notes: String = "",
        type: String = "reminder",
        timeoutSeconds: TimeInterval = 25.0,
        onSnooze: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil,
        onOpenApp: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.notes = notes
        self.type = type
        self.timeoutSeconds = timeoutSeconds
        self.onSnooze = onSnooze
        self.onComplete = onComplete
        self.onOpenApp = onOpenApp
        self.onClose = onClose
    }

    private var alertLabel: String {
        isPomodoro ? "Pomodoro" : "Reminder"
    }

    private var isPomodoro: Bool {
        type.lowercased() == "pomodoro"
    }

    private var openButtonTitle: String {
        type.lowercased() == "pomodoro" ? "Open Focus" : "Open"
    }

    private var openButtonHelp: String {
        type.lowercased() == "pomodoro" ? "Open Focenda Focus Timer" : "Open Focenda Reminders"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Bar
            HStack(spacing: 8) {
                // Animated notification badge
                HStack(spacing: 4) {
                    if isPomodoro {
                        PomodoroNotificationTimer()
                    } else {
                        ReminderNotificationBell()
                    }

                    Text(alertLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(AppTheme.accent.opacity(0.15))
                .clipShape(Capsule())

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

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
                .help("Dismiss reminder")
            }

            // Main Content: Reminder Title & Notes
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .opacity(0.25)

            // Action Buttons
            HStack(spacing: 8) {
                // Done / Complete Button
                Button {
                    onComplete?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                        Text("Done")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4.5)
                    .background(AppTheme.accent)
                    .foregroundStyle(AppTheme.textOnAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Mark reminder as done and dismiss")

                if onSnooze != nil {
                    // Snooze 5 Min Button
                    Button {
                        onSnooze?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 10, weight: .medium))
                            Text("Snooze 5m")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(AppTheme.cardBackgroundSubtle)
                        .foregroundStyle(AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(AppTheme.subtleBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Snooze reminder for 5 minutes")
                }

                Spacer()

                // Open App Button
                Button {
                    onOpenApp?()
                } label: {
                    HStack(spacing: 3) {
                        Text(openButtonTitle)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
                .help(openButtonHelp)
            }

            // Countdown Progress Bar
            if timeoutSeconds > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.cardBackgroundSubtle)
                            .frame(height: 2)

                        Capsule()
                            .fill(AppTheme.accent.opacity(0.8))
                            .frame(width: max(0, geo.size.width * timeRemainingRatio), height: 2)
                            .animation(.linear(duration: timeoutSeconds), value: timeRemainingRatio)
                    }
                }
                .frame(height: 2)
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
                    isCardPulseActive
                        ? AppTheme.accent.opacity(0.75)
                        : (isHovered ? AppTheme.border : AppTheme.subtleBorder),
                    lineWidth: isCardPulseActive ? 1.6 : 1.2
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 6)
        // Give the entire notification a brief entrance and attention pulse.
        .opacity(reduceMotion || isCardPresented ? 1 : 0)
        .scaleEffect(reduceMotion || isCardPresented ? 1 : 0.94, anchor: .topTrailing)
        .offset(y: reduceMotion || isCardPresented ? 0 : -8)
        .preferredColorScheme(AppTheme.current.colorScheme)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            presentCard()

            timeRemainingRatio = 1.0
            withAnimation(.linear(duration: timeoutSeconds)) {
                timeRemainingRatio = 0.0
            }
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            if shouldReduceMotion {
                isCardPresented = true
                isCardPulseActive = false
            } else if !isCardPresented {
                presentCard()
            }
        }
        .id(presentationID)
    }

    private func presentCard() {
        guard !reduceMotion else {
            isCardPresented = true
            isCardPulseActive = false
            return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            isCardPresented = true
        }

        // Schedule the pulse after the entrance so both animations remain visible.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            guard !reduceMotion else { return }

            withAnimation(.easeOut(duration: 0.18)) {
                isCardPulseActive = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                guard !reduceMotion else { return }

                withAnimation(.easeInOut(duration: 0.35)) {
                    isCardPulseActive = false
                }
            }
        }
    }
}

/// Small animated bell that makes an active reminder feel present without moving the card itself.
private struct ReminderNotificationBell: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "bell.badge.fill")
            .font(.system(size: 10, weight: .bold))
            .rotationEffect(.degrees(rotation), anchor: .bottom)
            .onAppear {
                startWiggleIfNeeded()
            }
            .onChange(of: reduceMotion) { _, shouldReduceMotion in
                if shouldReduceMotion {
                    rotation = 0
                } else {
                    startWiggleIfNeeded()
                }
            }
    }

    private func startWiggleIfNeeded() {
        guard !reduceMotion else { return }

        // Start from a slight tilt so the repeated animation rocks naturally from side to side.
        rotation = -7
        withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
            rotation = 7
        }
    }
}

/// Small animated timer that gives a completed Pomodoro the same visual presence as a reminder.
private struct PomodoroNotificationTimer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing: Bool = false

    var body: some View {
        Image(systemName: "timer")
            .font(.system(size: 10, weight: .bold))
            .scaleEffect(reduceMotion ? 1 : (isPulsing ? 1.12 : 0.92))
            .opacity(reduceMotion ? 1 : (isPulsing ? 1 : 0.78))
            .onAppear {
                startPulseIfNeeded()
            }
            .onChange(of: reduceMotion) { _, shouldReduceMotion in
                if shouldReduceMotion {
                    isPulsing = false
                } else {
                    startPulseIfNeeded()
                }
            }
    }

    private func startPulseIfNeeded() {
        guard !reduceMotion else {
            isPulsing = false
            return
        }

        isPulsing = false
        withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }
}
