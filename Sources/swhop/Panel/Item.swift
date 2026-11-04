//
//  Item.swift
//  swhop
//
//  Created by Yesset Murat on 04.11.2026.
//

// The result rows for the current query.

import SwhopCore

/// Its icon marks the calculator's row.
let CALCULATOR = "/System/Applications/Calculator.app"

/// The command row's label; fuzzy-matched like an app name.
let QUIT_ALL = "Quit All Apps"

/// Cache key for the command's icon; a NUL keeps it clear of any app path.
let QUIT_ICON_KEY = "\0quit-all-apps"

/// A result row: the calculator's answer, the "quit all apps" command, or
/// an app (index into `state.apps`).
enum Item {

    case calc(String)
    case quit
    case app(Int)
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
