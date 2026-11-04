//
//  LaunchCounts.swift
//  SwhopCore
//
//  Created by Yesset Murat on 04.11.2026.
//

// How often each app was launched from swhop, stored as `<count>\t<app path>`
// lines.

public enum LaunchCounts {

    /// `<count>\t<app path>` per line; broken lines are skipped.
    public static func parse(_ text: String) -> [String: UInt32] {
        var out: [String: UInt32] = [:]
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            guard let tab = line.firstIndex(of: "\t") else {
                continue
            }
            guard let n = UInt32(line[..<tab]) else {
                continue
            }
            out[String(line[line.index(after: tab)...])] = n
        }
        return out
    }

    public static func format(_ c: [String: UInt32]) -> String {
        c.sorted { $0.key < $1.key }
            .map { "\($0.value)\t\($0.key)\n" }
            .joined()
    }
}
