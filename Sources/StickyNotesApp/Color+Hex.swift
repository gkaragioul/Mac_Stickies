import AppKit
import SwiftUI

private func rgb(from hex: String) -> (r: UInt64, g: UInt64, b: UInt64) {
    let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&int)

    switch cleaned.count {
    case 6:
        return ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
    default:
        return (47, 91, 138)
    }
}

extension Color {
    init(hex: String) {
        let values = rgb(from: hex)
        self.init(
            .sRGB,
            red: Double(values.r) / 255.0,
            green: Double(values.g) / 255.0,
            blue: Double(values.b) / 255.0,
            opacity: 1.0
        )
    }
}

extension NSColor {
    convenience init(hex: String) {
        let values = rgb(from: hex)
        let red = CGFloat(Double(values.r) / 255.0)
        let green = CGFloat(Double(values.g) / 255.0)
        let blue = CGFloat(Double(values.b) / 255.0)
        self.init(
            srgbRed: red,
            green: green,
            blue: blue,
            alpha: 1.0
        )
    }
}
