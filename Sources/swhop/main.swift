// swhop: a light app launcher and calculator for macOS on cmd+space.
// `swhop` runs it; `swhop --test` runs the self-check. At login it is started
// by `brew services`.

import Foundation

let usage = "usage: swhop | swhop --test"

let args = Array(CommandLine.arguments.dropFirst())

if args.isEmpty {
    Panel.run()
}
if args == ["--test"] {
    SelfCheck.run()
}
logErr(usage)
exit(2)
