// The panel: built once and toggled by the hotkey. Typing filters apps
// (Enter opens one) or evaluates arithmetic (Enter copies it). The look
// defaults to the Alfred theme "Megan" and can be changed in
// `~/.config/swhop/theme`.

import AppKit
import Carbon

let PAD: CGFloat = 10.0
let FIELD_PAD_X: CGFloat = 8.0
let FIELD_PAD_Y: CGFloat = 12.0
let SPACING: CGFloat = 8.0
let ICON: CGFloat = 24.0
let ICON_PAD: CGFloat = 4.0
let ROW_PAD_Y: CGFloat = 6.0
let ROW_H: CGFloat = ICON + 2.0 * ROW_PAD_Y
let ROWS = 8

/// Its icon marks the calculator's row.
let CALCULATOR = "/System/Applications/Calculator.app"

/// The command row's label; fuzzy-matched like an app name.
let QUIT_ALL = "Quit All Apps"

/// Cache key for the command's icon; a NUL keeps it clear of any app path.
let QUIT_ICON_KEY = "\0quit-all-apps"

/// Side of the command's mark, smaller than app icons.
let QUIT_ICON: CGFloat = 12.0

/// A result row: the calculator's answer, the "quit all apps" command, or
/// an app (index into `state.apps`).
enum Item {
    case calc(String)
    case quit
    case app(Int)
}

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
var fieldFont = panelFont(["IBMPlexSans", "IBMPlexSans-Regular"], 16.0)
var rowFont = panelFont(["IBMPlexSans", "IBMPlexSans-Regular"], 12.0)

/// The colors, fonts and width from the theme file; the fonts are rebuilt
/// and the quit mark dropped so it is redrawn in the new text color.
func applyTheme(_ t: Theme) {
    theme = t
    fieldFont = panelFont([t.font, t.font + "-Regular"], t.fieldFontSize)
    rowFont = panelFont([t.font, t.font + "-Regular"], t.rowFontSize)
    state.icons[QUIT_ICON_KEY] = nil
}

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

enum Panel {
    static func run() -> Never {
        let app = NSApplication.shared
        // No Dock icon, no menu bar of its own.
        app.setActivationPolicy(.accessory)
        applyTheme(Theme.load())
        build()
        // Icons cost a few ms each the first time: load them now, not while
        // the user types. Apps installed later get theirs when first shown.
        for a in Apps.scan(Apps.sources()) {
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
    let frame = NSRect(x: 0, y: 0, width: theme.width, height: height(items: ROWS))
    let panel = SwhopPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
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
    applyTheme(Theme.load())
    state.apps = Apps.scan(Apps.sources())
    state.counts = (try? String(contentsOfFile: Apps.countsPath(), encoding: .utf8)).map(Apps.parseCounts) ?? [:]
    state.query = ""
    state.selected = 0
    state.prev = NSWorkspace.shared.frontmostApplication
    // The display with the pointer, panel top at a quarter of its height.
    let m = NSEvent.mouseLocation
    let screen = NSScreen.screens.first(where: { $0.frame.contains(m) }) ?? NSScreen.screens.first
    guard let screen else { return }
    state.shown = true
    let sf = screen.frame
    let top = sf.minY + sf.size.height * 0.75
    if let (panel, view) = ui {
        let h = height(items: ROWS)
        panel.setFrame(NSRect(x: sf.minX + (sf.size.width - theme.width) / 2.0, y: top - h, width: theme.width, height: h), display: true)
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
    let prev: NSRunningApplication?
    if !state.shown {
        return
    }
    state.shown = false
    prev = state.prev
    state.prev = nil
    ui?.panel.orderOut(nil)
    if refocus, let p = prev {
        p.activate(options: [])
    }
}

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
            guard let s = c.unicodeScalars.first else { return false }
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

/// Clean a clipboard paste for the query: trim the ends, fold newlines and
/// tabs to single spaces, drop the other control characters, and cut the
/// result to 256 characters.
func pasteText(_ s: String) -> String {
    let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
    let chars = trimmed.map { c in c.isNewline || c == "\t" ? " " : c }
    let cleaned = chars.filter { c -> Bool in
        guard let s = c.unicodeScalars.first else { return false }
        return s.properties.generalCategory != .control
    }
    return String(cleaned.prefix(256))
}

func step(_ by: Int) {
    let n = items().count
    if n > 0 {
        state.selected = (state.selected + by + n) % n
    }
}

/// Enter: open the app, or copy the result.
func choose() {
    let items = items()
    guard items.indices.contains(state.selected) else { return }
    switch items[state.selected] {
    case .calc(let v):
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(v, forType: .string)
        hide(true)
    case .app(let i):
        let path = state.apps[i].path
        state.counts[path, default: 0] += 1
        let counts = Apps.formatCounts(state.counts)
        let file = Apps.countsPath()
        do {
            let parent = (file as NSString).deletingLastPathComponent
            if !parent.isEmpty {
                try FileManager.default.createDirectory(atPath: parent, withIntermediateDirectories: true)
            }
            try counts.write(toFile: file, atomically: true, encoding: .utf8)
        } catch {
            logErr("swhop: cannot save " + file + ": " + error.localizedDescription)
        }
        hide(false)
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: path),
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, error in
            if let error {
                logErr("swhop: cannot open \(path): \(error.localizedDescription)")
            }
        }
    case .quit:
        hide(false)
        quitAll()
    }
}

/// Gracefully quit every visible app, keeping Finder and swhop itself. Asks
/// once first; then like pressing cmd+Q in each, so apps with unsaved work
/// prompt rather than die.
func quitAll() {
    let me = ProcessInfo.processInfo.processIdentifier
    let targets = NSWorkspace.shared.runningApplications.filter {
        $0.activationPolicy == .regular
            && $0.processIdentifier != me
            && $0.bundleIdentifier != "com.apple.finder"
    }
    guard !targets.isEmpty, confirm(targets.count) else {
        return
    }
    for app in targets {
        app.terminate()
    }
}

/// Modal "Quit N apps?" with Quit / Cancel; true if the user confirms.
func confirm(_ n: Int) -> Bool {
    let alert = NSAlert()
    alert.messageText = "Quit all apps?"
    let app = n == 1 ? "app" : "apps"
    alert.informativeText = "\(n) \(app) will be asked to quit."
    alert.addButton(withTitle: "Quit")
    alert.addButton(withTitle: "Cancel")
    // Accessory app: bring the alert to the front so it is not hidden.
    if #available(macOS 14.0, *) {
        NSApplication.shared.activate()
    } else {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    return alert.runModal() == .alertFirstButtonReturn
}

/// The calculator's answer first (when the query is arithmetic), then the
/// best matching apps.
func items() -> [Item] {
    var out: [Item] = []
    if let v = Calc.eval(state.query) {
        out.append(.calc(Calc.format(v)))
    }
    let ranked = Apps.rank(state.query, state.apps, state.counts)
    let slot = Apps.commandSlot(state.query, QUIT_ALL, ranked.map { $0.score })
    for (k, hit) in ranked.enumerated() {
        if slot == k {
            out.append(.quit)
        }
        out.append(.app(hit.index))
    }
    if slot == ranked.count {
        out.append(.quit)
    }
    return Array(out.prefix(ROWS))
}

/// Redraw, and the shadow with it (it follows what is drawn).
func relayout() {
    ui?.view.display()
    ui?.panel.invalidateShadow()
}

// MARK: - Geometry

func fieldH() -> CGFloat {
    textSize("Ag", fieldFont).height + 2.0 * FIELD_PAD_Y
}

func rowsTop() -> CGFloat {
    PAD + fieldH() + SPACING
}

func height(items n: Int) -> CGFloat {
    2.0 * PAD + fieldH() + (n > 0 ? SPACING + CGFloat(n) * ROW_H : 0.0)
}

