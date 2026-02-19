#!/usr/bin/env bash
# Claude Code custom statusline
# Reads JSON session data from stdin, outputs color-coded status line.

set -euo pipefail

# Read JSON from stdin
input=$(cat)

# Check jq is available
if ! command -v jq &>/dev/null; then
  printf 'jq not found'
  exit 0
fi

# Extract fields with fallback defaults
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "unknown"')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Round percentage to integer
used_pct=${used_pct%.*}
: "${used_pct:=0}"

# Color thresholds
if (( used_pct > 75 )); then
  color='\033[31m'  # Red
elif (( used_pct >= 50 )); then
  color='\033[33m'  # Yellow
else
  color='\033[32m'  # Green
fi

reset='\033[0m'
cyan='\033[36m'
dim='\033[2m'

# Progress bar (10 chars)
bar_width=10
filled=$(( used_pct * bar_width / 100 ))
empty=$(( bar_width - filled ))

bar=""
for (( i = 0; i < filled; i++ )); do bar+="▓"; done
for (( i = 0; i < empty; i++ )); do bar+="░"; done

# Format context size as human-readable
if (( ctx_size >= 1000000 )); then
  ctx_label="$(( ctx_size / 1000000 ))M"
elif (( ctx_size >= 1000 )); then
  ctx_label="$(( ctx_size / 1000 ))k"
else
  ctx_label="${ctx_size}"
fi

# Short model name: strip "Claude " prefix if present
short_model="${model#Claude }"

printf '%b' "${cyan}[${short_model}]${reset} ${color}${bar} ${used_pct}%${reset} ${dim}| ${ctx_label} ctx${reset}"
