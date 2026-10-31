// The panel theme: colors, corner radii, font and width, read from
// `~/.config/swhop/theme` as one `key = value` per line. The defaults are
// the Alfred theme "Megan"; a missing file, and every bad line, leaves the
// rest of the theme untouched.

import Foundation

struct Theme: Equatable {
    // Colors are 0xRRGGBBAA, the form rgba(_:) in Draw.swift takes.
    var window: UInt32 = 0x2D2D2DFF
    var field: UInt32 = 0x00000026
    var selection: UInt32 = 0x3E3E3E7F
    var text: UInt32 = 0xFFFFFFFF
    var rowText: UInt32 = 0xFFFFFFE5
    var windowRadius: CGFloat = 12
    var radius: CGFloat = 8
    var font: String = "IBMPlexSans"
    var fieldFontSize: CGFloat = 16
    var rowFontSize: CGFloat = 12
    var width: CGFloat = 480

    /// `~/.config/swhop/theme`.
    static func path() -> String {
        Apps.homeDir() + "/.config/swhop/theme"
    }

    /// The theme from the file: each error is logged and its line skipped;
    /// a missing or unreadable file returns the defaults silently.
    static func load() -> Theme {
        guard let text = try? String(contentsOfFile: path(), encoding: .utf8) else {
            return Theme()
        }
        let (theme, errors) = parse(text)
        for e in errors {
            logErr("swhop: theme: " + e)
        }
        return theme
    }

    /// The parser; pure for the self-check. Blank lines and `#` comments
    /// are skipped; a line without `=`, unknown keys and bad values are
    /// reported and skipped, the last of repeated keys wins.
    static func parse(_ text: String) -> (theme: Theme, errors: [String]) {
        var theme = Theme()
        var errors: [String] = []
        // "\r\n" is one Character: split on any newline, not just "\n".
        for (i, raw) in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).enumerated() {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            guard let eq = line.firstIndex(of: "=") else {
                errors.append("line \(i + 1): expected key = value")
                continue
            }
            let key = String(line[..<eq]).trimmingCharacters(in: .whitespacesAndNewlines)
            let value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            switch key {
            case "window", "field", "selection", "text", "row_text":
                guard let c = color(value) else {
                    errors.append("line \(i + 1): bad value for \(key)")
                    continue
                }
                switch key {
                case "window": theme.window = c
                case "field": theme.field = c
                case "selection": theme.selection = c
                case "text": theme.text = c
                default: theme.rowText = c
                }
            case "window_radius", "radius":
                guard let n = number(value), n >= 0 else {
                    errors.append("line \(i + 1): bad value for \(key)")
                    continue
                }
                if key == "window_radius" { theme.windowRadius = n } else { theme.radius = n }
            case "font":
                guard !value.isEmpty else {
                    errors.append("line \(i + 1): bad value for font")
                    continue
                }
                theme.font = value
            case "field_font_size", "row_font_size", "width":
                guard let n = number(value), n > 0 else {
                    errors.append("line \(i + 1): bad value for \(key)")
                    continue
                }
                switch key {
                case "field_font_size": theme.fieldFontSize = n
                case "row_font_size": theme.rowFontSize = n
                default: theme.width = n
                }
            default:
                errors.append("line \(i + 1): unknown key \(key)")
            }
        }
        return (theme, errors)
    }

    /// `RRGGBB` or `RRGGBBAA` hex, optional leading `#`; 6 digits means
    /// alpha `FF`.
    private static func color(_ s: String) -> UInt32? {
        var d = s
        if d.hasPrefix("#") { d = String(d.dropFirst()) }
        guard d.count == 6 || d.count == 8, d.allSatisfy(\.isHexDigit) else { return nil }
        guard let v = UInt32(d, radix: 16) else { return nil }
        return d.count == 8 ? v : (v << 8) | 0xFF
    }

    /// A finite number: `inf`, `nan` and anything `Double` rejects.
    private static func number(_ s: String) -> CGFloat? {
        guard let d = Double(s), d.isFinite else { return nil }
        return CGFloat(d)
    }
}
