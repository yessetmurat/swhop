// swhop: a light app launcher and calculator for macOS on cmd+space.
// `swhop` runs it; `swhop --start-service` and friends manage a launchd
// agent; `swhop --test` runs the self-check.

import Foundation

let usage = "usage: swhop | swhop --start-service|--stop-service|--restart-service|--uninstall-service | swhop --test"

let args = Array(CommandLine.arguments.dropFirst())

if args.isEmpty {
    Panel.run()
}
if args == ["--test"] {
    SelfCheck.run()
}
// `-service` dispatch: one arg ending in `-service`.
if args.count == 1, let a = args.first, a.hasSuffix("-service") {
    Service.handle(a)
}
logErr(usage)
exit(2)
