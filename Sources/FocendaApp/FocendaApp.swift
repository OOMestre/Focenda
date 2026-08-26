import SwiftUI
import AppKit
import FocendaCore

@main
struct FocendaApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
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
        MenuBarExtra("Focenda", systemImage: "timer") {
            Button("Open Focenda") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            Divider()
            Button("Quit Focenda") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        #endif
    }
}
