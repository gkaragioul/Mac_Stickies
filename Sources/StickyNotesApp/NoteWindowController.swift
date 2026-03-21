import AppKit
import SwiftUI

@MainActor
final class NoteWindowController: NSObject, NSWindowDelegate {
    let noteID: UUID
    private let store: NoteStore

    private(set) var window: NSWindow
    private var suppressFramePersistence = false

    init(noteID: UUID, store: NoteStore) {
        self.noteID = noteID
        self.store = store

        let contentView = StickyNoteView(noteID: noteID)
            .environmentObject(store)

        let note = store.note(with: noteID)
        let frame = note?.frame.cgRect ?? NoteFrame.defaultFrame.cgRect

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.backgroundColor = NSColor(hex: note?.colorHex ?? "#2F5B8A")
        window.isOpaque = true
        window.hasShadow = true
        window.contentView = NSHostingView(rootView: contentView)

        self.window = window
        super.init()
        window.delegate = self
        applyPinLevel(pinned: note?.isPinned ?? false)
    }

    func show(activate: Bool = true) {
        window.makeKeyAndOrderFront(nil)
        if activate {
            NSApp.activate(ignoringOtherApps: true)
        }
        store.setHidden(id: noteID, hidden: false)
    }

    func hide() {
        window.orderOut(nil)
        store.setHidden(id: noteID, hidden: true)
    }

    func closeAndDelete() {
        window.orderOut(nil)
        store.delete(id: noteID)
    }

    func setPinned(_ pinned: Bool) {
        applyPinLevel(pinned: pinned)
        store.setPinned(id: noteID, pinned: pinned)
    }

    func refreshFromStore() {
        guard let note = store.note(with: noteID) else { return }
        applyPinLevel(pinned: note.isPinned)
        window.backgroundColor = NSColor(hex: note.colorHex)

        if window.frame != note.frame.cgRect {
            suppressFramePersistence = true
            window.setFrame(note.frame.cgRect, display: true)
            suppressFramePersistence = false
        }

        if note.isHidden {
            window.orderOut(nil)
        } else if !window.isVisible {
            show(activate: false)
        }
    }

    func setColor(_ hex: String) {
        window.backgroundColor = NSColor(hex: hex)
        store.setColor(id: noteID, colorHex: hex)
    }

    func windowDidMove(_ notification: Notification) {
        persistFrame()
    }

    func windowDidResize(_ notification: Notification) {
        persistFrame()
    }

    func windowWillClose(_ notification: Notification) {
        store.setHidden(id: noteID, hidden: true)
    }

    private func persistFrame() {
        guard !suppressFramePersistence else { return }
        store.updateFrame(id: noteID, rect: window.frame)
    }

    private func applyPinLevel(pinned: Bool) {
        window.level = pinned ? .statusBar : .normal
    }
}
