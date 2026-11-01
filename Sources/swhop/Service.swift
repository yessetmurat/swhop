// The launchd agent `local.swhop`: started at login, restarted if it dies.

import Foundation

enum Service {
    static let label = "local.swhop"

    static func handle(_ action: String) -> Never {
        let home = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
        let path = home + "/Library/LaunchAgents/" + label + ".plist"
        let domain = "gui/\(getuid())"
        let target = domain + "/" + label
        func launchctl(_ args: [String]) {
            guard runLaunchctl(args) == 0 else {
                logErr("swhop: launchctl \(args.joined(separator: " ")) failed")
                exit(1)
            }
        }
        switch action {
        case "--start-service":
            guard let exe = executablePath() else {
                logErr("swhop: cannot resolve the executable path")
                exit(1)
            }
            guard let text = plist(label: label, exe: exe) else {
                logErr("swhop: cannot build the plist")
                exit(1)
            }
            let logs = logsDir()
            do {
                let fm = FileManager.default
                try fm.createDirectory(atPath: home + "/Library/LaunchAgents", withIntermediateDirectories: true)
                try fm.createDirectory(atPath: logs, withIntermediateDirectories: true)
                try text.write(toFile: path, atomically: true, encoding: .utf8)
            } catch {
                logErr("swhop: cannot write \(path)")
                exit(1)
            }
            if loaded(target) {
                // A kickstart alone would not reload the rewritten plist.
                launchctl(["bootout", target])
            }
            launchctl(["bootstrap", domain, path])
        case "--stop-service":
            launchctl(["bootout", target])
        case "--restart-service":
            launchctl(["kickstart", "-k", target])
        case "--uninstall-service":
            // Best effort: a stopped agent boots out clean, a missing one
            // does not fail the uninstall.
            _ = runLaunchctl(["bootout", target])
            try? FileManager.default.removeItem(atPath: path)
        default:
            logErr(usage)
            exit(2)
        }
        exit(0)
    }

    /// The agent's plist: start at load, restart on a non-zero exit, logs
    /// to `logsDir()`. nil if the plist cannot be serialized.
    static func plist(label: String, exe: String) -> String? {
        let logs = logsDir()
        let dict: [String: Any] = [
            "Label": label,
            "ProgramArguments": [exe],
            "RunAtLoad": true,
            "KeepAlive": ["SuccessfulExit": false],
            "StandardOutPath": logs + "/out.log",
            "StandardErrorPath": logs + "/err.log",
        ]
        guard let data = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// The agent's log files; the plist points there and the service creates
    /// it before bootstrapping.
    static func logsDir() -> String {
        homeDir() + "/Library/Logs/swhop"
    }

    private static func homeDir() -> String {
        ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
    }

    /// A launchctl call's exit status; -1 if launchctl itself would not start.
    /// `quiet` drops launchctl's own output.
    private static func runLaunchctl(_ args: [String], quiet: Bool = false) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = args
        if quiet {
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
        }
        do {
            try p.run()
        } catch {
            return -1
        }
        p.waitUntilExit()
        return p.terminationStatus
    }

    /// Whether the agent is loaded. Quiet: `print` dumps the whole service,
    /// or "Bad request. Could not find service" when it is not loaded.
    private static func loaded(_ target: String) -> Bool {
        runLaunchctl(["print", target], quiet: true) == 0
    }

    /// The running binary's path, symlinks resolved, for the plist.
    private static func executablePath() -> String? {
        var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
        var size = UInt32(buf.count)
        guard _NSGetExecutablePath(&buf, &size) == 0 else { return nil }
        return (String(cString: buf) as NSString).resolvingSymlinksInPath
    }
}
