# swhop

A light app launcher and calculator for macOS on cmd+space, written in
Swift. Typing filters apps (Enter opens one) or evaluates arithmetic
(Enter copies the result).

## Build

```
swift build -c release
```

No dependencies: Swift Package Manager, Foundation/AppKit/Carbon only.

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

Install a launchd agent (restarted if it dies):

```
.build/release/swhop --start-service
.build/release/swhop --stop-service
.build/release/swhop --restart-service
.build/release/swhop --uninstall-service
```

The agent is `local.swhop` in `~/Library/LaunchAgents`; its logs go to
`~/Library/Logs/swhop/{out,err}.log`.

## App sources

Where apps are found is set in `~/.config/swhop/apps`: one entry per
line, a folder or a single `.app` bundle. Folders are scanned at the top
level and one level down (not inside bundles); a bundle entry is added
as-is. The first entry wins a name. Blank lines and `#` comments are
skipped; a leading `~` is the home dir. An existing file replaces the
defaults completely; without the file the defaults are:

```
/Applications
/System/Applications
~/Applications
```

Example:

```
# Folders: .app bundles at the top level and one subfolder down.
/Applications
/System/Applications
~/Applications
# Single apps.
/System/Library/CoreServices/Applications/Keychain Access.app
```

The list is rescanned every time the panel opens, so edits apply without
a restart.

## Theme

The panel's colors, corner radii, font and width can be changed in
`~/.config/swhop/theme`: one `key = value` per line. A line whose first
non-blank character is `#` is a comment; a `#` later in the line is
part of the value. Colors are `RRGGBB` or `RRGGBBAA` hex with an
optional leading `#` (6 digits mean opaque). A bad line is logged to
stderr and skipped; an unknown `font` name falls back to the system
font without a message; a missing file means the default look. The
file is reread every time the panel opens, so edits apply without a
restart.

| key | default | meaning |
|---|---|---|
| `window` | `2D2D2DFF` | panel background |
| `field` | `00000026` | search field background |
| `selection` | `3E3E3E7F` | selected row background |
| `text` | `FFFFFFFF` | query, caret, selected row label, quit mark |
| `row_text` | `FFFFFFE5` | other row labels |
| `window_radius` | `12` | panel corners |
| `radius` | `8` | field and selection corners |
| `font` | `IBMPlexSans` | PostScript font name |
| `field_font_size` | `16` | query font size |
| `row_font_size` | `12` | row font size |
| `width` | `480` | panel width |

Example:

```
# A light theme.
window = F5F5F5FF
field = 0000000F
selection = 0000001A
text = 000000FF
row_text = 000000CC
font = Menlo
width = 560
```

## How ranking works

Fuzzy match: the query's letters in order, case-insensitive, scored by
the best alignment (points per letter, bonuses for word starts and the
start of the name). Among equal matches, launch counts break the tie,
then the name (case-insensitive). Launch counts are kept in
`~/Library/Application Support/swhop/counts`.

## Self-check

```
.build/release/swhop --test
```

Runs the asserts over the pure logic (calc, fuzzy scoring, ranking,
source parsing, the agent's plist) and prints `ok` on success.

## License

MIT, see `LICENSE`.
