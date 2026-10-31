// The `--test` self-check: asserts over the pure logic. CLT-only machine:
// no Xcode, no XCTest, so this flag is the test harness. Prints `ok` and
// exits 0 when everything passes; prints every failure and exits 1
// otherwise.

import Foundation

enum SelfCheck {
    private static var failures: [String] = []

    private static func check(_ name: String, _ ok: () -> Bool) {
        if !ok() {
            failures.append(name)
        }
    }

    /// Runs all the checks. Prints `ok` and exits 0 if all passed; prints
    /// every failure and exits 1 otherwise.
    static func run() -> Never {
        calc()
        apps()
        plistChecks()
        theme()
        paste()
        if failures.isEmpty {
            print("ok")
            exit(0)
        }
        for f in failures {
            print("fail: \(f)")
        }
        exit(1)
    }

    // MARK: Apps

    private static func apps() {
        for (q, n) in [
            ("tg", "Telegram"), ("ff", "Firefox"), ("FF", "firefox"),
        ] {
            check("score match \(q)", { Apps.score(q, n) != nil })
        }
        check("score no match xyz", { Apps.score("xyz", "Firefox") == nil })
        check("score saf Safari > System Information", {
            (Apps.score("saf", "Safari") ?? 0) > (Apps.score("saf", "System Information") ?? 0)
        })
        check("score ss System Settings > Messages", {
            (Apps.score("ss", "System Settings") ?? 0) > (Apps.score("ss", "Messages") ?? 0)
        })
        check("score ss System Settings > Stocks", {
            (Apps.score("ss", "System Settings") ?? 0) > (Apps.score("ss", "Stocks") ?? 0)
        })
        check("score ss System Settings == SF Symbols", {
            Apps.score("ss", "System Settings") == Apps.score("ss", "SF Symbols")
        })
        check("score tele Telegram > Remote Telescope", {
            (Apps.score("tele", "Telegram") ?? 0) > (Apps.score("tele", "Remote Telescope") ?? 0)
        })
        // String equality is canonical: a typed NFC "é" must match an NFD
        // file name ("Cafe" + combining acute).
        check("score NFC query matches NFD name", {
            Apps.score("\u{E9}", "Cafe\u{301}") != nil
        })
        check("parseSources: trim, skip comments and blanks, expand ~", {
            Apps.parseSources(
                """
                # app sources

                  /Applications
                ~/Applications
                /System/Applications
                """, home: "/h"
            ) == ["/Applications", "/h/Applications", "/System/Applications"]
        })
        let apps = [
            App(name: "Telegram", path: "/Applications/Telegram.app"),
            App(name: "Terminal", path: "/Applications/Terminal.app"),
            App(name: "TextEdit", path: "/Applications/TextEdit.app"),
        ]
        let telCount: [String: UInt32] = ["/Applications/Telegram.app": 1]
        check("rank tie -> launched first", {
            Apps.rank("te", apps, ["/Applications/Terminal.app": 5])[0].index == 1
        })
        check("rank no counts -> names", {
            Apps.rank("te", apps, [:]).map { apps[$0.index].name } == ["Telegram", "Terminal", "TextEdit"]
        })
        check("rank empty query -> []", { Apps.rank("", apps, telCount).isEmpty })
        check("rank count never beats better match", {
            Apps.rank("term", apps, telCount)[0].index == 1
        })
        // Name ties are broken case-insensitively: "acb" before "aZb".
        check("rank name tie case-insensitive", {
            let z = [
                App(name: "aZb", path: "/Applications/aZb.app"),
                App(name: "acb", path: "/Applications/acb.app"),
            ]
            return Apps.rank("ab", z, [:]).map { z[$0.index].name } == ["acb", "aZb"]
        })
        check("slot empty query -> nil", { Apps.commandSlot("", "Quit All Apps", [5]) == nil })
        check("slot no match -> nil", { Apps.commandSlot("zzz", "Quit All Apps", []) == nil })
        check("slot alone -> 0", { Apps.commandSlot("quit", "Quit All Apps", []) == 0 })
        let s = Apps.score("quit", "Quit All Apps")!
        check("slot beats -> 2", { Apps.commandSlot("quit", "Quit All Apps", [s + 1, s, s - 1]) == 2 })
        check("slot wins -> 0", { Apps.commandSlot("quit", "Quit All Apps", [s - 1]) == 0 })
        let c: [String: UInt32] = ["/Applications/Zed.app": 3, "/A b.app": 1]
        check("counts round-trip", { Apps.parseCounts(Apps.formatCounts(c)) == c })
        check("counts sorted", { Apps.formatCounts(c) == "1\t/A b.app\n3\t/Applications/Zed.app\n" })
        check("counts broken lines skipped", {
            Apps.parseCounts("x\t/a.app\n2\n4\t/b.app\n") == ["/b.app": 4]
        })
        scanFixture()
    }

    // MARK: Plist

    private static func plistChecks() {
        let xml: String? = Service.plist(label: "local.swhop", exe: "/opt/swhop/swhop")
        let d: [String: Any]?
        if let data = xml?.data(using: .utf8) {
            d = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any]
        } else {
            d = nil
        }
        check("plist decodes", { d != nil })
        check("plist label", { d?["Label"] as? String == "local.swhop" })
        check("plist program", { d?["ProgramArguments"] as? [String] == ["/opt/swhop/swhop"] })
        check("plist runatload", { d?["RunAtLoad"] as? Bool == true })
        check("plist keepalive", { (d?["KeepAlive"] as? [String: Any])?["SuccessfulExit"] as? Bool == false })
        check("plist out log", { d?["StandardOutPath"] as? String == Service.logsDir() + "/out.log" })
        check("plist err log", { d?["StandardErrorPath"] as? String == Service.logsDir() + "/err.log" })
    }

    private static func scanFixture() {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("swhop-apps-test-\(ProcessInfo.processInfo.processIdentifier)").path
        let fm = FileManager.default
        let one = base + "/one", two = base + "/two", three = base + "/three"
        for d in ["A.app/Contents/C.app", "Utilities/B.app"] {
            try! fm.createDirectory(atPath: one + "/" + d, withIntermediateDirectories: true)
        }
        try! "".write(toFile: one + "/notes.txt", atomically: true, encoding: .utf8)
        try! fm.createDirectory(atPath: one + "/iMovie.app", withIntermediateDirectories: true)
        try! fm.createDirectory(atPath: two + "/A.app", withIntermediateDirectories: true)
        try! fm.createDirectory(atPath: two + "/Zed.app", withIntermediateDirectories: true)
        try! fm.createDirectory(atPath: three + "/K.app", withIntermediateDirectories: true)
        defer { try? fm.removeItem(atPath: base) }
        // First dir wins; one level down; not inside bundles; a direct
        // bundle entry is added as-is.
        let names = Apps.scan([one, two, three + "/K.app"]).map { $0.name }
        check("scan nested, first dir wins, direct bundle", {
            names == ["A", "B", "iMovie", "K", "Zed"]
        })
        // Case-insensitive order: a byte sort would put iMovie after Zed.
        check("scan case-insensitive order", { names[2] == "iMovie" })
    }

    // MARK: Theme

    private static func theme() {
        let d = Theme()
        check("theme defaults are Megan", {
            d.window == 0x2D2D2DFF && d.field == 0x00000026 && d.selection == 0x3E3E3E7F
                && d.text == 0xFFFFFFFF && d.rowText == 0xFFFFFFE5
                && d.windowRadius == 12 && d.radius == 8 && d.font == "IBMPlexSans"
                && d.fieldFontSize == 16 && d.rowFontSize == 12 && d.width == 480
        })
        check("parse empty -> defaults", {
            let r = Theme.parse("")
            return r.theme == d && r.errors.isEmpty
        })
        check("parse all keys", {
            let r = Theme.parse(
                """
                # light
                window = FFFFFFFF
                field = 0000000F
                selection = DDDDDD
                text = 000000FF
                row_text = 333333CC
                window_radius = 0
                radius = 4.5
                font = Menlo
                field_font_size = 20
                row_font_size = 14
                width = 600
                """)
            var w = Theme()
            w.window = 0xFFFFFFFF; w.field = 0x0000000F; w.selection = 0xDDDDDDFF
            w.text = 0x000000FF; w.rowText = 0x333333CC
            w.windowRadius = 0; w.radius = 4.5; w.font = "Menlo"
            w.fieldFontSize = 20; w.rowFontSize = 14; w.width = 600
            return r.theme == w && r.errors.isEmpty
        })
        check("parse crlf and spacing", {
            let r = Theme.parse("  window\t=  #102030 \r\n\r\n  # c\r\nwidth=500\r\n")
            var w = Theme()
            w.window = 0x102030FF; w.width = 500
            return r.theme == w && r.errors.isEmpty
        })
        check("parse last key wins", {
            Theme.parse("width = 500\nwidth = 520").theme.width == 520
        })
        check("parse errors", {
            let r = Theme.parse(
                """
                window
                colour = FFFFFF
                window = 12345
                window = GGGGGG
                field = +2D2D2DF
                width = -1
                width = inf
                radius = abc
                window_radius = -2
                font =
                row_font_size = 0
                """)
            return r.theme == d && r.errors == [
                "line 1: expected key = value",
                "line 2: unknown key colour",
                "line 3: bad value for window",
                "line 4: bad value for window",
                "line 5: bad value for field",
                "line 6: bad value for width",
                "line 7: bad value for width",
                "line 8: bad value for radius",
                "line 9: bad value for window_radius",
                "line 10: bad value for font",
                "line 11: bad value for row_font_size",
            ]
        })
        check("parse partial", {
            let r = Theme.parse("width = 600\nwidth = wide\nradius = 2")
            return r.theme.width == 600 && r.theme.radius == 2 && r.errors == ["line 2: bad value for width"]
        })
    }

    // MARK: Paste

    private static func paste() {
        check("paste trims ends", { pasteText("  1299*12\n") == "1299*12" })
        check("paste newlines and tabs -> space", { pasteText("a\nb\tc\r\nd") == "a b c d" })
        check("paste drops control chars", { pasteText("\u{7}sa\u{1B}fari") == "safari" })
        check("paste keeps inner spaces", { pasteText("Visual Studio Code") == "Visual Studio Code" })
        check("paste empty", { pasteText("") == "" && pasteText(" \n\t ") == "" })
        check("paste cut to 256", { pasteText(String(repeating: "a", count: 300)).count == 256 })
    }

    // MARK: Calculator

    private static func calc() {
        for (expr, want) in [
            ("2+2*3", "8"), ("(2+2)*3", "12"), ("-3+5", "2"), ("7/2", "3.5"),
            ("1,5*2", "3"), ("200 + 10%", "220"), ("200 - 10%", "180"),
            ("200 * 10%", "20"), ("50%", "0.5"), ("-50%", "-0.5"), ("-5+1", "-4"),
        ] {
            check("calc \(expr)", { Calc.eval(expr).map(Calc.format) == want })
        }
        for bad in ["2+", "abc", "12", "1/0", "", "(1", "2 3", "-5", "-.5"] {
            check("calc rejects \(bad)", { Calc.eval(bad) == nil })
        }
        for (v, want) in [(3.5, "3.5"), (8.0, "8"), (0.1 + 0.2, "0.3"), (-0.0, "0"), (1.0 / 3.0, "0.3333333333"), (-2.5, "-2.5")] {
            check("format \(want)", { Calc.format(v) == want })
        }
    }
}
