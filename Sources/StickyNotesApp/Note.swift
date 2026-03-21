import Foundation
import CoreGraphics

struct Note: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var body: String
    var colorHex: String
    var frame: NoteFrame
    var isHidden: Bool
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case colorHex
        case frame
        case isHidden
        case isPinned
        case createdAt
        case updatedAt
    }

    init(
        id: UUID = UUID(),
        title: String = "New Note",
        body: String = "",
        colorHex: String = "#2F5B8A",
        frame: NoteFrame = .defaultFrame,
        isHidden: Bool = false,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.colorHex = colorHex
        self.frame = frame
        self.isHidden = isHidden
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "New Note"
        self.body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        self.colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#2F5B8A"
        self.frame = try container.decodeIfPresent(NoteFrame.self, forKey: .frame) ?? .defaultFrame
        self.isHidden = try container.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
        self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct NoteFrame: Codable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let defaultFrame = NoteFrame(x: 160, y: 400, width: 310, height: 280)

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    init(rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

enum NotePalette {
    static let colors: [(name: String, hex: String)] = [
        ("Ocean", "#2F5B8A"),
        ("Forest", "#2E6A4A"),
        ("Plum", "#5B3E7A"),
        ("Cherry", "#8A3248"),
        ("Slate", "#334A61"),
        ("Amber", "#8A5A2E")
    ]
}
