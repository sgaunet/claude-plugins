#!/usr/bin/env bash
# Install custom Claude Code statusline
# Copies statusline.sh to ~/.claude/ and updates settings.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
TARGET="$CLAUDE_DIR/statusline.sh"

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

# --- Install statusline script ---

cp "$SCRIPT_DIR/statusline.sh" "$TARGET"
chmod +x "$TARGET"
echo "Installed: $TARGET"

# --- Update settings.json ---

if [[ -f "$SETTINGS" ]]; then
  backup="${SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS" "$backup"
  echo "Backup:    $backup"

  # Merge statusLine key, preserving everything else
  jq '. * {"statusLine":{"type":"command","command":"~/.claude/statusline.sh","padding":0}}' \
    "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
else
  cat > "$SETTINGS" <<'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
EOF
fi

echo "Updated:   $SETTINGS"

# --- Verification ---

echo ""
echo "Done! Restart Claude Code to activate the new statusline."
echo ""
echo "Test it with:"
echo '  echo '\''{"model":{"display_name":"Opus"},"context_window":{"used_percentage":25,"context_window_size":200000}}'\'' | ~/.claude/statusline.sh'
