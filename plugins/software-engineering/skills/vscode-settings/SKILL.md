---
name: vscode-settings
description: Configure a project's .vscode/settings.json - 2-space indent, no symlink following, and a per-project title bar/status bar color. Use when setting up VS Code for a project or changing its window color.
argument-hint: '[color-name|#rrggbb|none] [--force] [--dry-run]'
user-invocable: true
allowed-tools: Read, Write, Edit, AskUserQuestion, Bash(git:*), Bash(awk:*)
---

# VS Code Project Settings

Write a project's `.vscode/settings.json` from the standard template -- 2-space indentation,
spaces instead of tabs, no symlink following -- plus a per-project title bar and status bar color
so several VS Code windows stay distinguishable at a glance. Settings already in the file are
merged, never clobbered.

## When to Use

- A fresh checkout has no `.vscode/settings.json` yet
- Changing a project's window color ("make this one blue")
- Removing the window color again (`none`)
- The file exists but is missing the indentation or symlink baseline

## Color Palette

The background is the chosen color; the foreground is whichever of `#15202b` or `#ffffff` contrasts
with it under WCAG. Both are resolved below, so a named color needs no computation.

| Name | Background | Foreground |
|------|------------|------------|
| `yellow` *(default)* | `#f9e64f` | `#15202b` |
| `blue` | `#1f6feb` | `#ffffff` |
| `green` | `#2ea043` | `#15202b` |
| `red` | `#da3633` | `#ffffff` |
| `purple` | `#8957e5` | `#ffffff` |
| `orange` | `#e36209` | `#15202b` |
| `cyan` | `#1f9cb8` | `#15202b` |
| `pink` | `#db61a2` | `#15202b` |

`none` (aliases `nocolor`, `no-color`) means: write the base settings only and omit
`workbench.colorCustomizations` entirely.

## Workflow

### Step 1: Parse Arguments

| Argument | Effect |
|----------|--------|
| `--dry-run` | Preview the resulting file, write nothing |
| `--force` | Skip the final confirmation |
| First bare argument | The color: a palette name, a `#rrggbb` hex, or `none` |

A color given as an argument skips Step 3. Anything else is unrecognised -- report it and stop
rather than guessing.

### Step 2: Locate the Target File

```bash
git rev-parse --show-toplevel
```

Use that path as the project root. If the command fails (not a git repository), use the current
directory. The target is `<root>/.vscode/settings.json`.

Read the file with the Read tool if it exists, and note whether it contains `//` comments -- VS
Code accepts JSONC, so a comment is valid content that must survive (Step 6).

### Step 3: Choose the Color

Skip this step when the color came from an argument.

Display the **Color Palette** table above so every option is visible, then:

```
Use AskUserQuestion:
  Question: "Which color should this project's title bar and status bar use?"
  Options:
    - "Yellow #f9e64f (template default)"
    - "Blue #1f6feb"
    - "Green #2ea043"
    - "No color - base settings only"
```

`AskUserQuestion` accepts at most four options, so the four above are the shortlist and the tool's
own *Other* choice carries the rest: say in the option descriptions that *Other* accepts any name
from the table or a raw `#rrggbb`.

If the answer is neither a palette name, a valid `#rrggbb`, nor `none`, say so and ask again.
Never substitute a nearby color.

### Step 4: Derive the Foreground

For a palette name, read `BG` and `FG` straight out of the table.

For a custom hex, `BG` is the value given and `FG` is computed from WCAG relative luminance.
Lowercase the hex, drop the leading `#`, substitute it for `f9e64f` below, and run:

```bash
awk 'BEGIN{
  h="f9e64f"; n="0123456789abcdef";
  for(i=0;i<3;i++){ c[i]=((index(n,substr(h,i*2+1,1))-1)*16+(index(n,substr(h,i*2+2,1))-1))/255 }
  for(i=0;i<3;i++){ c[i]=(c[i]<=0.03928)?c[i]/12.92:((c[i]+0.055)/1.055)^2.4 }
  L=0.2126*c[0]+0.7152*c[1]+0.0722*c[2];
  print (L>=0.2086 ? "#15202b" : "#ffffff")
}'
```

It prints the foreground to use. This form works with the BSD/macOS `awk` (no `strtonum`).

### Step 5: Build the Color Keys

With `BG` and `FG` resolved, the six keys are:

| Key | Value |
|-----|-------|
| `titleBar.activeBackground` | `BG` |
| `titleBar.activeForeground` | `FG` |
| `titleBar.inactiveBackground` | `BG` + `99` |
| `titleBar.inactiveForeground` | `FG` + `99` |
| `statusBar.background` | `BG` |
| `statusBar.foreground` | `FG` |

The `99` suffix is the alpha channel that fades the inactive window. Append it to the six-digit
hex -- do not recompute a lighter color.

### Step 6: Merge, Confirm, Write

**Base keys, always set:**

```json
"editor.tabSize": 2,
"editor.insertSpaces": true,
"search.followSymlinks": false
```

**Merge rules:**

- Keep every key already in the file that is not one of the nine this skill owns.
- The six color keys go *into* any existing `workbench.colorCustomizations` object, next to keys
  already there (for example `activityBar.background`) rather than replacing the object.
- For `none`: delete only those six keys. Drop `workbench.colorCustomizations` if it ends up
  empty; keep it if other keys remain.
- **If the file contains `//` comments**, make surgical `Edit` calls on the individual keys
  instead of rewriting the document, so the comments survive. Rewriting is only for a file that is
  plain JSON.

**A new file** is written in the template's key order, 2-space indented, with a trailing newline:

```json
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "search.followSymlinks": false,
  "workbench.colorCustomizations": {
    "titleBar.activeBackground": "#f9e64f",
    "titleBar.activeForeground": "#15202b",
    "titleBar.inactiveBackground": "#f9e64f99",
    "titleBar.inactiveForeground": "#15202b99",
    "statusBar.background": "#f9e64f",
    "statusBar.foreground": "#15202b"
  }
}
```

**Confirm before writing.** Display the resulting file, then:

```
Use AskUserQuestion:
  Question: "Overwrite existing .vscode/settings.json?"   (or "Create .vscode/settings.json?")
  Options:
    - "Yes, write the file" (proceed)
    - "No, cancel operation" (exit with message "Operation cancelled by user")
```

`--force` skips this prompt. `--dry-run` stops here and writes nothing.

Write only `.vscode/settings.json`. Never touch `extensions.json`, `launch.json`, `.gitignore`, or
any other file.

### Step 7: Report

State the path written and the color applied (name and hex, or "no color").

Then add this note whenever a color was applied:

> On macOS the custom title bar color only shows when `window.titleBarStyle` is `custom`. That is
> a user-level setting and needs a restart -- set it yourself if the title bar stays gray.

Do not write `window.titleBarStyle`: it is a user setting, not a project one.

## Error Handling

| Condition | Action |
|-----------|--------|
| File is malformed JSON | Report the parse error and the offending text; ask before overwriting |
| File contains `//` comments | Use surgical `Edit` calls, never a full rewrite |
| Unrecognised color name or malformed hex | Report it and re-prompt; never guess a nearby color |
| `.vscode/` does not exist | The Write tool creates it -- no `mkdir` needed |
| Not a git repository | Fall back to the current directory as the project root |
| Write fails | Report the path and the error; do not retry silently |
| `--dry-run` and `--force` both given | `--dry-run` wins; write nothing |

## Working Directory

If a `working_directory` context is provided (e.g., a worktree path from `feature-flow-w`), prefix
all commands with `cd <working_directory> &&` and resolve the project root from there. Otherwise,
use the current directory.
