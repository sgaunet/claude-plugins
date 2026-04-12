#!/usr/bin/env bash
# Claude Code PreToolUse hook — block access to sensitive files and content
# Receives JSON on stdin, exits 2 to block or 0 to allow.
#
# Layer 1: Filename pattern matching (always active, requires jq)
# Layer 2: Content scanning via gitleaks (if installed, graceful degradation)

set -euo pipefail

INPUT=$(cat)

# --- Prerequisites ---

if ! command -v jq &>/dev/null; then
  echo "no-leak: jq not found, skipping check" >&2
  exit 0
fi

# --- Gitleaks availability ---

GITLEAKS_AVAILABLE=false
GITLEAKS_CONFIG="$HOME/.claude/gitleaks.toml"

if [[ "${GITLEAKS_DISABLED:-}" == "1" ]]; then
  : # explicitly disabled by user
elif command -v gitleaks &>/dev/null; then
  GITLEAKS_AVAILABLE=true
fi

# --- Parse input ---

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# --- Blocked filename patterns ---

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

# --- Gitleaks content scan function ---

scan_with_gitleaks() {
  [[ "$GITLEAKS_AVAILABLE" == "true" ]] || return 0

  local mode="$1"
  local config_args=()
  if [[ -f "$GITLEAKS_CONFIG" ]]; then
    config_args=(--config "$GITLEAKS_CONFIG")
  fi

  local gitleaks_exit=0

  if [[ "$mode" == "file" ]]; then
    local filepath="$2"
    # Skip if file doesn't exist (Claude Code itself will report the error)
    [[ -f "$filepath" ]] || return 0
    gitleaks dir "${config_args[@]}" --no-banner --exit-code 99 --max-target-megabytes 1 "$filepath" 2>/dev/null || gitleaks_exit=$?
  elif [[ "$mode" == "stdin" ]]; then
    local content="$2"
    [[ -n "$content" ]] || return 0
    printf '%s\n' "$content" | gitleaks stdin "${config_args[@]}" --no-banner --exit-code 99 2>/dev/null || gitleaks_exit=$?
  fi

  if [[ "$gitleaks_exit" -eq 99 ]]; then
    echo "Blocked: gitleaks detected secrets in content. Review the content before proceeding." >&2
    exit 2
  fi
  # Exit codes 0 (clean) and others (gitleaks error) both allow the operation.
  # We only block on exit 99 (confirmed leaks).
  return 0
}

# --- Layer 1: Filename pattern checks ---

if [[ -n "$FILE_PATH" ]]; then
  check_path "$FILE_PATH"
fi

if [[ "$TOOL_NAME" == "Bash" && -n "$COMMAND" ]]; then
  for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if [[ "$COMMAND" =~ $pattern ]]; then
      echo "Blocked: Bash command references sensitive file pattern '$pattern'." >&2
      exit 2
    fi
  done
fi

# --- Layer 2: Content scanning with gitleaks ---

if [[ "$GITLEAKS_AVAILABLE" == "true" ]]; then
  case "$TOOL_NAME" in
    Read)
      if [[ -n "$FILE_PATH" ]]; then
        scan_with_gitleaks "file" "$FILE_PATH"
      fi
      ;;
    Write)
      CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // ""')
      if [[ -n "$CONTENT" ]]; then
        scan_with_gitleaks "stdin" "$CONTENT"
      fi
      ;;
    Edit)
      NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""')
      if [[ -n "$NEW_STRING" ]]; then
        scan_with_gitleaks "stdin" "$NEW_STRING"
      fi
      ;;
  esac
fi

exit 0
