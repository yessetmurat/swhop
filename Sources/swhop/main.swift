//
//  main.swift
//  swhop
//
//  Created by Yesset Murat on 31.10.2026.
//

// swhop: a light app launcher and calculator for macOS on cmd+space. Takes
// no arguments. At login it is started by `brew services`.

import Foundation

let usage = "usage: swhop"

if CommandLine.arguments.count > 1 {
    logErr(usage)
    exit(2)
}
Panel.run()
