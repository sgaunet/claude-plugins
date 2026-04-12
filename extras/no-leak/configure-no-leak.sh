#!/usr/bin/env bash
# Install no-leak PreToolUse hook into Claude Code user settings
# Copies no-leak.sh and gitleaks.toml to ~/.claude/ and merges hook config into settings.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
TARGET="$CLAUDE_DIR/no-leak.sh"
GITLEAKS_TARGET="$CLAUDE_DIR/gitleaks.toml"

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

# --- Soft prerequisites ---

if command -v gitleaks &>/dev/null; then
  echo "Found:     gitleaks $(gitleaks version 2>/dev/null)"
else
  echo "Warning:   gitleaks not found. Content scanning will be disabled."
  echo "           Install it for full protection:"
  echo "             macOS:  brew install gitleaks"
  echo "             Linux:  https://github.com/gitleaks/gitleaks#installation"
  echo ""
  echo "           The hook will still block based on filename patterns."
  echo ""
fi

# --- Install hook script ---

cp "$SCRIPT_DIR/no-leak.sh" "$TARGET"
chmod +x "$TARGET"
echo "Installed: $TARGET"

# --- Install gitleaks config ---

if [[ -f "$SCRIPT_DIR/gitleaks.toml" ]]; then
  cp "$SCRIPT_DIR/gitleaks.toml" "$GITLEAKS_TARGET"
  echo "Installed: $GITLEAKS_TARGET"
fi

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
echo "Test filename blocking:"
echo '  echo '\''{"tool_name":"Read","tool_input":{"file_path":".env"}}'\'' | ~/.claude/no-leak.sh'
echo '  # Expected: exit code 2 (blocked)'
echo ""
echo '  echo '\''{"tool_name":"Read","tool_input":{"file_path":"main.go"}}'\'' | ~/.claude/no-leak.sh'
echo '  # Expected: exit code 0 (allowed)'
echo ""
echo "Test gitleaks content scanning (requires gitleaks):"
echo '  echo '\''{"tool_name":"Write","tool_input":{"file_path":"x.yml","content":"key = AKIAIOSFODNN7EXAMPLO"}}'\'' | ~/.claude/no-leak.sh'
echo '  # Expected: exit code 2 (blocked by gitleaks)'
echo ""
echo "Disable gitleaks temporarily:"
echo '  GITLEAKS_DISABLED=1 your-command'
