import SwiftUI
import AppKit
import FocendaCore

@main
struct FocendaApp: App {
    @State private var appState = AppState()
    @State private var timerVM = FocusTimerViewModel()
    @State private var taskVM = TaskListViewModel()
    @State private var habitVM = HabitViewModel()

    var body: some Scene {
        WindowGroup {
            MainView(
                appState: appState,
                timerVM: timerVM,
                taskVM: taskVM,
                habitVM: habitVM
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
                Text(timerVM.status == .running ? timerVM.formattedTimeRemaining : "Focenda")
            }
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
