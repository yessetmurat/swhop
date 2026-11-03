// The panel theme: colors, corner radii, fonts and width, set in the
// `[theme]` table of swhop.toml (see Config.swift). The defaults are the
// Megan theme.

import Foundation

/// A font as "Family:Style:Size", e.g. "IBM Plex Sans:Regular:16", as in swwm.
struct FontSpec: Equatable {
    var family: String
    var style: String
    var size: CGFloat

    /// nil unless three non-empty parts with a size from 1 to 500.
    static func parse(_ s: String) -> FontSpec? {
        let parts = s.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 3, !parts[0].isEmpty, !parts[1].isEmpty,
              let size = Double(parts[2]), (1...500).contains(size) else { return nil }
        return FontSpec(family: parts[0], style: parts[1], size: CGFloat(size))
    }
}

struct Theme: Equatable {
    // Colors are 0xRRGGBBAA, the form rgba(_:) in Draw.swift takes; the file
    // has them as 0xAARRGGBB.
    var window: UInt32 = 0x2D2D2DFF
    var field: UInt32 = 0x00000026
    var selection: UInt32 = 0x3E3E3E7F
    var text: UInt32 = 0xFFFFFFFF
    var rowText: UInt32 = 0xFFFFFFE5
    var windowRadius: CGFloat = 12
    var radius: CGFloat = 8
    var fieldFont = FontSpec(family: "IBM Plex Sans", style: "Regular", size: 16)
    var rowFont = FontSpec(family: "IBM Plex Sans", style: "Regular", size: 12)
    var width: CGFloat = 480
}
