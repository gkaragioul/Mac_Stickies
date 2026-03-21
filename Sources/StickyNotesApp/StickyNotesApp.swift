import SwiftUI

@main
struct StickyNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var store: NoteStore
    @StateObject private var windowManager: NoteWindowManager

    init() {
        let store = NoteStore()
        let manager = NoteWindowManager(store: store)
        _store = StateObject(wrappedValue: store)
        _windowManager = StateObject(wrappedValue: manager)
        manager.restoreVisibleNotesAtLaunch()
    }

    var body: some Scene {
        MenuBarExtra("Stickies", systemImage: "note.text") {
            MenuBarView()
                .environmentObject(store)
                .environmentObject(windowManager)
                .onAppear {
                    windowManager.syncControllers()
                }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
