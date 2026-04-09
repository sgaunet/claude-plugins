---
name: go-tdd
description: Implement a Go feature using TDD methodology with up-to-date library documentation from Context7
argument-hint: "<feature description> [--skip-lint] [--skip-refactor] [--dry-run] [--force]"
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(go test:*), Bash(go vet:*), Bash(go build:*), Bash(golangci-lint:*), mcp__context7__resolve-library-id, mcp__context7__query-docs, AskUserQuestion
---

# Go TDD Implementation

Implement a Go feature using strict **RED → GREEN → REFACTOR** TDD methodology, with Context7 MCP integration for up-to-date library documentation at each phase.

## Arguments

- `$argument`: Feature description and optional flags (required)

### Flags

| Flag | Short | Effect |
|------|-------|--------|
| `--skip-lint` | `-l` | Skip golangci-lint in Phase 5 |
| `--skip-refactor` | `-r` | Skip Phase 4 refactoring |
| `--dry-run` | `-n` | Show plan only, no file writes |
| `--force` | `-f` | Skip all user confirmations |

## Error Handling

| Error | Action |
|-------|--------|
| No `go.mod` found | Abort with message: "Not a Go project — no go.mod found" |
| Context7 unavailable | Warn and continue without doc validation |
| Tests won't compile | Display errors, attempt fix (max 2 retries), then ask user |
| Tests fail in GREEN phase | Attempt fix (max 2 retries), then ask user |
| Lint failure | Attempt auto-fix, re-run, then ask user |
| Build failure | Display errors, abort |

## Process

### Phase 1: Discovery & Documentation (Automatic)

1. **Parse flags** from `$argument`:
   - Extract feature description (everything before flags)
   - Detect `--skip-lint` / `-l`, `--skip-refactor` / `-r`, `--dry-run` / `-n`, `--force` / `-f`

2. **Validate Go project**:
   - Check `go.mod` exists — if not, abort: "Not a Go project — no go.mod found"
   - Read `go.mod` to identify module name and Go version

3. **Analyze project structure**:
   - Scan existing packages, test patterns, coding conventions
   - Identify existing test helpers or shared fixtures
   - Note the project's import style, error handling patterns, naming conventions
   - Check existing `*_test.go` files for package naming: flag any white box tests (`package <pkgname>` without `_test` suffix) for potential conversion

4. **Identify libraries needed** for the feature:
   - Determine which standard library packages are involved
   - Determine which third-party libraries are needed

5. **Fetch Context7 documentation** for each library:
   - Call `mcp__context7__resolve-library-id` to get the library ID
   - Call `mcp__context7__query-docs` with a query specific to the feature being implemented
   - If Context7 is unavailable, warn and continue without doc validation

6. **Present implementation plan** to user:
   - Target files to create/modify
   - Packages involved
   - Libraries with doc summaries from Context7
   - Proposed test strategy (table-driven tests, subtests, benchmarks)

7. **Ask confirmation** via `AskUserQuestion` (skipped with `--force`):
   - "Proceed with this implementation plan?"
   - If `--dry-run`: display plan and stop here

### Phase 2: RED — Write Failing Tests

1. **Create or edit `*_test.go` files** with:
   - **Black box package naming**: use `package <pkgname>_test` (not `package <pkgname>`). Import the package under test explicitly so tests validate the public API. If internals must be tested, create an `export_test.go` in `package <pkgname>` that exports needed symbols (e.g., `var InternalFunc = internalFunc`)
   - Table-driven tests covering: happy path, edge cases, error cases
   - Test function names following Go conventions: `TestFeatureName_Scenario`
   - Use patterns from Context7 docs (e.g., testify assertions if project uses testify)
   - Include benchmark tests if the feature is performance-sensitive
   - Use `t.Helper()` in test helpers, `t.Parallel()` where safe
   - Add `defer goleak.VerifyNone(t)` to test functions that test goroutine-spawning code; import `go.uber.org/goleak`

2. **Run tests** to confirm RED state:
   ```bash
   go test -v ./...
   ```

3. **Validate RED state**:
   - If tests **fail** (expected) → RED state confirmed, display output
   - If tests **pass** (unexpected) → warn: "Tests pass without implementation — tests may not be testing the right thing"

4. **Ask confirmation** to proceed to GREEN phase (skipped with `--force`)

### Phase 3: GREEN — Minimal Implementation

1. **Write minimal code** to make all tests pass:
   - Follow library patterns from Context7 docs fetched in Phase 1
   - Follow Go idioms: explicit error handling, interface-driven design, standard library first
   - Do NOT optimize or refactor — just make tests green

2. **Run tests** to confirm GREEN state:
   ```bash
   go test -v ./...
   ```

3. **Validate GREEN state**:
   - If tests **pass** → GREEN state confirmed
   - If tests **fail** → attempt fix (max 2 iterations), then ask user via `AskUserQuestion`

4. **Ask confirmation** to proceed to REFACTOR phase (skipped with `--force`)

### Phase 4: REFACTOR — Clean Up (Skippable)

> Skipped entirely if `--skip-refactor` flag is set.

1. **Improve code quality** while keeping tests green:
   - Extract shared logic into helper functions
   - Improve variable and function naming
   - Add godoc comments to exported symbols
   - Apply Go idioms: composition over inheritance, small interfaces
   - Cross-reference with Context7 docs for idiomatic library usage

2. **Run tests after each refactoring step** to ensure no regression:
   ```bash
   go test ./...
   ```

3. **Run vet** for correctness checks:
   ```bash
   go vet ./...
   ```

4. If any test fails after a refactoring step → revert that step and warn user.

### Phase 5: Quality Gates (Automatic)

1. **Always run** (mandatory):
   ```bash
   go build ./...
   go vet ./...
   go test -race ./...
   go test -cover ./...
   ```

2. **Unless `--skip-lint`**, also run:
   ```bash
   golangci-lint run ./...
   ```

3. **On lint failure**: attempt auto-fix, re-run. If still failing, ask user via `AskUserQuestion`.

4. **Display quality summary** with pass/fail indicators for each gate.

### Phase 6: Summary (Automatic)

Display a structured summary:

```
## TDD Implementation Summary

### Files
- Created: [list of new files]
- Modified: [list of modified files]

### Tests
- Total: N tests
- Passed: N / N
- Coverage: XX%

### Libraries Used
- [library]: Context7 docs consulted ✓
- [library]: Standard library (no lookup needed)

### Quality Gates
- Build:  ✓ / ✗
- Vet:    ✓ / ✗
- Lint:   ✓ / ✗ / skipped
- Race:   ✓ / ✗
- Cover:  XX%
- Black box: ✓ all tests use _test suffix / ✗ N files use white box naming

### Next Steps
- Review changes
- Commit with: /commit
- Push to remote
```

## Example Usage

```bash
# Implement a Fibonacci calculator with full TDD flow
/go-tdd "Add a function to calculate Fibonacci numbers"

# Implement with no refactoring phase
/go-tdd "Add HTTP health check endpoint" --skip-refactor

# Preview the plan without writing any files
/go-tdd "Add Redis caching layer" --dry-run

# Run everything without confirmations
/go-tdd "Add JWT token validation middleware" --force

# Combine flags
/go-tdd "Add CSV export for reports" --force --skip-lint
```
