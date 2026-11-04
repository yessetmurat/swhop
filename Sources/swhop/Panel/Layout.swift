//
//  Layout.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

// The panel geometry: fixed paddings and sizes, and the heights that depend
// on the field font.

import AppKit

let PAD: CGFloat = 10.0
let FIELD_PAD_X: CGFloat = 8.0
let FIELD_PAD_Y: CGFloat = 12.0
let SPACING: CGFloat = 8.0
let ICON: CGFloat = 24.0
let ICON_PAD: CGFloat = 4.0
let ROW_PAD_Y: CGFloat = 6.0
let ROW_H: CGFloat = ICON + 2.0 * ROW_PAD_Y
let ROWS = 8

/// Side of the command's mark, smaller than app icons.
let QUIT_ICON: CGFloat = 12.0

func fieldH() -> CGFloat {
    textSize("Ag", fieldFont).height + 2.0 * FIELD_PAD_Y
}

func rowsTop() -> CGFloat {
    PAD + fieldH() + SPACING
}

func height(items n: Int) -> CGFloat {
    2.0 * PAD + fieldH() + (n > 0 ? SPACING + CGFloat(n) * ROW_H : 0.0)
}
