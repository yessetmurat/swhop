//
//  SwhopPanel.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

import AppKit

/// A borderless panel that takes keys without activating swhop, so the
/// previous app stays frontmost.
final class SwhopPanel: NSPanel {

    override var canBecomeKey: Bool { true }

    /// Clicked elsewhere: close.
    override func resignKey() {
        super.resignKey()
        hide(false)
    }
}
