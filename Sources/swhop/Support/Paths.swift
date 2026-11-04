//
//  Paths.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

import Foundation

/// Where swhop keeps its files.
enum Paths {

    static func home() -> String {
        ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
    }

    static func config() -> String {
        home() + "/.config/swhop/swhop.toml"
    }

    static func launchCounts() -> String {
        home() + "/Library/Application Support/swhop/counts"
    }
}
