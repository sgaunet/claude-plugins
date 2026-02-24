---
name: auto-mr
description: Push current branch, create MR/PR, wait for CI pipeline, merge, and clean up branch using auto-mr CLI
argument-hint: '[--squash] [--no-squash] [--msg "text"] [--labels "label1,label2"] [--list-labels] [--pipeline-timeout "30m"] [--log-level debug|info|warn|error]'
user-invokable: true
---

# auto-mr Skill

Push the current branch, create a MR/PR on GitHub or GitLab, wait for the CI pipeline, merge, and clean up the branch — all via the `auto-mr` CLI.

## CLI Reference

```
Flags:
  --labels string             Comma-separated label names (e.g., "bug,enhancement")
  --list-labels               List all available labels and exit
  -l, --log-level string      Set log level (debug, info, warn, error) [default "info"]
  --msg string                Custom message for MR/PR (overrides commit message selection)
  --no-squash                 Disable squash merge (default: squash enabled)
  --pipeline-timeout string   Pipeline/workflow timeout [default "30m"]
  -v, --version               Print version and exit
```

## Workflow

### Step 1: Pre-flight Checks

**Verify `auto-mr` is installed:**
```bash
auto-mr --version
```
If the command fails, abort with:
> `auto-mr` is not installed. Install it from https://github.com/sgaunet/auto-mr and ensure it is in your PATH.

**Get current branch:**
```bash
git rev-parse --abbrev-ref HEAD
```
If the branch is `main`, `master`, or `develop`, warn the user:
> Warning: you are on a protected branch (`<branch>`). `auto-mr` is intended for feature branches.

**Check for uncommitted changes:**
```bash
git status --porcelain
```
If the working tree is dirty, warn the user:
> Warning: you have uncommitted changes. Consider committing or stashing them before creating a MR/PR.

### Step 2: Label Discovery (early exit)

If `--list-labels` is present in the arguments:
```bash
auto-mr --list-labels
```
Display the output and return. Do not proceed further.

### Step 3: Assemble Command

Base command: `auto-mr`

Append all provided flags verbatim (e.g., `--squash`, `--msg "fix: ..."`, `--labels "bug,help wanted"`).

If a `working_directory` context is provided, prefix with `cd <working_directory> &&`.

### Step 4: Confirm Before Executing

Display a summary to the user:
```
Branch:  <current-branch>
Command: <assembled-command>
```

Ask the user to confirm via `AskUserQuestion`:
> Proceed with the above command? (yes/no)

If the user declines, abort gracefully.

### Step 5: Execute

Run the assembled command. `auto-mr` handles the full flow:
1. Push branch to remote
2. Create MR (GitLab) or PR (GitHub)
3. Wait for CI pipeline/checks
4. Merge when CI passes
5. Delete the remote branch

**On success:** display the output (includes the MR/PR URL).

**On failure:** display the error output, then suggest the manual fallback:
```bash
git push -u origin <branch>
# Then open a MR/PR via the repository web UI
```

## Working Directory

If a `working_directory` context is provided (e.g., a worktree path from `feature-flow-w`), prefix all commands with `cd <working_directory> &&`. Otherwise, use the current directory.
