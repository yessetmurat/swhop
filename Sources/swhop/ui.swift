// Panel text helpers: measuring, drawing, and the stderr logger.

import AppKit

func logErr(_ s: String) {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
}

/// The face by family and style name (PostScript names differ: "SemiBold"
/// is IBMPlexSans-SmBld), as swwm finds it; else the system font.
func panelFont(_ spec: FontSpec) -> NSFont {
    let members = NSFontManager.shared.availableMembers(ofFontFamily: spec.family) ?? []
    if let member = members.first(where: { ($0[1] as? String)?.caseInsensitiveCompare(spec.style) == .orderedSame }),
       let name = member[0] as? String, let font = NSFont(name: name, size: spec.size) {
        return font
    }
    return NSFont.systemFont(ofSize: spec.size)
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
