#!/bin/bash

# Version Validation Script for Claude Code Plugins
# Checks that marketplace.json versions match individual plugin.json versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Files
MARKETPLACE_JSON="$PROJECT_ROOT/.claude-plugin/marketplace.json"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo "Please install jq to run this script:"
    echo "  - macOS: brew install jq"
    echo "  - Ubuntu/Debian: sudo apt-get install jq"
    echo "  - Other: https://stedolan.github.io/jq/download/"
    exit 1
fi

# Check if marketplace.json exists
if [ ! -f "$MARKETPLACE_JSON" ]; then
    echo -e "${RED}Error: marketplace.json not found at $MARKETPLACE_JSON${NC}"
    exit 1
fi

echo "==================================="
echo "Plugin Version Validation"
echo "==================================="
echo ""

# Initialize counters
total_plugins=0
mismatches=0
errors=0

# Read plugins from marketplace.json
plugins=$(jq -r '.plugins[] | @base64' "$MARKETPLACE_JSON")

for plugin_base64 in $plugins; do
    # Decode plugin data
    plugin_data=$(echo "$plugin_base64" | base64 --decode)

    plugin_name=$(echo "$plugin_data" | jq -r '.name')
    marketplace_version=$(echo "$plugin_data" | jq -r '.version')
    plugin_source=$(echo "$plugin_data" | jq -r '.source')

    total_plugins=$((total_plugins + 1))

    # Construct path to plugin.json
    plugin_json="$PROJECT_ROOT/$plugin_source/.claude-plugin/plugin.json"

    echo -n "Checking $plugin_name... "

    # Check if plugin.json exists
    if [ ! -f "$plugin_json" ]; then
        echo -e "${RED}ERROR${NC}"
        echo "  └─ plugin.json not found at: $plugin_json"
        errors=$((errors + 1))
        continue
    fi

    # Read plugin version
    plugin_version=$(jq -r '.version' "$plugin_json")

    # Compare versions
    if [ "$marketplace_version" = "$plugin_version" ]; then
        echo -e "${GREEN}✓${NC} v$plugin_version"
    else
        echo -e "${RED}✗ MISMATCH${NC}"
        echo "  ├─ marketplace.json: v$marketplace_version"
        echo "  └─ plugin.json:      v$plugin_version"
        mismatches=$((mismatches + 1))
    fi
done

echo ""
echo "==================================="
echo "Summary"
echo "==================================="
echo "Total plugins: $total_plugins"
echo -e "Matches:       ${GREEN}$((total_plugins - mismatches - errors))${NC}"

if [ $mismatches -gt 0 ]; then
    echo -e "Mismatches:    ${RED}$mismatches${NC}"
fi

if [ $errors -gt 0 ]; then
    echo -e "Errors:        ${RED}$errors${NC}"
fi

echo ""

# Exit with appropriate code
if [ $mismatches -gt 0 ] || [ $errors -gt 0 ]; then
    echo -e "${RED}Version validation FAILED${NC}"
    echo ""
    echo "To fix version mismatches:"
    echo "  1. Update plugin.json to the desired version (source of truth)"
    echo "  2. Update marketplace.json to match"
    echo ""
    exit 1
else
    echo -e "${GREEN}All versions are synchronized ✓${NC}"
    exit 0
fi
