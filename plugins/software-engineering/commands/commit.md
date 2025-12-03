---
description: Generate and execute git commit with conventional commit format. Analyzes staged changes and requests user confirmation before committing.
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
---

# Git Commit Command

Generate a git commit for staged changes using conventional commit format. This command analyzes the current git state, creates an appropriate commit message, and executes the commit with user permission.

## Process

1. **Analyze Changes**: Check git status and diff to understand what's being committed:
   ```bash
   git status
   git diff --staged
   ```

2. **Generate Commit Message**: Create a conventional commit message based on the changes (without Claude Code attribution)

3. **Request Permission**: Always ask user confirmation before executing the commit

4. **Execute Commit**: Run the git commit command (without Claude Code attribution)

## Conventional Commit Format

**Structure**: `<type>[optional scope]: <description>`

### Types

- **feat**: New feature or functionality
- **fix**: Bug fix or error correction
- **docs**: Documentation changes only
- **style**: Code formatting, missing semicolons, whitespace (no logic changes)
- **refactor**: Code restructuring without changing external behavior
- **test**: Adding, updating, or fixing tests
- **chore**: Maintenance tasks, dependency updates, build changes
- **perf**: Performance improvements
- **ci**: CI/CD pipeline changes
- **build**: Build system or external dependency changes
- **revert**: Reverting a previous commit

### Scope Guidelines

- **Optional**: Component, module, or area affected
- **Format**: Lowercase, no spaces (use hyphens if needed)
- **Examples**: `auth`, `api`, `ui`, `database`, `user-management`

### Description Rules

- **Tense**: Present tense, imperative mood ("add" not "adds" or "added")
- **Case**: Lowercase start
- **Length**: Under 50 characters for the subject line
- **Punctuation**: No period at the end
- **Clarity**: Be specific and concise

## Examples

```bash
git commit -m "feat(auth): add oauth2 integration"
git commit -m "fix(api): handle null response in user endpoint"
git commit -m "docs: update installation instructions"
git commit -m "refactor(database): simplify connection pooling"
git commit -m "test(auth): add unit tests for login validation"
```

## Multi-line Commit Messages

For complex changes, use a body and optional footer:

```bash
git commit -m "feat(api): add user profile management

- Add GET /profile endpoint
- Add PUT /profile endpoint
- Include avatar upload functionality
- Add input validation for profile fields

Closes #123"
```

## Validation Rules

- **Staged Changes**: Must have files in staging area
- **No Empty Commits**: Ensure meaningful changes are staged
- **Message Quality**: Clear, descriptive, follows conventional format
- **No Attribution**: Do not include Claude Code co-authorship or generation notices

## Error Handling

- **No Staged Changes**: Inform user to stage files first
- **Merge Conflicts**: Resolve conflicts before committing
- **Invalid Repository**: Ensure working in a git repository
- **Hook Failures**: Handle pre-commit hook failures gracefully
