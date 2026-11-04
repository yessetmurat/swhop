//
//  PanelState.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

// The panel's state: the query, the app list, the window and the theme in
// use.

import AppKit
import SwhopCore

final class PanelState {

    var query = ""
    var apps: [App] = []
    var counts: [String: UInt32] = [:]
    var selected = 0
    var icons: [String: NSImage] = [:]
    /// The app that was frontmost when the panel opened, refocused when it
    /// is closed with Esc.
    var prev: NSRunningApplication?
    var shown = false
}

let state = PanelState()
var ui: (panel: SwhopPanel, view: SwhopView)?

var theme = Theme()
var fieldFont = panelFont(Theme().fieldFont)
var rowFont = panelFont(Theme().rowFont)

/// The colors, fonts and width from the config; the fonts are rebuilt
/// and the quit mark dropped so it is redrawn in the new text color.
func applyTheme(_ t: Theme) {
    theme = t
    fieldFont = panelFont(t.fieldFont)
    rowFont = panelFont(t.rowFont)
    state.icons[QUIT_ICON_KEY] = nil
}
