# Create Issue Command

Create an issue for the current git repository. This command automatically detects whether the repository is hosted on GitHub or GitLab and uses the appropriate MCP server.

## Process

1. **Detect Repository Host**: Execute the command below to determine the repository hosting service:

```bash
git remote -v
```

2. **Validate Arguments**: Ensure the issue topic/description is provided as `$argument`

3. **Create Issue**: Use the appropriate MCP server:
   - **GitHub**: Use `mcp__github__create_issue`
   - **GitLab**: Use `mcp__gitlab-mcp__create_issues`

4. **Request Permission**: Always ask the user for permission before creating the issue

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

## Example Usage

```
/create-issue "Add dark mode toggle to user preferences"
```

This will create an issue with proper formatting, context, and request user confirmation before proceeding.
