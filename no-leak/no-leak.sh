#!/usr/bin/env bash
# Claude Code PreToolUse hook — block access to sensitive files
# Receives JSON on stdin, exits 2 to block or 0 to allow.

set -euo pipefail

INPUT=$(cat)

# Check jq is available
if ! command -v jq &>/dev/null; then
  echo "no-leak: jq not found, skipping check" >&2
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Extract file path from tool_input (Read, Edit, Write, Glob)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# For Bash, extract the command string
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Patterns that indicate sensitive files (matched against basename)
BLOCKED_PATTERNS=(
  '\.env$'
  '\.env\.'
  '\.envrc$'
  '\.vault\.'
  'credentials\.json$'
  '\.pem$'
  '\.key$'
  'secret'
)

check_path() {
  local path="$1"
  local name
  name=$(basename "$path" 2>/dev/null || echo "$path")
  for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if [[ "$name" =~ $pattern ]]; then
      echo "Blocked: '$path' matches sensitive pattern '$pattern'. This file may contain secrets." >&2
      exit 2
    fi
  done
}

# --- File-based tools (Read, Edit, Write, Glob) ---
if [[ -n "$FILE_PATH" ]]; then
  check_path "$FILE_PATH"
fi

# --- Bash commands referencing sensitive files ---
if [[ "$TOOL_NAME" == "Bash" && -n "$COMMAND" ]]; then
  for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
      echo "Blocked: Bash command references sensitive file pattern '$pattern'." >&2
      exit 2
    fi
  done
fi

exit 0
