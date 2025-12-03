#!/bin/bash

# Version Update Script for Claude Code Plugins
# Automatically bumps versions for affected plugins based on git staged files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MARKETPLACE_JSON="$PROJECT_ROOT/.claude-plugin/marketplace.json"

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_dependencies() {
    local missing_deps=()

    # Check jq
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    # Check semver
    if ! command -v semver &> /dev/null; then
        missing_deps+=("semver")
    fi

    # Check git repo
    if ! git rev-parse --git-dir &> /dev/null; then
        echo -e "${RED}Error: Not in a git repository${NC}" >&2
        exit 1
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies${NC}" >&2
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep" >&2
        done
        echo "" >&2
        echo "Installation instructions:" >&2
        echo "  - jq:     brew install jq" >&2
        echo "  - semver: npm install -g semver" >&2
        exit 1
    fi
}

validate_bump_type() {
    local bump_type="$1"
    local bump_type_lower
    bump_type_lower=$(echo "$bump_type" | tr '[:upper:]' '[:lower:]')

    case "$bump_type_lower" in
        major|minor|patch)
            echo "$bump_type_lower"
            ;;
        *)
            echo -e "${RED}Error: Invalid bump type '${bump_type}'${NC}" >&2
            echo "" >&2
            echo "Usage: $0 <major|minor|patch>" >&2
            echo "" >&2
            echo "Examples:" >&2
            echo "  $0 patch   # 0.7.0 → 0.7.1" >&2
            echo "  $0 minor   # 0.7.0 → 0.8.0" >&2
            echo "  $0 major   # 0.7.0 → 1.0.0" >&2
            exit 1
            ;;
    esac
}

# ============================================================================
# FILE DETECTION FUNCTIONS
# ============================================================================

get_staged_files() {
    local staged_files
    staged_files=$(git diff --cached --name-only)

    if [ -z "$staged_files" ]; then
        echo -e "${RED}Error: No files are staged${NC}" >&2
        echo "Please stage your changes first: git add <files>" >&2
        exit 1
    fi

    echo "$staged_files"
}

extract_plugin_from_path() {
    local file_path="$1"

    # Match: plugins/<plugin-name>/...
    if [[ "$file_path" =~ ^plugins/([^/]+)(/|$) ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

get_affected_plugins() {
    local staged_files="$1"
    local plugins=""

    # Check if marketplace.json is staged (special case)
    if echo "$staged_files" | grep -q "^.claude-plugin/marketplace.json$"; then
        echo -e "${YELLOW}Warning: marketplace.json is staged${NC}" >&2
        echo "This will update ALL plugins based on other staged files" >&2
    fi

    # Extract plugins from file paths and deduplicate
    while IFS= read -r file; do
        local plugin_name
        plugin_name=$(extract_plugin_from_path "$file")
        if [ -n "$plugin_name" ]; then
            # Check if plugin already in list
            if ! echo "$plugins" | grep -q "\b$plugin_name\b"; then
                plugins="$plugins $plugin_name"
            fi
        fi
    done <<< "$staged_files"

    # Trim leading/trailing spaces
    plugins=$(echo "$plugins" | xargs)

    if [ -z "$plugins" ]; then
        echo -e "${BLUE}Info: No plugin files are staged${NC}" >&2
        echo "Staged files don't belong to any plugin:" >&2
        echo "$staged_files" | sed 's/^/  - /' >&2
        echo "" >&2
        echo "No version updates needed." >&2
        exit 0
    fi

    echo "$plugins"
}

# ============================================================================
# VERSION OPERATION FUNCTIONS
# ============================================================================

get_current_version() {
    local plugin_name="$1"
    local plugin_json="$PROJECT_ROOT/plugins/$plugin_name/.claude-plugin/plugin.json"

    if [ ! -f "$plugin_json" ]; then
        echo -e "${RED}ERROR: plugin.json not found${NC}" >&2
        echo "Expected: $plugin_json" >&2
        exit 1
    fi

    local version
    version=$(jq -r '.version' "$plugin_json")

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        echo -e "${RED}ERROR: No version found in $plugin_json${NC}" >&2
        exit 1
    fi

    echo "$version"
}

calculate_new_version() {
    local current_version="$1"
    local bump_type="$2"

    # Calculate new version
    local new_version
    new_version=$(semver next "$bump_type" "$current_version")

    if [ $? -ne 0 ] || [ -z "$new_version" ]; then
        echo -e "${RED}ERROR: Failed to calculate new version${NC}" >&2
        echo "Current version: $current_version" >&2
        echo "Bump type: $bump_type" >&2
        exit 1
    fi

    echo "$new_version"
}

update_plugin_json() {
    local plugin_name="$1"
    local new_version="$2"
    local plugin_json="$PROJECT_ROOT/plugins/$plugin_name/.claude-plugin/plugin.json"

    # Create temp file
    local temp_file
    temp_file=$(mktemp)

    # Update version using jq
    if ! jq --arg version "$new_version" '.version = $version' "$plugin_json" > "$temp_file"; then
        rm -f "$temp_file"
        echo -e "${RED}ERROR: Failed to update $plugin_json${NC}" >&2
        exit 1
    fi

    # Atomic replace
    mv "$temp_file" "$plugin_json"
}

update_marketplace_json() {
    local plugin_name="$1"
    local new_version="$2"

    # Create temp file
    local temp_file
    temp_file=$(mktemp)

    # Update the specific plugin's version in the plugins array
    if ! jq --arg name "$plugin_name" --arg version "$new_version" \
        '(.plugins[] | select(.name == $name) | .version) = $version' \
        "$MARKETPLACE_JSON" > "$temp_file"; then
        rm -f "$temp_file"
        echo -e "${RED}ERROR: Failed to update marketplace.json${NC}" >&2
        exit 1
    fi

    # Atomic replace
    mv "$temp_file" "$MARKETPLACE_JSON"
}

stage_json_files() {
    local plugin_name="$1"
    local plugin_json="$PROJECT_ROOT/plugins/$plugin_name/.claude-plugin/plugin.json"

    git add "$plugin_json"
    git add "$MARKETPLACE_JSON"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    local bump_type="$1"

    # Validate argument
    if [ -z "$bump_type" ]; then
        validate_bump_type "invalid"
    fi
    bump_type=$(validate_bump_type "$bump_type")

    # Validate dependencies
    validate_dependencies

    # Header
    echo "==================================="
    echo "Plugin Version Update"
    echo "==================================="
    echo "Bump type: $bump_type"
    echo ""

    # Get staged files
    echo "Detecting affected plugins..."
    local staged_files
    staged_files=$(get_staged_files)
    local file_count
    file_count=$(echo "$staged_files" | wc -l | tr -d ' ')
    echo "Found $file_count staged file(s)"
    echo ""

    # Determine affected plugins
    local affected_plugins
    affected_plugins=$(get_affected_plugins "$staged_files")
    echo "Affected plugins: $affected_plugins"
    echo ""

    # Track versions for summary (using simple string format)
    local version_summary=""

    # Update each plugin
    local updates_made=0
    for plugin_name in $affected_plugins; do
        echo "Updating $plugin_name..."

        # Get current version
        local current_version
        current_version=$(get_current_version "$plugin_name")
        echo "  Current version: $current_version"

        # Calculate new version
        local new_version
        new_version=$(calculate_new_version "$current_version" "$bump_type")
        echo "  New version:     $new_version"

        # Store for summary
        version_summary="$version_summary
  - $plugin_name: $current_version → $new_version"

        # Update files
        update_plugin_json "$plugin_name" "$new_version"
        echo -e "  ${GREEN}✓${NC} Updated plugin.json"

        update_marketplace_json "$plugin_name" "$new_version"
        echo -e "  ${GREEN}✓${NC} Updated marketplace.json"

        # Stage files
        stage_json_files "$plugin_name"
        echo -e "  ${GREEN}✓${NC} Staged changes"

        echo ""
        updates_made=$((updates_made + 1))
    done

    # Summary
    echo "==================================="
    echo "Summary"
    echo "==================================="
    echo "Updated $updates_made plugin(s):$version_summary"
    echo ""

    # Validation
    echo "==================================="
    echo "Validating version synchronization..."
    echo "==================================="
    if "$SCRIPT_DIR/check-versions.sh"; then
        echo ""
        echo -e "${GREEN}✓ Version update successful${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}✗ Version validation failed${NC}" >&2
        echo "Please review the changes" >&2
        exit 1
    fi
}

# Run main with all arguments
main "$@"
