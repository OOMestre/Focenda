import SwiftUI
import AppKit
import FocendaCore

@main
struct FocendaApp: App {
    @State private var appState = AppState()
    @State private var timerVM = FocusTimerViewModel()
    @State private var taskVM = TaskListViewModel()
    @State private var scratchpadVM = ScratchpadViewModel()
    @State private var bookmarkVM = BookmarkViewModel()
    @State private var recurringReminderVM = RecurringReminderViewModel()

    init() {
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
                recurringReminderVM: recurringReminderVM
            )
            .task {
                _ = try? await NotificationManager.shared.requestAuthorization()
                GlobalShortcutManager.shared.setup(timerVM: timerVM, appState: appState)
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusShortcutTriggered)) { _ in
                // Visual feedback or state synchronization handled reactively
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusSessionCompleted)) { _ in
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.taskReminderFiredNotification)) { _ in
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NotificationManager.recurringReminderFiredNotification)) { _ in
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
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
                appState: appState
            )
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
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
