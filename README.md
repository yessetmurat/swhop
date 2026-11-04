# swhop

A light app launcher and calculator for macOS on cmd+space, written in
Swift. Typing filters apps (Enter opens one) or evaluates arithmetic
(Enter copies the result).

## Build

```
swift build -c release
```

Swift Package Manager, Foundation/AppKit/Carbon, and TOMLKit for the config
(fetched by SwiftPM on the first build).

## Run

```
.build/release/swhop
```

The hotkey is cmd+space; type a query, Enter opens the selected app or
copies the result, Esc closes and refocuses the previous app, arrows or
ctrl+j/k move the selection. cmd+v appends the clipboard text to the
query (newlines and tabs become spaces, cut to 256 characters), and
cmd+delete clears the query.

The calculator supports `+ - * /`, parentheses, decimals (`.` or `,`), an
optional leading minus, and Alfred-style percent: `200 + 10%` is 220. A
bare number is not a calculation.

`quit all apps` is a built-in command: it asks once, then asks every
visible app to quit (Finder and swhop itself are kept).

## Launch at login

`brew services start swhop` starts it now and at login, and restarts it if
it crashes; `brew services stop swhop` stops it. Logs go to
`$(brew --prefix)/var/log/swhop.log`.

## Config

Everything is set in `~/.config/swhop/swhop.toml`, in the format swwm uses:
kebab-case keys, colors as `"0xAARRGGBB"`, fonts as `"Family:Style:Size"`.
swhop writes the file with the defaults below when it is missing. It is
read every time the panel opens, so edits apply without a restart. A bad,
mistyped or unknown key is logged to stderr and keeps its default; a file
that does not parse is left as it is and the defaults are used.

```toml
# Where apps are found: folders (scanned at the top level and one level
# down, not inside bundles) or single .app bundles; a leading ~ is the
# home dir; the first entry wins a name.
apps = [
  "/Applications",
  "/System/Applications",
  "~/Applications",
]

# The panel look (the Megan theme).
[theme]
window = "0xFF2D2D2D"           # panel background
field = "0x26000000"            # search field background
selection = "0x7F3E3E3E"        # selected row background
text = "0xFFFFFFFF"             # query, caret, selected row label, quit mark
row-text = "0xE5FFFFFF"         # other row labels
window-radius = 12              # panel corners
radius = 8                      # field and selection corners
field-font = "IBM Plex Sans:Regular:16"
row-font = "IBM Plex Sans:Regular:12"
width = 480                     # panel width
```

A font whose family or style is not installed falls back to the system
font at that size.

## How ranking works

Fuzzy match: the query's letters in order, case-insensitive, scored by
the best alignment (points per letter, bonuses for word starts and the
start of the name). Among equal matches, launch counts break the tie,
then the name (case-insensitive). Launch counts are kept in
`~/Library/Application Support/swhop/counts`.

## Tests

```
swift test
```

Swift Testing over the pure logic in `SwhopCore` (calc, fuzzy scoring,
ranking, launch counts, config parsing, paste cleanup).

## License

MIT, see `LICENSE`.
