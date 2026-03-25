# Shared Detection Function Library

Reusable bash functions for auto-detecting Go project settings from go.mod and git remote.

Used by: `gen-goreleaser`, `gen-taskfiles`, `gen-gitlab-ci`, `gen-github-dir`, and other gen-* commands.

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

### Version detection (gen-taskfiles, gen-gitlab-ci, gen-github-dir)

```bash
PRE_COMMIT_HOOKS_VERSION=$(detect_pre_commit_hooks_version)
DOCKER_DIND_VERSION=$(detect_docker_dind_version)
GOLANGCI_LINT_VERSION=$(detect_golangci_lint_version)
GORELEASER_VERSION=$(detect_goreleaser_version)
GO_VERSION=$(detect_go_version)
GOLANGCI_LINT_BINARIES_LOCATION=$(derive_golangci_lint_binaries_location "${GOLANGCI_LINT_VERSION:-v2.2.2}")
```

### Version placeholder substitution

```bash
# gen-taskfiles (.pre-commit-config.yaml)
template=$(substitute_version_placeholders "$template" \
    "PRE_COMMIT_HOOKS_VERSION=${PRE_COMMIT_HOOKS_VERSION:-v4.3.0}")

# gen-gitlab-ci (.gitlab-ci.yml)
template=$(substitute_version_placeholders "$template" \
    "GO_VERSION=${GO_VERSION:-1.25.1}" \
    "DOCKER_DIND_VERSION=${DOCKER_DIND_VERSION:-20.10.16-dind}" \
    "GORELEASER_VERSION=${GORELEASER_VERSION:-v2.12.0}")

# gen-github-dir (linter.yml)
template=$(substitute_version_placeholders "$template" \
    "GOLANGCI_LINT_VERSION=${GOLANGCI_LINT_VERSION:-v2.2.2}" \
    "GOLANGCI_LINT_BINARIES_LOCATION=${GOLANGCI_LINT_BINARIES_LOCATION:-golangci-lint-2.2.2-linux-amd64}")
```

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
| `[DOCKER_DIND_VERSION]` | Docker Hub API | `20.10.16-dind` |
| `[GO_VERSION]` | go.mod | `1.25.1` |
| `[GORELEASER_VERSION]` | `gh release view --repo goreleaser/goreleaser` | `v2.12.0` |
| `[GOLANGCI_LINT_VERSION]` | `gh release view --repo golangci/golangci-lint` | `v2.2.2` |
| `[GOLANGCI_LINT_BINARIES_LOCATION]` | Derived from GOLANGCI_LINT_VERSION | `golangci-lint-2.2.2-linux-amd64` |
