//
//  PasteTextTests.swift
//  SwhopCoreTests
//
//  Created by Yesset Murat on 04.11.2026.
//

import Testing
@testable import SwhopCore

@Test func pasteTrimsEnds() {
    #expect(pasteText("  1299*12\n") == "1299*12")
}

@Test func pasteFoldsNewlinesAndTabs() {
    #expect(pasteText("a\nb\tc\r\nd") == "a b c d")
}

@Test func pasteDropsControlCharacters() {
    #expect(pasteText("\u{7}sa\u{1B}fari") == "safari")
}

@Test func pasteKeepsInnerSpaces() {
    #expect(pasteText("Visual Studio Code") == "Visual Studio Code")
}

@Test func pasteEmpty() {
    #expect(pasteText("") == "")
    #expect(pasteText(" \n\t ") == "")
}

@Test func pasteCutTo256() {
    #expect(pasteText(String(repeating: "a", count: 300)).count == 256)
}
