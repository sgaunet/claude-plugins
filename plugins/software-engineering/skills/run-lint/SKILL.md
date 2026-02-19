---
name: run-lint
description: Auto-detect project linter and run it. Internal utility skill used by feature-flow commands for the lint phase.
user-invocable: false
allowed-tools: Bash(task:*), Bash(make:*), Bash(golangci-lint:*), Bash(go:*), Bash(npm:*), Bash(npx:*), Bash(eslint:*), Bash(ruff:*), Bash(python:*), Bash(cargo:*), Glob
---

# Run Lint Skill

Auto-detect the project's linter from build files and run it. Returns pass/fail status with output.

## Detection Logic

Probe for build/config files using **first match wins**:

| Trigger | Command | Fallback |
|---------|---------|----------|
| Taskfile.yml (`lint` task) | `task lint` | -- |
| Makefile (`lint` target) | `make lint` | -- |
| go.mod | `golangci-lint run ./...` | `go vet ./...` |
| package.json (`lint` script) | `npm run lint` | `npx eslint .` |
| pyproject.toml / setup.py | `ruff check .` | `python -m flake8 .` |
| Cargo.toml | `cargo clippy -- -D warnings` | -- |
| None detected | Warn: "No linter detected" and skip | -- |

## Execution

1. Detect linter using the table above
2. Run the detected command
3. On success: report "Lint passed"
4. On failure: display errors, attempt auto-fix if supported (`--fix` flag for the tool), re-run once
5. Return final status (pass/fail) and output

## Working Directory

If a `working_directory` context is provided (e.g., a worktree path), run all commands prefixed with `cd <working_directory> &&`. Otherwise, use the current directory.
