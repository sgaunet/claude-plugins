---
name: create-issue
description: Create formatted GitHub/GitLab issue with approval
argument-hint: "<issue-topic-or-description>"
allowed-tools: Read, Grep, Glob, Skill, Bash(gh:*), mcp__github__issue_write, mcp__github__get_label, mcp__gitlab-mcp__create_issues, mcp__gitlab-mcp__list_labels, AskUserQuestion
---

# Create Issue Command

Create an issue for the current git repository. This command automatically detects whether the repository is hosted on GitHub or GitLab and uses the appropriate MCP server.

## Process

1. **Detect Repository Host**: Use the `detect-repo-host` skill to identify the hosting service (GitHub or GitLab) and extract owner/repo details.

2. **Validate Arguments**: Ensure the issue topic/description is provided as `$argument`

3. Always list available labels before creating the issue. Do not add labels that do not exist in the host repository.
   - **GitHub**: Use `gh label list --repo <owner>/<repo>` via Bash
   - **GitLab**: Use `mcp__gitlab-mcp__list_labels`

4. **Create Issue**: Use the appropriate MCP server:
   - **GitHub**: Use `mcp__github__issue_write`
   - **GitLab**: Use `mcp__gitlab-mcp__create_issues`

5. **Request Permission**: Always ask the user for permission before creating the issue

## Issue Content Guidelines

The issue content should be based on: `$argument`

### Requirements:
- **Title**: Clear, concise summary (max 80 characters)
- **Description**: Detailed explanation including:
  - Problem description or feature request
  - Steps to reproduce (if bug)
  - Expected behavior
  - Current behavior
  - Additional context or screenshots
- **Labels**: Suggest appropriate labels based on those available in the host repository.

### Formatting:
- Use proper markdown formatting
- Include code blocks with syntax highlighting when relevant
- Add checklists for actionable items
- Reference related issues or PRs when applicable

## Error Handling

- If repository host detection fails: The `detect-repo-host` skill provides detailed error messages (not a git repo, no remotes, unsupported host)
- If MCP server is unavailable: Inform user and suggest manual creation

## Example Usage

```
/create-issue "Add dark mode toggle to user preferences"
```

This will create an issue with proper formatting, context, and request user confirmation before proceeding.
