# Shared Detection Function Library

Reusable bash functions for auto-detecting Go project settings from go.mod and git remote.

Used by: `gen-goreleaser`, `gen-taskfiles`, `gen-gitlab-ci`, `gen-github-dir`, `gen-forgejo-dir`, and other gen-* commands.

## Detection Functions

```bash
# Function 1: Extract project name from go.mod
detect_project_name() {
    local module_path=$(grep '^module ' go.mod 2>/dev/null | awk '{print $2}')
    [[ -z "$module_path" ]] && return 1
    # Strip version suffix and get basename
    basename "$module_path" | sed 's|/v[0-9]*$||'
}

# Function 2: Extract owner from git remote URL
detect_git_owner() {
    local remote_url=$(git remote get-url origin 2>/dev/null)
    [[ -z "$remote_url" ]] && return 1

    # SSH: git@github.com:sgaunet/repo.git → sgaunet
    if [[ "$remote_url" =~ git@[^:]+:([^/]+)/ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi

    # HTTPS: https://github.com/sgaunet/repo.git → sgaunet
    if [[ "$remote_url" =~ https?://[^/]+/([^/]+)/ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi

    return 1
}

# Function 3: Detect main package directory
detect_main_dir() {
    local main_files=$(find . -type f -name "main.go" 2>/dev/null | grep -v vendor | sort)
    [[ -z "$main_files" ]] && echo "." && return 0

    # Prefer cmd/* paths
    local cmd_main=$(echo "$main_files" | grep -E '^\./cmd/' | head -1)
    if [[ -n "$cmd_main" ]]; then
        dirname "$cmd_main" | sed 's|^\./||'
        return 0
    fi

    # Use first main.go found
    dirname "$(echo "$main_files" | head -1)" | sed 's|^\./||' | sed 's|^\.$|.|'
}

# Function 4: Detect registry from git platform
detect_registry() {
    local remote_url=$(git remote get-url origin 2>/dev/null)
    case "$remote_url" in
        *github.com*) echo "ghcr.io" ;;
        *gitlab.com*) echo "registry.gitlab.com" ;;
        *git.sylvlab.fr*) echo "git.sylvlab.fr" ;;  # Forgejo: container/package registry shares the instance host
        *) echo "ghcr.io" ;;  # Default
    esac
}

# Function 5: Extract author info from git config
detect_author() {
    local name=$(git config user.name 2>/dev/null)
    local email=$(git config user.email 2>/dev/null)
    echo "${name}|${email}"
}

# Function 6: Substitute placeholders in content
substitute_placeholders() {
    local content="$1"
    local project_name="$2"
    local owner="$3"
    local registry="$4"
    local main_dir="$5"
    local author_name="${6:-}"
    local author_email="${7:-}"

    # Escape special characters for sed
    project_name=$(echo "$project_name" | sed 's/[&\/]/\\&/g')
    owner=$(echo "$owner" | sed 's/[&\/]/\\&/g')
    registry=$(echo "$registry" | sed 's/[&\/]/\\&/g')
    main_dir=$(echo "$main_dir" | sed 's/[&\/]/\\&/g')

    # Replace all placeholders (using | delimiter to avoid URL conflicts)
    content=$(echo "$content" | sed "s|\[PROJECT_NAME\]|${project_name}|g")
    content=$(echo "$content" | sed "s|\[PROJECT_BINARY\]|${project_name}|g")
    content=$(echo "$content" | sed "s|\[PROJECT_USER\]|${project_name}|g")
    content=$(echo "$content" | sed "s|\[OWNER\]|${owner}|g")
    content=$(echo "$content" | sed "s|\[GITHUB_USERNAME\]|${owner}|g")
    content=$(echo "$content" | sed "s|\[REGISTRY_URL\]|${registry}|g")
    content=$(echo "$content" | sed "s|\[MAIN_DIR\]|${main_dir}|g")

    # Author placeholders (optional, only replaced if provided)
    if [[ -n "$author_name" ]]; then
        author_name=$(echo "$author_name" | sed 's/[&\/]/\\&/g')
        content=$(echo "$content" | sed "s|\[AUTHOR_NAME\]|${author_name}|g")
    fi
    if [[ -n "$author_email" ]]; then
        author_email=$(echo "$author_email" | sed 's/[&\/]/\\&/g')
        content=$(echo "$content" | sed "s|\[AUTHOR_EMAIL\]|${author_email}|g")
    fi

    echo "$content"
}

# Function 7: Detect latest pre-commit-hooks version
detect_pre_commit_hooks_version() {
    gh release view --repo pre-commit/pre-commit-hooks --json tagName -q .tagName 2>/dev/null
}

# Function 8: Detect latest Docker DinD version
detect_docker_dind_version() {
    curl -s 'https://hub.docker.com/v2/repositories/library/docker/tags/?page_size=50&name=dind' | \
        jq -r '[.results[].name | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+-dind$"))] | sort_by(split("-")[0] | split(".") | map(tonumber)) | last'
}

# Function 9: Detect latest golangci-lint version
detect_golangci_lint_version() {
    gh release view --repo golangci/golangci-lint --json tagName -q .tagName 2>/dev/null
}

# Function 10: Detect latest GoReleaser version
detect_goreleaser_version() {
    gh release view --repo goreleaser/goreleaser --json tagName -q .tagName 2>/dev/null
}

# Function 11: Detect Go version from go.mod
detect_go_version() {
    grep '^go ' go.mod 2>/dev/null | awk '{print $2}'
}

# Function 12: Derive golangci-lint binaries-location from version
derive_golangci_lint_binaries_location() {
    local version="$1"
    local stripped="${version#v}"
    echo "golangci-lint-${stripped}-linux-amd64"
}

# Function 13: Substitute version placeholders (key=value pairs)
substitute_version_placeholders() {
    local content="$1"
    shift
    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"
        if [[ -n "$value" ]]; then
            value=$(echo "$value" | sed 's/[&\/]/\\&/g')
            content=$(echo "$content" | sed "s|\[${key}\]|${value}|g")
        fi
        shift
    done
    echo "$content"
}

# Function 14: Strip a leading "v" from a version string
# mise's `github:golangci/golangci-lint` backend expects a BARE version
# (e.g. "2.12.2"), whereas gh release tags are "v"-prefixed (e.g. "v2.12.2").
strip_leading_v() {
    echo "${1#v}"
}
```

## Usage

### Basic detection (all gen-* commands)

```bash
PROJECT_NAME=$(detect_project_name)
OWNER=$(detect_git_owner)
REGISTRY=$(detect_registry)
MAIN_DIR=$(detect_main_dir)
```

### With author info (gen-goreleaser)

```bash
AUTHOR_INFO=$(detect_author)
AUTHOR_NAME=$(echo "$AUTHOR_INFO" | cut -d'|' -f1)
AUTHOR_EMAIL=$(echo "$AUTHOR_INFO" | cut -d'|' -f2)
```

### Placeholder substitution

```bash
# Without author (gen-taskfiles)
template=$(substitute_placeholders "$template" \
    "$PROJECT_NAME" "$OWNER" "$REGISTRY" "$MAIN_DIR")

# With author (gen-goreleaser)
template=$(substitute_placeholders "$template" \
    "$PROJECT_NAME" "$OWNER" "$REGISTRY" "$MAIN_DIR" "$AUTHOR_NAME" "$AUTHOR_EMAIL")
```

### Version detection

```bash
PRE_COMMIT_HOOKS_VERSION=$(detect_pre_commit_hooks_version)
GOLANGCI_LINT_VERSION=$(detect_golangci_lint_version)
GORELEASER_VERSION=$(detect_goreleaser_version)
GO_VERSION=$(detect_go_version)
```

### Version placeholder substitution

```bash
# gen-taskfiles (.pre-commit-config.yaml)
template=$(substitute_version_placeholders "$template" \
    "PRE_COMMIT_HOOKS_VERSION=${PRE_COMMIT_HOOKS_VERSION:-v4.3.0}")
```

### mise.toml substitution (gen-taskfiles, gen-github-dir, gen-forgejo-dir, gen-gitlab-ci)

`mise.toml` is the single source of truth for tool versions. The CI workflow
templates are now static (no version placeholders) — versions are substituted
into `mise.toml` instead, then the workflows install via mise.

```bash
# Detect versions
GO_VERSION=$(detect_go_version)
GOLANGCI_LINT_VERSION=$(detect_golangci_lint_version)
GORELEASER_VERSION=$(detect_goreleaser_version)

# golangci-lint's github: backend wants a BARE version (strip the leading "v")
GOLANGCI_LINT_VERSION_BARE=$(strip_leading_v "${GOLANGCI_LINT_VERSION:-v2.2.2}")

# Substitute into the mise.toml template
mise_template=$(substitute_version_placeholders "$mise_template" \
    "GO_VERSION=${GO_VERSION:-1.25}" \
    "GOLANGCI_LINT_VERSION_BARE=${GOLANGCI_LINT_VERSION_BARE:-2.2.2}" \
    "GORELEASER_VERSION=${GORELEASER_VERSION:-v2.12.0}")
```

The **CI generators** (`/gen-github-dir`, `/gen-forgejo-dir`, `/gen-gitlab-ci`)
only write `mise.toml` if it does not already exist in the target repo — they
never overwrite a project's existing tool pins. The one exception is
`/gen-taskfiles`, the canonical owner of `mise.toml`: it may regenerate and
overwrite the file (e.g. when run with `--force`) to refresh the pinned tool
versions.

## Placeholder Reference

| Placeholder | Source | Fallback |
|-------------|--------|----------|
| `[PROJECT_NAME]` | go.mod module path | "app" |
| `[PROJECT_BINARY]` | Same as PROJECT_NAME | "app" |
| `[PROJECT_USER]` | Same as PROJECT_NAME | "app" |
| `[OWNER]` | git remote origin | Preserved as-is |
| `[GITHUB_USERNAME]` | Same as OWNER | Preserved as-is |
| `[REGISTRY_URL]` | git remote platform | "ghcr.io" |
| `[MAIN_DIR]` | main.go location | "." |
| `[AUTHOR_NAME]` | git config user.name | Empty string |
| `[AUTHOR_EMAIL]` | git config user.email | Empty string |
| `[PRE_COMMIT_HOOKS_VERSION]` | `gh release view --repo pre-commit/pre-commit-hooks` | `v4.3.0` |
| `[DOCKER_DIND_VERSION]` | Docker Hub API (legacy; pre-mise GitLab CI) | `20.10.16-dind` |
| `[GO_VERSION]` | go.mod | `1.25.1` |
| `[GORELEASER_VERSION]` | `gh release view --repo goreleaser/goreleaser` | `v2.12.0` |
| `[GOLANGCI_LINT_VERSION]` | `gh release view --repo golangci/golangci-lint` | `v2.2.2` |
| `[GOLANGCI_LINT_VERSION_BARE]` | `strip_leading_v` of GOLANGCI_LINT_VERSION (for mise.toml) | `2.2.2` |
| `[GOLANGCI_LINT_BINARIES_LOCATION]` | Derived from GOLANGCI_LINT_VERSION (legacy; pre-mise workflows) | `golangci-lint-2.2.2-linux-amd64` |
