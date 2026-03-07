---
name: upd-project-description
description: Update repo description and topics from README analysis
allowed-tools: Read, Skill, Bash(gh:*), Bash(glab:*)
---

# Update Project Description Command

Update the description and topics of the current project. This command automatically detects whether the repository is hosted on GitHub or GitLab and uses the appropriate CLI to update the project metadata (description and topics/tags).

## Process

1. **Detect Repository Host**: Use the `detect-repo-host` skill to identify the hosting service (GitHub or GitLab) and extract owner/repo details.

2. **Analyze README**: Use a Haiku agent to analyze the README.md file:
   - Extract concise project description (first 1-2 paragraphs, max 200 chars)
   - Identify relevant topics/tags from content (technologies, frameworks, keywords)
   - Return: `{description: "...", topics: ["topic1", "topic2", ...]}`

3. **Launch 2 parallel Haiku agents** to update project metadata concurrently:

   **Agent #1: Update Project Description**
   - **GitHub**: `gh repo edit --description "<description>"`
   - **GitLab**: `glab repo edit --description "<description>"`
   - Return: success/failure status

   **Agent #2: Update Project Topics/Tags**
   - **GitHub**: `gh repo edit --add-topic "<topic>"` (one per topic)
   - **GitLab**: `glab repo edit --tag "<topic>"` (one per topic)
   - Return: success/failure status

4. **Verify Updates**: Confirm both description and topics were updated successfully.

## Parallel CLI Invocation Pattern

```
# Step 1: Detect repository host
host_info = Skill("detect-repo-host")
# Returns: platform, owner, repo, project_path, remote_url

# Step 2: Analyze README
Task(subagent_type: "general-purpose", model: "haiku", prompt: "Analyze README.md and extract: 1) Concise description (max 200 chars), 2) Relevant topics/tags. Return JSON: {description, topics[]}")
# Wait for result
readme_analysis = get_task_result()

# Step 3: Launch 2 parallel Haiku agents to update metadata
if host_info.platform == "github":
    Task(tool: "Bash", params: {command: 'gh repo edit owner/repo --description "description"'})
    Task(tool: "Bash", params: {command: 'gh repo edit owner/repo --add-topic "topic1" --add-topic "topic2"'})
elif host_info.platform == "gitlab":
    Task(tool: "Bash", params: {command: 'glab repo edit --description "description"'})
    Task(tool: "Bash", params: {command: 'glab repo edit --tag "topic1" --tag "topic2"'})

# Step 4: Verify both operations completed successfully
```

Note: For GitHub, `gh repo edit` supports both `--description` and `--add-topic` flags in a single call for efficiency.

## Error Handling

- If repository host detection fails: The `detect-repo-host` skill provides detailed error messages (not a git repo, no remotes, unsupported host)
- If CLI is unavailable: Inform user to install `gh` or `glab`
