---
name: upd-project-description
description: Update repo description and topics from README analysis (GitHub/GitLab/Forgejo)
allowed-tools: Read, Skill, Bash(gh:*), Bash(glab:*), Bash(fgj:*), Bash(curl:*)
---

# Update Project Description Command

Update the description and topics of the current project. This command automatically detects whether the repository is hosted on GitHub, GitLab, or Forgejo and uses the appropriate CLI (or REST API for Forgejo) to update the project metadata (description and topics/tags).

## Process

1. **Detect Repository Host**: Use the `detect-repo-host` skill to identify the hosting service (GitHub, GitLab, or Forgejo) and extract owner/repo details.

2. **Analyze README**: Use a Haiku agent to analyze the README.md file:
   - Extract concise project description (first 1-2 paragraphs, max 200 chars)
   - Identify relevant topics/tags from content (technologies, frameworks, keywords)
   - Return: `{description: "...", topics: ["topic1", "topic2", ...]}`

3. **Launch 2 parallel Haiku agents** to update project metadata concurrently:

   **Agent #1: Update Project Description**
   - **GitHub**: `gh repo edit --description "<description>"`
   - **GitLab**: `glab repo edit --description "<description>"`
   - **Forgejo**: `fgj` has no `repo edit` subcommand — call the Forgejo REST API with `curl`, using the token from `fgj auth token`:
     `curl -X PATCH -H "Authorization: token <TOKEN>" -H "Content-Type: application/json" -d '{"description":"<description>"}' https://git.sylvlab.fr/api/v1/repos/<owner>/<repo>`
   - Return: success/failure status

   **Agent #2: Update Project Topics/Tags**
   - **GitHub**: `gh repo edit --add-topic "<topic>"` (one per topic)
   - **GitLab**: `glab repo edit --tag "<topic>"` (one per topic)
   - **Forgejo**: `fgj` has no `repo edit` subcommand — call the Forgejo REST API with `curl`, using the token from `fgj auth token` (sets the full topic list in one call):
     `curl -X PUT -H "Authorization: token <TOKEN>" -H "Content-Type: application/json" -d '{"topics":["<topic1>","<topic2>"]}' https://git.sylvlab.fr/api/v1/repos/<owner>/<repo>/topics`
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
elif host_info.platform == "forgejo":
    # fgj has no `repo edit`; get the token from `fgj auth token` and call the Forgejo REST API
    Task(tool: "Bash", params: {command: 'curl -X PATCH -H "Authorization: token $(fgj auth token)" -H "Content-Type: application/json" -d \'{"description":"description"}\' https://git.sylvlab.fr/api/v1/repos/owner/repo'})
    Task(tool: "Bash", params: {command: 'curl -X PUT -H "Authorization: token $(fgj auth token)" -H "Content-Type: application/json" -d \'{"topics":["topic1","topic2"]}\' https://git.sylvlab.fr/api/v1/repos/owner/repo/topics'})

# Step 4: Verify both operations completed successfully
```

Note: For GitHub, `gh repo edit` supports both `--description` and `--add-topic` flags in a single call for efficiency. For Forgejo, the topics endpoint replaces the full topic list in a single `PUT`, so send all topics together.

## Error Handling

- If repository host detection fails: The `detect-repo-host` skill provides detailed error messages (not a git repo, no remotes, unsupported host)
- If CLI is unavailable: Inform user to install `gh`, `glab`, or `fgj`
