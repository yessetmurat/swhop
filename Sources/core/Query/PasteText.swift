//
//  PasteText.swift
//  SwhopCore
//
//  Created by Yesset Murat on 04.11.2026.
//

import Foundation

/// Clean a clipboard paste for the query: trim the ends, fold newlines and
/// tabs to single spaces, drop the other control characters, and cut the
/// result to 256 characters.
public func pasteText(_ s: String) -> String {
    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
    let chars = trimmed.map { c in c.isNewline || c == "\t" ? " " : c }
    let cleaned = chars.filter { c -> Bool in
        guard let s = c.unicodeScalars.first else {
            return false
        }
        return s.properties.generalCategory != .control
    }
    return String(cleaned.prefix(256))
}
