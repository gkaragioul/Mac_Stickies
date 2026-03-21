import AppKit
import Foundation
import SwiftUI

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [Note] = []
    @Published private(set) var startupErrorMessage: String?

    private let saveURL: URL
    private var pendingSaveTask: Task<Void, Never>?
    private var shouldBackupCorruptFileOnNextWrite = false

    private struct LoadResult {
        let notes: [Note]
        let hadDecodeError: Bool
    }

    init(saveURL: URL? = nil) {
        if let saveURL {
            let directory = saveURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            self.saveURL = saveURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let directory = appSupport.appendingPathComponent("StickyNotesApp", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            self.saveURL = directory.appendingPathComponent("notes.json")
        }

        let loadResult = loadNotes()
        self.notes = loadResult.notes
        if loadResult.hadDecodeError {
            startupErrorMessage = "Saved notes could not be read. Your data file may be corrupted."
            shouldBackupCorruptFileOnNextWrite = true
        }

        // Seed only on first run (missing file), not on decode failure.
        if notes.isEmpty && !loadResult.hadDecodeError && !FileManager.default.fileExists(atPath: self.saveURL.path) {
            let first = Note(title: "Quick Note", body: "Type anything here...")
            notes = [first]
            save(immediate: true)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        pendingSaveTask?.cancel()
    }

    @objc
    private func handleWillTerminate(_ notification: Notification) {
        flushPendingSaves()
    }

    func consumeStartupError() -> String? {
        defer { startupErrorMessage = nil }
        return startupErrorMessage
    }

    func note(with id: UUID) -> Note? {
        notes.first(where: { $0.id == id })
    }

    @discardableResult
    func createNote() -> Note {
        let offset = Double(notes.count % 8) * 26
        let defaultColor = NotePalette.colors[notes.count % NotePalette.colors.count].hex
        let note = Note(
            title: "Note \(notes.count + 1)",
            colorHex: defaultColor,
            frame: NoteFrame(x: 160 + offset, y: 440 - offset, width: 320, height: 280)
        )
        notes.append(note)
        save(immediate: true)
        return note
    }

    func update(id: UUID, title: String, body: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        if notes[index].title == title && notes[index].body == body { return }
        notes[index].title = title
        notes[index].body = body
        notes[index].updatedAt = Date()
        save(immediate: false)
    }

    func updateFrame(id: UUID, rect: CGRect) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        let nextFrame = NoteFrame(rect: rect)
        if notes[index].frame == nextFrame { return }
        notes[index].frame = nextFrame
        notes[index].updatedAt = Date()
        save(immediate: false)
    }

    func setHidden(id: UUID, hidden: Bool) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        if notes[index].isHidden == hidden { return }
        notes[index].isHidden = hidden
        notes[index].updatedAt = Date()
        save(immediate: false)
    }

    func setPinned(id: UUID, pinned: Bool) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        if notes[index].isPinned == pinned { return }
        notes[index].isPinned = pinned
        notes[index].updatedAt = Date()
        save(immediate: false)
    }

    func setColor(id: UUID, colorHex: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        if notes[index].colorHex == colorHex { return }
        notes[index].colorHex = colorHex
        notes[index].updatedAt = Date()
        save(immediate: false)
    }

    func delete(id: UUID) {
        notes.removeAll(where: { $0.id == id })
        save(immediate: true)
    }

    func exportNotes(to url: URL) async throws {
        flushPendingSaves()
        let snapshot = notes
        let data = try await Task.detached(priority: .userInitiated) {
            try JSONEncoder().encode(snapshot)
        }.value
        try await Task.detached(priority: .userInitiated) {
            try data.write(to: url, options: [.atomic])
        }.value
    }

    func importNotes(from url: URL) async throws {
        let data = try await Task.detached(priority: .userInitiated) {
            try Data(contentsOf: url)
        }.value
        let imported = try await Task.detached(priority: .userInitiated) {
            try JSONDecoder().decode([Note].self, from: data)
        }.value

        notes = normalizeImportedNotes(imported)
        save(immediate: true)
    }

    private func normalizeImportedNotes(_ imported: [Note]) -> [Note] {
        var seen = Set<UUID>()
        var result: [Note] = []
        result.reserveCapacity(imported.count)

        for note in imported {
            var sanitized = note
            if seen.contains(sanitized.id) {
                sanitized.id = UUID()
            }
            seen.insert(sanitized.id)
            result.append(sanitized)
        }

        return result
    }

    private func loadNotes() -> LoadResult {
        guard let data = try? Data(contentsOf: saveURL) else {
            return LoadResult(notes: [], hadDecodeError: false)
        }

        do {
            let decoded = try JSONDecoder().decode([Note].self, from: data)
            return LoadResult(notes: normalizeImportedNotes(decoded), hadDecodeError: false)
        } catch {
            return LoadResult(notes: [], hadDecodeError: true)
        }
    }

    private func save(immediate: Bool) {
        pendingSaveTask?.cancel()

        if immediate {
            persistNow()
            return
        }

        pendingSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            self?.persistNow()
        }
    }

    private func flushPendingSaves() {
        pendingSaveTask?.cancel()
        persistNow()
    }

    private func persistNow() {
        backupCorruptFileIfNeeded()
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: saveURL, options: [.atomic])
    }

    private func backupCorruptFileIfNeeded() {
        guard shouldBackupCorruptFileOnNextWrite else { return }
        shouldBackupCorruptFileOnNextWrite = false
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let stamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupURL = saveURL.deletingLastPathComponent()
            .appendingPathComponent("notes.corrupt.\(stamp).json")

        try? FileManager.default.copyItem(at: saveURL, to: backupURL)
    }
}
