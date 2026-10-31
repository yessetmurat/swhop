// Panel text helpers: measuring, drawing, and the stderr logger.

import AppKit

func logErr(_ s: String) {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
}

/// First font found by PostScript name, else the system font.
func panelFont(_ names: [String], _ size: CGFloat) -> NSFont {
    for n in names {
        if let f = NSFont(name: n, size: size) { return f }
    }
    return NSFont.systemFont(ofSize: size)
}

func white(_ a: CGFloat) -> NSColor {
    NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: a)
}

/// The size the text occupies at that font; the color does not affect it.
func textSize(_ s: String, _ f: NSFont) -> NSSize {
    (s as NSString).size(withAttributes: [.font: f])
}

/// Text at the left edge of the rect, centered vertically.
func drawTextLeft(_ s: String, _ f: NSFont, _ color: NSColor, _ r: NSRect) {
    let size = textSize(s, f)
    let p = NSPoint(x: r.minX, y: r.minY + (r.height - size.height) / 2.0)
    (s as NSString).draw(at: p, withAttributes: [.font: f, .foregroundColor: color])
}
