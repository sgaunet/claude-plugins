# Shared Detection Function Library

Reusable bash functions for auto-detecting Go project settings from go.mod and git remote.

Used by: `gen-goreleaser`, `gen-taskfiles`, and other gen-* commands.

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
