---
name: go-oat
description: Scaffold the oat.ink HTML+CSS UI library into a Go web app with embedded assets for zero-dependency binaries. Internal skill used by golang-pro agent when building minimal HTML UIs without a JS framework.
user-invocable: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(go:*), Bash(curl:*), Bash(mkdir:*), Bash(shasum:*), Bash(sha256sum:*)
---

# Oat UI for Go

Scaffold [oat](https://github.com/knadh/oat) — an ultra-lightweight semantic HTML + CSS component library (~8KB, MIT, zero runtime deps) — into a Go web app. Assets are **always** downloaded at setup time and embedded into the binary with `//go:embed`. The running binary never fetches anything from the network.

Oat styles native HTML elements (`<button>`, `<input>`, `<dialog>`, `<table>`, forms, etc.) without classes, supports dark mode via `prefers-color-scheme`, and uses a small JS file only for Web Components (dialogs, tooltips, tabs, toasts).

## When to Use

- User asks for a simple HTML UI, admin panel, or settings page in a Go app without a JS framework
- User mentions "minimalist", "no JS toolchain", "vanilla HTML", "semantic HTML", or explicitly names oat
- `html/template`, `templ`, or `*.gohtml` files exist but no CSS framework is present
- `oat.min.css` or `oat.min.js` are already in the repo and need wiring or upgrading

## Prerequisites

1. **go.mod exists**: The project must be a Go module. Abort otherwise.
2. **Go ≥ 1.16**: `//go:embed` requires Go 1.16+. Read the `go` directive in `go.mod` to verify.
3. **HTTP server present or planned**: oat renders HTML served over HTTP. Confirm with the user if unclear.

## Core Principle

**Zero runtime dependencies.** The binary must run offline after `go build`. Never reference `unpkg.com`, `cdn.jsdelivr.net`, or `raw.githubusercontent.com` from rendered HTML. Download once at setup time, embed, commit, ship.

## Asset Source

Use the pinned npm-on-jsdelivr URL — it is immutable per version and fetched only at setup:

```
https://cdn.jsdelivr.net/npm/@knadh/oat@<VERSION>/oat.min.css
https://cdn.jsdelivr.net/npm/@knadh/oat@<VERSION>/oat.min.js
```

**Do not** use:
- `raw.githubusercontent.com/knadh/oat/gh-pages/...` — `gh-pages` is a moving target
- `unpkg.com/@knadh/oat/...` without a version — resolves to `latest`, not reproducible
- `github.com/knadh/oat/releases/...` — release tarballs do not contain the minified dist files

To find the current version: `curl -s https://api.github.com/repos/knadh/oat/releases/latest | grep tag_name`

## Workflow: Scaffold oat into a Go project

### Step 1: Choose asset layout

| Project shape | Recommended layout |
|---|---|
| Flat app (`main.go` at root) | `web/static/oat.min.css`, `web/static/oat.min.js`, `web/embed.go` |
| `internal/` + layered (`cmd/...`, `internal/...`) | `internal/ui/static/oat.min.css`, `internal/ui/embed.go` |
| Library with optional web UI | `web/ui/static/...` in a separate package |

Prefer `internal/ui/` when there is already an `internal/` tree. Otherwise use `web/`.

### Step 2: Download pinned assets

```bash
VERSION=v0.6.0  # confirm latest via the release API before running
DEST=internal/ui/static
mkdir -p "$DEST"
curl -sSLo "$DEST/oat.min.css" "https://cdn.jsdelivr.net/npm/@knadh/oat@${VERSION#v}/oat.min.css"
curl -sSLo "$DEST/oat.min.js"  "https://cdn.jsdelivr.net/npm/@knadh/oat@${VERSION#v}/oat.min.js"
```

Note: the jsdelivr npm path uses a bare version like `0.6.0` (no `v` prefix), while GitHub release tags use `v0.6.0`. The `${VERSION#v}` strips the `v`.

### Step 3: Record the version and checksums

Create a `OAT_VERSION` file (or header comment in `embed.go`) so upgrades are traceable:

```
oat v0.6.0
oat.min.css sha256: <output of shasum -a 256 oat.min.css>
oat.min.js  sha256: <output of shasum -a 256 oat.min.js>
```

### Step 4: Create the embed package

```go
// internal/ui/embed.go
package ui

import "embed"

// Static holds oat's CSS and JS. See ../../OAT_VERSION for the pinned release.
//
//go:embed static/oat.min.css static/oat.min.js
var Static embed.FS
```

If a `theme.css` is added later (see Theming), extend the directive:

```go
//go:embed static/oat.min.css static/oat.min.js static/theme.css
```

### Step 5: Wire the static file handler

```go
// in route setup (main.go or internal/server/routes.go)
import (
    "io/fs"
    "net/http"

    "yourmod/internal/ui"
)

func registerStatic(mux *http.ServeMux) {
    sub, err := fs.Sub(ui.Static, "static")
    if err != nil {
        panic(err) // compile-time constant; impossible at runtime
    }
    mux.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.FS(sub))))
}
```

### Step 6: Create a minimal oat-styled template

```html
<!-- internal/ui/templates/index.html -->
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{{.Title}}</title>
  <link rel="stylesheet" href="/static/oat.min.css">
  <script src="/static/oat.min.js" defer></script>
</head>
<body>
  <main>
    <h1>{{.Title}}</h1>
    <form method="post" action="/save">
      <label>Name <input name="name" required></label>
      <label>Email <input type="email" name="email"></label>
      <button type="submit">Save</button>
    </form>
    <button onclick="document.getElementById('about').showModal()">About</button>
    <dialog id="about">
      <h2>About</h2>
      <p>Styled by oat — no classes needed.</p>
      <button onclick="this.closest('dialog').close()">Close</button>
    </dialog>
  </main>
</body>
</html>
```

Embed templates alongside assets:

```go
//go:embed templates/*.html
var Templates embed.FS
```

Parse at startup with `template.ParseFS(ui.Templates, "templates/*.html")`.

### Step 7: Verify zero-dependency build

```bash
go build -o app ./...
./app &
curl -sI http://localhost:PORT/static/oat.min.css | head -1   # expect 200
# kill the app, disable network, rerun — it still works
```

## Workflow: Upgrade oat

1. Check the latest release: `curl -s https://api.github.com/repos/knadh/oat/releases/latest | grep tag_name`
2. Re-run Step 2 with the new version
3. Update `OAT_VERSION` and checksums (Step 3)
4. Run the app; review the [oat changelog](https://github.com/knadh/oat/releases) for breaking changes (oat is pre-v1; breaking changes are expected)
5. Commit as a single changeset so the bump is traceable

## Pattern: Pair with templ

If `**/*.templ` files exist, render via templ components instead of `html/template`. The embed and handler steps are unchanged — only the rendering layer differs.

```go
// internal/ui/layout.templ
package ui

templ Layout(title string) {
    <!doctype html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <title>{ title }</title>
        <link rel="stylesheet" href="/static/oat.min.css">
        <script src="/static/oat.min.js" defer></script>
    </head>
    <body>
        <main>
            { children... }
        </main>
    </body>
    </html>
}
```

If templ is not yet set up in the project, defer to the **go-tool** skill to add it via `go get -tool github.com/a-h/templ/cmd/templ`, then return here.

## Pattern: Theming

Oat themes via CSS custom properties. Override them in a sibling `theme.css` loaded after `oat.min.css`:

```css
/* internal/ui/static/theme.css */
:root {
  --oat-primary: #4a6cf7;
  --oat-radius: 4px;
  --oat-font: system-ui, sans-serif;
}
```

```html
<link rel="stylesheet" href="/static/oat.min.css">
<link rel="stylesheet" href="/static/theme.css">
```

Add `theme.css` to the `//go:embed` directive. For the full list of custom properties, inspect `oat.min.css` or see the [customization docs](https://oat.ink/).

## Anti-Patterns

| Don't | Do |
|---|---|
| `<link rel="stylesheet" href="https://unpkg.com/@knadh/oat/oat.min.css">` in rendered HTML | Download once at setup, embed, serve from `/static/` |
| `wget .../gh-pages/oat.min.css` for the pinned version | `curl .../npm/@knadh/oat@X.Y.Z/oat.min.css` — gh-pages is mutable |
| `npm install @knadh/oat` and a Node build step | Pure Go workflow — download the two files, embed, done |
| Unminified sources shipped in the binary | Always use `oat.min.css` / `oat.min.js` |
| Overriding oat class names with custom CSS classes | Oat styles semantic HTML — use `<button>`, not `<button class="btn-primary">` |
| Skipping `defer` on the `<script>` tag | `defer` is required — oat's JS expects the DOM to be parsed |

## Reference Layout

A completed setup looks like:

```
.
├── go.mod
├── main.go
├── OAT_VERSION
└── internal/
    └── ui/
        ├── embed.go
        ├── render.go
        ├── static/
        │   ├── oat.min.css
        │   ├── oat.min.js
        │   └── theme.css          (optional)
        └── templates/
            ├── layout.html
            └── index.html
```

## Error Handling

| Condition | Action |
|---|---|
| No `go.mod` | Abort: "Not a Go module — run `go mod init` first." |
| Go version `< 1.16` | Abort: "`//go:embed` requires Go 1.16+. Update the `go` directive in go.mod." |
| `curl` returns non-200 for an asset | Verify the version exists on npm: `https://www.npmjs.com/package/@knadh/oat` |
| User insists on CDN at runtime | Push back: the skill's reason for existing is offline, zero-dep binaries. If they still want CDN, decline and let them wire it manually without this skill. |
| Oat assets already present in the repo | Skip download; verify checksums against `OAT_VERSION` and proceed to wire the handler and template. |
