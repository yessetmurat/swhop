//
//  Keys.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

// Keys in the panel: typing edits the query, arrows or ctrl+j/k move the
// selection, Enter chooses, Esc closes.

import AppKit
import Carbon
import SwhopCore

func key(_ event: NSEvent) {
    let mods = event.modifierFlags
    let plain = event.charactersIgnoringModifiers ?? ""
    let ctrl = mods.contains(.control)

    switch (event.keyCode, ctrl, plain) {
    case (UInt16(kVK_Escape), _, _):
        return hide(true)
    case (UInt16(kVK_Return), _, _), (UInt16(kVK_ANSI_KeypadEnter), _, _):
        return choose()
    case (UInt16(kVK_UpArrow), _, _), (_, true, "k"):
        step(-1)
    case (UInt16(kVK_DownArrow), _, _), (_, true, "j"):
        step(1)
    case (UInt16(kVK_Delete), _, _):
        if mods.contains(.command) {
            state.query = ""
        } else if !state.query.isEmpty {
            state.query.removeLast()
        }
        state.selected = 0
    case (UInt16(kVK_ANSI_V), _, _) where mods.contains(.command):
        // cmd+V: append the clipboard, cleaned. Nothing pasted: no redraw.
        let pasted: String = NSPasteboard.general.string(forType: .string).map(pasteText) ?? ""
        if pasted.isEmpty {
            return
        }
        state.query += pasted
        state.selected = 0
    default:
        if mods.contains(.command) || mods.contains(.control) {
            return
        }
        // Arrows and function keys arrive as private-use characters.
        let raw: String = event.characters ?? ""
        let typed = raw.filter { c -> Bool in
            guard let s = c.unicodeScalars.first else {
                return false
            }
            if (0xF700...0xF8FF).contains(s.value) { return false }
            return s.properties.generalCategory != .control
        }
        if typed.isEmpty {
            return
        }
        state.query += typed
        state.selected = 0
    }

    relayout()
}

func step(_ by: Int) {
    let n = items().count
    if n > 0 {
        state.selected = (state.selected + by + n) % n
    }
}
