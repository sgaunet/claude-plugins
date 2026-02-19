---
name: run-tests
description: Auto-detect project test runner and run it. Internal utility skill used by feature-flow commands for the test phase.
user-invocable: false
allowed-tools: Bash(task:*), Bash(make:*), Bash(go:*), Bash(npm:*), Bash(npx:*), Bash(python:*), Bash(cargo:*), Glob
---

# Run Tests Skill

Auto-detect the project's test runner from build files and run it. Returns pass/fail status with output.

## Detection Logic

Probe for build/config files using **first match wins**:

| Trigger | Command | Fallback |
|---------|---------|----------|
| Taskfile.yml (`test` task) | `task test` | -- |
| Makefile (`test` target) | `make test` | -- |
| go.mod | `go test ./...` | -- |
| package.json (`test` script) | `npm test` | `npx jest` or `npx vitest run` |
| pyproject.toml / setup.py | `python -m pytest` | -- |
| Cargo.toml | `cargo test` | -- |
| None detected | Warn: "No test runner detected" and skip | -- |

## Execution

1. Detect test runner using the table above
2. Run the detected command
3. On success: report "Tests passed"
4. On failure: display output, attempt fix (max 2 retries) — analyze failure, apply fix via Edit, re-run
5. Return final status (pass/fail) and output

## Working Directory

If a `working_directory` context is provided (e.g., a worktree path), run all commands prefixed with `cd <working_directory> &&`. Otherwise, use the current directory.
