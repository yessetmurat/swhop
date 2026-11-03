// `~/.config/swhop/swhop.toml`: where apps are found and the panel theme, in
// the format swwm uses (kebab-case keys, "0xAARRGGBB" colors,
// "Family:Style:Size" fonts). Read on every panel open; written with the
// defaults when missing.

import Foundation
import TOMLKit

struct Config: Equatable {
    var apps: [String]
    var theme: Theme

    static func defaults(home: String) -> Config {
        Config(apps: ["/Applications", "/System/Applications", home + "/Applications"], theme: Theme())
    }

    static func path() -> String {
        Apps.homeDir() + "/.config/swhop/swhop.toml"
    }

    /// The config from the file, each error logged. A missing file is
    /// written with `defaultText` first; an unreadable or broken one is left
    /// alone and its bad parts fall back to the defaults.
    static func load() -> Config {
        let home = Apps.homeDir()
        let fm = FileManager.default
        // A link, even a dangling one, is the user's: never replaced.
        let isLink = (try? fm.destinationOfSymbolicLink(atPath: path())) != nil
        if !isLink, !fm.fileExists(atPath: path()) {
            try? fm.createDirectory(atPath: home + "/.config/swhop", withIntermediateDirectories: true)
            try? defaultText.write(toFile: path(), atomically: true, encoding: .utf8)
        }
        guard let text = try? String(contentsOfFile: path(), encoding: .utf8) else {
            logErr("swhop: cannot read \(path()), using the defaults")
            return defaults(home: home)
        }
        let (config, errors) = parse(text, home: home)
        for e in errors {
            logErr("swhop: swhop.toml: " + e)
        }
        return config
    }

    /// The parser; pure for the self-check. Every bad, mistyped or unknown
    /// key is reported and keeps its default; a missing key is its default.
    static func parse(_ text: String, home: String) -> (config: Config, errors: [String]) {
        var c = defaults(home: home)
        var errors: [String] = []
        let root: TOMLTable
        do {
            root = try TOMLTable(string: text)
        } catch let e as TOMLParseError {
            return (c, ["line \(e.source.begin.line): \(e.description)"])
        } catch {
            return (c, ["\(error)"])
        }
        for key in root.keys where !["apps", "theme"].contains(key) {
            errors.append("unknown key \(key)")
        }
        if let v = root["apps"] {
            if let list = v.array, case let paths = list.compactMap(\.string), paths.count == list.count {
                c.apps = paths.map { $0 == "~" || $0.hasPrefix("~/") ? home + String($0.dropFirst()) : $0 }
            } else {
                errors.append("apps must be a list of paths")
            }
        }
        guard let v = root["theme"] else { return (c, errors) }
        guard let t = v.table else { return (c, errors + ["theme must be a table"]) }
        for key in t.keys {
            switch key {
            case "window", "field", "selection", "text", "row-text":
                guard let argb = t[key]?.string.flatMap(color) else {
                    errors.append("theme.\(key) must be \"0xAARRGGBB\"")
                    continue
                }
                let rgba = argb << 8 | argb >> 24
                switch key {
                case "window": c.theme.window = rgba
                case "field": c.theme.field = rgba
                case "selection": c.theme.selection = rgba
                case "text": c.theme.text = rgba
                default: c.theme.rowText = rgba
                }
            case "window-radius", "radius", "width":
                // Bounded: a huge value would build an absurd window frame.
                guard let n = t[key].flatMap(number), key == "width" ? (1...10000).contains(n) : (0...1000).contains(n) else {
                    errors.append("theme.\(key) must be a number")
                    continue
                }
                switch key {
                case "window-radius": c.theme.windowRadius = n
                case "radius": c.theme.radius = n
                default: c.theme.width = n
                }
            case "field-font", "row-font":
                guard let f = t[key]?.string.flatMap(FontSpec.parse) else {
                    errors.append("theme.\(key) must be \"Family:Style:Size\"")
                    continue
                }
                if key == "field-font" { c.theme.fieldFont = f } else { c.theme.rowFont = f }
            default:
                errors.append("unknown key theme.\(key)")
            }
        }
        return (c, errors)
    }

    /// "0xAARRGGBB", case-insensitive.
    private static func color(_ s: String) -> UInt32? {
        let hex = s.lowercased()
        guard hex.hasPrefix("0x"), hex.count == 10 else { return nil }
        return UInt32(hex.dropFirst(2), radix: 16)
    }

    /// An integer or a finite float.
    private static func number(_ v: TOMLValueConvertible) -> CGFloat? {
        if let i = v.int { return CGFloat(i) }
        if let d = v.double, d.isFinite { return CGFloat(d) }
        return nil
    }

    static let defaultText = """
    # swhop configuration. Changes apply the next time the panel opens.

    # Where apps are found: folders (scanned at the top level and one level
    # down, not inside bundles) or single .app bundles; a leading ~ is the
    # home dir; the first entry wins a name.
    apps = [
      "/Applications",
      "/System/Applications",
      "~/Applications",
    ]

    # The panel look (the Megan theme). Colors are "0xAARRGGBB", fonts
    # "Family:Style:Size".
    [theme]
    window = "0xFF2D2D2D"
    field = "0x26000000"
    selection = "0x7F3E3E3E"
    text = "0xFFFFFFFF"
    row-text = "0xE5FFFFFF"
    window-radius = 12
    radius = 8
    field-font = "IBM Plex Sans:Regular:16"
    row-font = "IBM Plex Sans:Regular:12"
    width = 480

    """
}
