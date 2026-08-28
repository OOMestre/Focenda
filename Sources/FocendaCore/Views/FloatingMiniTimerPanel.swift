import SwiftUI
import AppKit

/// A native draggable floating HUD panel that stays on top of all windows anywhere on the screen
public final class FloatingMiniTimerPanel: NSPanel {
    public static let shared = FloatingMiniTimerPanel()

    public init() {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 340, height: 380),
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

    public func show(
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel = TaskListViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel(),
        at point: NSPoint? = nil
    ) {
        let view = FloatingControlCenterView(
            timerVM: timerVM,
            taskVM: taskVM,
            scratchpadVM: scratchpadVM,
            onClose: { [weak self] in
                self?.orderOut(nil)
            }
        )
        self.contentView = NSHostingView(rootView: view)

        if let pt = point {
            let width: CGFloat = 340
            let height: CGFloat = 380
            let origin = NSPoint(
                x: max(10, min(NSScreen.main?.frame.maxX ?? 1400 - width - 10, pt.x - width / 2)),
                y: max(10, min(NSScreen.main?.frame.maxY ?? 900 - height - 30, pt.y - height))
            )
            self.setFrameOrigin(origin)
        } else if self.frame.origin.x == 100 && self.frame.origin.y == 100 {
            self.center()
        }

        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
    }

    public func toggle(
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel = TaskListViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel()
    ) {
        if isVisible {
            orderOut(nil)
        } else {
            show(timerVM: timerVM, taskVM: taskVM, scratchpadVM: scratchpadVM)
        }
    }
}

public typealias FloatingMiniTimerView = FloatingControlCenterView

/// Floating Draggable Control Center / Mini Timer View that floats anywhere on the screen
public struct FloatingControlCenterView: View {
    public var timerVM: FocusTimerViewModel
    public var taskVM: TaskListViewModel
    public var scratchpadVM: ScratchpadViewModel
    public var onClose: (() -> Void)?

    @State private var isCompact: Bool = false
    @State private var isHovered: Bool = false
    @State private var selectedSection: MenuBarSection = .focus
    @State private var quickNoteText: String = ""
    @State private var newTaskTitle: String = ""
    @State private var newTaskPriority: TaskPriority = .medium

    public init(
        timerVM: FocusTimerViewModel,
        taskVM: TaskListViewModel = TaskListViewModel(),
        scratchpadVM: ScratchpadViewModel = ScratchpadViewModel(),
        onClose: (() -> Void)? = nil
    ) {
        self.timerVM = timerVM
        self.taskVM = taskVM
        self.scratchpadVM = scratchpadVM
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Drag Header
            HStack(spacing: 8) {
                // Drag handle pill
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 9))
                    Text("Drag Anywhere")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.accent.opacity(0.15))
                .clipShape(Capsule())

                Spacer()

                // Compact Toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isCompact.toggle()
                    }
                } label: {
                    Image(systemName: isCompact ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(5)
                        .background(AppTheme.cardBackgroundSubtle)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isCompact ? "Expand to Full Control Center" : "Collapse to Compact Mini Timer")

                // Close Button
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Close floating panel")
            }

            if isCompact {
                compactContent
            } else {
                expandedContent
            }
        }
        .padding(14)
        .frame(width: isCompact ? 280 : 340)
        .background(
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isHovered ? AppTheme.border : AppTheme.subtleBorder,
                    lineWidth: 1.2
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
        .preferredColorScheme(AppTheme.current.colorScheme)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            quickNoteText = scratchpadVM.currentContent
        }
    }

    // MARK: - Compact Content
    private var compactContent: some View {
        HStack(spacing: 12) {
            // Mini Circular Progress
            ZStack {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.18), lineWidth: 4.5)
                Circle()
                    .trim(from: 0, to: CGFloat(min(timerVM.progress, 1.0)))
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: timerVM.progress)

                Image(systemName: timerVM.status == .running ? "flame.fill" : "timer")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
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
                    .foregroundStyle(AppTheme.accent)
            }

            Spacer()

            // Controls
            HStack(spacing: 6) {
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
                        .foregroundStyle(AppTheme.textOnAccent)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(AppTheme.accent)
                        )
                }
                .buttonStyle(.plain)

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
            }
        }
    }

    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(spacing: 12) {
            // Segmented Section Switcher
            HStack(spacing: 4) {
                ForEach(MenuBarSection.allCases) { section in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) {
                            selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: section.iconName)
                                .font(.system(size: 10, weight: .bold))
                            Text(section.rawValue)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedSection == section
                                ? AppTheme.accent
                                : AppTheme.cardBackgroundSubtle
                        )
                        .foregroundStyle(
                            selectedSection == section
                                ? AppTheme.textOnAccent
                                : AppTheme.textSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Active Tab Content
            switch selectedSection {
            case .focus:
                focusTab
            case .quickNote:
                quickNoteTab
            case .quickTask:
                quickTaskTab
            case .reminders:
                remindersTab
            case .quickLinks:
                quickLinksTab
            }
        }
    }

    // MARK: - Focus Tab
    private var focusTab: some View {
        VStack(spacing: 10) {
            // Mode pills
            HStack(spacing: 6) {
                ForEach(FocusMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            timerVM.switchMode(to: mode)
                        }
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .background(timerVM.currentMode == mode ? AppTheme.accent : AppTheme.cardBackgroundSubtle)
                            .foregroundStyle(timerVM.currentMode == mode ? AppTheme.textOnAccent : AppTheme.textSecondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Countdown Readout & Ring
            ZStack {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(min(timerVM.progress, 1.0)))
                    .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: timerVM.progress)

                VStack(spacing: 2) {
                    Text(timerVM.formattedTimeRemaining)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(timerVM.status == .running ? "RUNNING" : (timerVM.status == .paused ? "PAUSED" : "READY"))
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .frame(width: 110, height: 110)
            .padding(.vertical, 2)

            // Controls
            HStack(spacing: 14) {
                Button {
                    timerVM.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppTheme.cardBackgroundSubtle))
                }
                .buttonStyle(.plain)

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
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.textOnAccent)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AppTheme.accent))
                }
                .buttonStyle(.plain)

                Button {
                    timerVM.skip()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppTheme.cardBackgroundSubtle))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Quick Note Tab
    private var quickNoteTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $quickNoteText)
                .font(.callout)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(AppTheme.cardBackgroundSubtle.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(height: 100)
                .onChange(of: quickNoteText) { _, newText in
                    scratchpadVM.updateContent(newText)
                }

            HStack {
                Text("\(quickNoteText.count) chars")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
                Spacer()
                Button("Copy") {
                    scratchpadVM.copyCurrentNoteToClipboard()
                }
                .font(.caption2)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Quick Task Tab
    private var quickTaskTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Add task...", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .padding(6)
                    .background(AppTheme.cardBackgroundSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onSubmit {
                        if !newTaskTitle.isEmpty {
                            taskVM.addTask(title: newTaskTitle, priority: newTaskPriority)
                            newTaskTitle = ""
                        }
                    }

                Button {
                    if !newTaskTitle.isEmpty {
                        taskVM.addTask(title: newTaskTitle, priority: newTaskPriority)
                        newTaskTitle = ""
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .padding(6)
                        .background(AppTheme.accent)
                        .foregroundStyle(AppTheme.textOnAccent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            ForEach(Array(taskVM.tasks.filter { !$0.isCompleted }.prefix(3))) { task in
                HStack {
                    Button {
                        taskVM.toggleTaskCompletion(task)
                    } label: {
                        Image(systemName: "circle")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .buttonStyle(.plain)

                    Text(task.title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(4)
            }
        }
    }

    // MARK: - Reminders Tab
    private var remindersTab: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Active Reminders")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSecondary)

            let activeReminders = RecurringReminderViewModel().activeReminders
            if activeReminders.isEmpty {
                Text("No active reminders scheduled.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            } else {
                ForEach(activeReminders.prefix(3)) { reminder in
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(AppTheme.accent)
                        Text(reminder.title)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(reminder.formattedTime)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(4)
                }
            }
        }
    }

    // MARK: - Quick Links Tab
    private var quickLinksTab: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(QuickLink.defaultLinks) { link in
                Button {
                    if let url = link.url {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: link.iconName)
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.accent)
                        Text(link.title)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(6)
                    .background(AppTheme.cardBackgroundSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
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
