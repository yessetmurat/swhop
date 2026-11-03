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
        config()
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

    private static func config() {
        let home = "/h"
        let d = Config(apps: ["/Applications", "/System/Applications", "/h/Applications"], theme: Theme())
        func parse(_ t: String) -> (config: Config, errors: [String]) { Config.parse(t, home: home) }
        check("theme defaults are Megan", {
            let t = Theme()
            return t.window == 0x2D2D2DFF && t.field == 0x00000026 && t.selection == 0x3E3E3E7F
                && t.text == 0xFFFFFFFF && t.rowText == 0xFFFFFFE5 && t.windowRadius == 12 && t.radius == 8
                && t.fieldFont == FontSpec(family: "IBM Plex Sans", style: "Regular", size: 16)
                && t.rowFont == FontSpec(family: "IBM Plex Sans", style: "Regular", size: 12) && t.width == 480
        })
        check("default text round-trip", {
            let r = parse(Config.defaultText)
            return r.config == d && r.errors.isEmpty
        })
        check("empty file -> defaults", {
            let r = parse("")
            return r.config == d && r.errors.isEmpty
        })
        check("all keys", {
            let r = parse("""
                apps = ["/A", "~/B"]
                [theme]
                window = "0xFFFFFFFF"
                field = "0x0F000000"
                selection = "0xFFDDDDDD"
                text = "0xFF000000"
                row-text = "0xCC333333"
                window-radius = 0
                radius = 4.5
                field-font = "Menlo:Bold:20"
                row-font = "Menlo:Regular:14"
                width = 600
                """)
            var t = Theme()
            t.window = 0xFFFFFFFF; t.field = 0x0000000F; t.selection = 0xDDDDDDFF; t.text = 0x000000FF; t.rowText = 0x333333CC
            t.windowRadius = 0; t.radius = 4.5; t.width = 600
            t.fieldFont = FontSpec(family: "Menlo", style: "Bold", size: 20)
            t.rowFont = FontSpec(family: "Menlo", style: "Regular", size: 14)
            return r.config == Config(apps: ["/A", "/h/B"], theme: t) && r.errors.isEmpty
        })
        check("bad color", {
            let r = parse("[theme]\nwindow = \"2D2D2D\"\nwidth = 600")
            return r.config.theme.window == Theme().window && r.config.theme.width == 600 && r.errors.count == 1
        })
        check("bad font", {
            let r = parse("[theme]\nrow-font = \"Menlo\"")
            return r.config.theme.rowFont == Theme().rowFont && r.errors.count == 1
        })
        check("bad number", {
            let r = parse("[theme]\nwidth = 0\nradius = \"8\"")
            return r.config.theme == Theme() && r.errors.count == 2
        })
        check("unknown key", {
            let r = parse("[theme]\nblur = 1\n[extra]\na = 1")
            return r.config == d && r.errors.count == 2
        })
        check("bad apps", {
            let r = parse("apps = 3")
            return r.config.apps == d.apps && r.errors.count == 1
        })
        check("missing theme", {
            let r = parse("apps = [\"/X\"]")
            return r.config.theme == Theme() && r.config.apps == ["/X"] && r.errors.isEmpty
        })
        check("tilde only for the home dir", {
            parse("apps = [\"~/A\", \"~\", \"~bob/B\"]").config.apps == ["/h/A", "/h", "~bob/B"]
        })
        check("huge numbers", {
            let r = parse("[theme]\nwidth = 1e308\nradius = 9223372036854775807\nrow-font = \"Menlo:Regular:100000\"")
            return r.config.theme == Theme() && r.errors.count == 3
        })
        check("syntax error", {
            let r = parse("apps = [")
            return r.config == d && r.errors.count == 1
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
