// Drawing the panel in the configured theme (Megan by default).

import AppKit

func drawPanel(_ b: NSRect) {
    let items = items()
    // Window (the part in use), color and radius from the theme (default:
    // #2D2D2D, radius 12). No border: on the edge it reads as a dark halo.
    let used = NSRect(x: b.minX, y: b.minY, width: b.size.width, height: height(items: items.count))
    fillRounded(used, theme.windowRadius, rgba(theme.window))

    // Search field, color, radius and font from the theme.
    let ff = fieldFont
    let field = NSRect(x: PAD, y: PAD, width: b.size.width - 2.0 * PAD, height: fieldH())
    fillRounded(field, theme.radius, rgba(theme.field))
    let query = state.query
    let text = NSRect(
        x: field.minX + FIELD_PAD_X,
        y: field.minY,
        width: field.size.width - 2.0 * FIELD_PAD_X,
        height: field.size.height
    )
    drawTextLeft(query, ff, rgba(theme.text), text)
    // Caret after the text.
    let cx = text.minX + textSize(query, ff).width + 1.0
    let ch = textSize("Ag", ff).height
    rgba(theme.text).setFill()
    NSRect(x: cx, y: field.minY + (field.size.height - ch) / 2.0, width: 1.5, height: ch).fill()

    // Rows: icon 24, row font from the theme; the selected one's color and
    // radius come from the theme too.
    let rf = rowFont
    let selected = state.selected
    for (k, item) in items.enumerated() {
        let r = NSRect(x: PAD, y: rowsTop() + CGFloat(k) * ROW_H, width: b.size.width - 2.0 * PAD, height: ROW_H)
        let sel = k == selected
        if sel {
            fillRounded(r, theme.radius, rgba(theme.selection))
        }
        let icon = NSRect(x: r.minX + ICON_PAD, y: r.minY + ROW_PAD_Y, width: ICON, height: ICON)
        let labelX = icon.minX + ICON + 2.0 * ICON_PAD
        let label = NSRect(x: labelX, y: r.minY, width: r.size.width - (labelX - r.minX), height: ROW_H)
        let color: NSColor = sel ? rgba(theme.text) : rgba(theme.rowText)
        switch item {
        case .calc(let v):
            drawIcon(iconCached(CALCULATOR), icon)
            drawTextLeft("= \(v)", rf, color, label)
        case .quit:
            let img = iconCached(QUIT_ICON_KEY)
            // A small mark centered in the icon slot.
            let m = QUIT_ICON / 2.0
            drawIcon(img, NSRect(x: icon.midX - m, y: icon.midY - m, width: QUIT_ICON, height: QUIT_ICON))
            drawTextLeft(QUIT_ALL, rf, color, label)
        case .app(let i):
            let app = state.apps[i]
            drawIcon(iconCached(app.path), icon)
            drawTextLeft(app.name, rf, color, label)
        }
    }
}

/// Cache an icon on first use (the launch of a result row may be the first
/// time it is needed).
func iconCached(_ path: String) -> NSImage {
    if let img = state.icons[path] {
        return img
    }
    let img = path == QUIT_ICON_KEY ? quitIcon() : NSWorkspace.shared.icon(forFile: path)
    state.icons[path] = img
    return img
}

func drawIcon(_ img: NSImage, _ r: NSRect) {
    img.draw(in: r, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
}

/// The SF Symbol "xmark", tinted with the theme's text color so it reads
/// on the rows. Falls back to an empty image if the symbol is unavailable.
func quitIcon() -> NSImage {
    let cfg = NSImage.SymbolConfiguration(hierarchicalColor: rgba(theme.text))
    return NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg)
        ?? NSImage()
}

func fillRounded(_ r: NSRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
}

/// `0xRRGGBBAA`, as Theme keeps its colors.
func rgba(_ c: UInt32) -> NSColor {
    func ch(_ shift: UInt32) -> CGFloat { CGFloat((c >> shift) & 0xFF) / 255.0 }
    return NSColor(srgbRed: ch(24), green: ch(16), blue: ch(8), alpha: ch(0))
}
