---
name: detect-repo-host
description: Detect repository hosting service (GitHub/GitLab/Forgejo) from git remote and extract owner/repo/project_path. Internal utility skill used by commands that need platform-aware routing.
user-invocable: false
allowed-tools: Bash(git remote:*)
---

# Detect Repository Host Skill

Detect the repository hosting service from git remote configuration and extract structured metadata for platform-aware command routing.

## Overview

Many commands need to determine whether the current repository is hosted on GitHub, GitLab, or Forgejo to route CLI calls correctly. This skill centralizes that detection logic so commands can invoke it via the `Skill` tool instead of duplicating `git remote -v` parsing.

## When to Use

- Before calling GitHub, GitLab, or Forgejo CLI tools that require `owner/repo` or `project_path`
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

**SSH formats (scp-style):**
```
git@github.com:owner/repo.git
git@gitlab.com:group/subgroup/project.git
git@gitlab.self-hosted.example.com:group/project.git
git@git.sylvlab.fr:owner/repo.git
```

**SSH formats (`ssh://` scheme, may include a custom port):**
```
ssh://git@github.com/owner/repo.git
ssh://git@git.sylvlab.fr:2222/sylvain/mountain-blog-test.git
```

**HTTPS formats:**
```
https://github.com/owner/repo.git
https://gitlab.com/group/subgroup/project.git
https://gitlab.self-hosted.example.com/group/project.git
https://git.sylvlab.fr/owner/repo.git
```

**Parsing rules:**
1. Strip trailing `.git` suffix if present
2. Extract hostname from URL:
   - scp-style (`[user@]host:path`): hostname is between `@` (if present) and the first `:`.
   - `ssh://[user@]host[:port]/path`: strip the `ssh://` scheme and any `user@`, then the hostname is up to the next `/` or `:` — **drop the `:<port>` segment** (e.g. `:2222`); it is not part of the path.
   - `https://host/path`: hostname is between `://` and the next `/`.
3. Extract path segments after the hostname (after the `:` for scp-style, after the host[:port] for `ssh://`, after the host for HTTPS). The port number is never an owner/path segment.

### Step 3: Detect Platform

Map the extracted hostname against an explicit hostname table. Add new self-hosted instances here as needed:

| Hostname | Platform |
|----------|----------|
| `github.com` | GitHub |
| `gitlab.com` | GitLab |
| `git.sylvlab.fr` | Forgejo |
| *(any other host)* | Assume GitLab (self-hosted GitLab instances are common); **emit a warning** that the host is unrecognized so the user can verify the routing or add the host to this table |

### Step 4: Extract Metadata

**For GitHub** (`github.com`):
- `owner`: First path segment (user or organization)
- `repo`: Second path segment (repository name)
- `project_path`: `owner/repo`

**For GitLab** (`gitlab.com` or self-hosted):
- `project_path`: Full path after hostname (supports nested groups, e.g., `group/subgroup/project`)
- `owner`: First path segment (top-level group)
- `repo`: Last path segment (project name)

**For Forgejo** (`git.sylvlab.fr`):
- `project_path`: Full path after hostname
- `owner`: First path segment (user or organization)
- `repo`: Last path segment (repository name)

## Output

Return the following structured information:

| Field | Description | Example (GitHub) | Example (GitLab) | Example (Forgejo) |
|-------|-------------|-------------------|-------------------|-------------------|
| `platform` | Hosting service | `github` | `gitlab` | `forgejo` |
| `owner` | User/org/group | `sgaunet` | `myorg` | `sylvain` |
| `repo` | Repository name | `claude-plugins` | `myproject` | `mountain-blog-test` |
| `project_path` | Full path | `sgaunet/claude-plugins` | `myorg/team/myproject` | `sylvain/mountain-blog-test` |
| `remote_url` | Raw remote URL | `git@github.com:sgaunet/claude-plugins.git` | `https://gitlab.com/myorg/team/myproject.git` | `git@git.sylvlab.fr:sylvain/mountain-blog-test.git` |

## Error Handling

| Condition | Action |
|-----------|--------|
| Not a git repository | Abort: "Not a git repository. Initialize with `git init` first." |
| No remotes configured | Abort: "No git remotes found. Add a remote with `git remote add origin <url>`." |
| No `origin` remote | Fall back to first available remote, warn user |
| URL format unrecognized | Abort: "Could not parse remote URL: `<url>`. Expected GitHub, GitLab, or Forgejo format." |

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

### Forgejo SSH (`ssh://` scheme with custom port)
```
$ git remote -v
origin  ssh://git@git.sylvlab.fr:2222/sylvain/mountain-blog-test.git (fetch)

→ platform: forgejo
→ owner: sylvain          # the :2222 port is dropped, NOT treated as the owner
→ repo: mountain-blog-test
→ project_path: sylvain/mountain-blog-test
→ remote_url: ssh://git@git.sylvlab.fr:2222/sylvain/mountain-blog-test.git
```

### Forgejo SSH (scp-style)
```
$ git remote -v
origin  git@git.sylvlab.fr:sylvain/mountain-blog-test.git (fetch)

→ platform: forgejo
→ owner: sylvain
→ repo: mountain-blog-test
→ project_path: sylvain/mountain-blog-test
→ remote_url: git@git.sylvlab.fr:sylvain/mountain-blog-test.git
```
