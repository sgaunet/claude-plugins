---
name: go-blackbox
description: Detect white box Go tests and propose conversion to black box tests (package foo_test). Internal skill used by golang-pro agent to enforce black box testing conventions.
user-invocable: false
allowed-tools: Read, Glob, Grep, Bash(go test:*), Bash(go vet:*)
---

# Go Black Box Test Enforcement

Detect Go test files using white box testing (same package name) and propose conversion to black box testing (`package foo_test`). Creates `export_test.go` bridge files when internal symbols need external test access.

## When to Use

- Creating new test files (enforce black box from the start)
- Reviewing existing test files in a Go project
- User asks to audit or improve test quality
- The golang-pro agent encounters `*_test.go` files during implementation
- The golang-pro agent encounters goroutine-spawning code while writing or reviewing tests

## Prerequisites

1. **go.mod exists**: Abort if missing.
2. **Go source files exist**: At least one `.go` file and one `*_test.go` file to analyze.

## Workflow: Detect White Box Tests

### Step 1: Scan Test Files

Use Glob to find all test files:

```
**/*_test.go
```

Exclude `vendor/` and `export_test.go` files from analysis.

### Step 2: Classify Each Test File

For each `*_test.go` file, read the `package` declaration (first non-comment, non-blank line starting with `package`).

**Classification rules:**

| Package declaration | Source package | Classification |
|---|---|---|
| `package foo_test` | `foo` | Black box (correct) |
| `package foo` | `foo` | White box (needs conversion) |
| `package foo_test` | N/A (no source) | Black box (standalone) |

To determine the source package: look for non-test `.go` files in the same directory and read their `package` declaration.

### Step 3: Check for export_test.go

For each directory containing test files, check whether an `export_test.go` already exists.

### Step 4: Report Findings

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

## Workflow: Add Goroutine Leak Detection

After conversion (or during new test creation), detect test functions that exercise goroutine-spawning code and add `go.uber.org/goleak` verification.

### Step 1: Identify Goroutine-Spawning Source Code

For each package under test, scan the **non-test** `.go` source files for goroutine launches:

```
Grep pattern: `go\s+func\s*\(|go\s+[a-zA-Z]`
```

This matches:
- `go func() { ... }()` — anonymous goroutine
- `go myFunction(...)` — named function goroutine
- `go obj.Method(...)` — method goroutine

Exclude `vendor/` and generated files. Record which **exported functions/methods** directly or transitively spawn goroutines.

### Step 2: Map Tests to Goroutine-Spawning Functions

For each test file in the package, identify test functions that call (directly or via helpers) the goroutine-spawning functions found in Step 1.

**Classification:**

| Test Function | Calls Goroutine-Spawning Code | Action |
|---|---|---|
| `TestWorkerPool` | Yes (`StartWorkers` uses `go`) | Add `goleak.VerifyNone(t)` |
| `TestParseConfig` | No | Skip — no goroutine risk |
| `TestServerStart` | Yes (`Serve` uses `go`) | Add `goleak.VerifyNone(t)` |

### Step 3: Add goleak to Test Functions

For each test function classified as needing leak detection:

1. **Add the defer call** as the first statement in the test function body:

```go
func TestWorkerPool(t *testing.T) {
    defer goleak.VerifyNone(t)
    // ... rest of test
}
```

2. **Add the import** to the test file if not already present:

```go
import (
    "testing"

    "go.uber.org/goleak"
)
```

3. **Install the module** if not already in `go.mod`:

```bash
go get go.uber.org/goleak@latest
go mod tidy
```

### Step 4: Handle goleak Options

Some goroutines are expected and should not trigger false positives. Common cases:

| Scenario | Option |
|---|---|
| Known background goroutine from a dependency | `goleak.IgnoreTopFunction("package.function")` |
| Goroutine matching a pattern | `goleak.IgnoreAnyFunction("package.glob*")` |

If `goleak.VerifyNone(t)` fails due to known background goroutines (e.g., from `net/http` or logging libraries), add options:

```go
defer goleak.VerifyNone(t,
    goleak.IgnoreTopFunction("net/http.(*Server).Serve"),
)
```

Do not suppress unknown goroutines — investigate them first.

### Step 5: Validate

Run the tests with the race detector to confirm no leaks and no regressions:

```bash
go test -race -count=1 ./...
```

If `goleak.VerifyNone` reports leaked goroutines:
1. Check if the tested code properly shuts down goroutines (context cancellation, channel close, `sync.WaitGroup`)
2. If the goroutine is from a third-party dependency and cannot be controlled, add a targeted `goleak.IgnoreTopFunction` option
3. Never blanket-ignore all goroutines — each ignore must be specific and documented

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
| `go get go.uber.org/goleak` fails | Display error. Check network connectivity and module proxy settings. |
| `goleak.VerifyNone` reports leaked goroutines | Investigate source. Fix goroutine lifecycle first; use `IgnoreTopFunction` only for third-party goroutines that cannot be controlled. |
| No goroutine-spawning code found in package | Skip goleak workflow: "No goroutine usage detected. Goroutine leak detection not needed." |
