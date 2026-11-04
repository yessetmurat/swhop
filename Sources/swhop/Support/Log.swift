//
//  Log.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

import Foundation

/// One line to stderr.
func logErr(_ s: String) {
    FileHandle.standardError.write((s + "\n").data(using: .utf8)!)
}
