# VHS Tape Cheatsheet

Reference for authoring `.tape` files for [VHS](https://github.com/charmbracelet/vhs)
(Charmbracelet). Only the directives listed here exist — VHS fails the whole tape on an
unknown keyword, so never invent syntax.

## Runtime requirements

VHS renders by driving a real terminal and encoding the frames. Three binaries are involved:

| Binary | Required for | Install |
|---|---|---|
| `vhs` | everything | `mise use vhs@0.11.0`, `brew install vhs`, `go install github.com/charmbracelet/vhs@latest` |
| `ttyd` | rendering (headless terminal) | `brew install ttyd` |
| `ffmpeg` | rendering (frame encoding) | `brew install ffmpeg` |

Writing a tape needs only `vhs`. Producing a GIF needs all three. `vhs validate <file>.tape`
parses without rendering, so it works even when `ttyd`/`ffmpeg` are missing — always run it
before attempting a render.

Note: `vhs themes` prints to **stderr**, so capture it with `2>&1`.

## Tape structure

```tape
# Header comment: what this demo shows and how to regenerate it.

Output doc/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 700
Set Padding 20

Hide
Type "<setup that must not appear on screen>" Enter
Show

Type "<visible command>" Enter
Sleep 2s
```

Order matters: `Output` and every `Set` must come **before** the first `Type`/`Enter`.

## Directives

### Output

```tape
Output demo.gif          # GIF (the usual choice for READMEs)
Output demo.mp4          # MP4
Output demo.webm         # WebM
Output frames/           # raw PNG frames (trailing slash)
```

Paths are relative to the **working directory VHS is run from**, not to the tape file. A tape at
`doc/demo.tape` rendered by `vhs doc/demo.tape` from the repo root must therefore say
`Output doc/demo.gif`.

Multiple `Output` lines emit multiple formats from one recording.

### Require

```tape
Require jwt-cli
Require docker
```

Aborts before recording if the binary is **not on `$PATH`**. Useful for tools the user installs
globally; useless for a binary built into the repo root, which is not on `$PATH` — use the
`Hide` PATH preamble below instead.

### Set

| Directive | Example | Notes |
|---|---|---|
| `Set Shell` | `Set Shell "bash"` | Pin it. Inheriting the author's `zsh` + prompt theme makes tapes unreproducible. |
| `Set FontSize` | `Set FontSize 18` | 16-22 for wide demos, 28-32 for narrow ones. |
| `Set FontFamily` | `Set FontFamily "JetBrains Mono"` | Must be installed on the rendering machine; omit unless you know it is. |
| `Set Width` | `Set Width 1200` | Pixels. 1200 is a good README width. |
| `Set Height` | `Set Height 700` | Pixels. Must fit the tallest output, or lines scroll away. |
| `Set Padding` | `Set Padding 20` | Pixels of inner padding. |
| `Set Margin` | `Set Margin 40` | Outer margin around the window. |
| `Set MarginFill` | `Set MarginFill "#674EFF"` | Colour or image path behind the margin. |
| `Set Theme` | `Set Theme "Catppuccin Mocha"` | See themes below. |
| `Set Framerate` | `Set Framerate 50` | Default 50. Lowering shrinks the file. |
| `Set PlaybackSpeed` | `Set PlaybackSpeed 0.5` | <1 slows the final video down. |
| `Set TypingSpeed` | `Set TypingSpeed 50ms` | Per-character delay; default 50ms. |
| `Set LetterSpacing` | `Set LetterSpacing 1.0` | Tracking. |
| `Set LineHeight` | `Set LineHeight 1.2` | Line spacing. |
| `Set LoopOffset` | `Set LoopOffset 20%` | Frame the GIF loop starts on. |
| `Set WindowBar` | `Set WindowBar Colorful` | `Colorful`, `ColorfulRight`, `Rings`, `RingsRight`. |
| `Set BorderRadius` | `Set BorderRadius 10` | Rounded corners; pair with `Set Margin`. |
| `Set CursorBlink` | `Set CursorBlink false` | Steady cursor records more cleanly. |

### Type

```tape
Type "echo hello"
Type@10ms "fast typing"
Type `command with "double quotes" inside`
```

Types characters without pressing Enter. `@<duration>` overrides `TypingSpeed` for that line.
Quoting: `"…"`, `'…'`, and backticks all work — pick whichever does not collide with the shell
quoting inside the command. Backticks are the escape hatch for a command containing both quote
kinds.

`Type` does **not** submit — always follow with `Enter`.

### Keys

```tape
Enter
Enter 3
Enter@500ms
Backspace 5
Tab
Space
Up / Down / Left / Right
Ctrl+C
Ctrl+L
Alt+.
Escape
PageUp / PageDown
```

All accept an optional `@<duration>` and an optional repeat count.

### Sleep

```tape
Sleep 500ms
Sleep 2s
Sleep 2
```

The only way to hold a frame so the viewer can read output. Budget generously **after** a command
that prints something, sparingly between typed lines.

### Hide / Show

```tape
Hide
Type "export PATH=$PWD:$PATH" Enter
Type "clear" Enter
Show
```

Everything between `Hide` and `Show` executes but is not recorded. This is where setup belongs:
building a binary, exporting variables, seeding fixtures, clearing the screen.

### Wait

```tape
Wait                          # wait for the prompt to return
Wait@60s                      # with a timeout
Wait+Line /Done/              # wait until a line matches the regex
Wait+Screen@30s /\$ $/        # wait until the screen matches
```

More robust than a fixed `Sleep` for commands with variable duration (builds, network calls).
Still add a short `Sleep` afterwards so the result stays on screen.

### Screenshot, Copy / Paste, Source

```tape
Screenshot frame.png          # still frame at this point
Copy "text to clipboard"
Paste
Source other.tape             # inline another tape
```

## The PATH preamble idiom

Most repos build their binary into the repo root or `./bin`, neither of which is on `$PATH`.
`Require` cannot see it. Prepend the build output directory inside a `Hide` block, and flatten the
prompt while you are there so the recording does not leak the author's shell theme:

```tape
Hide
Type "export PATH=$PWD:$PATH" Enter
Type "export PS1='$ '" Enter
Type "clear" Enter
Show
```

Pair this with a task-runner dependency that builds the binary before `vhs` runs, so the tape
never records a "command not found".

## Themes

`vhs themes 2>&1` lists 348 themes on VHS 0.11.0. Names are case- and space-sensitive. Verified
dark themes that read well in both GitHub light and dark mode:

- `Catppuccin Mocha`, `Catppuccin Macchiato`, `Catppuccin Frappe`
- `Dracula`
- `GitHub Dark`
- `GruvboxDark`, `GruvboxDarkHard`
- `Builtin Solarized Dark`
- `DimmedMonokai`

Light themes: `Catppuccin Latte`, `Gruvbox Light`, `Github`.

Omitting `Set Theme` uses the VHS default, which is a safe choice. If a theme name is supplied by
the user, validate it against `vhs themes 2>&1` before writing it into the tape.

## Sizing and file weight

- `Set Width 1200` × `Set Height 700` at `FontSize 18` fits ~100 columns × ~28 rows.
- Keep the whole tape under ~45 seconds. Beyond that, viewers scrub instead of watching.
- Aim for a GIF under 5 MB. GitHub renders larger ones but they load slowly on mobile.
- To shrink a GIF: cut `Sleep` durations first, then lower `Set Framerate` (50 → 24), then reduce
  `Set Width`/`Set Height`. Lowering `FontSize` without lowering the dimensions does not help.

## Content rules for generated tapes

- **Never bake real credentials into a tape.** No live API keys, tokens, private keys, hostnames,
  or customer data. Use obviously-fake values (`demo@example.com`, `hunter2`) or generate the
  material inside a `Hide` block (`openssl rand -hex 32`).
- **Never depend on untracked or gitignored fixtures.** A tape must render from a clean clone.
  Check `.gitignore` and `git ls-files` before referencing any fixture path; if the file is not
  tracked, generate it in a `Hide` block instead.
- **Only use flags the CLI currently accepts.** Deprecated aliases print warnings that end up in
  the recording. Verify each command exits 0 before writing it into the tape.
- **Introduce each scene with a comment line** the viewer can read:
  `Type "# Encode a token" Enter` — cheap narration that makes a silent GIF legible.

## Reference

- Docs: https://github.com/charmbracelet/vhs
- Command list: https://github.com/charmbracelet/vhs#vhs-command-reference
- Themes: `vhs themes 2>&1`
- Scaffold a starter tape: `vhs new demo.tape`
- Parse without rendering: `vhs validate demo.tape`
- Record an interactive session into a tape: `vhs record > demo.tape`
