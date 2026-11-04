//
//  Theme.swift
//  SwhopCore
//
//  Created by Yesset Murat on 31.10.2026.
//

// The panel theme: colors, corner radii, fonts and width, set in the
// `[theme]` table of swhop.toml (see Config.swift). The defaults are the
// Megan theme.

import Foundation

public struct Theme: Equatable, Sendable {

    // Colors are 0xRRGGBBAA; the config file has them as 0xAARRGGBB.
    public var window: UInt32 = 0x2D2D2DFF
    public var field: UInt32 = 0x00000026
    public var selection: UInt32 = 0x3E3E3E7F
    public var text: UInt32 = 0xFFFFFFFF
    public var rowText: UInt32 = 0xFFFFFFE5
    public var windowRadius: CGFloat = 12
    public var radius: CGFloat = 8
    public var fieldFont = FontSpec(family: "IBM Plex Sans", style: "Regular", size: 16)
    public var rowFont = FontSpec(family: "IBM Plex Sans", style: "Regular", size: 12)
    public var width: CGFloat = 480

    public init() {}
}
