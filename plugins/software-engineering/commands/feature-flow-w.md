---
name: feature-flow-w
description: Complete git worktree workflow orchestration - worktree, branch, issue, commit
argument-hint: "[context | #issue-number] [--skip-branch] [--skip-issue] [--skip-mr] [--squash] [--msg \"text\"] [--dry-run] [--force] [--worktree-path <path>]"
allowed-tools: Read, Write, Edit, Grep, Glob, Skill, Bash(git:*), Bash(make:*), Bash(npm:*), Bash(npx:*), Bash(go:*), Bash(python:*), Bash(cargo:*), Bash(task:*), Bash(golangci-lint:*), Bash(eslint:*), Bash(ruff:*), Bash(mypy:*), Bash(auto-mr:*), Bash(gh:*), Bash(glab:*), AskUserQuestion
---

# Feature Flow Worktree Command

Orchestrate a complete git workflow using **worktrees** for feature development. Creates a parallel working directory instead of switching branches, keeping your current branch untouched. Two modes:

1. **Staged Changes Mode** (default): Analyze staged changes → worktree + branch → create issue → commit (in worktree)
2. **Issue Mode** (`#<number>`): Retrieve issue → worktree + branch → implement → lint → test → verify → commit → merge (all in worktree)

Use `feature-flow-w` instead of `feature-flow` when you want to work on multiple features simultaneously without leaving your current branch.

## Mode Detection

**Route based on `$argument`:** first positional argument matching `#<number>` or bare `<number>` → **Issue Mode**; otherwise → **Staged Changes Mode**.

Issue Mode examples: `/feature-flow-w #42`, `/feature-flow-w 42 --squash`
Staged Mode examples: `/feature-flow-w`, `/feature-flow-w add user auth`, `/feature-flow-w --skip-issue`

## Worktree Path Computation

Before creating any worktree, compute the target path:

1. If `--worktree-path <path>` (or `-w <path>`) provided → use that path (resolve to absolute if relative)
2. Default: `<repo-parent>/<repo-name>-<sanitized-branch>` where `/` in branch name becomes `-`
   - Example: repo at `/home/user/my-project`, branch `feat/add-auth` → `/home/user/my-project-feat-add-auth`
3. Validate directory does not already exist

Store `<worktree-path>` and `<original-path>` (result of `pwd`) for use throughout all phases.

## Staged Changes Mode (5 Phases)

### Phase 1: Discovery & Validation (Automatic)

**Execute parallel git commands:** `git status` and `git diff --staged`

**Detect Repository Host**: Use the `detect-repo-host` skill to identify the hosting service (GitHub or GitLab) and extract owner/repo details.

**Analysis steps:**
1. **Analyze staged changes:**
   - Extract file paths, extensions, and types
   - Determine change type: new files → `feat`, test+fixes → `fix`, docs only → `docs`, structural → `refactor`, build/config → `chore`
   - Extract primary scope from directory (e.g., `src/api/` → `api`, `internal/auth/` → `auth`)

2. **Generate proposed branch name:**
   - Format: `<type>/<scope>-<description>` (kebab-case, 2-4 words)
   - Types: feat, fix, refactor, docs, chore, test, perf, ci
   - Examples: `feat/api-user-profile`, `fix/auth-jwt-validation`, `docs/readme-update`

**Error handling:**
- No staged changes → Abort: "No staged changes found. Stage files with 'git add' first."
- Repository host detection fails → The `detect-repo-host` skill provides detailed error messages

### Phase 2: Worktree Creation (User Confirmation)

**Parse flags:** `--skip-branch` or `-b` → skip this phase (no worktree created, behaves like original `feature-flow`).

**If not skipped:**

1. Check current branch: `git rev-parse --abbrev-ref HEAD`
2. Compute worktree path (see Worktree Path Computation above)
3. Display proposed branch name and worktree path
4. Ask confirmation via AskUserQuestion: "Create worktree at `<path>` with branch `<name>`?" with options: "Yes, create worktree", "Use different name", "Skip worktree creation"
5. Handle response:
   - "Yes, create": Execute worktree creation sequence (see below)
   - "Use different name": Ask for custom name, recompute path, then create
   - "Skip": Continue on current branch without worktree

**Worktree creation sequence (staged changes transfer):**

1. Save staged diff: `git diff --staged > /tmp/feature-flow-w-staged-$(date +%s).patch`
2. Unstage from original: `git reset HEAD`
3. Create worktree: `git worktree add <path> -b <branch-name>`
4. Apply in worktree: `cd <path> && git apply <patch-file> && git add .`
5. Clean up patch file: `rm <patch-file>`
6. Verify: `git worktree list`

**Error handling:**
- Worktree directory already exists → Suggest `<path>-v2` or ask for alternative
- Branch already checked out in another worktree → Display the other worktree path, ask for different branch name
- Patch apply fails → Remove worktree (`git worktree remove <path>`), re-stage original changes (`git stash pop` or re-apply patch), display error, suggest manual resolution
- Branch exists → Suggest `<name>-v2` or ask for alternative
- `.gitmodules` detected → Run `git submodule update --init --recursive` in new worktree
- Git error → Display error, abort

### Phase 3: Issue Creation (User Confirmation)

**Parse flags:** `--skip-issue` or `-i` → skip this phase.

**If not skipped:**

1. **List available labels** (same pattern as `/create-issue` command):
   - GitHub: `gh label list --repo <owner>/<repo>`
   - GitLab: `glab label list`

2. **Generate issue content** following `/create-issue` conventions:
   - Title: under 80 chars, imperative mood, based on change type and scope
   - Description: Overview + Changes list + Testing section + Branch reference + **Worktree path** (if created)
   - Labels: map type to labels (`feat`→enhancement, `fix`→bug, `docs`→documentation, etc.), validate against available labels

3. Display preview, ask confirmation: "Create issue with this content?" → "Yes, create issue" / "Skip issue creation"

4. Create issue if approved:
   - GitHub: `gh issue create --repo <owner>/<repo> --title "<title>" --body "<body>" --label "<label1>" --label "<label2>"`
   - GitLab: `glab issue create --title "<title>" --description "<body>" --label "<label1>" --label "<label2>"`
   - Parse issue number from command output; store for Phase 4

**Error handling:**
- `gh`/`glab` CLI not installed → Skip issue creation, warn, continue to commit
- Invalid labels → Remove silently, warn user
- Issue creation fails → Log error, continue to Phase 4 without issue reference

### Phase 4: Commit Execution (User Confirmation)

**All git commands execute in worktree directory** (if created): prefix with `cd <worktree-path> &&`.

**Generate conventional commit message** following `/commit` command format (see `commit.md` for full spec):
- Type from branch name or change analysis
- Scope from primary directory
- Description: imperative mood, lowercase, under 50 chars, no period
- Body: bullet points for multi-file changes
- Footer: `Refs #<issue-number>` or `Closes #<N>` for fixes
- **CRITICAL**: NO Claude Code attribution (per commit command's no-attribution policy)

**Display preview, ask confirmation:** "Commit with this message?" → "Yes, commit now" / "Edit message" / "Cancel workflow"

**Execute:** `cd <worktree-path> && git commit -m "<message>"`, verify with `cd <worktree-path> && git log -1 --oneline`.

**Error handling:**
- Pre-commit hook fails → Display error, abort, provide recovery steps
- Commit fails → Display git error, abort

### Phase 5: Summary & Next Steps (Automatic)

Display workflow summary showing:
- Completed steps (worktree created, branch created, issue created, commit hash)
- **Worktree location:** `<worktree-path>`
- **Quick access:** `cd <worktree-path>`
- **Return to original:** `cd <original-path>`
- Next steps: push branch, create PR/MR, continue development
- **Cleanup after merge:** `git worktree remove <worktree-path> && git branch -d <branch-name>`

## Issue Mode Process (8 Phases)

### Phase I-1: Issue Retrieval (Automatic)

**Detect Repository Host**: Use the `detect-repo-host` skill.

**Get current branch:** `git rev-parse --abbrev-ref HEAD`

**Fetch issue details:**
- GitHub: `gh issue view <number> --repo <owner>/<repo> --json title,body,labels`
- GitLab: `glab issue view <number>`

**Extract:** Title (→ branch name, commit, MR title), Body (→ implementation spec), Labels (→ type detection)

**Error handling:**
- Issue not found → Abort: "Issue #N not found in <owner/repo>."
- `gh`/`glab` CLI not installed → Abort: "Cannot retrieve issue. Install `gh` (GitHub) or `glab` (GitLab) CLI first."

### Phase I-2: Worktree Creation (User Confirmation)

**Parse flags:** `--skip-branch` or `-b` → skip this phase.

**If not skipped:**

1. **Derive branch type from labels:**

   | Label contains | Type |
   |----------------|------|
   | bug, bugfix, fix | `fix` |
   | enhancement, feature | `feat` |
   | documentation, docs | `docs` |
   | refactor | `refactor` |
   | test | `test` |
   | ci, ci-cd | `ci` |
   | performance | `perf` |
   | *(no match)* | `feat` |

2. **Generate branch name:** `<type>/<scope>-issue-<N>` (scope from issue title, kebab-case)

3. Compute worktree path (see Worktree Path Computation above)

4. Ask confirmation via AskUserQuestion: "Create worktree at `<path>` with branch `<name>`?" → handle response same as Phase 2.

5. Create worktree: `git worktree add <path> -b <branch-name>`

6. If `.gitmodules` detected: `cd <path> && git submodule update --init --recursive`

7. Verify: `git worktree list`

**Error handling:**
- Worktree directory already exists → Suggest `<path>-v2` or ask for alternative
- Branch already checked out in another worktree → Display the other worktree path, ask for different branch name
- Branch exists → Suggest `<name>-v2` or ask for alternative
- Git error → Display error, abort

### Phase I-3: AI Implementation (User Confirmation)

**All file operations target the worktree directory.**

1. Read issue body as specification; parse requirements and target files
2. Analyze project structure in worktree using Glob/Read to find relevant files and conventions
3. Implement solution using Write/Edit in worktree directory; follow existing code style; include tests if module has them
4. Display change summary (files created/modified)
5. Ask confirmation: "Implementation complete. Review changes and continue?" → "Yes, continue to lint & test" / "Make adjustments" / "Cancel workflow"

### Phase I-4: Lint (Automatic)

**Use the `run-lint` skill** with `working_directory` set to `<worktree-path>`. If lint fails, ask user whether to continue.

### Phase I-5: Test (Automatic)

**Use the `run-tests` skill** with `working_directory` set to `<worktree-path>`. If tests fail, ask user whether to continue.

### Phase I-6: Verification (User Confirmation)

**All commands run in worktree directory.**

1. Re-run lint and tests to confirm clean
2. Display `cd <worktree-path> && git diff --stat` summary
3. Show pass/fail gate: Lint ✓/⚠/✗, Tests ✓/⚠/✗, file stats
4. Ask confirmation: "Verification complete. Proceed to commit?" → "Yes, commit changes" / "Go back and fix issues" / "Cancel workflow"

### Phase I-7: Commit (User Confirmation)

**All git commands run in worktree directory.**

1. Stage implementation files: `cd <worktree-path> && git add <files from Phase I-3>` (only created/modified files)
2. Generate conventional commit per Phase 4 format, with: type from Phase I-2, scope from issue, footer `Closes #<N>`
3. **CRITICAL**: NO Claude Code attribution
4. Display preview, ask confirmation, execute `cd <worktree-path> && git commit -m "<message>"`, verify with `cd <worktree-path> && git log -1 --oneline`

**Error handling:** Pre-commit hook fails → abort with recovery steps; commit fails → abort.

**On successful commit:** Immediately proceed to Phase I-8.

### Phase I-8: Merge via auto-mr + Summary (Automatic, Skippable)

**Parse flags:** `--skip-mr` → skip this phase.

**Build command:** `cd <worktree-path> && auto-mr [--squash] [--msg "<message>"]`
- `--squash`: if `-s` flag was passed
- `--msg`: default `<type>(<scope>): <issue-title> (Closes #<N>)`, override with user's `--msg`

**Execute:** Run `auto-mr` from worktree → on success display MR/PR URL → on failure warn and show manual push instructions.

**Display summary** showing:
- All completed steps (issue retrieved, worktree, branch, implementation, lint, tests, commit, MR) with URLs and hashes
- **Worktree location:** `<worktree-path>`
- **Quick access:** `cd <worktree-path>`
- **Return to original:** `cd <original-path>`
- **Cleanup after merge:** `git worktree remove <worktree-path> && git branch -d <branch-name>`

## Flag Support

**Both modes:**

| Flag | Short | Effect |
|------|-------|--------|
| `--skip-branch` | `-b` | Skip worktree/branch creation, stay on current branch |
| `--worktree-path <path>` | `-w <path>` | Override default worktree directory location |
| `--dry-run` | `-n` | Preview mode: show what would be done without executing |
| `--force` | `-f` | Skip all confirmation prompts, auto-approve all phases |

**Staged changes mode only:**

| Flag | Short | Effect |
|------|-------|--------|
| `--skip-issue` | `-i` | Skip issue creation |

**Issue mode only:**

| Flag | Short | Effect |
|------|-------|--------|
| `--squash` | `-s` | Pass `--squash` to auto-mr |
| `--msg "text"` | `-m "text"` | Custom MR message for auto-mr |
| `--skip-mr` | none | Skip auto-mr phase (I-8) |

**Flag parsing:** Split `$argument` by spaces. Tokens starting with `--` or `-` are flags. `#<number>` or bare `<number>` as first positional → Issue Mode. Remaining non-flag text → context for branch/commit description. `--worktree-path` / `-w` consumes the next token as its value.

**Dry run (`--dry-run`):** Executes discovery/retrieval phases, displays all proposed actions (worktree path, branch, issue, commit, implementation plan, lint/test commands), but does NOT execute any mutations. Ends with "Dry run complete. No changes made."

**Force mode (`--force`):** Skips all AskUserQuestion calls, auto-approves all phases. Still displays progress and aborts on errors.

## When to Use `feature-flow-w` vs `feature-flow`

| Use case | Command |
|----------|---------|
| Work on multiple features in parallel | `feature-flow-w` |
| Keep current branch untouched | `feature-flow-w` |
| Simple single-feature workflow | `feature-flow` |
| Branch switching is acceptable | `feature-flow` |
| CI running on current branch, need to start new work | `feature-flow-w` |

## Integration

Works with `/create-issue` (same CLI logic), `/commit` (same conventional format), and `/analyze-pr` (compatible output).

## Examples

### Staged Changes Mode

```bash
# Stage files, create worktree → branch + issue + commit
git add api/user.go api/user_test.go
/feature-flow-w

# Custom worktree location
git add api/user.go
/feature-flow-w --worktree-path ~/worktrees/user-feature

# Skip issue creation for trivial changes
git add docs/README.md
/feature-flow-w --skip-issue

# Preview without executing
git add database/schema.sql
/feature-flow-w --dry-run

# Minimal workflow: commit only (no worktree, no issue)
git add config.yml
/feature-flow-w --skip-branch --skip-issue
```

### Issue Mode

```bash
# Full workflow from issue (creates worktree)
/feature-flow-w #42

# With squash merge
/feature-flow-w #42 --squash

# Custom worktree path
/feature-flow-w #42 --worktree-path ../my-project-issue-42

# Implement and commit only, no MR
/feature-flow-w #42 --skip-mr

# Auto-approve everything
/feature-flow-w #42 --force --squash
```

## Error Handling

### Staged Changes Mode Errors

| # | Error | Message / Action |
|---|-------|-----------------|
| 1 | No staged changes | "No staged changes found. Stage files with 'git add <file>' first." |
| 2 | Not a git repository | "Not a git repository. Initialize with 'git init' first." |
| 3 | Branch already exists | Suggest `<name>-v2` or ask for alternative |
| 4 | Worktree directory already exists | Suggest `<path>-v2` or ask for alternative |
| 5 | Branch checked out in another worktree | Display the other worktree path, ask for different branch name |
| 6 | Patch apply fails | Remove worktree, display error, suggest manual resolution |
| 7 | Pre-commit hook fails | Display hook output, abort, suggest fixing and retrying |
| 8 | `gh`/`glab` CLI not found (issue) | Skip issue creation, warn, continue to commit |
| 9 | Invalid labels | Remove invalid labels silently, warn user |
| 10 | Issue creation fails | Log error, continue to commit without issue reference |
| 11 | Commit fails | Display git error, abort |
| 12 | `.gitmodules` detected | Run `git submodule update --init --recursive` in new worktree |

### Issue Mode Errors

| # | Error | Message / Action |
|---|-------|-----------------|
| 13 | Issue not found | "Issue #N not found in <owner/repo>." Abort. |
| 14 | `gh`/`glab` CLI not found (retrieval) | "Cannot retrieve issue. Install `gh` or `glab` CLI first." Abort. |
| 15 | Worktree directory already exists | Suggest `<path>-v2` or ask for alternative |
| 16 | Branch checked out in another worktree | Display the other worktree path, ask for different branch name |
| 17 | Lint failure | Display errors, attempt auto-fix, ask user to continue or abort |
| 18 | Test failure | Display output, attempt fix (max 2 retries), ask user |
| 19 | auto-mr not installed | Warn, show manual push: `git push -u origin <branch-name>` |
| 20 | auto-mr fails | Show error, provide manual push command and MR URL |
| 21 | `.gitmodules` detected | Run `git submodule update --init --recursive` in new worktree |

## Best Practices

- Stage only related files for cohesive branch/issue/commit (staged mode)
- Use `--dry-run` first to preview either mode
- Use `--skip-issue` for trivial changes (staged mode)
- Use custom context for better branch names: `/feature-flow-w add OAuth2 integration`
- Use `--worktree-path` when the default path is too long or you prefer a specific location
- Use `--skip-mr` to commit without creating a merge request (issue mode)
- Clean up worktrees after merging: `git worktree remove <path> && git branch -d <branch>`
- List active worktrees: `git worktree list`
- Combine with existing commands: `/feature-flow-w` → work in worktree → `/commit` → `/analyze-pr`
