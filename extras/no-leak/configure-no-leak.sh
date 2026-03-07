#!/usr/bin/env bash
# Install no-leak PreToolUse hook into Claude Code user settings
# Copies no-leak.sh to ~/.claude/ and merges hook config into settings.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
TARGET="$CLAUDE_DIR/no-leak.sh"

# --- Prerequisites ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it first:"
  echo "  Ubuntu/Debian: sudo apt install jq"
  echo "  macOS:         brew install jq"
  echo "  Rocky/RHEL:    sudo dnf install jq"
  exit 1
fi

if [[ ! -d "$CLAUDE_DIR" ]]; then
  echo "Error: $CLAUDE_DIR does not exist. Is Claude Code installed?"
  exit 1
fi

# --- Install hook script ---

cp "$SCRIPT_DIR/no-leak.sh" "$TARGET"
chmod +x "$TARGET"
echo "Installed: $TARGET"

# --- Update settings.json ---

HOOK_CONFIG='{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write|Bash|Glob",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/no-leak.sh"
          }
        ]
      }
    ]
  }
}'

if [[ -f "$SETTINGS" ]]; then
  backup="${SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS" "$backup"
  echo "Backup:    $backup"

  # Deep merge: preserves existing keys and existing hooks entries
  jq --argjson hook "$HOOK_CONFIG" '
    .hooks.PreToolUse = ((.hooks.PreToolUse // []) + $hook.hooks.PreToolUse | unique_by(.matcher))
  ' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
else
  echo "$HOOK_CONFIG" | jq '.' > "$SETTINGS"
fi

echo "Updated:   $SETTINGS"

# --- Verification ---

echo ""
echo "Done! Restart Claude Code to activate the no-leak hook."
echo ""
echo "Test it with:"
echo '  echo '\''{"tool_name":"Read","tool_input":{"file_path":".env"}}'\'' | ~/.claude/no-leak.sh'
echo '  # Expected: exit code 2 (blocked)'
echo ""
echo '  echo '\''{"tool_name":"Read","tool_input":{"file_path":"main.go"}}'\'' | ~/.claude/no-leak.sh'
echo '  # Expected: exit code 0 (allowed)'
