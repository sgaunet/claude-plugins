---
name: upd-project-description
description: Update repo description and topics from README analysis
allowed-tools: Read, Bash(git remote:*), Bash(gh:*), Bash(glab:*), mcp__github__get_me, mcp__gitlab-mcp__get_project_description, mcp__gitlab-mcp__get_project_topics, mcp__gitlab-mcp__update_project_description, mcp__gitlab-mcp__update_project_topics
---

# Update Project Description Command

Update the description and topics of the current project. This command automatically detects whether the repository is hosted on GitHub or GitLab and uses the appropriate MCP server to update the project metadata (description and topics/tags).

## Process

1. **Detect Repository Host**: Execute the command below to determine the repository hosting service:

```bash
git remote -v
```

2. **Analyze README**: Use a Haiku agent to analyze the README.md file:
   - Extract concise project description (first 1-2 paragraphs, max 200 chars)
   - Identify relevant topics/tags from content (technologies, frameworks, keywords)
   - Return: `{description: "...", topics: ["topic1", "topic2", ...]}`

3. **Launch 2 parallel Haiku agents** to update project metadata concurrently:

   **Agent #1: Update Project Description**
   - **GitHub**: Use `mcp__github__update_repository` with description field (or gh CLI if MCP unavailable)
   - **GitLab**: Use `mcp__gitlab-mcp__update_project_description` (or glab CLI if MCP unavailable)
   - Return: success/failure status

   **Agent #2: Update Project Topics/Tags**
   - **GitHub**: Use `mcp__github__update_repository` with topics field (or gh CLI if MCP unavailable)
   - **GitLab**: Use `mcp__gitlab-mcp__update_project_topics` (or glab CLI if MCP unavailable)
   - Return: success/failure status

4. **Verify Updates**: Confirm both description and topics were updated successfully.

## Parallel MCP Invocation Pattern

```
# Step 1: Detect repository host
git_remote = Bash("git remote -v")
is_github = detect_github(git_remote)
is_gitlab = detect_gitlab(git_remote)
project_path = extract_project_path(git_remote)

# Step 2: Analyze README
Task(subagent_type: "general-purpose", model: "haiku", prompt: "Analyze README.md and extract: 1) Concise description (max 200 chars), 2) Relevant topics/tags. Return JSON: {description, topics[]}")
# Wait for result
readme_analysis = get_task_result()

# Step 3: Launch 2 parallel Haiku agents to update metadata
if is_github:
    Task(tool: "mcp__github__update_repository", params: {description: readme_analysis.description})
    Task(tool: "mcp__github__update_repository", params: {topics: readme_analysis.topics})
elif is_gitlab:
    Task(tool: "mcp__gitlab-mcp__update_project_description", params: {project_path, description: readme_analysis.description})
    Task(tool: "mcp__gitlab-mcp__update_project_topics", params: {project_path, topics: readme_analysis.topics})

# Step 4: Verify both operations completed successfully
```

Note: For GitHub, if the API supports updating description and topics in a single call, that's even more efficient. For GitLab, two separate calls are required by the MCP API.

## Error Handling

- If `git remote -v` fails: Repository is not a git repo or has no remotes
- If remote URL doesn't match GitHub/GitLab: Unsupported hosting service
- If MCP server is unavailable, use:
  - For GitHub: use gh cli tool to update description and topics
  - For GitLab: use glab cli tool to update description and topics
