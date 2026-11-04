//
//  Actions.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

// What Enter or a click does with the selected row.

import AppKit
import SwhopCore

/// Enter: open the app, or copy the result.
func choose() {
    let items = items()
    guard items.indices.contains(state.selected) else {
        return
    }

    switch items[state.selected] {
    case .calc(let v):
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(v, forType: .string)
        hide(true)
    case .app(let i):
        let path = state.apps[i].path
        state.counts[path, default: 0] += 1
        let counts = LaunchCounts.format(state.counts)
        let file = Paths.launchCounts()
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
