---
name: analyze-and-create-issue
description: Analyze codebase and create GitHub/GitLab issues per finding
argument-hint: "[optional: domain to focus analysis, e.g., 'security', 'performance', 'documentation']"
allowed-tools: Read, Grep, Glob, Skill, Task, mcp__github__create_issue, mcp__github__list_labels, mcp__gitlab-mcp__create_issues, mcp__gitlab-mcp__list_labels, AskUserQuestion
---

# Analyze And Create Issue Command

Analyze codebase to find improvements. For each improvement:
* Describe concisely to the user and ask if they want to create an issue
* If yes, create the issue in the git repository (GitHub or GitLab) using the appropriate MCP server.

## Process

1. **Detect Repository Host**: Use the `detect-repo-host` skill to identify the hosting service (GitHub or GitLab) and extract owner/repo details.

2. **Validate Arguments**: Ensure the issues are in the domain of `$argument`. If no `$argument` is provided, consider all types of issues.

3. Get the list of labels for the current project
  
4. For each improvement, Ask the user if they want to create an issue

5. If yes, **Create Issue**: Use the appropriate MCP server:
   - **GitHub**: Use `mcp__github__create_issue`
   - **GitLab**: Use `mcp__gitlab-mcp__create_issues`

## Issue Content Guidelines

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
