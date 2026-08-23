---
name: go-blackbox
description: Detect white box Go tests and propose conversion to black box tests (package foo_test), creating export_test.go bridges when tests need access to internals.
user-invocable: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(go list:*), Bash(go test:*), Bash(go vet:*)
---

# Go Black Box Test Enforcement

Detect Go test files using white box testing (same package name) and propose conversion to black box testing (`package foo_test`). Creates `export_test.go` bridge files when internal symbols need external test access.

## When to Use

- Creating new test files (enforce black box from the start)
- Reviewing existing test files in a Go project
- User asks to audit or improve test quality
- The golang-pro agent encounters `*_test.go` files during implementation

## Prerequisites

1. **go.mod exists**: Abort if missing.
2. **Go source files exist**: At least one `.go` file and one `*_test.go` file to analyze.

## Workflow: Detect White Box Tests

### Step 1: Classify Test Files with `go list`

`go list` already reports the in-package/external split per package, and honours
build constraints. Use it rather than globbing:

```bash
go list -f '{{.ImportPath}} {{.Name}} white={{.TestGoFiles}} black={{.XTestGoFiles}}' ./...
```

| Field | Package clause | Classification |
|---|---|---|
| `TestGoFiles` | `package foo` | White box — candidate for conversion |
| `XTestGoFiles` | `package foo_test` | Black box — already correct |

Two rules when reading the output:

- **Drop `export_test.go` from the white box set.** It is a bridge file and belongs
  to the source package by design, so it is never a conversion candidate.
- **A package can legitimately hold both.** Seeing entries in `TestGoFiles` and
  `XTestGoFiles` for the same package is normal, not a defect.

Why not Glob `**/*_test.go` and read `package` lines: a test file behind a
constraint like `//go:build linux` is matched by Glob on any OS but correctly
excluded by `go list`, so the manual approach both over- and under-reports. `go
list` also names the source package directly, removing the need to read sibling
non-test files to infer it.

### Step 2: Check for export_test.go

For each directory containing test files, check whether an `export_test.go` already exists.

### Step 3: Report Findings

Present a summary table:

| File | Package | Classification | export_test.go |
|---|---|---|---|
| `calc_test.go` | `calculator` | White box | No |
| `math_test.go` | `calculator_test` | Black box | N/A |
| `internal_test.go` | `parser` | White box | Yes |

## Workflow: Convert White Box to Black Box

For each white box test file identified:

### Step 1: Analyze Unexported Symbol Usage

Read the test file and identify references to unexported symbols (lowercase-initial identifiers) from the package under test:

- Unexported functions/methods called directly
- Unexported types used in variable declarations or assertions
- Unexported struct fields accessed directly
- Unexported constants/variables referenced

### Step 2: Determine Conversion Strategy

**Case A — No unexported symbols used:**
- Change `package foo` to `package foo_test`
- Add import for the package under test
- Prefix exported symbol references with the package name (e.g., `Add(1, 2)` → `calculator.Add(1, 2)`)

**Case B — Unexported symbols used:**
- Change `package foo` to `package foo_test` in the test file
- Add import for the package under test
- Create or update `export_test.go` in the same directory with `package foo` (no `_test` suffix) that exports needed internals:

```go
package foo

// Exported for testing in foo_test package.
var (
    TestableInternalFunc = internalFunc
    TestableInternalVar  = internalVar
)
```

- Update test file to use the exported aliases via the package import

**Case C — Heavy internal coupling (>10 unexported references):**
- Flag for manual review rather than automatic conversion
- Suggest refactoring the API to export what tests need, or keeping this specific file as white box with a justifying comment

### Step 3: Validate

After conversion, run:

```bash
go test ./...
go vet ./...
```

If tests fail, diagnose: missing imports, renamed references, or unexported symbols not yet bridged via `export_test.go`.

## export_test.go Conventions

1. **File name**: Always `export_test.go` (Go convention)
2. **Package**: Same as the source package (NOT `_test` suffix) — this is what makes it a bridge
3. **Build constraint**: None needed — Go includes `export_test.go` only during `go test`
4. **Naming**: Prefix exported aliases with `Testable` or use the capitalized form of the original name
5. **Comment**: Add `// Exported for testing in <pkg>_test package.` header comment
6. **Scope**: Export only what tests actually need — do not blanket-export all internals

## Error Handling

| Condition | Action |
|-----------|--------|
| No `go.mod` found | Abort: "Not a Go module." |
| No test files found | Report: "No test files found. Nothing to analyze." |
| All tests already black box | Report: "All test files use black box naming. No conversion needed." |
| Test compilation fails after conversion | Diagnose missing imports or unexported references. Attempt fix (max 2 retries). |
| `go vet` fails after conversion | Display errors and suggest manual review. |
