---
name: feature-flow
description: Complete git workflow orchestration - branch, issue, commit
argument-hint: "[context] [--skip-branch] [--skip-issue] [--dry-run] [--force]"
allowed-tools: Read, Grep, Glob, Bash(git:*), mcp__github__create_issue, mcp__github__list_labels, mcp__gitlab-mcp__create_issues, mcp__gitlab-mcp__list_labels, AskUserQuestion
---

# Feature Flow Command

Orchestrate a complete git workflow for feature development: create a feature branch, document work in an issue tracker, and make the initial commit. This command automates the repetitive steps developers perform when starting new work.

## Why This Command Exists

**Problem**: Developers spend time on repetitive workflow setup - creating branches, writing issues, formatting commits.

**Solution**: Automated orchestration that:
- Analyzes staged changes intelligently
- Proposes conventional branch names
- Creates tracking issues with proper formatting
- Commits with conventional commit format
- Ensures consistent workflow across the team

## Process (5 Phases)

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
   - If issue created: `Refs #<issue-number>`
   - If issue exists: `Closes #<issue-number>` (for fixes)
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

## Flag Support

**Supported flags** (parsed from $argument):

- `--skip-branch` or `-b`: Skip Phase 2 (branch creation), stay on current branch
- `--skip-issue` or `-i`: Skip Phase 3 (issue creation), no tracking issue
- `--dry-run` or `-n`: Show what would be done without executing (preview mode)
- `--force` or `-f`: Skip all confirmation prompts, auto-approve all phases

**Flag parsing:**
```
# Split $argument by spaces
# Check each token:
#   - If starts with "--" or "-": it's a flag
#   - Otherwise: it's context for branch/commit description
# Examples:
#   "--skip-issue add user auth" → skip_issue=true, context="add user auth"
#   "-b -f" → skip_branch=true, force=true
```

**Dry run mode (--dry-run):**
- Execute Phase 1 (discovery)
- Display proposed branch name
- Display proposed issue content
- Display proposed commit message
- DO NOT execute: branch creation, issue creation, commit
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

| Manual | /feature-flow |
|--------|---------------|
| git checkout -b feat/new | Automatic branch naming |
| Write issue manually | Generated from changes |
| git commit -m "..." | Conventional format |
| 5-10 minutes | 30 seconds |

## Examples

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

## Error Handling

**Common errors and recovery:**

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

5. **MCP server unavailable:**
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

## Best Practices

**When to use /feature-flow:**
- Starting new feature development
- Beginning bug fix work
- Creating documentation updates
- Any workflow requiring branch + issue + commit

**When NOT to use /feature-flow:**
- Already have a branch and issue
- Making quick fixes without tracking
- Amending previous commits
- Cherry-picking or rebasing

**Tips:**
- Stage only related files for cohesive branch/issue/commit
- Use `--dry-run` first to preview
- Use `--skip-issue` for trivial changes
- Use custom context for better branch names: `/feature-flow add OAuth2 integration`
- Combine with existing commands: `/feature-flow` → work → `/commit` → `/analyze-pr`

## Validation Checklist

After implementation, verify:

- [ ] Command validates: `cd plugins/software-engineering && claude plugin validate .`
- [ ] Frontmatter includes all required fields
- [ ] All 5 phases documented clearly
- [ ] Error handling covers all scenarios
- [ ] User confirmation gates at each major step
- [ ] NO Claude Code attribution in any output
- [ ] Conventional commit format validated
- [ ] Branch naming is intelligent and consistent
- [ ] Issue content is well-formatted
- [ ] Flags are parsed correctly
- [ ] GitHub and GitLab both supported
- [ ] Integration with existing commands works
- [ ] Dry-run mode works correctly
- [ ] Force mode skips confirmations

## Success Criteria

✅ Reduces developer friction (5-10 min → 30 sec workflow)
✅ Consistent branch naming across project
✅ All features have tracking issues
✅ High-quality conventional commits
✅ Seamless GitHub/GitLab integration
✅ Clear error messages and recovery steps
✅ Flexible usage via flags
✅ Quality standards maintained (no AI attribution)
✅ Clear next steps provided (push, create PR)
