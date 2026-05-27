---
name: go-bulma
description: Scaffold the Bulma CSS framework into a Go web app with embedded assets for zero-dependency binaries. Internal skill used by golang-pro agent when building HTML UIs with a classes-based CSS framework and no Node toolchain.
user-invocable: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(go:*), Bash(curl:*), Bash(mkdir:*), Bash(shasum:*), Bash(sha256sum:*)
---

# Bulma for Go

Scaffold [Bulma](https://bulma.io/documentation/) — a modern, classes-based, CSS-only framework (MIT, no JavaScript, no jQuery) — into a Go web app. Assets are **always** downloaded at setup time and embedded into the binary with `//go:embed`. The running binary never fetches anything from the network.

Bulma styles components through utility and component classes (`class="button is-primary"`, `class="column is-half"`, `class="navbar"`). Bulma 1.0+ (released Feb 2024) ships **CSS custom properties** for theming, so colors, radii, fonts, and spacing can be customized without Sass or a Node build step.

Bulma intentionally ships **zero JavaScript**, so interactive components (navbar burger, modal, dropdown, tabs) need a small amount of vanilla JS to actually work. This skill scaffolds a self-contained `app.js` covering those patterns.

## When to Use

- User asks for a polished classes-based HTML UI in a Go app without React/Vue/Angular
- User mentions "Bulma", "no Node", "no Sass", or wants a Bootstrap-like experience with a cleaner class system
- `html/template`, `templ`, or `*.gohtml` files exist but no CSS framework is present
- `bulma.min.css` is already in the repo and needs wiring or upgrading

## Prerequisites

1. **go.mod exists**: The project must be a Go module. Abort otherwise.
2. **Go ≥ 1.16**: `//go:embed` requires Go 1.16+. Read the `go` directive in `go.mod` to verify.
3. **HTTP server present or planned**: Bulma renders HTML served over HTTP. Confirm with the user if unclear.

## Core Principle

**Zero runtime dependencies.** The binary must run offline after `go build`. Never reference `cdn.jsdelivr.net`, `unpkg.com`, or `cdnjs.cloudflare.com` from rendered HTML. Download once at setup time, embed, commit, ship.

## Asset Source

Use the pinned npm-on-jsdelivr URL — it is immutable per version and fetched only at setup:

```
https://cdn.jsdelivr.net/npm/bulma@<VERSION>/css/bulma.min.css
```

Alternative (also acceptable, also pinned): the GitHub release zip:

```
https://github.com/jgthms/bulma/releases/download/<VERSION>/bulma-<VERSION>.zip
```

The zip contains `css/bulma.min.css` and the unminified sources. For a Go workflow the single `bulma.min.css` from jsdelivr is simpler.

**Do not** use:
- `unpkg.com/bulma/...` without a version — resolves to `latest`, not reproducible
- `cdnjs.cloudflare.com/.../latest/...` — same problem
- Bulma's GitHub `master` branch raw URLs — moving target, not a release artifact

To find the current version: `curl -s https://api.github.com/repos/jgthms/bulma/releases/latest | grep tag_name`

## Workflow: Scaffold Bulma into a Go project

### Step 1: Choose asset layout

| Project shape | Recommended layout |
|---|---|
| Flat app (`main.go` at root) | `web/static/bulma.min.css`, `web/static/app.js`, `web/embed.go` |
| `internal/` + layered (`cmd/...`, `internal/...`) | `internal/ui/static/bulma.min.css`, `internal/ui/embed.go` |
| Library with optional web UI | `web/ui/static/...` in a separate package |

Prefer `internal/ui/` when there is already an `internal/` tree. Otherwise use `web/`.

### Step 2: Download pinned assets

```bash
VERSION=1.0.4  # confirm latest via the release API before running
DEST=internal/ui/static
mkdir -p "$DEST"
curl -sSLo "$DEST/bulma.min.css" "https://cdn.jsdelivr.net/npm/bulma@${VERSION}/css/bulma.min.css"
```

The jsdelivr npm path uses a bare version like `1.0.4` (no `v` prefix); GitHub release tags happen to match (also `1.0.4`, no `v`).

### Step 3: Record the version and checksums

Create a `BULMA_VERSION` file (or header comment in `embed.go`) so upgrades are traceable:

```
bulma 1.0.4
bulma.min.css sha256: <output of shasum -a 256 bulma.min.css>
app.js        sha256: <output of shasum -a 256 app.js>
```

### Step 4: Create the embed package

```go
// internal/ui/embed.go
package ui

import "embed"

// Static holds Bulma's CSS and the vanilla JS helpers.
// See ../../BULMA_VERSION for the pinned release.
//
//go:embed static/bulma.min.css static/app.js
var Static embed.FS
```

If a `theme.css` is added later (see Theming), extend the directive:

```go
//go:embed static/bulma.min.css static/app.js static/theme.css
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

### Step 6: Create a minimal Bulma-styled template

```html
<!-- internal/ui/templates/index.html -->
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{{.Title}}</title>
  <link rel="stylesheet" href="/static/bulma.min.css">
  <script src="/static/app.js" defer></script>
</head>
<body>
  <nav class="navbar is-primary" role="navigation" aria-label="main navigation">
    <div class="navbar-brand">
      <a class="navbar-item" href="/"><strong>{{.Title}}</strong></a>
      <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false" data-target="mainMenu">
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
        <span aria-hidden="true"></span>
      </a>
    </div>
    <div id="mainMenu" class="navbar-menu">
      <div class="navbar-end">
        <a class="navbar-item" href="/about">About</a>
      </div>
    </div>
  </nav>

  <section class="section">
    <div class="container">
      <h1 class="title">{{.Title}}</h1>
      <form method="post" action="/save">
        <div class="field">
          <label class="label">Name</label>
          <div class="control">
            <input class="input" name="name" required>
          </div>
        </div>
        <div class="field">
          <label class="label">Email</label>
          <div class="control">
            <input class="input" type="email" name="email">
          </div>
        </div>
        <div class="field">
          <div class="control">
            <button class="button is-primary" type="submit">Save</button>
            <button class="button" type="button" data-target="aboutModal">About</button>
          </div>
        </div>
      </form>
    </div>
  </section>

  <div id="aboutModal" class="modal">
    <div class="modal-background"></div>
    <div class="modal-card">
      <header class="modal-card-head">
        <p class="modal-card-title">About</p>
        <button class="delete" aria-label="close"></button>
      </header>
      <section class="modal-card-body">
        <p>Styled by Bulma — embedded in the binary, served offline.</p>
      </section>
    </div>
  </div>
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
curl -sI http://localhost:PORT/static/bulma.min.css | head -1   # expect 200
curl -sI http://localhost:PORT/static/app.js | head -1          # expect 200
# kill the app, disable network, rerun — it still works
```

## Workflow: Upgrade Bulma

1. Check the latest release: `curl -s https://api.github.com/repos/jgthms/bulma/releases/latest | grep tag_name`
2. Re-run Step 2 with the new version
3. Update `BULMA_VERSION` and checksums (Step 3)
4. Run the app; review the [Bulma changelog](https://github.com/jgthms/bulma/blob/master/CHANGELOG.md) for breaking changes (Bulma 1.x is stable; minor releases are additive but always read the changelog)
5. Commit as a single changeset so the bump is traceable

## Pattern: Vanilla JS helpers (`app.js`)

Write this verbatim to `static/app.js`. It covers navbar burger, modal open/close, dropdown toggle, and tabs — Bulma's four interactive patterns. Zero dependencies, plain DOM API.

```javascript
// internal/ui/static/app.js
// Vanilla JS helpers for Bulma's interactive components.
// Bulma ships zero JS by design; this file wires the standard idioms
// documented at https://bulma.io/documentation/.

(() => {
  // Navbar burger: toggle .is-active on burger + matching menu.
  document.querySelectorAll('.navbar-burger').forEach((burger) => {
    burger.addEventListener('click', () => {
      const target = document.getElementById(burger.dataset.target);
      burger.classList.toggle('is-active');
      if (target) target.classList.toggle('is-active');
    });
  });

  // Modal: any element with data-target="modal-id" opens that modal.
  // .modal-background, .modal-close, .delete (inside .modal), and Escape close it.
  const openModal = (el) => el.classList.add('is-active');
  const closeModal = (el) => el.classList.remove('is-active');
  const closeAllModals = () =>
    document.querySelectorAll('.modal.is-active').forEach(closeModal);

  document.querySelectorAll('[data-target]').forEach((trigger) => {
    const target = document.getElementById(trigger.dataset.target);
    if (target && target.classList.contains('modal')) {
      trigger.addEventListener('click', () => openModal(target));
    }
  });

  document
    .querySelectorAll('.modal-background, .modal-close, .modal-card-head .delete, .modal .delete')
    .forEach((el) => {
      const modal = el.closest('.modal');
      if (modal) el.addEventListener('click', () => closeModal(modal));
    });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeAllModals();
  });

  // Dropdown: click .dropdown-trigger to toggle, click outside to close.
  document.querySelectorAll('.dropdown:not(.is-hoverable)').forEach((dropdown) => {
    const trigger = dropdown.querySelector('.dropdown-trigger');
    if (!trigger) return;
    trigger.addEventListener('click', (e) => {
      e.stopPropagation();
      dropdown.classList.toggle('is-active');
    });
  });
  document.addEventListener('click', () => {
    document
      .querySelectorAll('.dropdown.is-active:not(.is-hoverable)')
      .forEach((d) => d.classList.remove('is-active'));
  });

  // Tabs: <div class="tabs"><ul><li data-tab="panel-id">...</li></ul></div>
  // Panels are any elements with id matching data-tab; only the active one shows.
  document.querySelectorAll('.tabs').forEach((tabs) => {
    const items = tabs.querySelectorAll('li[data-tab]');
    items.forEach((item) => {
      item.addEventListener('click', () => {
        items.forEach((i) => i.classList.remove('is-active'));
        item.classList.add('is-active');
        items.forEach((i) => {
          const panel = document.getElementById(i.dataset.tab);
          if (panel) panel.hidden = i !== item;
        });
      });
    });
  });
})();
```

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
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <title>{ title }</title>
        <link rel="stylesheet" href="/static/bulma.min.css">
        <script src="/static/app.js" defer></script>
    </head>
    <body>
        <section class="section">
            <div class="container">
                { children... }
            </div>
        </section>
    </body>
    </html>
}
```

If templ is not yet set up in the project, defer to the **go-tool** skill to add it via `go get -tool github.com/a-h/templ/cmd/templ`, then return here.

## Pattern: Theming via CSS custom properties

Bulma 1.0+ exposes its design tokens as CSS custom properties (HSL components for colors, plus radii, fonts, spacing). Override them in a sibling `theme.css` loaded **after** `bulma.min.css`:

```css
/* internal/ui/static/theme.css */
:root {
  --bulma-primary-h: 217;
  --bulma-primary-s: 71%;
  --bulma-primary-l: 53%;

  --bulma-link-h: 217;
  --bulma-link-s: 71%;
  --bulma-link-l: 53%;

  --bulma-radius: 4px;
  --bulma-radius-small: 2px;
  --bulma-radius-large: 6px;

  --bulma-family-primary: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}
```

```html
<link rel="stylesheet" href="/static/bulma.min.css">
<link rel="stylesheet" href="/static/theme.css">
```

Add `theme.css` to the `//go:embed` directive. For the full list of custom properties, search `bulma.min.css` for `--bulma-` or see the [customize colors docs](https://bulma.io/documentation/features/customize-colors/).

Deeper customization (new component variants, removing unused modules to shrink the bundle) requires Sass and Node — **out of scope for this skill**. If the user asks for that, push back: the value proposition here is "no Node toolchain", and tree-shaking saves at most ~150KB on an already-cached file.

## Anti-Patterns

| Don't | Do |
|---|---|
| `<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma/...">` in rendered HTML | Download once at setup, embed, serve from `/static/` |
| `npm install bulma` + a Sass build step | Pure Go workflow — download `bulma.min.css`, write `app.js`, embed, done |
| Shipping unminified `bulma.css` in the binary | Always use `bulma.min.css` |
| Inline `<style>` blocks duplicating Bulma utilities | Use Bulma helper classes: `.has-text-centered`, `.mt-4`, `.is-flex`, etc. |
| Mixing Bootstrap and Bulma classes in the same page | Pick one. For Bootstrap, defer to the `html-first-frontend` agent |
| Forgetting `defer` on `<script src="/static/app.js">` | `defer` is required — the helpers query the DOM at load time |
| Reaching for jQuery or Alpine for navbar/modal | The scaffolded `app.js` already covers Bulma's four interactive patterns |

## Reference Layout

A completed setup looks like:

```
.
├── go.mod
├── main.go
├── BULMA_VERSION
└── internal/
    └── ui/
        ├── embed.go
        ├── render.go
        ├── static/
        │   ├── bulma.min.css
        │   ├── app.js
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
| `curl` returns non-200 for `bulma.min.css` | Verify the version exists on npm: `https://www.npmjs.com/package/bulma`. The release tag and the npm version should match. |
| User insists on CDN at runtime | Push back: the skill's reason for existing is offline, zero-dep, fully standalone binaries. If they still want CDN, decline and let them wire it manually without this skill. |
| Bulma assets already present in the repo | Skip download; verify checksums against `BULMA_VERSION` and proceed to wire the handler, write `app.js` if missing, and add the template. |
