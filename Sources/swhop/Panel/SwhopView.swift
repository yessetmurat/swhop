//
//  SwhopView.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

import AppKit

/// The panel's content: draws it and takes its keys and clicks.
final class SwhopView: NSView {

    var drawMs: Double = 0

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let t = Date()
        drawPanel(self.bounds)
        drawMs = Date().timeIntervalSince(t) * 1000
    }

    override func keyDown(with event: NSEvent) {
        let t = Date()
        key(event)

        let ms = Date().timeIntervalSince(t) * 1000
        if ms > 8 {
            logErr(String(format: "swhop: slow key: %dms (draw %dms)", Int(ms), Int(drawMs)))
        }
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let row = floor((p.y - rowsTop()) / ROW_H)
        let n = items().count

        if p.y > height(items: n) {
            // The transparent part below the rows: a click outside.
            hide(false)
        } else if row >= 0.0, Int(row) < n {
            state.selected = Int(row)
            choose()
        }
    }
}
