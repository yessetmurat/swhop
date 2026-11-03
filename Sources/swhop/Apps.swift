// The app list: scanning app folders, fuzzy matching, ranking by how often
// an app was launched from swhop.

import Foundation

struct App {
    /// The bundle's file name without `.app`.
    let name: String
    let path: String
}

enum Apps {
    /// `.app` bundles at the top of each folder entry and in its direct
    /// subfolders (`Utilities`), not inside bundles; a path to a single
    /// bundle is added as-is; the first entry wins a name.
    static func scan(_ entries: [String]) -> [App] {
        var out: [App] = []
        var seen = Set<String>()
        func add(_ path: String) {
            let component = (path as NSString).lastPathComponent
            let name = NSString(string: component).deletingPathExtension
            guard seen.insert(name).inserted else { return }
            out.append(App(name: name, path: path))
        }
        for e in entries {
            if isApp(e) {
                add(e)
                continue
            }
            for p in Self.entries(e) {
                if isApp(p) {
                    add(p)
                } else if isDir(p) {
                    for q in Self.entries(p) where isApp(q) { add(q) }
                }
            }
        }
        out.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return out
    }

    /// Fuzzy match: the query's letters in order, case-insensitive, scored
    /// by the best alignment. Points per letter: 1, +5 right after the
    /// previous match, +5 at a word start, +8 at the start of the name.
    /// nil if a letter is missing.
    static func score(_ query: String, _ name: String) -> Int? {
        let n = Array(name)
        let q = Array(query.lowercased())
        guard let first = q.first else { return 0 }
        func eq(_ j: Int, _ c: Character) -> Bool {
            n[j].lowercased() == String(c)
        }
        func points(_ j: Int) -> Int {
            let word = j == 0
                || "-._ ".contains(n[j - 1])
                || (n[j - 1].isLowercase && n[j].isUppercase)
            return 1 + (word ? 5 : 0) + (j == 0 ? 8 : 0)
        }
        // best[j]: best score of the query so far with its last letter at j.
        var best: [Int?] = (0..<n.count).map { j in eq(j, first) ? points(j) : nil }
        for c in q.dropFirst() {
            best = (0..<n.count).map { j -> Int? in
                var prev: Int? = nil
                for k in 0..<j {
                    guard let b = best[k] else { continue }
                    let cand = b + (k + 1 == j ? 5 : 0)
                    if prev == nil || cand > prev! { prev = cand }
                }
                guard let p = prev, eq(j, c) else { return nil }
                return p + points(j)
            }
        }
        return best.compactMap { $0 }.max()
    }

    /// Matching apps, best match first; launch counts order equal matches
    /// (short queries: `t` lists the T apps you launch most first), then
    /// names. Each hit carries its index into `apps` and its score: the
    /// command slot needs them, the panel needs the index.
    static func rank(_ query: String, _ apps: [App], _ counts: [String: UInt32]) -> [(index: Int, score: Int)] {
        guard !query.isEmpty else { return [] }
        var hits: [(index: Int, count: UInt32, score: Int)] = []
        for (i, a) in apps.enumerated() {
            guard let s = score(query, a.name) else { continue }
            hits.append((i, counts[a.path] ?? 0, s))
        }
        hits.sort { x, y in
            if x.score != y.score { return x.score > y.score }
            if x.count != y.count { return x.count > y.count }
            return apps[x.index].name.localizedStandardCompare(apps[y.index].name) == .orderedAscending
        }
        return hits.map { (index: $0.index, score: $0.score) }
    }

    /// Where a synthetic command row (scored by `score` against `label`)
    /// goes among `appScores` (each shown app's score, best first): before
    /// the first app it outscores, after apps it ties. nil if the query is
    /// empty or the command does not match.
    static func commandSlot(_ query: String, _ label: String, _ appScores: [Int]) -> Int? {
        guard !query.isEmpty, let c = score(query, label) else { return nil }
        for (i, s) in appScores.enumerated() where c > s { return i }
        return appScores.count
    }

    /// `<count>\t<app path>` per line; broken lines are skipped.
    static func parseCounts(_ text: String) -> [String: UInt32] {
        var out: [String: UInt32] = [:]
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            guard let tab = line.firstIndex(of: "\t") else { continue }
            guard let n = UInt32(line[..<tab]) else { continue }
            out[String(line[line.index(after: tab)...])] = n
        }
        return out
    }

    static func formatCounts(_ c: [String: UInt32]) -> String {
        c.sorted { $0.key < $1.key }
            .map { "\($0.value)\t\($0.key)\n" }
            .joined()
    }

    static func countsPath() -> String {
        homeDir() + "/Library/Application Support/swhop/counts"
    }

    // MARK: - Helpers

    static func homeDir() -> String {
        ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
    }

    private static func entries(_ dir: String) -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: dir))
            .map { $0.sorted().map { dir + "/" + $0 } }
            .flatMap { $0 } ?? []
    }

    private static func isApp(_ path: String) -> Bool {
        (path as NSString).pathExtension == "app" && isDir(path)
    }

    private static func isDir(_ path: String) -> Bool {
        var d: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &d) && d.boolValue
    }
}
