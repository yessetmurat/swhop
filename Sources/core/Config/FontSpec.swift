//
//  FontSpec.swift
//  SwhopCore
//
//  Created by Yesset Murat on 04.11.2026.
//

import Foundation

/// A font as "Family:Style:Size", e.g. "IBM Plex Sans:Regular:16", as in swwm.
public struct FontSpec: Equatable, Sendable {

    public var family: String
    public var style: String
    public var size: CGFloat

    /// nil unless three non-empty parts with a size from 1 to 500.
    static func parse(_ s: String) -> FontSpec? {
        let parts = s.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 3,
              !parts[0].isEmpty,
              !parts[1].isEmpty,
              let size = Double(parts[2]),
              (1...500).contains(size) else {
            return nil
        }
        return FontSpec(family: parts[0], style: parts[1], size: CGFloat(size))
    }
}
