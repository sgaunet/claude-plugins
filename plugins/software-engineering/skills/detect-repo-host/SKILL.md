---
name: detect-repo-host
description: Detect repository hosting service (GitHub/GitLab) from git remote and extract owner/repo/project_path. Internal utility skill used by commands that need platform-aware routing.
version: 1.0.0
author: sylvain
license: MIT
user-invocable: false
allowed-tools: Bash(git remote:*)
---

# Detect Repository Host Skill

Detect the repository hosting service from git remote configuration and extract structured metadata for platform-aware command routing.

## Overview

Many commands need to determine whether the current repository is hosted on GitHub or GitLab to route MCP calls correctly. This skill centralizes that detection logic so commands can invoke it via the `Skill` tool instead of duplicating `git remote -v` parsing.

## When to Use

- Before calling GitHub or GitLab MCP tools that require `owner/repo` or `project_path`
- When a command needs to branch logic based on hosting platform
- Any workflow requiring platform-aware routing

## Workflow

### Step 1: Read Git Remotes

```bash
git remote -v
```

Parse the output to find the `origin` remote (or the first available remote if `origin` is not set).

### Step 2: Parse Remote URL

Support both SSH and HTTPS URL formats:

**SSH formats:**
```
git@github.com:owner/repo.git
git@gitlab.com:group/subgroup/project.git
git@gitlab.self-hosted.example.com:group/project.git
```

**HTTPS formats:**
```
https://github.com/owner/repo.git
https://gitlab.com/group/subgroup/project.git
https://gitlab.self-hosted.example.com/group/project.git
```

**Parsing rules:**
1. Strip trailing `.git` suffix if present
2. Extract hostname from URL
3. Extract path segments after hostname

### Step 3: Detect Platform

| Hostname Pattern | Platform |
|-----------------|----------|
| `github.com` | GitHub |
| `gitlab.com` | GitLab |
| Other hostnames | Assume GitLab (self-hosted instances are common) |

### Step 4: Extract Metadata

**For GitHub** (`github.com`):
- `owner`: First path segment (user or organization)
- `repo`: Second path segment (repository name)
- `project_path`: `owner/repo`

**For GitLab** (`gitlab.com` or self-hosted):
- `project_path`: Full path after hostname (supports nested groups, e.g., `group/subgroup/project`)
- `owner`: First path segment (top-level group)
- `repo`: Last path segment (project name)

## Output

Return the following structured information:

| Field | Description | Example (GitHub) | Example (GitLab) |
|-------|-------------|-------------------|-------------------|
| `platform` | Hosting service | `github` | `gitlab` |
| `owner` | User/org/group | `sgaunet` | `myorg` |
| `repo` | Repository name | `claude-plugins` | `myproject` |
| `project_path` | Full path | `sgaunet/claude-plugins` | `myorg/team/myproject` |
| `remote_url` | Raw remote URL | `git@github.com:sgaunet/claude-plugins.git` | `https://gitlab.com/myorg/team/myproject.git` |

## Error Handling

| Condition | Action |
|-----------|--------|
| Not a git repository | Abort: "Not a git repository. Initialize with `git init` first." |
| No remotes configured | Abort: "No git remotes found. Add a remote with `git remote add origin <url>`." |
| No `origin` remote | Fall back to first available remote, warn user |
| URL format unrecognized | Abort: "Could not parse remote URL: `<url>`. Expected GitHub or GitLab format." |
| Unsupported host (not GitHub/GitLab) | Abort: "Unsupported hosting service: `<hostname>`. Only GitHub and GitLab are supported." |

## Examples

### GitHub SSH
```
$ git remote -v
origin  git@github.com:sgaunet/claude-plugins.git (fetch)

→ platform: github
→ owner: sgaunet
→ repo: claude-plugins
→ project_path: sgaunet/claude-plugins
→ remote_url: git@github.com:sgaunet/claude-plugins.git
```

### GitLab HTTPS with Subgroups
```
$ git remote -v
origin  https://gitlab.com/myorg/backend/api-service.git (fetch)

→ platform: gitlab
→ owner: myorg
→ repo: api-service
→ project_path: myorg/backend/api-service
→ remote_url: https://gitlab.com/myorg/backend/api-service.git
```

### Self-Hosted GitLab
```
$ git remote -v
origin  git@gitlab.company.internal:devteam/infra.git (fetch)

→ platform: gitlab
→ owner: devteam
→ repo: infra
→ project_path: devteam/infra
→ remote_url: git@gitlab.company.internal:devteam/infra.git
```
