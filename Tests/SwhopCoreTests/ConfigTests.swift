//
//  ConfigTests.swift
//  SwhopCoreTests
//
//  Created by Yesset Murat on 04.11.2026.
//

import Testing
@testable import SwhopCore

private let defaults = Config(
    apps: ["/Applications", "/System/Applications", "/h/Applications"],
    theme: Theme()
)

private func parse(_ text: String) -> (config: Config, errors: [String]) {
    Config.parse(text, home: "/h")
}

@Test func themeDefaultsAreMegan() {
    let t = Theme()

    #expect(t.window == 0x2D2D2DFF)
    #expect(t.field == 0x00000026)
    #expect(t.selection == 0x3E3E3E7F)
    #expect(t.text == 0xFFFFFFFF)
    #expect(t.rowText == 0xFFFFFFE5)
    #expect(t.windowRadius == 12)
    #expect(t.radius == 8)
    #expect(t.fieldFont == FontSpec(family: "IBM Plex Sans", style: "Regular", size: 16))
    #expect(t.rowFont == FontSpec(family: "IBM Plex Sans", style: "Regular", size: 12))
    #expect(t.width == 480)
}

@Test func defaultTextRoundTrip() {
    let r = parse(Config.defaultText)

    #expect(r.config == defaults)
    #expect(r.errors.isEmpty)
}

@Test func emptyFileIsDefaults() {
    let r = parse("")

    #expect(r.config == defaults)
    #expect(r.errors.isEmpty)
}

@Test func allKeys() {
    var t = Theme()
    t.window = 0xFFFFFFFF
    t.field = 0x0000000F
    t.selection = 0xDDDDDDFF
    t.text = 0x000000FF
    t.rowText = 0x333333CC
    t.windowRadius = 0
    t.radius = 4.5
    t.width = 600
    t.fieldFont = FontSpec(family: "Menlo", style: "Bold", size: 20)
    t.rowFont = FontSpec(family: "Menlo", style: "Regular", size: 14)

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

    #expect(r.config == Config(apps: ["/A", "/h/B"], theme: t))
    #expect(r.errors.isEmpty)
}

@Test func badColor() {
    let r = parse("[theme]\nwindow = \"2D2D2D\"\nwidth = 600")

    #expect(r.config.theme.window == Theme().window)
    #expect(r.config.theme.width == 600)
    #expect(r.errors.count == 1)
}

@Test func badFont() {
    let r = parse("[theme]\nrow-font = \"Menlo\"")

    #expect(r.config.theme.rowFont == Theme().rowFont)
    #expect(r.errors.count == 1)
}

@Test func badNumber() {
    let r = parse("[theme]\nwidth = 0\nradius = \"8\"")

    #expect(r.config.theme == Theme())
    #expect(r.errors.count == 2)
}

@Test func unknownKey() {
    let r = parse("[theme]\nblur = 1\n[extra]\na = 1")

    #expect(r.config == defaults)
    #expect(r.errors.count == 2)
}

@Test func badApps() {
    let r = parse("apps = 3")

    #expect(r.config.apps == defaults.apps)
    #expect(r.errors.count == 1)
}

@Test func missingTheme() {
    let r = parse("apps = [\"/X\"]")

    #expect(r.config.theme == Theme())
    #expect(r.config.apps == ["/X"])
    #expect(r.errors.isEmpty)
}

@Test func tildeOnlyForTheHomeDir() {
    #expect(parse("apps = [\"~/A\", \"~\", \"~bob/B\"]").config.apps == ["/h/A", "/h", "~bob/B"])
}

@Test func hugeNumbers() {
    let r = parse("[theme]\nwidth = 1e308\nradius = 9223372036854775807\nrow-font = \"Menlo:Regular:100000\"")

    #expect(r.config.theme == Theme())
    #expect(r.errors.count == 3)
}

@Test func syntaxError() {
    let r = parse("apps = [")

    #expect(r.config == defaults)
    #expect(r.errors.count == 1)
}
