#!/bin/bash
# Stop hook: run tests and linter before allowing Claude to stop

INPUT=$(cat)

# Prevent infinite loops: if already continuing from a stop hook, allow stop
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

# Run tests if the task exists
if task --list-all 2>/dev/null | grep -q '^\* tests:'; then
  task tests || {
    echo '{"decision":"block","reason":"Tests failed. Please fix before stopping."}' >&2
    exit 2
  }
fi

# Run lint if the task exists
if task --list-all 2>/dev/null | grep -q '^\* lint:'; then
  task lint || {
    echo '{"decision":"block","reason":"Linting failed. Please fix before stopping."}' >&2
    exit 2
  }
fi

exit 0
