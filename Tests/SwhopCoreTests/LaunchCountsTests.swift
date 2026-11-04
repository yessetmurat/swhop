//
//  LaunchCountsTests.swift
//  SwhopCoreTests
//
//  Created by Yesset Murat on 04.11.2026.
//

import Testing
@testable import SwhopCore

private let counts: [String: UInt32] = ["/Applications/Zed.app": 3, "/A b.app": 1]

@Test func launchCountsRoundTrip() {
    #expect(LaunchCounts.parse(LaunchCounts.format(counts)) == counts)
}

@Test func launchCountsFormatSorted() {
    #expect(LaunchCounts.format(counts) == "1\t/A b.app\n3\t/Applications/Zed.app\n")
}

@Test func launchCountsParseSkipsBrokenLines() {
    #expect(LaunchCounts.parse("x\t/a.app\n2\n4\t/b.app\n") == ["/b.app": 4])
}
