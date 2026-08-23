---
name: run-tests
description: Auto-detect the project's test runner (Taskfile, Makefile, go test, npm, pytest, cargo) and run it, reporting pass or fail.
user-invocable: true
allowed-tools: Read, Edit, Bash(task:*), Bash(make:*), Bash(go:*), Bash(npm:*), Bash(npx:*), Bash(python:*), Bash(cargo:*), Glob
---

# Run Tests Skill

Auto-detect the project's test runner from build files and run it. Returns pass/fail status with output.

## Detection Logic

Probe for build/config files using **first match wins** -- but a config file
existing does not mean the *target* inside it exists. Verify the named target
before running it; when it is absent, fall through to the next matching row
rather than reporting a failure.

| Trigger | Verify the target exists | Command | Fallback |
|---------|-------------------------|---------|----------|
| Taskfile.yml | `task --list-all \| grep -qE '^\* test:'` | `task test` | fall through to next row |
| Makefile | `make -n test >/dev/null 2>&1` | `make test` | fall through to next row |
| go.mod | n/a | `go test ./...` | -- |
| package.json | `--if-present` handles it | `npm test --if-present` | `npx jest` or `npx vitest run` |
| pyproject.toml / setup.py | n/a | `python -m pytest` | -- |
| Cargo.toml | n/a | `cargo test` | -- |
| None detected | n/a | Warn: "No test runner detected" and skip | -- |

**A missing target is not a test failure.** `task test` where no `test` task is
defined (this marketplace's own repo is exactly that case) exits non-zero for a
reason that has nothing to do with the code -- never take it into the
fix-and-retry loop below. Treat it as "this row does not apply", fall through to
language-native detection, and report "No test runner detected" only once every
row is exhausted.

## Execution

1. Detect the test runner using the table above, verifying the target exists before running it
2. Run the detected command
3. On success: report "Tests passed"
4. On failure: display output, attempt fix (max 2 retries) — analyze failure, apply fix via Edit, re-run.
   **Only for genuine test failures.** If the command failed because the target or
   tool was absent, go back to detection instead of editing any code.
5. Return final status (pass/fail) and output

## Working Directory

If a `working_directory` context is provided (e.g., a worktree path), run all commands prefixed with `cd <working_directory> &&`. Otherwise, use the current directory.
