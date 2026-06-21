import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MenuBarView: View {
    @EnvironmentObject private var store: NoteStore
    @EnvironmentObject private var windowManager: NoteWindowManager
    @State private var didCheckStartupError = false
    @State private var isBusy = false

    var body: some View {
        Button {
            windowManager.createAndShowNote()
        } label: {
            Label("New Sticky Note", systemImage: "plus")
        }
        .keyboardShortcut("n", modifiers: [.command])
        .disabled(isBusy)

        if store.notes.isEmpty {
            Text("No notes")
        } else {
            Menu("Notes (\(store.notes.count))") {
                ForEach(store.notes) { note in
                    Menu(noteTitle(note)) {
                        Button(note.isHidden ? "Show" : "Hide") {
                            windowManager.toggleVisibility(noteID: note.id)
                        }
                        .disabled(isBusy)

                        Button(note.isPinned ? "Unpin" : "Pin Always On Top") {
                            windowManager.setPinned(noteID: note.id, pinned: !note.isPinned)
                        }
                        .disabled(isBusy)

                        Menu("Theme") {
                            ForEach(NotePalette.colors, id: \.hex) { option in
                                Button {
                                    windowManager.setColor(noteID: note.id, colorHex: option.hex)
                                } label: {
                                    Label(option.name, systemImage: note.colorHex == option.hex ? "checkmark" : "circle")
                                }
                                .disabled(isBusy)
                            }
                        }

                        Divider()

                        Button("Delete", role: .destructive) {
                            windowManager.delete(noteID: note.id)
                        }
                        .disabled(isBusy)
                    }
                }
            }

            Divider()

            Button("Show All") {
                for note in store.notes {
                    windowManager.show(noteID: note.id)
                }
            }
            .disabled(isBusy)

            Button("Hide All") {
                windowManager.hideAll()
            }
            .disabled(isBusy)
        }

        Divider()

        Button("Export Backup (JSON)...") {
            exportNotes()
        }
        .disabled(isBusy)

        Button("Import Backup (JSON)...") {
            importNotes()
        }
        .disabled(isBusy)

        Divider()

        Button("About Mac Stickies") {
            showAbout()
        }
        .disabled(isBusy)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
        .disabled(isBusy)
        .onAppear {
            guard !didCheckStartupError else { return }
            didCheckStartupError = true
            if let message = store.consumeStartupError() {
                showError(message)
            }
        }
    }

    private func noteTitle(_ note: Note) -> String {
        if note.title.isEmpty {
            return "Untitled"
        }
        return note.title
    }

    private func exportNotes() {
        guard !isBusy else { return }
        let panel = NSSavePanel()
        panel.title = "Export Sticky Notes"
        panel.nameFieldStringValue = "sticky-notes-backup.json"
        panel.allowedContentTypes = [UTType.json]
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            isBusy = true
            Task {
                defer { Task { @MainActor in self.isBusy = false } }
                do {
                    try await store.exportNotes(to: url)
                } catch {
                    await MainActor.run {
                        showError("Could not export notes: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func importNotes() {
        guard !isBusy else { return }
        let panel = NSOpenPanel()
        panel.title = "Import Sticky Notes"
        panel.allowedContentTypes = [UTType.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            isBusy = true
            Task {
                defer { Task { @MainActor in self.isBusy = false } }
                let oldVisibility = Dictionary(uniqueKeysWithValues: store.notes.map { ($0.id, $0.isHidden) })

                do {
                    try await store.importNotes(from: url)
                    windowManager.syncControllers()
                    windowManager.restoreVisibleNotesAtLaunch()
                } catch {
                    // Restore previous visibility state if import fails.
                    for note in store.notes {
                        if let wasHidden = oldVisibility[note.id] {
                            store.setHidden(id: note.id, hidden: wasHidden)
                        }
                    }
                    windowManager.syncControllers()
                    await MainActor.run {
                        showError("Could not import notes: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Sticky Notes Error"
        alert.informativeText = message
        alert.runModal()
    }

    private func showAbout() {
        let credits = """
        MIT License

        Mac Stickies is open source under the MIT License.

        Notes are stored locally in ~/Library/Application Support/StickyNotesApp/notes.json. The app has no telemetry, network sync, or third-party runtime dependencies.
        """

        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "Mac Stickies",
            .applicationVersion: "1.0",
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "Copyright (c) 2026 George Karagioules",
            .credits: NSAttributedString(string: credits)
        ])
    }
}
