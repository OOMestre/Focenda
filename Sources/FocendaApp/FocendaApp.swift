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
                bookmarkVM: bookmarkVM
            )
            .task {
                _ = try? await NotificationManager.shared.requestAuthorization()
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusSessionCompleted)) { _ in
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible }) ?? NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FocendaTaskReminderFired"))) { _ in
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
                    // Quick add shortcut
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }

        #if os(macOS)
        MenuBarExtra(isInserted: .constant(true)) {
            MenuBarCardView(
                timerVM: timerVM,
                taskVM: taskVM,
                scratchpadVM: scratchpadVM,
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
