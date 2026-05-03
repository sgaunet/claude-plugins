---
name: go-tool
description: Manage Go tool dependencies using the tool directive (Go 1.24+). Use when a Go project needs code generation tools like sqlc, moq, templ, swag, or stringer managed as reproducible Go tool dependencies.
user-invocable: false
allowed-tools: Bash(go:*), Read, Glob, Grep
---

# Go Tool Dependency Management

Manage Go development tool dependencies using the `tool` directive introduced in Go 1.24. This ensures reproducible builds by tracking tool versions in `go.mod` — eliminating the old `tools.go` workaround and version drift across developers and CI.

For detailed per-tool information, see the [reference catalog](${CLAUDE_SKILL_DIR}/../../docs/go-tool-catalog.md).

## When to Use

- A Go project needs external code generation or build tools
- Indicator files suggest a tool should be added (`.templ`, `.proto`, `sqlc.yml`, etc.)
- The user explicitly requests adding a Go tool dependency
- Auditing existing tool dependencies for consistency or cleanup
- Migrating from `tools.go` pattern to the native `tool` directive

## Prerequisites

Before proceeding, verify:

1. **go.mod exists**: Check for `go.mod` in the project root. Abort if missing.
2. **Go version ≥ 1.24**: Read the `go` directive in `go.mod`. If the version is below 1.24, inform the user: "The Go tool directive requires Go 1.24+. Update the `go` directive in go.mod to 1.24 or later."

## Workflow: Detect Recommended Tools

Scan the project for indicator files and compare against existing tool declarations in `go.mod`.

### Step 1: Read Existing Tools

Parse `go.mod` for the `tool` block to identify already-tracked tools.

### Step 2: Scan for Indicator Files

Use Glob to detect files that suggest specific tools:

| Indicator | Tool | Module Path |
|-----------|------|-------------|
| `sqlc.yml` / `sqlc.yaml` / `sqlc.json` | sqlc | `github.com/sqlc-dev/sqlc/cmd/sqlc` |
| `**/*.templ` | templ | `github.com/a-h/templ/cmd/templ` |
| `swagger.yaml` / `swagger.json` | swag | `github.com/swaggo/swag/cmd/swag` |

For **stringer** and **enumer**, detection requires context: `const` blocks with `iota` patterns. These are best suggested when the user is working with enum-like types.

### Step 3: Report Findings

Present a table comparing detected recommendations against existing tools:

| Tool | Status | Reason |
|------|--------|--------|
| templ | Missing | `.templ` files found but tool not in go.mod |
| sqlc | Present | Already tracked in go.mod |

## Workflow: Add Tool

### Step 1: Install

```bash
go get -tool <module-path>@latest
```

Replace `@latest` with a specific version if the user requests one.

### Step 2: Tidy

```bash
go mod tidy
```

### Step 3: Verify

```bash
go tool <tool-name> --help
```

Confirm the tool runs without error.

### Step 4: Suggest go:generate Directive

Based on the tool, suggest the appropriate `//go:generate` directive. See the [reference catalog](${CLAUDE_SKILL_DIR}/../../docs/go-tool-catalog.md) for canonical directives per tool.

General pattern:
```go
//go:generate go tool <name> <args>
```

Place the directive in the file closest to the generated output.

## Workflow: Remove Tool

### Step 1: Remove from go.mod

```bash
go get -tool <module-path>@none
```

### Step 2: Tidy

```bash
go mod tidy
```

### Step 3: Clean Up

Search for and remove any `//go:generate` directives that reference the removed tool:

```
Grep for: //go:generate go tool <name>
```

## Workflow: Audit Tools

### Step 1: List Declared Tools

Parse the `tool (...)` block from `go.mod`.

### Step 2: Cross-Reference with Source

For each declared tool, search for `//go:generate go tool <name>` in Go source files.

### Step 3: Report

| Tool | In go.mod | Has go:generate | Status |
|------|-----------|-----------------|--------|
| sqlc | Yes | Yes | OK |
| moq | Yes | No | Possibly unused |
| templ | No | Yes | Missing from go.mod |

## go:generate Best Practices

1. **Always use `go tool <name>`** in directives — not a direct binary path. This ensures the version pinned in `go.mod` is used.
2. **Place directives near generated output** — in the package that owns the generated code.
3. **Run all generators**: `go generate ./...`
4. **Commit generated code** to version control so builds don't require running generators.
5. **One directive per tool invocation** — avoid chaining multiple tools in a single directive.

## Non-Go Tools

The `go tool` directive only supports tools written in Go. For non-Go tools (Node.js, Rust, Python), use alternative management:

- **Taskfile.yml** or **Makefile** for running non-Go tools
- **Docker** for tools with complex dependencies

## Error Handling

| Condition | Action |
|-----------|--------|
| No `go.mod` found | Abort: "Not a Go module — no go.mod found. Run `go mod init` first." |
| Go version < 1.24 | Abort: "Go tool directive requires Go 1.24+. Update the `go` directive in go.mod." |
| `go get -tool` fails | Display error. Common causes: invalid module path, network issues, module not found. |
| Tool already in go.mod | Skip: "Tool already tracked in go.mod." Suggest verifying version if needed. |
| `go tool <name>` fails after install | Check `go mod tidy` was run. Verify the module provides a binary at the expected path. |
