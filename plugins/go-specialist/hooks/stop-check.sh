#!/bin/bash
# Stop hook: run tests and linter before allowing Claude to stop

INPUT=$(cat)

# Prevent infinite loops: if already continuing from a stop hook, allow stop
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

# Run tests then lint — fail fast with &&
task tests && task lint || {
  echo '{"decision":"block","reason":"Tests or linting failed. Please fix before stopping."}' >&2
  exit 2
}

exit 0
