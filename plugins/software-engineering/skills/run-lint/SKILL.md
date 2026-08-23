---
name: run-lint
description: Auto-detect the project's linter (Taskfile, Makefile, golangci-lint, eslint, ruff, clippy) and run it, reporting pass or fail.
user-invocable: true
allowed-tools: Bash(task:*), Bash(make:*), Bash(golangci-lint:*), Bash(go:*), Bash(npm:*), Bash(npx:*), Bash(eslint:*), Bash(ruff:*), Bash(python:*), Bash(cargo:*), Glob
---

# Run Lint Skill

Auto-detect the project's linter from build files and run it. Returns pass/fail status with output.

## Detection Logic

Probe for build/config files using **first match wins** -- but a config file
existing does not mean the *target* inside it exists. Verify the named target
before running it; when it is absent, fall through to the next matching row
rather than reporting a failure.

| Trigger | Verify the target exists | Command | Fallback |
|---------|-------------------------|---------|----------|
| Taskfile.yml | `task --list-all \| grep -qE '^\* lint:'` | `task lint` | fall through to next row |
| Makefile | `make -n lint >/dev/null 2>&1` | `make lint` | fall through to next row |
| go.mod | n/a | `golangci-lint run ./...` | `go vet ./...` |
| package.json | `--if-present` handles it | `npm run lint --if-present` | `npx eslint .` |
| pyproject.toml / setup.py | n/a | `ruff check .` | `python -m flake8 .` |
| Cargo.toml | n/a | `cargo clippy -- -D warnings` | -- |
| None detected | n/a | Warn: "No linter detected" and skip | -- |

**A missing target is not a lint failure.** `task lint` where no `lint` task is
defined, or `npm run lint` with no `lint` script, exits non-zero for a reason that
has nothing to do with the code. Treat it as "this row does not apply" and
continue detection; `npm run lint --if-present` exits 0 silently when the script
is absent, so chain its fallback rather than reading the exit code as success.

## Execution

1. Detect the linter using the table above, verifying the target exists before running it
2. Run the detected command
3. On success: report "Lint passed"
4. On failure: display errors, attempt auto-fix if supported (`--fix` flag for the tool), re-run once
5. Return final status (pass/fail) and output

## Working Directory

If a `working_directory` context is provided (e.g., a worktree path), run all commands prefixed with `cd <working_directory> &&`. Otherwise, use the current directory.
