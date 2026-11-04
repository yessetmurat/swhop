//
//  AppsTests.swift
//  SwhopCoreTests
//
//  Created by Yesset Murat on 04.11.2026.
//

import Foundation
import Testing
@testable import SwhopCore

private let apps = [
    App(name: "Telegram", path: "/Applications/Telegram.app"),
    App(name: "Terminal", path: "/Applications/Terminal.app"),
    App(name: "TextEdit", path: "/Applications/TextEdit.app"),
]

private let telegramCount: [String: UInt32] = ["/Applications/Telegram.app": 1]

@Test(arguments: [("tg", "Telegram"), ("ff", "Firefox"), ("FF", "firefox")])
func scoreMatches(query: String, name: String) {
    #expect(Apps.score(query, name) != nil)
}

@Test func scoreNoMatch() {
    #expect(Apps.score("xyz", "Firefox") == nil)
}

@Test func scorePrefersNameStart() {
    #expect((Apps.score("saf", "Safari") ?? 0) > (Apps.score("saf", "System Information") ?? 0))
}

@Test func scorePrefersWordStarts() {
    let settings = Apps.score("ss", "System Settings") ?? 0

    #expect(settings > (Apps.score("ss", "Messages") ?? 0))
    #expect(settings > (Apps.score("ss", "Stocks") ?? 0))
    #expect(Apps.score("ss", "System Settings") == Apps.score("ss", "SF Symbols"))
}

@Test func scorePrefersStartOverLaterWord() {
    #expect((Apps.score("tele", "Telegram") ?? 0) > (Apps.score("tele", "Remote Telescope") ?? 0))
}

/// String equality is canonical: a typed NFC "é" must match an NFD file
/// name ("Cafe" + combining acute).
@Test func scoreNFCQueryMatchesNFDName() {
    #expect(Apps.score("\u{E9}", "Cafe\u{301}") != nil)
}

@Test func rankTieGoesToLaunchedFirst() {
    #expect(Apps.rank("te", apps, ["/Applications/Terminal.app": 5])[0].index == 1)
}

@Test func rankWithoutCountsByName() {
    let names = Apps.rank("te", apps, [:]).map { apps[$0.index].name }

    #expect(names == ["Telegram", "Terminal", "TextEdit"])
}

@Test func rankEmptyQuery() {
    #expect(Apps.rank("", apps, telegramCount).isEmpty)
}

@Test func rankCountNeverBeatsBetterMatch() {
    #expect(Apps.rank("term", apps, telegramCount)[0].index == 1)
}

/// Name ties are broken case-insensitively: "acb" before "aZb".
@Test func rankNameTieCaseInsensitive() {
    let z = [
        App(name: "aZb", path: "/Applications/aZb.app"),
        App(name: "acb", path: "/Applications/acb.app"),
    ]

    let names = Apps.rank("ab", z, [:]).map { z[$0.index].name }

    #expect(names == ["acb", "aZb"])
}

@Test func commandSlotPlacement() {
    let s = Apps.score("quit", "Quit All Apps")!

    #expect(Apps.commandSlot("", "Quit All Apps", [5]) == nil)
    #expect(Apps.commandSlot("zzz", "Quit All Apps", []) == nil)
    #expect(Apps.commandSlot("quit", "Quit All Apps", []) == 0)
    #expect(Apps.commandSlot("quit", "Quit All Apps", [s + 1, s, s - 1]) == 2)
    #expect(Apps.commandSlot("quit", "Quit All Apps", [s - 1]) == 0)
}

/// First dir wins; one level down; not inside bundles; a direct bundle
/// entry is added as-is; names in case-insensitive order (a byte sort
/// would put iMovie after Zed).
@Test func scanFindsNestedBundles() throws {
    let fm = FileManager.default
    let base = fm.temporaryDirectory
        .appendingPathComponent("swhop-apps-test-\(ProcessInfo.processInfo.processIdentifier)").path
    let one = base + "/one", two = base + "/two", three = base + "/three"
    defer { try? fm.removeItem(atPath: base) }
    for d in ["A.app/Contents/C.app", "Utilities/B.app"] {
        try fm.createDirectory(atPath: one + "/" + d, withIntermediateDirectories: true)
    }
    try "".write(toFile: one + "/notes.txt", atomically: true, encoding: .utf8)
    try fm.createDirectory(atPath: one + "/iMovie.app", withIntermediateDirectories: true)
    try fm.createDirectory(atPath: two + "/A.app", withIntermediateDirectories: true)
    try fm.createDirectory(atPath: two + "/Zed.app", withIntermediateDirectories: true)
    try fm.createDirectory(atPath: three + "/K.app", withIntermediateDirectories: true)

    let names = Apps.scan([one, two, three + "/K.app"]).map { $0.name }

    #expect(names == ["A", "B", "iMovie", "K", "Zed"])
}
