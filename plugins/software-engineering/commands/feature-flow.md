---
name: feature-flow
description: Complete git workflow orchestration - branch, issue, commit
argument-hint: "[context | #issue-number] [--skip-branch] [--skip-issue] [--skip-mr] [--squash] [--msg \"text\"] [--dry-run] [--force]"
allowed-tools: Read, Write, Edit, Grep, Glob, Skill, Bash(git:*), Bash(make:*), Bash(npm:*), Bash(npx:*), Bash(go:*), Bash(python:*), Bash(cargo:*), Bash(task:*), Bash(golangci-lint:*), Bash(eslint:*), Bash(ruff:*), Bash(mypy:*), Bash(auto-mr:*), Bash(gh:*), Bash(glab:*), AskUserQuestion
---

# Feature Flow Command

Orchestrate a complete git workflow for feature development. Two modes:

1. **Staged Changes Mode** (default): Analyze staged changes → branch → create issue → commit
2. **Issue Mode** (`#<number>`): Retrieve issue → branch → implement → lint → test → verify → commit → merge

Automates repetitive workflow setup (branching, issues, commits, quality checks, merge requests).

## Mode Detection

**Route based on `$argument`:** first positional argument matching `#<number>` or bare `<number>` → **Issue Mode**; otherwise → **Staged Changes Mode**.

Issue Mode examples: `/feature-flow #42`, `/feature-flow 42 --squash`
Staged Mode examples: `/feature-flow`, `/feature-flow add user auth`, `/feature-flow --skip-issue`

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

### Phase 2: Branch Creation (User Confirmation)

**Parse flags:** `--skip-branch` or `-b` → skip this phase.

**If not skipped:**

1. Check current branch: `git rev-parse --abbrev-ref HEAD`
2. Display proposed branch name
3. Ask confirmation via AskUserQuestion: "Create branch '<proposed-name>'?" with options: "Yes, create this branch", "Use different name", "Skip branch creation"
4. Handle response:
   - "Yes, create": `git checkout -b <branch-name>`, verify
   - "Use different name": Ask for custom name, then create
   - "Skip": Continue on current branch

**Error handling:**
- Branch exists → Suggest `<name>-v2` or ask for alternative
- Git error → Display error, abort

### Phase 3: Issue Creation (User Confirmation)

**Parse flags:** `--skip-issue` or `-i` → skip this phase.

**If not skipped:**

1. **List available labels** (same pattern as `/create-issue` command):
   - GitHub: `gh label list --repo <owner>/<repo>`
   - GitLab: `glab label list`

2. **Generate issue content** following `/create-issue` conventions:
   - Title: under 80 chars, imperative mood, based on change type and scope
   - Description: Overview + Changes list + Testing section + Branch reference
   - Labels: map type to labels (`feat`→enhancement, `fix`→bug, `docs`→documentation, etc.), validate against available labels

3. Display preview, ask confirmation: "Create issue with this content?" → "Yes, create issue" / "Skip issue creation"

4. Create issue if approved:
   - GitHub: `gh issue create --repo <owner>/<repo> --title "<title>" --body "<body>" --label "<label1>" --label "<label2>" --assignee @me`
   - GitLab: `glab issue create --title "<title>" --description "<body>" --label "<label1>" --label "<label2>" --assignee "$(glab api user | jq -r '.username')"`
   - Parse issue number from command output; store for Phase 4

**Error handling:**
- `gh`/`glab` CLI not installed → Skip issue creation, warn, continue to commit
- Invalid labels → Remove silently, warn user
- Issue creation fails → Log error, continue to Phase 4 without issue reference

### Phase 4: Commit Execution (User Confirmation)

**Generate conventional commit message** following `/commit` command format (see `commit.md` for full spec):
- Type from branch name or change analysis
- Scope from primary directory
- Description: imperative mood, lowercase, under 50 chars, no period
- Body: bullet points for multi-file changes
- Footer: `Closes #<issue-number>` (always use `Closes`, not `Refs`, when an issue was created in Phase 3)
- **CRITICAL**: NO Claude Code attribution (per commit command's no-attribution policy)

**Display preview, ask confirmation:** "Commit with this message?" → "Yes, commit now" / "Edit message" / "Cancel workflow"

**Execute:** `git commit -m "<message>"`, verify with `git log -1 --oneline`.

**Error handling:**
- Pre-commit hook fails → Display error, abort, provide recovery steps
- Commit fails → Display git error, abort

### Phase 5: Summary & Next Steps (Automatic)

Display workflow summary showing completed steps (branch created, issue created, commit hash) and next steps: push branch, create PR/MR, continue development.

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

### Phase I-2: Branch Creation (User Confirmation)

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

3. Ask confirmation via AskUserQuestion, handle response same as Phase 2.

**Error handling:** Same as Phase 2 (branch exists → suggest alternative, git error → abort).

### Phase I-3: AI Implementation (User Confirmation)

1. Read issue body as specification; parse requirements and target files
2. Analyze project structure using Glob/Read to find relevant files and conventions
3. Implement solution using Write/Edit; follow existing code style; include tests if module has them
4. Display change summary (files created/modified)
5. Ask confirmation: "Implementation complete. Review changes and continue?" → "Yes, continue to lint & test" / "Make adjustments" / "Cancel workflow"

### Phase I-4: Lint (Automatic)

**Use the `run-lint` skill** to auto-detect and execute the project linter. If lint fails, ask user whether to continue.

### Phase I-5: Test (Automatic)

**Use the `run-tests` skill** to auto-detect and execute the project test runner. If tests fail, ask user whether to continue.

### Phase I-6: Verification (User Confirmation)

1. Re-run lint and tests to confirm clean
2. Display `git diff --stat` summary
3. Show pass/fail gate: Lint ✓/⚠/✗, Tests ✓/⚠/✗, file stats
4. Ask confirmation: "Verification complete. Proceed to commit?" → "Yes, commit changes" / "Go back and fix issues" / "Cancel workflow"

### Phase I-7: Commit (User Confirmation)

1. Stage implementation files: `git add <files from Phase I-3>` (only created/modified files)
2. Generate conventional commit per Phase 4 format, with: type from Phase I-2, scope from issue, footer `Closes #<N>`
3. **CRITICAL**: NO Claude Code attribution
4. Display preview, ask confirmation, execute commit, verify with `git log -1 --oneline`

**Error handling:** Pre-commit hook fails → abort with recovery steps; commit fails → abort.

**On successful commit:** Immediately proceed to Phase I-8.

### Phase I-8: Merge via auto-mr (Automatic, Skippable)

**Parse flags:** `--skip-mr` → skip this phase.

**Build command:** `auto-mr [--squash] [--msg "<message>"]`
- `--squash`: if `-s` flag was passed
- `--msg`: default `<type>(<scope>): <issue-title> (Closes #<N>)`, override with user's `--msg`

**Execute:** Run `auto-mr` → on success display MR/PR URL → on failure warn and show manual push instructions.

**Display summary** showing all completed steps (issue retrieved, branch, implementation, lint, tests, commit, MR) with URLs and hashes.

## Flag Support

**Both modes:**

| Flag | Short | Effect |
|------|-------|--------|
| `--skip-branch` | `-b` | Skip branch creation, stay on current branch |
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

**Flag parsing:** Split `$argument` by spaces. Tokens starting with `--` or `-` are flags. `#<number>` or bare `<number>` as first positional → Issue Mode. Remaining non-flag text → context for branch/commit description.

**Dry run (`--dry-run`):** Executes discovery/retrieval phases, displays all proposed actions (branch, issue, commit, implementation plan, lint/test commands), but does NOT execute any mutations. Ends with "Dry run complete. No changes made."

**Force mode (`--force`):** Skips all AskUserQuestion calls, auto-approves all phases. Still displays progress and aborts on errors.

## Integration

Works with `/create-issue` (same CLI logic), `/commit` (same conventional format), and `/analyze-pr` (compatible output).

## Examples

### Staged Changes Mode

```bash
# Stage files, run command → branch + issue + commit
git add api/user.go api/user_test.go
/feature-flow

# Skip issue creation for trivial changes
git add docs/README.md
/feature-flow --skip-issue

# Preview without executing
git add database/schema.sql
/feature-flow --dry-run

# Minimal workflow: commit only (no branch, no issue)
git add config.yml
/feature-flow --skip-branch --skip-issue
```

### Issue Mode

```bash
# Full workflow from issue
/feature-flow #42

# With squash merge
/feature-flow #42 --squash

# Implement and commit only, no MR
/feature-flow #42 --skip-mr

# Auto-approve everything
/feature-flow #42 --force --squash
```

## Error Handling

### Staged Changes Mode Errors

| # | Error | Message / Action |
|---|-------|-----------------|
| 1 | No staged changes | "No staged changes found. Stage files with 'git add <file>' first." |
| 2 | Not a git repository | "Not a git repository. Initialize with 'git init' first." |
| 3 | Branch already exists | Suggest `<name>-v2` or ask for alternative |
| 4 | Pre-commit hook fails | Display hook output, abort, suggest fixing and retrying |
| 5 | `gh`/`glab` CLI not found (issue) | Skip issue creation, warn, continue to commit |
| 6 | Invalid labels | Remove invalid labels silently, warn user |
| 7 | Issue creation fails | Log error, continue to commit without issue reference |
| 8 | Commit fails | Display git error, abort |

### Issue Mode Errors

| # | Error | Message / Action |
|---|-------|-----------------|
| 9 | Issue not found | "Issue #N not found in <owner/repo>." Abort. |
| 10 | `gh`/`glab` CLI not found (retrieval) | "Cannot retrieve issue. Install `gh` or `glab` CLI first." Abort. |
| 11 | Lint failure | Display errors, attempt auto-fix, ask user to continue or abort |
| 12 | Test failure | Display output, attempt fix (max 2 retries), ask user |
| 13 | auto-mr not installed | Warn, show manual push: `git push -u origin <branch-name>` |
| 14 | auto-mr fails | Show error, provide manual push command and MR URL |

## Best Practices

- Stage only related files for cohesive branch/issue/commit (staged mode)
- Use `--dry-run` first to preview either mode
- Use `--skip-issue` for trivial changes (staged mode)
- Use custom context for better branch names: `/feature-flow add OAuth2 integration`
- Use `--skip-mr` to commit without creating a merge request (issue mode)
- Combine with existing commands: `/feature-flow` → work → `/commit` → `/analyze-pr`
