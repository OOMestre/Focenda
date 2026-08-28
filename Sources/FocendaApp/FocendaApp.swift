import SwiftUI
import AppKit
import FocendaCore

@main
struct FocendaApp: App {
    private let secureStore: SecureStore
    @State private var appState: AppState
    @State private var timerVM: FocusTimerViewModel
    @State private var taskVM: TaskListViewModel
    @State private var scratchpadVM: ScratchpadViewModel
    @State private var bookmarkVM: BookmarkViewModel
    @State private var recurringReminderVM: RecurringReminderViewModel
    @State private var productivityProfileVM: ProductivityProfileViewModel
    @State private var updateManager: AppUpdateManager
    @State private var isReminderAlertActive: Bool = false

    init() {
        let secureStore = SecureStore.shared
        self.secureStore = secureStore
        _appState = State(initialValue: AppState(secureStore: secureStore))
        _timerVM = State(initialValue: FocusTimerViewModel())
        _taskVM = State(initialValue: TaskListViewModel(secureStore: secureStore))
        _scratchpadVM = State(initialValue: ScratchpadViewModel(secureStore: secureStore))
        _bookmarkVM = State(initialValue: BookmarkViewModel(secureStore: secureStore))
        _recurringReminderVM = State(initialValue: RecurringReminderViewModel(secureStore: secureStore))
        _productivityProfileVM = State(initialValue: ProductivityProfileViewModel(secureStore: secureStore))
        _updateManager = State(initialValue: AppUpdateManager(secureStore: secureStore))

        OwlBrandAssets.configureDockIcon()
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            MainView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM,
                scratchpadVM: scratchpadVM,
                bookmarkVM: bookmarkVM,
                recurringReminderVM: recurringReminderVM,
                productivityProfileVM: productivityProfileVM,
                updateManager: updateManager
            )
            .task {
                _ = try? await NotificationManager.shared.requestAuthorization()
                GlobalShortcutManager.shared.setup(timerVM: timerVM, appState: appState)
                updateManager.startAutomaticChecks(enabled: appState.automaticUpdateChecksEnabled)
            }
            .onChange(of: appState.automaticUpdateChecksEnabled) { _, isEnabled in
                updateManager.setAutomaticChecksEnabled(isEnabled)
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusShortcutTriggered)) { _ in
                // Visual feedback or state synchronization handled reactively
            }
            .onReceive(NotificationCenter.default.publisher(for: .productivityProfileShortcutTriggered)) { notification in
                guard let profileID = notification.userInfo?["profileID"] as? UUID else { return }
                productivityProfileVM.activateProfile(id: profileID)
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.openFocusTabNotification)) { _ in
                appState.selectedTab = .timer
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.taskReminderFiredNotification)) { _ in
                isReminderAlertActive = true
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.recurringReminderFiredNotification)) { _ in
                isReminderAlertActive = true
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.openRemindersTabNotification)) { _ in
                appState.selectedTab = .reminders
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.reminderAlertBannerNotification)) { _ in
                isReminderAlertActive = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.reminderAlertDismissedNotification)) { _ in
                isReminderAlertActive = false
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.openSettingsNotification)) { _ in
                updateManager.checkForUpdates()
                appState.selectedTab = .settings
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentMinSize)
        .defaultSize(width: MainView.defaultWindowWidth, height: MainView.defaultWindowHeight)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    appState.selectedTab = .kanban
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandMenu("Focus") {
                Button(timerVM.status == .running ? "Pause Focus" : "Start Focus") {
                    timerVM.toggleStartPause()
                }
                .keyboardShortcut("f", modifiers: [.option, .command])

                Divider()

                Button("Deep Focus Mode") {
                    timerVM.startMode(.work)
                }
                .keyboardShortcut("1", modifiers: [.option, .command])

                Button("Short Break") {
                    timerVM.startMode(.shortBreak)
                }
                .keyboardShortcut("2", modifiers: [.option, .command])

                Button("Long Break") {
                    timerVM.startMode(.longBreak)
                }
                .keyboardShortcut("3", modifiers: [.option, .command])

                Divider()

                Button("Reset Timer") {
                    timerVM.reset()
                }
                .keyboardShortcut("r", modifiers: [.option, .command])

                Button("Skip Session") {
                    timerVM.skip()
                }
                .keyboardShortcut("s", modifiers: [.option, .command])
            }
        }

        #if os(macOS)
        MenuBarExtra(isInserted: .constant(true)) {
            MenuBarCardView(
                timerVM: timerVM,
                taskVM: taskVM,
                scratchpadVM: scratchpadVM,
                recurringReminderVM: recurringReminderVM,
                appState: appState,
                secureStore: secureStore
            )
        } label: {
            HStack(spacing: 4) {
                if isReminderAlertActive {
                    Image(systemName: "bell.badge.fill")
                        .symbolRenderingMode(.multicolor)
                } else {
                    OwlMenuBarIconView()
                }
                if timerVM.status == .running {
                    Text(timerVM.formattedTimeRemaining)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
