---
name: detect-repo-host
description: Detect repository hosting service (GitHub/GitLab/Forgejo) from the git remote and extract hostname, owner, repo, project_path, and api_base for platform-aware routing.
user-invocable: false
allowed-tools: Bash(git remote:*), Bash(gh auth status:*), Bash(glab auth status:*), Bash(fgj auth status:*), AskUserQuestion
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

Parse the output to find the `origin` remote. If `origin` is not set, prefer a remote named `upstream` before falling back to the first available one, and say which one you picked.

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
2. Strip a trailing `/` if present. Do this *before* splitting path segments —
   otherwise `.../group/project/` yields an empty last segment and `repo` comes
   back blank.
3. Extract hostname from URL:
   - scp-style (`[user@]host:path`): hostname is between `@` (if present) and the first `:`.
   - `ssh://[user@]host[:port]/path`: strip the `ssh://` scheme and any `user@`, then the hostname is up to the next `/` or `:` — **drop the `:<port>` segment** (e.g. `:2222`); it is not part of the path.
   - `https://[user[:password]@]host/path`: drop the `https://` scheme, then take
     everything up to the first `/` as the authority. **If the authority contains
     `@`, keep only what follows the last `@`** — credentials are not part of the
     hostname. This matters for tokenised CI remotes such as
     `https://x-access-token:TOKEN@github.com/owner/repo.git`, which otherwise
     produce the hostname `x-access-token:TOKEN@github.com` and fail the platform
     lookup in Step 3. Drop a `:<port>` suffix here too.
4. Extract path segments after the hostname (after the `:` for scp-style, after the host[:port] for `ssh://`, after the host for HTTPS). The port number is never an owner/path segment.

**Never echo a parsed URL that contained credentials** back to the user or into a
commit message, log, or issue body — report the sanitised `https://host/path`
form instead.

**Canonical recipe.** Six commands depend on this parse; derive it once rather
than re-implementing the string handling per caller:

```bash
url=$(git remote get-url origin 2>/dev/null || git remote -v | awk 'NR==1{print $2}')
raw="$url"
url="${url%.git}"          # 1. strip .git
url="${url%/}"             # 2. strip trailing slash

case "$url" in
  *://*)                   # scheme form: ssh:// or https://
    rest="${url#*://}"
    authority="${rest%%/*}"
    path="${rest#*/}"
    ;;
  *:*)                     # scp-style: [user@]host:path
    authority="${url%%:*}"
    path="${url#*:}"
    ;;
  *) echo "unparseable remote: $raw" >&2; exit 1 ;;
esac

authority="${authority##*@}"   # 3. drop any user[:password]@ credentials
hostname="${authority%%:*}"    #    drop any :port

owner="${path%%/*}"            # first segment
repo="${path##*/}"             # last segment
project_path="$path"           # full path (nested GitLab subgroups included)
```

Verify against these cases before trusting a change to the recipe:

| Remote | hostname | owner | repo |
|---|---|---|---|
| `git@github.com:sgaunet/claude-plugins.git` | `github.com` | `sgaunet` | `claude-plugins` |
| `ssh://git@git.sylvlab.fr:2222/sylvain/blog.git` | `git.sylvlab.fr` | `sylvain` | `blog` |
| `https://x-access-token:TOK@github.com/o/r.git` | `github.com` | `o` | `r` |
| `https://gitlab.com/g/sub/deeper/proj/` | `gitlab.com` | `g` | `proj` |

### Step 3: Detect Platform

Map the extracted hostname against an explicit hostname table. Add new self-hosted instances here as needed:

| Hostname | Platform |
|----------|----------|
| `github.com` | GitHub |
| `gitlab.com` | GitLab |
| `git.sylvlab.fr` | Forgejo |
| *(any other host)* | **Do not guess** — run the fallback in Step 3b |

### Step 3b: Fallback for an Unrecognized Host

Never default to a platform. Guessing misroutes GitHub Enterprise, third-party
self-hosted Forgejo, and even genuine GitHub remotes rewritten by a
`url.<base>.insteadOf` rule — `git remote -v` reports the *rewritten* URL, so the
hostname may not be the real one.

Instead, ask the locally configured CLIs which hosts they know about. Each prints
its authenticated hosts:

```bash
gh auth status      # GitHub / GitHub Enterprise hosts
glab auth status    # GitLab (gitlab.com or self-hosted)
fgj auth status     # Forgejo instances
```

1. If exactly one of the three reports the hostname as an authenticated host, use
   that platform.
2. If none report it, or more than one does, **ask the user** via
   `AskUserQuestion`: "`<hostname>` isn't a known host. Which platform is it —
   GitHub, GitLab, or Forgejo?" Then proceed with the answer.
3. Offer to record the confirmed answer in the Step 3 table so the next run on
   that instance is a fast path rather than another prompt.

Never continue with an unresolved platform: an unrecognized host means the wrong
CLI gets invoked against the wrong API, which at best fails and at worst targets
somebody else's repository.

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
| `hostname` | Parsed host, credentials and port stripped | `github.com` | `gitlab.com` | `git.sylvlab.fr` |
| `api_base` | Base URL for REST calls | `https://api.github.com` | `https://gitlab.com/api/v4` | `https://git.sylvlab.fr/api/v1` |

`api_base` is derived from `hostname`, never hardcoded: GitHub → `https://api.github.com` (GitHub Enterprise → `https://<hostname>/api/v3`), GitLab → `https://<hostname>/api/v4`, Forgejo → `https://<hostname>/api/v1`. Commands that call a REST API directly **must** use this field so the skill works on any self-hosted instance, not just one.

## Error Handling

| Condition | Action |
|-----------|--------|
| Not a git repository | Abort: "Not a git repository. Initialize with `git init` first." |
| No remotes configured | Abort: "No git remotes found. Add a remote with `git remote add origin <url>`." |
| No `origin` remote | Prefer a remote named `upstream` (the canonical repo in a fork workflow); otherwise fall back to the first available remote. Warn the user, naming which remote was chosen — targeting a fork by accident creates issues and PRs in the wrong place. |
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
