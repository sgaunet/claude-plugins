#!/bin/bash

# Frontmatter Validation Script for Claude Code Plugins
# Validates agent and command frontmatter fields against the official Claude Code spec:
#   - Agents: https://code.claude.com/docs/en/sub-agents
#   - Skills/Commands: https://code.claude.com/docs/en/skills

set -e

# Colors for output (matching check-versions.sh conventions)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Defaults
FILTER=""
VERBOSE=false
STRICT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --agents-only)  FILTER="agents"; shift ;;
        --commands-only) FILTER="commands"; shift ;;
        --verbose)      VERBOSE=true; shift ;;
        --strict)       STRICT=true; shift ;;
        -h|--help)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Validate plugin frontmatter against official Claude Code spec."
            echo ""
            echo "Options:"
            echo "  --agents-only    Only validate agent files"
            echo "  --commands-only  Only validate command/skill files"
            echo "  --verbose        Show passing files"
            echo "  --strict         Treat warnings as errors"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Valid fields per component type
AGENT_FIELDS="name description tools disallowedTools model permissionMode maxTurns skills mcpServers hooks memory"
AGENT_WARN_FIELDS="color"
AGENT_WRONG_FIELDS="allowed-tools"

COMMAND_FIELDS="name description argument-hint disable-model-invocation user-invocable allowed-tools model context agent hooks"
COMMAND_WRONG_FIELDS="tools"

# Valid values
VALID_MODELS="sonnet opus haiku inherit"
VALID_PERMISSION_MODES="default acceptEdits dontAsk bypassPermissions plan"

# Counters
total_files=0
pass_count=0
warn_count=0
error_count=0

# Extract frontmatter fields from a markdown file
# Returns lines of "key: value" from the YAML frontmatter block
extract_frontmatter() {
    local file="$1"
    awk '
        BEGIN { in_fm=0; started=0 }
        /^---\s*$/ {
            if (!started) { in_fm=1; started=1; next }
            else { exit }
        }
        in_fm { print }
    ' "$file"
}

# Check if a value is in a space-separated list
in_list() {
    local val="$1"
    local list="$2"
    for item in $list; do
        [ "$item" = "$val" ] && return 0
    done
    return 1
}

# Validate a single file
# Args: file_path component_type(agent|command)
validate_file() {
    local file="$1"
    local type="$2"
    local rel_path="${file#$PROJECT_ROOT/}"
    local file_errors=0
    local file_warnings=0
    local messages=""

    # Check frontmatter exists
    local fm
    fm=$(extract_frontmatter "$file")
    if [ -z "$fm" ]; then
        messages="${messages}\n  ${RED}ERROR${NC}: No YAML frontmatter found"
        file_errors=$((file_errors + 1))
        total_files=$((total_files + 1))
        error_count=$((error_count + file_errors))
        echo -n "Checking $rel_path... "
        echo -e "${RED}FAIL${NC}"
        echo -e "$messages"
        return
    fi

    # Extract field names (handle both "key: value" and "key:" with no value)
    local fields
    fields=$(echo "$fm" | awk -F: '/^[a-zA-Z]/ { gsub(/^[ \t]+/, "", $1); print $1 }')

    # Set valid/wrong fields based on type
    local valid_fields wrong_fields warn_fields
    if [ "$type" = "agent" ]; then
        valid_fields="$AGENT_FIELDS"
        wrong_fields="$AGENT_WRONG_FIELDS"
        warn_fields="$AGENT_WARN_FIELDS"
    else
        valid_fields="$COMMAND_FIELDS"
        wrong_fields="$COMMAND_WRONG_FIELDS"
        warn_fields=""
    fi

    # Check each field
    for field in $fields; do
        if in_list "$field" "$wrong_fields"; then
            if [ "$type" = "agent" ]; then
                messages="${messages}\n  ${RED}ERROR${NC}: Field '$field' is not valid for agents (use 'tools' instead)"
            else
                messages="${messages}\n  ${RED}ERROR${NC}: Field '$field' is not valid for commands (use 'allowed-tools' instead)"
            fi
            file_errors=$((file_errors + 1))
        elif in_list "$field" "$warn_fields"; then
            messages="${messages}\n  ${YELLOW}WARN${NC}: Field '$field' is not in the official spec (used by /agents UI)"
            file_warnings=$((file_warnings + 1))
        elif ! in_list "$field" "$valid_fields"; then
            messages="${messages}\n  ${RED}ERROR${NC}: Unknown field '$field'"
            file_errors=$((file_errors + 1))
        fi
    done

    # Agent-specific: require name and description
    if [ "$type" = "agent" ]; then
        if ! echo "$fields" | grep -qx "name"; then
            messages="${messages}\n  ${RED}ERROR${NC}: Missing required field 'name'"
            file_errors=$((file_errors + 1))
        fi
        if ! echo "$fields" | grep -qx "description"; then
            messages="${messages}\n  ${RED}ERROR${NC}: Missing required field 'description'"
            file_errors=$((file_errors + 1))
        fi
    fi

    # Validate model value if present
    local model_val
    model_val=$(echo "$fm" | awk -F': *' '/^model:/ { print $2 }' | tr -d '[:space:]')
    if [ -n "$model_val" ] && ! in_list "$model_val" "$VALID_MODELS"; then
        messages="${messages}\n  ${RED}ERROR${NC}: Invalid model '$model_val' (valid: $VALID_MODELS)"
        file_errors=$((file_errors + 1))
    fi

    # Validate permissionMode value if present (agents only)
    if [ "$type" = "agent" ]; then
        local perm_val
        perm_val=$(echo "$fm" | awk -F': *' '/^permissionMode:/ { print $2 }' | tr -d '[:space:]')
        if [ -n "$perm_val" ] && ! in_list "$perm_val" "$VALID_PERMISSION_MODES"; then
            messages="${messages}\n  ${RED}ERROR${NC}: Invalid permissionMode '$perm_val' (valid: $VALID_PERMISSION_MODES)"
            file_errors=$((file_errors + 1))
        fi
    elif echo "$fields" | grep -qx "permissionMode"; then
        messages="${messages}\n  ${RED}ERROR${NC}: Field 'permissionMode' is not valid for commands"
        file_errors=$((file_errors + 1))
    fi

    # Update counters
    total_files=$((total_files + 1))
    error_count=$((error_count + file_errors))
    warn_count=$((warn_count + file_warnings))

    # Print results
    if [ $file_errors -gt 0 ]; then
        echo -n "Checking $rel_path... "
        echo -e "${RED}FAIL${NC}"
        echo -e "$messages"
    elif [ $file_warnings -gt 0 ]; then
        echo -n "Checking $rel_path... "
        echo -e "${YELLOW}WARN${NC}"
        echo -e "$messages"
    else
        pass_count=$((pass_count + 1))
        if [ "$VERBOSE" = true ]; then
            echo -e "Checking $rel_path... ${GREEN}OK${NC}"
        fi
    fi
}

echo "==================================="
echo "Plugin Frontmatter Validation"
echo "==================================="
echo ""

# Find and validate agent files
if [ "$FILTER" != "commands" ]; then
    agent_files=$(find "$PROJECT_ROOT/plugins" -path "*/agents/*.md" -type f 2>/dev/null | sort)
    if [ -n "$agent_files" ]; then
        echo "--- Agents ---"
        while IFS= read -r file; do
            validate_file "$file" "agent"
        done <<< "$agent_files"
        echo ""
    fi
fi

# Find and validate command files
if [ "$FILTER" != "agents" ]; then
    command_files=$(find "$PROJECT_ROOT/plugins" -path "*/commands/*.md" -not -path "*/commands/*/*" -type f 2>/dev/null | sort)
    if [ -n "$command_files" ]; then
        echo "--- Commands ---"
        while IFS= read -r file; do
            validate_file "$file" "command"
        done <<< "$command_files"
        echo ""
    fi
fi

# Find and validate skill files
if [ "$FILTER" != "agents" ]; then
    skill_files=$(find "$PROJECT_ROOT/plugins" -path "*/skills/*/SKILL.md" -type f 2>/dev/null | sort)
    if [ -n "$skill_files" ]; then
        echo "--- Skills ---"
        while IFS= read -r file; do
            validate_file "$file" "command"
        done <<< "$skill_files"
        echo ""
    fi
fi

echo "==================================="
echo "Summary"
echo "==================================="
echo "Total files: $total_files"
echo -e "Passed:      ${GREEN}$pass_count${NC}"

if [ $warn_count -gt 0 ]; then
    echo -e "Warnings:    ${YELLOW}$warn_count${NC}"
fi

if [ $error_count -gt 0 ]; then
    echo -e "Errors:      ${RED}$error_count${NC}"
fi

echo ""

# Exit logic
if [ $error_count -gt 0 ]; then
    echo -e "${RED}Frontmatter validation FAILED${NC}"
    exit 1
elif [ $warn_count -gt 0 ] && [ "$STRICT" = true ]; then
    echo -e "${YELLOW}Frontmatter validation FAILED (strict mode: warnings treated as errors)${NC}"
    exit 1
else
    echo -e "${GREEN}Frontmatter validation passed${NC}"
    exit 0
fi
