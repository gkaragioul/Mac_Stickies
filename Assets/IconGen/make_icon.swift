import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let bg = NSGradient(colors: [
    NSColor(calibratedRed: 0.11, green: 0.20, blue: 0.36, alpha: 1.0),
    NSColor(calibratedRed: 0.18, green: 0.34, blue: 0.55, alpha: 1.0)
])!
bg.draw(in: NSRect(origin: .zero, size: size), angle: 90)

let inset: CGFloat = 130
let noteRect = NSRect(x: inset, y: inset + 20, width: size.width - inset * 2, height: size.height - inset * 2 - 40)
let notePath = NSBezierPath(roundedRect: noteRect, xRadius: 88, yRadius: 88)

NSColor(calibratedRed: 0.19, green: 0.43, blue: 0.67, alpha: 1.0).setFill()
notePath.fill()

NSColor(calibratedWhite: 1.0, alpha: 0.16).setStroke()
notePath.lineWidth = 10
notePath.stroke()

let foldSize: CGFloat = 170
let foldPath = NSBezierPath()
foldPath.move(to: NSPoint(x: noteRect.maxX - foldSize, y: noteRect.maxY))
foldPath.line(to: NSPoint(x: noteRect.maxX, y: noteRect.maxY - foldSize))
foldPath.line(to: NSPoint(x: noteRect.maxX, y: noteRect.maxY))
foldPath.close()
NSColor(calibratedWhite: 1.0, alpha: 0.22).setFill()
foldPath.fill()

let pinCenter = NSPoint(x: noteRect.maxX - 105, y: noteRect.maxY - 105)
let pin = NSBezierPath(ovalIn: NSRect(x: pinCenter.x - 24, y: pinCenter.y - 24, width: 48, height: 48))
NSColor(calibratedWhite: 0.95, alpha: 0.95).setFill()
pin.fill()

let lineColor = NSColor(calibratedWhite: 1.0, alpha: 0.70)
lineColor.setStroke()
for i in 0..<4 {
    let y = noteRect.maxY - 210 - CGFloat(i) * 95
    let p = NSBezierPath()
    p.move(to: NSPoint(x: noteRect.minX + 95, y: y))
    p.line(to: NSPoint(x: noteRect.maxX - 130, y: y))
    p.lineWidth = 22
    p.lineCapStyle = .round
    p.stroke()
}

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else {
    fputs("Failed to render icon\n", stderr)
    exit(1)
}

let outURL = URL(fileURLWithPath: "/Volumes/Files/DevWork/OSXNotes/StickyNotesApp/Assets/IconGen/AppIcon1024.png")
try png.write(to: outURL)
print("Wrote \(outURL.path)")
