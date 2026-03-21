import XCTest
@testable import StickyNotesApp

@MainActor
final class NoteStoreTests: XCTestCase {
    private func makeTempFileURL(name: String = UUID().uuidString) -> URL {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("StickyNotesAppTests", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(name)
    }

    func testBackwardCompatibleDecodeDefaultsMissingFields() throws {
        let json = """
        [{
          "id": "11111111-1111-1111-1111-111111111111",
          "title": "Old Note",
          "body": "Legacy",
          "colorHex": "#334A61",
          "frame": {"x": 10, "y": 20, "width": 300, "height": 200},
          "isHidden": false,
          "createdAt": 0,
          "updatedAt": 0
        }]
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode([Note].self, from: json)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].title, "Old Note")
        XCTAssertFalse(decoded[0].isPinned, "Missing isPinned should default to false")
    }

    func testImportDeduplicatesDuplicateIDs() async throws {
        let storeURL = makeTempFileURL(name: "store-\(UUID().uuidString).json")
        let importURL = makeTempFileURL(name: "import-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: importURL)
        }

        let duplicateID = "22222222-2222-2222-2222-222222222222"
        let json = """
        [
          {
            "id": "\(duplicateID)",
            "title": "A",
            "body": "1",
            "colorHex": "#2F5B8A",
            "frame": {"x": 1, "y": 1, "width": 300, "height": 200},
            "isHidden": false,
            "isPinned": false,
            "createdAt": 0,
            "updatedAt": 0
          },
          {
            "id": "\(duplicateID)",
            "title": "B",
            "body": "2",
            "colorHex": "#2E6A4A",
            "frame": {"x": 2, "y": 2, "width": 300, "height": 200},
            "isHidden": true,
            "isPinned": true,
            "createdAt": 0,
            "updatedAt": 0
          }
        ]
        """
        try json.data(using: .utf8)!.write(to: importURL)

        let store = NoteStore(saveURL: storeURL)
        try await store.importNotes(from: importURL)

        XCTAssertEqual(store.notes.count, 2)
        let uniqueIDs = Set(store.notes.map(\.id))
        XCTAssertEqual(uniqueIDs.count, 2, "Imported notes should have unique IDs")
    }

    func testExportImportRoundTrip() async throws {
        let storeURL1 = makeTempFileURL(name: "store1-\(UUID().uuidString).json")
        let storeURL2 = makeTempFileURL(name: "store2-\(UUID().uuidString).json")
        let backupURL = makeTempFileURL(name: "backup-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: storeURL1)
            try? FileManager.default.removeItem(at: storeURL2)
            try? FileManager.default.removeItem(at: backupURL)
        }

        let store1 = NoteStore(saveURL: storeURL1)
        let note = store1.createNote()
        store1.update(id: note.id, title: "RoundTrip", body: "Payload")
        store1.setPinned(id: note.id, pinned: true)
        store1.setColor(id: note.id, colorHex: "#8A3248")

        try await store1.exportNotes(to: backupURL)

        let store2 = NoteStore(saveURL: storeURL2)
        try await store2.importNotes(from: backupURL)

        XCTAssertTrue(store2.notes.contains(where: { $0.title == "RoundTrip" && $0.body == "Payload" }))
        XCTAssertTrue(store2.notes.contains(where: { $0.isPinned }))
    }

    func testDecodeFailureSurfacesStartupErrorInsteadOfSeeding() throws {
        let storeURL = makeTempFileURL(name: "broken-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        try Data("not-json".utf8).write(to: storeURL)

        let store = NoteStore(saveURL: storeURL)
        XCTAssertEqual(store.notes.count, 0, "Store should not seed over decode failure")
        XCTAssertNotNil(store.startupErrorMessage)
    }

    func testImportEmptyBackupKeepsEmptyState() async throws {
        let storeURL = makeTempFileURL(name: "store-empty-\(UUID().uuidString).json")
        let importURL = makeTempFileURL(name: "import-empty-\(UUID().uuidString).json")
        defer {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: importURL)
        }

        try Data("[]".utf8).write(to: importURL)

        let store = NoteStore(saveURL: storeURL)
        try await store.importNotes(from: importURL)

        XCTAssertEqual(store.notes.count, 0)
    }

    func testCorruptFileIsBackedUpBeforeFirstWrite() throws {
        let storeURL = makeTempFileURL(name: "corrupt-source-\(UUID().uuidString).json")
        let parentDir = storeURL.deletingLastPathComponent()
        defer {
            try? FileManager.default.removeItem(at: storeURL)
            let files = (try? FileManager.default.contentsOfDirectory(atPath: parentDir.path)) ?? []
            for f in files where f.contains("notes.corrupt.") {
                try? FileManager.default.removeItem(at: parentDir.appendingPathComponent(f))
            }
        }

        try Data("corrupt".utf8).write(to: storeURL)
        let store = NoteStore(saveURL: storeURL)
        XCTAssertNotNil(store.startupErrorMessage)

        _ = store.createNote()

        let files = try FileManager.default.contentsOfDirectory(atPath: parentDir.path)
        XCTAssertTrue(files.contains(where: { $0.hasPrefix("notes.corrupt.") && $0.hasSuffix(".json") }))
    }
}
