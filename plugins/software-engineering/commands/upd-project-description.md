# Update Project Description Command

Update the description and topics of the current project. This command automatically detects whether the repository is hosted on GitHub or GitLab and uses the appropriate MCP server to update the project metadata (description and topics/tags).

## Process

1. **Detect Repository Host**: Execute the command below to determine the repository hosting service:

```bash
git remote -v
```

2. **README**: Analyze the README.md file in the repository root to extract a concise project description (first paragraph) and relevant topics/tags (keywords from README or predefined list).

3. **Create Issue**: Use the appropriate MCP server:
   - **GitHub**: Use github mcp server
   - **GitLab**: 
     - Use `mcp__gitlab-mcp__update_project_description`
     - Use `mcp__gitlab-mcp__update_project_topics`

## Error Handling

- If `git remote -v` fails: Repository is not a git repo or has no remotes
- If remote URL doesn't match GitHub/GitLab: Unsupported hosting service
- If MCP server is unavailable, use:
  - For GitHub: use gh cli tool to update description and topics
  - For GitLab: use glab cli tool to update description and topics
