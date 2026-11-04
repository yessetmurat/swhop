//
//  ConfigLoader.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

// Reading `~/.config/swhop/swhop.toml`: on every panel open; written with
// the defaults when missing.

import Foundation
import SwhopCore

enum ConfigLoader {

    /// The config from the file, each error logged. A missing file is
    /// written with `Config.defaultText` first; an unreadable or broken one
    /// is left alone and its bad parts fall back to the defaults.
    static func load() -> Config {
        let home = Paths.home()
        let path = Paths.config()
        let fm = FileManager.default

        // A link, even a dangling one, is the user's: never replaced.
        let isLink = (try? fm.destinationOfSymbolicLink(atPath: path)) != nil
        if !isLink, !fm.fileExists(atPath: path) {
            try? fm.createDirectory(atPath: home + "/.config/swhop", withIntermediateDirectories: true)
            try? Config.defaultText.write(toFile: path, atomically: true, encoding: .utf8)
        }

        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
            logErr("swhop: cannot read \(path), using the defaults")
            return Config.defaults(home: home)
        }

        let (config, errors) = Config.parse(text, home: home)
        for e in errors {
            logErr("swhop: swhop.toml: " + e)
        }
        return config
    }
}
