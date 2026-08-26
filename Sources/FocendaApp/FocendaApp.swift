import SwiftUI
import AppKit
import FocendaCore

@main
struct FocendaApp: App {
    @State private var appState = AppState()
    @State private var timerVM = FocusTimerViewModel()
    @State private var taskVM = TaskListViewModel()
    @State private var habitVM = HabitViewModel()
    @State private var scratchpadVM = ScratchpadViewModel()

    var body: some Scene {
        WindowGroup {
            MainView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM,
                habitVM: habitVM,
                scratchpadVM: scratchpadVM
            )
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
            MenuBarCardView(timerVM: timerVM, appState: appState)
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
