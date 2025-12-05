---
description: Analyze codebase for improvements and create GitHub/GitLab issues for each finding with user confirmation
argument-hint: "[optional: domain to focus analysis, e.g., 'security', 'performance', 'documentation']"
allowed-tools: Read, Grep, Glob, Bash(git remote:*), Task, mcp__github__create_issue, mcp__github__list_labels, mcp__gitlab-mcp__create_issues, mcp__gitlab-mcp__list_labels, AskUserQuestion
---

# Analyze And Create Issue Command

Analyze codebase to find improvements. For each improvement:
* Describe consily to the the user and ask him if he wants to create an issue
* If yes, create the issue in the git repository (GitHub or GitLab) using the appropriate MCP server.

## Process

1. **Detect Repository Host**: Execute the command below to determine the repository hosting service:

```bash
git remote -v
```

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
- **Labels**: Suggest appropriate labels based on thoses available in the host repository.

### Formatting:
- Use proper markdown formatting
- Include code blocks with syntax highlighting when relevant
- Add checklists for actionable items
- Reference related issues or PRs when applicable

## Error Handling

- If `git remote -v` fails: Repository is not a git repo or has no remotes
- If remote URL doesn't match GitHub/GitLab: Unsupported hosting service
- If MCP server is unavailable: Inform user and suggest manual creation
