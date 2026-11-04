//
//  Panel.swift
//  swhop
//
//  Created by Yesset Murat on 31.10.2026.
//

// The panel: built once and toggled by the hotkey. Typing filters apps
// (Enter opens one) or evaluates arithmetic (Enter copies it). The look
// defaults to the Megan theme and can be changed in
// `~/.config/swhop/swhop.toml`.

import AppKit
import SwhopCore

enum Panel {

    static func run() -> Never {
        let app = NSApplication.shared
        // No Dock icon, no menu bar of its own.
        app.setActivationPolicy(.accessory)

        let config = ConfigLoader.load()
        applyTheme(config.theme)
        build()

        // Icons cost a few ms each the first time: load them now, not while
        // the user types. Apps installed later get theirs when first shown.
        for a in Apps.scan(config.apps) {
            state.icons[a.path] = NSWorkspace.shared.icon(forFile: a.path)
        }

        if let err = Hotkey.register(toggle) {
            logErr("swhop: " + err)
            exit(1)
        }
        app.run()
        exit(0)
    }
}

/// The hotkey: open, or close if open.
func toggle() {
    if state.shown {
        hide(true)
    } else {
        show()
    }
}

func build() {
    // Always tall enough for every row, transparent below the ones shown:
    // resizing while typing makes the window jump.
    let frame = NSRect(
        x: 0,
        y: 0,
        width: theme.width,
        height: height(items: ROWS)
    )
    let panel = SwhopPanel(
        contentRect: frame,
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    panel.isReleasedWhenClosed = false
    panel.hidesOnDeactivate = false
    // Above other windows and the menu bar.
    panel.level = .popUpMenu
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    let view = SwhopView(frame: frame)
    panel.contentView = view
    ui = (panel, view)
}

func show() {
    let config = ConfigLoader.load()
    applyTheme(config.theme)
    state.apps = Apps.scan(config.apps)
    state.counts = (try? String(contentsOfFile: Paths.launchCounts(), encoding: .utf8)).map(LaunchCounts.parse) ?? [:]
    state.query = ""
    state.selected = 0
    state.prev = NSWorkspace.shared.frontmostApplication

    // The display with the pointer, panel top at a quarter of its height.
    let m = NSEvent.mouseLocation
    let screen = NSScreen.screens.first(where: { $0.frame.contains(m) }) ?? NSScreen.screens.first
    guard let screen else {
        return
    }
    state.shown = true
    let sf = screen.frame
    let top = sf.minY + sf.size.height * 0.75

    if let (panel, view) = ui {
        let h = height(items: ROWS)
        let frame = NSRect(
            x: sf.minX + (sf.size.width - theme.width) / 2.0,
            y: top - h,
            width: theme.width,
            height: h
        )
        panel.setFrame(frame, display: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(view)
        view.display()
        panel.invalidateShadow()
    }
}

/// Close; with `refocus`, give focus back to the app that had it (Esc,
/// cmd+space, a copied result). Not after a click elsewhere: that click
/// chose where focus goes.
func hide(_ refocus: Bool) {
    guard state.shown else {
        return
    }

    state.shown = false
    let prev = state.prev
    state.prev = nil
    ui?.panel.orderOut(nil)

    if refocus, let p = prev {
        p.activate(options: [])
    }
}

/// Redraw, and the shadow with it (it follows what is drawn).
func relayout() {
    ui?.view.display()
    ui?.panel.invalidateShadow()
}
