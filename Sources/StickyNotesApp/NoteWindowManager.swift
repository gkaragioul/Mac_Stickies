import Foundation

@MainActor
final class NoteWindowManager: ObservableObject {
    private let store: NoteStore
    private var controllers: [UUID: NoteWindowController] = [:]

    init(store: NoteStore) {
        self.store = store
        ensureControllersForCurrentNotes()
    }

    func createAndShowNote() {
        let note = store.createNote()
        let controller = NoteWindowController(noteID: note.id, store: store)
        controllers[note.id] = controller
        controller.show()
    }

    func show(noteID: UUID) {
        ensureController(for: noteID)?.show()
    }

    func hide(noteID: UUID) {
        if let controller = controllers[noteID] {
            controller.hide()
        } else {
            store.setHidden(id: noteID, hidden: true)
        }
    }

    func toggleVisibility(noteID: UUID) {
        guard let note = store.note(with: noteID) else { return }
        note.isHidden ? show(noteID: noteID) : hide(noteID: noteID)
    }

    func setPinned(noteID: UUID, pinned: Bool) {
        ensureController(for: noteID)?.setPinned(pinned)
    }

    func setColor(noteID: UUID, colorHex: String) {
        ensureController(for: noteID)?.setColor(colorHex)
    }

    func delete(noteID: UUID) {
        if let controller = controllers[noteID] {
            controller.closeAndDelete()
            controllers[noteID] = nil
        } else {
            store.delete(id: noteID)
        }
    }

    func hideAll() {
        for note in store.notes {
            hide(noteID: note.id)
        }
    }

    func restoreVisibleNotesAtLaunch() {
        ensureControllersForCurrentNotes()
        for note in store.notes where !note.isHidden {
            controllers[note.id]?.show(activate: false)
        }
    }

    func syncControllers() {
        ensureControllersForCurrentNotes()

        let active = Set(store.notes.map(\.id))
        let staleIDs = controllers.keys.filter { !active.contains($0) }
        for id in staleIDs {
            controllers[id]?.window.orderOut(nil)
            controllers[id] = nil
        }

        for note in store.notes {
            controllers[note.id]?.refreshFromStore()
        }
    }

    private func ensureControllersForCurrentNotes() {
        for note in store.notes {
            _ = ensureController(for: note.id)
        }
    }

    @discardableResult
    private func ensureController(for noteID: UUID) -> NoteWindowController? {
        guard store.note(with: noteID) != nil else { return nil }
        if let existing = controllers[noteID] {
            existing.refreshFromStore()
            return existing
        }
        let controller = NoteWindowController(noteID: noteID, store: store)
        controllers[noteID] = controller
        return controller
    }
}
