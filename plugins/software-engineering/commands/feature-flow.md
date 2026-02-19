---
name: feature-flow
description: Complete git workflow orchestration - branch, issue, commit
argument-hint: "[context | #issue-number] [--skip-branch] [--skip-issue] [--skip-lint] [--skip-test] [--skip-mr] [--squash] [--msg \"text\"] [--dry-run] [--force]"
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(git:*), Bash(make:*), Bash(npm:*), Bash(npx:*), Bash(go:*), Bash(python:*), Bash(cargo:*), Bash(task:*), Bash(golangci-lint:*), Bash(eslint:*), Bash(ruff:*), Bash(mypy:*), Bash(auto-mr:*), mcp__github__create_issue, mcp__github__issue_read, mcp__github__list_labels, mcp__gitlab-mcp__create_issues, mcp__gitlab-mcp__list_issues, mcp__gitlab-mcp__list_labels, AskUserQuestion
---

# Feature Flow Command

Orchestrate a complete git workflow for feature development. Supports two modes:

1. **Staged Changes Mode** (default): Analyze staged changes → branch → create issue → commit
2. **Issue Mode** (`#<number>`): Retrieve issue → branch → implement → lint → test → verify → commit → merge

This command automates the repetitive steps developers perform when starting or completing work.

## Why This Command Exists

**Problem**: Developers spend time on repetitive workflow setup - creating branches, writing issues, formatting commits, running quality checks, and creating merge requests.

**Solution**: Automated orchestration that:
- Analyzes staged changes or fetches issue specifications
- Proposes conventional branch names
- Creates tracking issues or implements from existing ones
- Runs lint and test quality gates (issue mode)
- Commits with conventional commit format
- Creates merge requests via auto-mr (issue mode)
- Ensures consistent workflow across the team

## Mode Detection

**Route based on `$argument`:**

1. **Parse first positional argument** (non-flag token):
   - If matches `#<number>` or bare `<number>` (e.g., `#42`, `42`) → **Issue Mode**
   - Otherwise → **Staged Changes Mode**

2. **Issue Mode** requires a valid issue number:
   ```
   /feature-flow #42              → Issue Mode, issue=42
   /feature-flow 42 --squash      → Issue Mode, issue=42, squash=true
   /feature-flow #42 --dry-run    → Issue Mode, issue=42, dry_run=true
   ```

3. **Staged Changes Mode** uses remaining text as context:
   ```
   /feature-flow                  → Staged Changes Mode, no context
   /feature-flow add user auth    → Staged Changes Mode, context="add user auth"
   /feature-flow --skip-issue     → Staged Changes Mode, skip_issue=true
   ```

## Staged Changes Mode (5 Phases)

### Phase 1: Discovery & Validation (Automatic)

**Execute parallel git commands:**
```bash
git status
git diff --staged
git remote -v
```

**Analysis steps:**
1. **Detect repository host** from remote URL (pattern from create-issue.md):
   - GitHub: `github.com`
   - GitLab: `gitlab.com` or self-hosted GitLab
   - Abort if unsupported host

2. **Analyze staged changes:**
   - Extract file paths, extensions, and types
   - Determine change type:
     - New files/functions → `feat`
     - Test files + fixes → `fix`
     - Only docs (*.md, *.txt) → `docs`
     - Structural changes, renames → `refactor`
     - Build/config files → `chore`
   - Extract primary scope from directory:
     - `src/api/` → `api`
     - `internal/auth/` → `auth`
     - `pkg/database/` → `database`
     - `cmd/server/` → `server`

3. **Generate proposed branch name:**
   - Format: `<type>/<scope>-<description>`
   - Types: feat, fix, refactor, docs, chore, test, perf, ci
   - Scope: Primary directory/module (lowercase, no spaces)
   - Description: 2-4 words, kebab-case, from file/function names
   - Examples:
     - `feat/api-user-profile`
     - `fix/auth-jwt-validation`
     - `docs/readme-update`
     - `refactor/database-connection-pool`

**Error handling:**
- No staged changes → Abort: "No staged changes found. Stage files with 'git add' first."
- Not a git repo → Abort: "Not a git repository. Initialize with 'git init' first."
- Unsupported host → Abort: "Only GitHub and GitLab are supported."

### Phase 2: Branch Creation (User Confirmation)

**Parse flags from $argument:**
- If contains `--skip-branch` or `-b`: Skip this phase entirely

**If not skipped:**

1. **Check current branch:**
   ```bash
   git rev-parse --abbrev-ref HEAD
   ```

2. **Display proposed branch name** to user

3. **Ask confirmation** via AskUserQuestion:
   ```
   Question: "Create branch '<proposed-name>'?"
   Options:
     - "Yes, create this branch"
     - "Use different name"
     - "Skip branch creation"
   ```

4. **Handle response:**
   - **"Yes, create"**: Execute `git checkout -b <branch-name>`, verify with `git rev-parse --abbrev-ref HEAD`
   - **"Use different name"**: Ask for custom name, then create with custom name
   - **"Skip branch creation"**: Continue on current branch, skip to Phase 3

**Error handling:**
- Branch exists → Check if identical (`git rev-parse --verify <branch-name>`):
  - If exists: Suggest `<name>-v2` or ask for alternative name
  - Retry with new name
- Git error → Display error message, abort workflow

### Phase 3: Issue Creation (User Confirmation)

**Parse flags from $argument:**
- If contains `--skip-issue` or `-i`: Skip this phase entirely

**If not skipped:**

1. **List available labels** using MCP (pattern from create-issue.md):
   - GitHub: `mcp__github__list_labels`
   - GitLab: `mcp__gitlab-mcp__list_labels`
   - Store labels for validation

2. **Generate issue content:**

   **Title generation:**
   - Under 80 characters
   - Imperative mood ("Add", "Fix", "Update", "Refactor")
   - Based on branch description and change type
   - Examples:
     - `feat/api-user-profile` → "Add user profile API endpoint"
     - `fix/auth-jwt` → "Fix JWT token validation in auth module"
     - `docs/readme` → "Update README with installation instructions"

   **Description structure:**
   ```markdown
   ## Overview
   [Brief explanation of the change based on file analysis]

   ## Changes
   - [File 1]: [Description of change]
   - [File 2]: [Description of change]
   [Continue for all modified files]

   ## Testing
   [If test files present, describe test approach]
   [If no test files, mention "Tests pending"]

   Branch: `<branch-name>`
   ```

   **Label suggestions** (only use labels that exist):
   - `feat/*` → enhancement, feature
   - `fix/*` → bug, bugfix
   - `docs/*` → documentation
   - `refactor/*` → refactoring
   - `test/*` → testing
   - `chore/*` → maintenance
   - Validate against available labels, remove invalid ones

3. **Display issue preview** to user

4. **Ask confirmation** via AskUserQuestion:
   ```
   Question: "Create issue with this content?"
   Options:
     - "Yes, create issue"
     - "Skip issue creation"
   ```

5. **Create issue** if approved (pattern from create-issue.md):
   - GitHub: `mcp__github__create_issue(owner, repo, title, body, labels)`
   - GitLab: `mcp__gitlab-mcp__create_issues(project_path, title, description, labels)`
   - Extract issue number from response (e.g., #123)
   - Store issue number for Phase 4

**Error handling:**
- MCP server unavailable → Skip issue creation, warn user, continue to commit
- Label doesn't exist → Remove invalid labels from suggestion
- Issue creation fails → Log error, continue to Phase 4 without issue reference

### Phase 4: Commit Execution (User Confirmation)

**Parse flags from $argument:**
- Extract any non-flag text as commit context/override

**Generate conventional commit message** (pattern from commit.md):

1. **Determine type** (from branch name or change analysis):
   - Valid types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert

2. **Extract scope** (from primary directory):
   - Lowercase, no spaces
   - Examples: api, auth, database, ui

3. **Write description:**
   - Present tense, imperative mood ("add" not "adds" or "added")
   - Lowercase start
   - No period at end
   - Under 50 characters
   - Be specific and concise

4. **Add body** (for multi-file changes):
   - Use bullet points
   - One bullet per significant change
   - Format: `- [Action] [what changed]`

5. **Add footer:**
   - `Closes #<issue-number>` (for fixes)
   - Never include breaking changes without user consent

**Format example:**
```
feat(api): add user profile endpoint

- Implement GET /api/profile endpoint
- Add ProfileHandler with authentication
- Include unit tests for profile operations

Refs #123
```

**CRITICAL**: NO Claude Code attribution (per commit.md:19,23,87)

**Display commit message preview**

**Ask confirmation** via AskUserQuestion:
```
Question: "Commit with this message?"
Options:
  - "Yes, commit now"
  - "Edit message"
  - "Cancel workflow"
```

**Handle response:**
- **"Yes, commit now"**: Execute commit
- **"Edit message"**: Ask for modifications, regenerate, show preview again
- **"Cancel workflow"**: Abort, no changes made

**Execute commit:**
```bash
git commit -m "<message>"
```

Verify with:
```bash
git log -1 --oneline
```

**Error handling:**
- Pre-commit hook fails:
  - Display hook error output
  - Abort workflow
  - Provide recovery steps: "Fix issues reported by pre-commit hook, then retry"
- Commit fails:
  - Display git error
  - Abort workflow
  - Suggest checking staged changes

### Phase 5: Summary & Next Steps (Automatic)

**Display workflow summary:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature Flow Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[If branch created:]
✓ Created branch: <branch-name>

[If issue created:]
✓ Created issue: #<number> (<issue-url>)

[Always:]
✓ Committed changes: <commit-hash> "<commit-message-first-line>"

Next steps:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Push branch: git push -u origin <branch-name>
2. Create PR:
   - GitHub: gh pr create (or use GitHub UI)
   - GitLab: Visit: <gitlab-url>/-/merge_requests/new
3. Continue development on this branch
```

## Issue Mode Process (8 Phases)

### Phase I-1: Issue Retrieval (Automatic)

**Execute parallel git commands:**
```bash
git remote -v
git rev-parse --abbrev-ref HEAD
```

**Detect repository host** from remote URL:
- GitHub: `github.com` → extract `owner/repo`
- GitLab: `gitlab.com` or self-hosted → extract `project_path`
- Abort if unsupported host

**Fetch issue details:**
- GitHub: `mcp__github__issue_read(method="get", owner, repo, issue_number)`
- GitLab: `mcp__gitlab-mcp__list_issues(project_path, state="opened")` → filter by IID

**Extract from issue:**
- Title → used for branch name, commit message, MR title
- Body → used as implementation spec in Phase I-3
- Labels → used for type detection in Phase I-2

**Error handling:**
- Issue not found → Abort: "Issue #N not found in <owner/repo>."
- MCP unavailable → Abort: "Cannot connect to GitHub/GitLab. Issue retrieval requires MCP."

### Phase I-2: Branch Creation (User Confirmation)

**Parse flags from $argument:**
- If contains `--skip-branch` or `-b`: Skip this phase entirely

**If not skipped:**

1. **Derive branch type from issue labels:**
   - Labels containing `bug`, `bugfix`, `fix` → `fix`
   - Labels containing `enhancement`, `feature` → `feat`
   - Labels containing `documentation`, `docs` → `docs`
   - Labels containing `refactor` → `refactor`
   - Labels containing `test` → `test`
   - Labels containing `ci`, `ci-cd` → `ci`
   - Labels containing `performance` → `perf`
   - Default (no matching labels) → `feat`

2. **Generate branch name:**
   - Format: `<type>/<scope>-issue-<N>`
   - Scope: derived from issue title (first noun/module, kebab-case, 2-4 words)
   - Examples:
     - Issue #42 "Add user profile API" (label: enhancement) → `feat/user-profile-api-issue-42`
     - Issue #15 "Fix JWT expiration" (label: bug) → `fix/jwt-expiration-issue-15`
     - Issue #8 "Update README" (label: documentation) → `docs/readme-issue-8`

3. **Ask confirmation** via AskUserQuestion:
   ```
   Question: "Create branch '<proposed-name>' for issue #N?"
   Options:
     - "Yes, create this branch"
     - "Use different name"
     - "Skip branch creation"
   ```

4. **Handle response:**
   - **"Yes, create"**: Execute `git checkout -b <branch-name>`, verify
   - **"Use different name"**: Ask for custom name, then create
   - **"Skip branch creation"**: Continue on current branch

**Error handling:**
- Branch exists → Suggest `<name>-v2` or ask for alternative
- Git error → Display error, abort

### Phase I-3: AI Implementation (User Confirmation)

1. **Read issue body as specification:**
   - Parse requirements, acceptance criteria, and technical details from issue description
   - Identify target files and modules mentioned

2. **Analyze project structure:**
   ```bash
   # Discover project layout
   ```
   - Use Glob to find relevant source files matching the issue scope
   - Use Read to understand existing code patterns and conventions
   - Identify where new code should be placed

3. **Implement solution:**
   - Use Write/Edit tools to create or modify files
   - Follow existing code style and conventions
   - Include necessary imports/dependencies
   - Add or update tests if test files exist for the module

4. **Display change summary:**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Implementation Summary (Issue #N)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Files created:
     + path/to/new_file.ext
   Files modified:
     ~ path/to/existing_file.ext
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

5. **Ask confirmation** via AskUserQuestion:
   ```
   Question: "Implementation complete. Review changes and continue?"
   Options:
     - "Yes, continue to lint & test"
     - "Make adjustments"
     - "Cancel workflow"
   ```

### Phase I-4: Lint (Automatic, Skippable)

**Parse flags from $argument:**
- If contains `--skip-lint` or `-l`: Skip this phase entirely

**Lint detection algorithm** (first match wins):

1. **Taskfile** (Taskfile.yml exists) → check if `lint` task defined:
   ```bash
   task lint
   ```
2. **Makefile** (Makefile exists) → check if `lint` target defined:
   ```bash
   make lint
   ```
3. **Go** (go.mod exists):
   ```bash
   golangci-lint run ./...
   ```
   Fallback if golangci-lint not installed:
   ```bash
   go vet ./...
   ```
4. **Node.js** (package.json exists) → check if `lint` script defined:
   ```bash
   npm run lint
   ```
   Fallback:
   ```bash
   npx eslint .
   ```
5. **Python** (pyproject.toml or setup.py exists):
   ```bash
   ruff check .
   ```
   Fallback:
   ```bash
   python -m flake8 .
   ```
6. **Rust** (Cargo.toml exists):
   ```bash
   cargo clippy -- -D warnings
   ```
7. **None detected** → Warn: "No linter detected. Skipping lint phase." and continue.

**On lint failure:**
- Display lint errors
- Attempt auto-fix if linter supports it (e.g., `golangci-lint run --fix`, `ruff check --fix`, `eslint --fix`)
- Re-run lint after fix
- If still failing, display remaining errors and ask user whether to continue

### Phase I-5: Test (Automatic, Skippable)

**Parse flags from $argument:**
- If contains `--skip-test` or `-t`: Skip this phase entirely

**Test detection algorithm** (first match wins):

1. **Taskfile** (Taskfile.yml exists) → check if `test` task defined:
   ```bash
   task test
   ```
2. **Makefile** (Makefile exists) → check if `test` target defined:
   ```bash
   make test
   ```
3. **Go** (go.mod exists):
   ```bash
   go test ./...
   ```
4. **Node.js** (package.json exists) → check if `test` script defined:
   ```bash
   npm test
   ```
   Fallback (check for test runner config):
   ```bash
   npx jest
   # or
   npx vitest run
   ```
5. **Python** (pyproject.toml or setup.py exists):
   ```bash
   python -m pytest
   ```
6. **Rust** (Cargo.toml exists):
   ```bash
   cargo test
   ```
7. **None detected** → Warn: "No test runner detected. Skipping test phase." and continue.

**On test failure:**
- Display test output
- Attempt fix (max 2 retries): analyze failure, apply fix via Edit, re-run
- If still failing after retries, display failures and ask user whether to continue

### Phase I-6: Verification (User Confirmation)

1. **Re-run lint** (unless `--skip-lint`): confirm clean
2. **Re-run tests** (unless `--skip-test`): confirm passing
3. **Display diff summary:**
   ```bash
   git diff --stat
   ```
4. **Show pass/fail gate:**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Verification Results
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Lint:  ✓ passed  (or ⚠ skipped / ✗ failed)
   Tests: ✓ passed  (or ⚠ skipped / ✗ failed)
   Files: N files changed, +X insertions, -Y deletions
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```
5. **Ask confirmation** via AskUserQuestion:
   ```
   Question: "Verification complete. Proceed to commit?"
   Options:
     - "Yes, commit changes"
     - "Go back and fix issues"
     - "Cancel workflow"
   ```

### Phase I-7: Commit (User Confirmation)

1. **Stage implementation files:**
   ```bash
   git add <list of created/modified files from Phase I-3>
   ```
   Only stage files that were created or modified during the implementation.

2. **Generate conventional commit message:**
   - Type: from branch type (Phase I-2)
   - Scope: from issue scope
   - Description: from issue title (imperative mood, lowercase, under 50 chars)
   - Body: bullet points of significant changes
   - Footer: `Closes #<N>`

   **Format:**
   ```
   <type>(<scope>): <description>

   - Change 1
   - Change 2

   Closes #<N>
   ```

3. **CRITICAL**: NO Claude Code attribution (per commit.md:19,23,87)

4. **Display commit message preview**

5. **Ask confirmation** via AskUserQuestion:
   ```
   Question: "Commit with this message?"
   Options:
     - "Yes, commit now"
     - "Edit message"
     - "Cancel workflow"
   ```

6. **Execute commit:**
   ```bash
   git commit -m "<message>"
   ```
   Verify with `git log -1 --oneline`.

**Error handling:**
- Pre-commit hook fails → Display error, abort, provide recovery steps
- Commit fails → Display git error, abort

### Phase I-8: Merge via auto-mr (Automatic, Skippable)

**Parse flags from $argument:**
- If contains `--skip-mr`: Skip this phase entirely

**Build auto-mr command:**
```bash
auto-mr [--squash] [--msg "<message>"]
```

- `--squash`: Include if `--squash` or `-s` flag was passed
- `--msg`: Default message: `<type>(<scope>): <issue-title> (Closes #<N>)`
  - Override with `--msg "custom text"` if provided by user

**Execute:**
1. Run `auto-mr` command
2. On success: display MR/PR URL
3. On failure or not installed:
   - Warn: "auto-mr not available or failed. Commit preserved."
   - Show manual push instructions:
     ```
     Manual steps:
       git push -u origin <branch-name>
       Then create MR/PR via web UI or CLI
     ```

**Summary display:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Issue Flow Complete (Issue #N)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Retrieved issue: #N "<issue-title>"
[If branch created:]
✓ Created branch: <branch-name>
✓ Implemented solution: N files changed
[If lint ran:]
✓ Lint: passed
[If tests ran:]
✓ Tests: passed
✓ Committed: <commit-hash> "<commit-first-line>"
[If auto-mr ran:]
✓ Merge request: <MR-URL>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Flag Support

**Flags for both modes:**

| Flag | Short | Effect |
|------|-------|--------|
| `--skip-branch` | `-b` | Skip branch creation, stay on current branch |
| `--dry-run` | `-n` | Show what would be done without executing (preview mode) |
| `--force` | `-f` | Skip all confirmation prompts, auto-approve all phases |

**Staged changes mode only:**

| Flag | Short | Effect |
|------|-------|--------|
| `--skip-issue` | `-i` | Skip issue creation, no tracking issue |

**Issue mode only:**

| Flag | Short | Effect |
|------|-------|--------|
| `--squash` | `-s` | Pass `--squash` to auto-mr |
| `--msg "text"` | `-m "text"` | Custom MR message for auto-mr |
| `--skip-lint` | `-l` | Skip lint phase (I-4) |
| `--skip-test` | `-t` | Skip test phase (I-5) |
| `--skip-mr` | none | Skip auto-mr phase (I-8), commit only |

**Flag parsing:**
```
# Split $argument by spaces
# Check each token:
#   - If starts with "--" or "-": it's a flag
#   - "#<number>" or bare "<number>" as first positional: issue number → Issue Mode
#   - Otherwise: it's context for branch/commit description (Staged Changes Mode)
# Examples (Staged Changes Mode):
#   "--skip-issue add user auth" → skip_issue=true, context="add user auth"
#   "-b -f" → skip_branch=true, force=true
# Examples (Issue Mode):
#   "#42 --squash" → issue=42, squash=true
#   "42 --skip-lint --skip-test" → issue=42, skip_lint=true, skip_test=true
#   "#42 --msg 'custom message'" → issue=42, msg="custom message"
```

**Dry run mode (--dry-run):**

*Staged Changes Mode:*
- Execute Phase 1 (discovery)
- Display proposed branch name
- Display proposed issue content
- Display proposed commit message
- DO NOT execute: branch creation, issue creation, commit
- Show summary: "Dry run complete. No changes made."

*Issue Mode:*
- Execute Phase I-1 (issue retrieval)
- Display issue details and proposed branch name
- Display implementation plan (files to create/modify)
- Display lint and test commands that would run
- Display proposed commit message and auto-mr command
- DO NOT execute: branch creation, implementation, lint, test, commit, auto-mr
- Show summary: "Dry run complete. No changes made."

**Force mode (--force):**
- Skip all AskUserQuestion calls
- Auto-approve all phases
- Still display what's happening
- Still abort on errors

## Branch Naming Intelligence

**Algorithm:**

1. **Analyze file extensions:**
   - `.go`, `.mod` → Go code
   - `.js`, `.ts`, `.jsx`, `.tsx` → JavaScript/TypeScript
   - `.py` → Python
   - `.rs` → Rust
   - `.java` → Java
   - `.md`, `.txt`, `.rst` → Documentation

2. **Detect change type:**
   - New files (git status shows `??` or `A`) → `feat`
   - Modified files with test files → `test` or `fix`
   - Only documentation files → `docs`
   - Structural changes (file moves, renames) → `refactor`
   - Build files (Dockerfile, Makefile, package.json, go.mod) → `chore`
   - CI/CD files (.github/workflows/, .gitlab-ci.yml) → `ci`

3. **Extract scope:**
   - Use primary directory (deepest common path)
   - Remove prefixes: `src/`, `internal/`, `pkg/`, `cmd/`
   - Convert to lowercase
   - Replace spaces/underscores with hyphens
   - Examples:
     - `src/api/handlers/user.go` → `api`
     - `internal/auth/jwt.go` → `auth`
     - `pkg/database/postgres/connection.go` → `database`

4. **Generate description:**
   - Extract from file base names:
     - `user_profile.go` → `user-profile`
     - `jwt_validator.py` → `jwt-validator`
   - Or use function names (if new functions detected):
     - `func HandleUserProfile()` → `handle-user-profile`
   - Limit to 2-4 words
   - Use kebab-case

**Examples:**

| Files | Generated Branch |
|-------|-----------------|
| `api/user.go`, `api/user_test.go` | `feat/api-user-endpoint` |
| `auth/jwt.go` (bug fix) | `fix/auth-jwt-validation` |
| `docs/README.md`, `docs/CONTRIBUTING.md` | `docs/readme-contributing` |
| `database/migrations/001_users.sql` | `feat/database-users-migration` |
| `.github/workflows/ci.yml` | `ci/github-workflows` |
| `Dockerfile`, `docker-compose.yml` | `chore/docker-config` |

## Issue Content Quality

**Title generation rules:**
- Maximum 80 characters
- Use imperative mood:
  - `feat` → "Add [feature]"
  - `fix` → "Fix [problem]"
  - `docs` → "Update [documentation]"
  - `refactor` → "Refactor [component]"
  - `chore` → "Update [dependency/config]"
- Be specific: "Add user profile API endpoint" not "Add endpoint"
- Based on scope and file names

**Description structure:**

```markdown
## Overview
[1-2 sentences explaining the purpose of this change]

## Changes
[List of files with brief descriptions]
- path/to/file1.ext: [What changed and why]
- path/to/file2.ext: [What changed and why]

[If test files present:]
## Testing
- Unit tests: [describe test coverage]
- Integration tests: [if applicable]
- Manual testing: [steps if needed]

[If no test files:]
## Testing
Tests pending - will be added in follow-up commit.

Branch: `<branch-name>`
```

**Label suggestions:**

Only suggest labels that exist in the repository (validated via list_labels).

**Type to label mapping:**
- `feat` → `enhancement`, `feature`, `new-feature`
- `fix` → `bug`, `bugfix`, `fix`
- `docs` → `documentation`, `docs`
- `test` → `testing`, `tests`
- `refactor` → `refactoring`, `code-quality`
- `chore` → `maintenance`, `dependencies`
- `perf` → `performance`, `optimization`
- `ci` → `ci-cd`, `automation`

**Additional labels based on files:**
- Test files present → `testing`
- Security-related → `security`
- Database files → `database`
- API files → `api`

## Commit Message Quality

**Validation** (per commit.md:25-55):

1. **Type validation:**
   - Must be one of: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
   - Lowercase only

2. **Scope rules:**
   - Optional but recommended
   - Lowercase, no spaces
   - Use hyphens for multi-word scopes
   - Derived from primary directory

3. **Description rules:**
   - Present tense, imperative mood
   - Lowercase start
   - No period at end
   - Under 50 characters
   - Specific and concise

4. **Body formatting:**
   - Use bullets for multi-file changes
   - Format: `- [Action] [description]`
   - Blank line after description

5. **Footer formatting:**
   - `Refs #<issue-number>` for tracking
   - `Closes #<issue-number>` for fixes
   - `Breaking Change:` if breaking (ask user first)

**Multi-line format** (per commit.md:69-80):
```
<type>(<scope>): <description>

- Bullet point 1
- Bullet point 2
- Bullet point 3

Refs #<issue-number>
```

**Single-line format** (for simple changes):
```
<type>(<scope>): <description>
```

## Integration with Existing Commands

**Works with:**
- `/create-issue`: Same repository detection and MCP logic
- `/commit`: Same conventional commit format
- `/analyze-pr`: Generated issues/commits compatible with PR analysis

**Workflow comparison:**

| Manual | /feature-flow (staged) | /feature-flow (issue) |
|--------|------------------------|----------------------|
| git checkout -b feat/new | Automatic branch naming | Branch from issue labels |
| Write issue manually | Generated from changes | Already exists |
| Implement code | Already staged | AI implementation |
| Run lint/test manually | N/A | Automated quality gates |
| git commit -m "..." | Conventional format | Conventional format |
| Push + create MR | Manual push | auto-mr integration |
| 10-30 minutes | 30 seconds | 2-5 minutes |

## Examples

### Staged Changes Mode

```bash
# Happy path: stage files, run command
git add api/user.go api/user_test.go
/feature-flow
# → Creates: feat/api-user branch, issue #N, commit

# Bug fix with custom context
git add auth/jwt.go
/feature-flow fix JWT expiration bug
# → Creates: fix/auth-jwt branch, uses context in description

# Documentation update, skip issue
git add docs/README.md
/feature-flow --skip-issue
# → Creates: docs/readme branch, commit, no issue

# Preview without executing
git add database/schema.sql
/feature-flow --dry-run
# → Shows what would happen, no changes made

# Auto-approve all phases
git add api/test.go
/feature-flow --force
# → No confirmation prompts, executes all phases

# Skip branch creation (already on correct branch)
git checkout -b feat/my-feature
git add src/feature.go
/feature-flow --skip-branch
# → Creates issue and commit on current branch

# Minimal workflow (commit only)
git add config.yml
/feature-flow --skip-branch --skip-issue
# → Only creates conventional commit
```

### Issue Mode

```bash
# Full workflow from issue 42
/feature-flow #42
# → Fetches issue, creates branch, implements, lint, test, commit, MR

# With squash merge
/feature-flow #42 --squash
# → Same as above but passes --squash to auto-mr

# Preview plan without executing
/feature-flow #42 --dry-run
# → Shows issue details, planned branch, implementation plan, no changes

# Skip quality checks
/feature-flow #42 --skip-lint --skip-test
# → Implements and commits without running lint or tests

# Implement and commit only, no merge request
/feature-flow #42 --skip-mr
# → Full workflow except auto-mr, shows manual push instructions

# No confirmations, squash merge
/feature-flow #42 --force --squash
# → Auto-approves all phases, squash merge via auto-mr

# Custom MR message
/feature-flow #42 --msg "feat: implement user profile (Closes #42)"
# → Uses custom message for auto-mr

# Bare issue number (without #)
/feature-flow 42
# → Same as /feature-flow #42
```

## Error Handling

### Staged Changes Mode Errors

1. **No staged changes:**
   - Message: "No staged changes found. Stage files with 'git add <file>' first."
   - Recovery: `git add <files>`, then retry

2. **Not a git repository:**
   - Message: "Not a git repository. Initialize with 'git init' first."
   - Recovery: `git init`, add remote, then retry

3. **Branch already exists:**
   - Message: "Branch '<name>' already exists. Suggestions: <name>-v2, <name>-alt"
   - Recovery: Choose alternative name or switch to existing branch

4. **Pre-commit hook fails:**
   - Message: "Pre-commit hook failed: [hook output]"
   - Recovery: Fix issues reported, then retry (changes are staged)

5. **MCP server unavailable (issue creation):**
   - Message: "Cannot connect to GitHub/GitLab. Skipping issue creation."
   - Action: Continue to commit phase, warn user to create issue manually

6. **Invalid labels:**
   - Action: Remove invalid labels silently, continue with valid labels
   - Warn: "Some labels not found in repository and were removed"

7. **Issue creation fails:**
   - Message: "Failed to create issue: [error]. Continuing to commit."
   - Action: Continue to Phase 4, commit without issue reference

8. **Commit fails:**
   - Message: "Commit failed: [git error]"
   - Recovery: Check staged changes, verify no conflicts, retry

### Issue Mode Errors

9. **Issue not found:**
    - Message: "Issue #N not found in <owner/repo>."
    - Action: Abort workflow immediately

10. **MCP unavailable (issue retrieval):**
    - Message: "Cannot connect to GitHub/GitLab. Issue retrieval requires MCP."
    - Action: Abort workflow (cannot proceed without issue details)

11. **Lint failure:**
    - Display lint errors
    - Attempt auto-fix if supported
    - Ask user whether to continue or abort

12. **Test failure:**
    - Display test output
    - Attempt fix (max 2 retries)
    - Ask user whether to continue or abort

13. **auto-mr not installed:**
    - Message: "auto-mr not found. Commit preserved."
    - Action: Show manual push command: `git push -u origin <branch-name>`

14. **auto-mr fails:**
    - Message: "auto-mr failed: [error]. Commit preserved."
    - Action: Show manual push command and MR creation URL

## Best Practices

**When to use /feature-flow (Staged Changes Mode):**
- Starting new feature development from existing code
- Beginning bug fix work with changes already staged
- Creating documentation updates
- Any workflow requiring branch + issue + commit

**When to use /feature-flow (Issue Mode):**
- Implementing a tracked issue end-to-end
- Automating the full cycle: issue → code → lint → test → commit → MR
- Ensuring quality gates before merge

**When NOT to use /feature-flow:**
- Making quick fixes without tracking
- Amending previous commits
- Cherry-picking or rebasing

**Tips:**
- Stage only related files for cohesive branch/issue/commit (staged changes mode)
- Use `--dry-run` first to preview either mode
- Use `--skip-issue` for trivial changes (staged changes mode)
- Use custom context for better branch names: `/feature-flow add OAuth2 integration`
- Use `--skip-lint --skip-test` for quick iterations without quality gates (issue mode)
- Use `--skip-mr` to implement and commit without creating a merge request (issue mode)
- Combine with existing commands: `/feature-flow` → work → `/commit` → `/analyze-pr`

## Validation Checklist

After implementation, verify:

- [ ] Command validates: `cd plugins/software-engineering && claude plugin validate .`
- [ ] Frontmatter includes all required fields
- [ ] Mode detection routes correctly (#number → issue mode, else → staged mode)
- [ ] Staged Changes Mode: all 5 phases documented and unchanged in behavior
- [ ] Issue Mode: all 8 phases documented clearly
- [ ] Error handling covers all scenarios (both modes)
- [ ] User confirmation gates at each major step
- [ ] NO Claude Code attribution in any output
- [ ] Conventional commit format validated
- [ ] Branch naming is intelligent and consistent (both modes)
- [ ] Lint/test detection algorithms cover Go, Node.js, Python, Rust
- [ ] auto-mr integration with graceful fallback
- [ ] Flags are parsed correctly (shared and mode-specific)
- [ ] GitHub and GitLab both supported
- [ ] Integration with existing commands works
- [ ] Dry-run mode works correctly (both modes)
- [ ] Force mode skips confirmations

## Success Criteria

✅ Reduces developer friction (staged: 10 min → 30 sec, issue: 30 min → 2-5 min)
✅ Consistent branch naming across project (both modes)
✅ All features have tracking issues (created or referenced)
✅ High-quality conventional commits
✅ Seamless GitHub/GitLab integration
✅ Automated lint and test quality gates (issue mode)
✅ auto-mr integration with graceful fallback (issue mode)
✅ Clear error messages and recovery steps
✅ Flexible usage via flags (shared and mode-specific)
✅ Quality standards maintained (no AI attribution)
✅ Clear next steps provided (push, create PR/MR)
