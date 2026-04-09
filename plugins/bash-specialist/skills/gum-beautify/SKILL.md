---
name: gum-beautify
description: Integrate Charmbracelet gum for beautiful, TTY-safe terminal output in bash scripts. Internal skill used by bash-pro agent for interactive prompts, styled output, and structured logging.
user-invocable: false
allowed-tools: Read, Glob, Grep, Bash(gum:*)
---

# Gum Terminal UX Integration

Integrate Charmbracelet's `gum` CLI tool into bash scripts for beautiful terminal output, interactive prompts, and structured logging -- with mandatory TTY detection to ensure scripts remain pipe-safe.

## When to Use

- User requests interactive prompts (selection menus, confirmations, text input)
- Script needs visually styled output (headers, banners, success/error messages)
- Structured logging is needed (`gum log` with levels and key-value pairs)
- Progress indication for long-running operations (spinners)
- User wants a polished CLI experience for their bash tools
- Existing scripts need UX improvements without changing functionality

## Prerequisites

1. **gum is installed**: The script must verify gum is available at runtime. This skill provides the detection boilerplate but does NOT handle gum installation -- the script should fail with a clear message directing the user to install gum.
2. **Bash 4+**: Gum integration patterns use bash-specific features (`[[ ]]` tests, process substitution).

## Gum Subcommand Reference

| Subcommand | Purpose | Needs TTY stdin | Output |
|------------|---------|-----------------|--------|
| `gum input` | Single-line text input | Yes | stdout |
| `gum write` | Multi-line text editor | Yes | stdout |
| `gum filter` | Fuzzy filter from list | Yes | stdout |
| `gum choose` | Select from options | Yes | stdout |
| `gum confirm` | Yes/no confirmation | Yes | exit code |
| `gum file` | File picker | Yes | stdout |
| `gum pager` | Scrollable text viewer | Yes | none |
| `gum spin` | Spinner during command | No | passthrough |
| `gum table` | Formatted table display | No | stdout |
| `gum style` | Styled text block | No | stdout |
| `gum format` | Markdown/emoji rendering | No | stdout |
| `gum log` | Structured log messages | No | stderr |
| `gum join` | Join styled blocks | No | stdout |

**Key distinction**: Commands marked "Needs TTY stdin: Yes" require an interactive terminal on stdin. Commands like `gum style`, `gum format`, `gum table`, `gum log`, and `gum spin` work without a TTY on stdin, but display-oriented ones (`gum style`, `gum format`) should still fall back to plain text when stdout is piped.

`gum log` is always safe -- it writes to stderr by default.

## Workflow: Add Gum Dependency Check

Every script using gum must include this check near the top, before any gum calls.

### Step 1: Add Dependency Check Function

Insert this function in the script's function section:

```bash
require_gum() {
    if ! command -v gum >/dev/null 2>&1; then
        echo >&2 "Error: gum is not installed."
        echo >&2 "Install it from https://github.com/charmbracelet/gum"
        echo >&2 "  macOS:  brew install gum"
        echo >&2 "  Linux:  see https://github.com/charmbracelet/gum#installation"
        exit 1
    fi
}
```

### Step 2: Call Early in Main

```bash
main() {
    require_gum
    # ... rest of script
}
```

## Workflow: TTY Detection (Critical)

This is the most important pattern. Scripts must detect whether their stdin/stdout are terminals and fall back to plain text when piped.

### Step 1: Define TTY Detection Helpers

Place these near the top of the script, after constants:

```bash
# TTY detection -- true when connected to a terminal
is_interactive_stdin()  { [ -t 0 ]; }
is_interactive_stdout() { [ -t 1 ]; }

# Master check: can we use fully interactive gum features?
is_interactive() { is_interactive_stdin && is_interactive_stdout; }
```

### Step 2: Define Dual-Mode Input Wrappers

Create wrapper functions that use gum when interactive, and fall back to plain alternatives when piped:

```bash
# --- User Input (requires TTY on stdin AND stdout) ---

prompt_input() {
    local prompt_text="$1"
    local default_val="${2:-}"
    if is_interactive; then
        gum input --placeholder "$prompt_text" --value "$default_val"
    else
        if [ -n "$default_val" ]; then
            echo "$default_val"
        else
            read -r reply
            echo "$reply"
        fi
    fi
}

prompt_choose() {
    # Args: option1 option2 option3 ...
    if is_interactive; then
        gum choose "$@"
    else
        # When piped, use first option as default
        echo "$1"
    fi
}

prompt_confirm() {
    local message="$1"
    if is_interactive; then
        gum confirm "$message"
    else
        # When piped, auto-confirm (caller can override with --no-confirm flag)
        return 0
    fi
}

prompt_filter() {
    # Reads options from stdin
    if is_interactive; then
        gum filter "$@"
    else
        head -1
    fi
}
```

### Step 3: Define Dual-Mode Display Wrappers

Display functions separate UX output (stderr, for humans) from data output (stdout, for pipes):

```bash
# --- Display Output (TTY-aware, always to stderr) ---

show_header() {
    local text="$1"
    if is_interactive_stdout; then
        gum style --foreground 212 --border rounded --border-foreground 212 \
            --padding "0 2" --bold "$text" >&2
    else
        echo >&2 "=== $text ==="
    fi
}

show_success() {
    local text="$1"
    if is_interactive_stdout; then
        gum format -t emoji ":white_check_mark: $text" >&2
    else
        echo >&2 "OK $text"
    fi
}

show_error() {
    local text="$1"
    if is_interactive_stdout; then
        gum format -t emoji ":x: $text" >&2
    else
        echo >&2 "ERROR $text"
    fi
}

show_warning() {
    local text="$1"
    if is_interactive_stdout; then
        gum format -t emoji ":warning: $text" >&2
    else
        echo >&2 "WARN $text"
    fi
}
```

### Step 4: Rationale for stderr

All display/UX output goes to stderr (`>&2`) because:

- `stderr` is typically still connected to the terminal even when stdout is piped
- Data on stdout remains clean for piping to other tools (`jq`, `grep`, `awk`)
- `gum log` already writes to stderr by default -- this keeps everything consistent
- Unix philosophy: scripts that separate data from decoration compose well

## Workflow: Structured Logging with gum log

Replace manual `echo >&2` logging with `gum log` for structured, leveled output.

### Step 1: Define Log Functions

```bash
# gum log writes to stderr by default -- always pipe-safe
log_debug() { gum log --level debug "$@"; }
log_info()  { gum log --level info "$@"; }
log_warn()  { gum log --level warn "$@"; }
log_error() { gum log --level error "$@"; }

# Structured key-value logging
log_info_kv() {
    local msg="$1"; shift
    # Remaining args are key value key value ...
    gum log --structured --level info "$msg" "$@"
}
```

### Step 2: Usage Examples

```bash
log_info "Starting deployment"
log_warn "Config file not found, using defaults"
log_error "Connection to database failed"
log_debug "Parsed 42 records from input"

# Structured logging with key-value pairs
log_info_kv "Deployment complete" env production version "1.2.3" duration "34s"
```

### Step 3: Log Level Control via Environment

Use the `GUM_LOG_LEVEL` environment variable (built into gum) to control verbosity:

```bash
# Users can control log verbosity:
# GUM_LOG_LEVEL=debug ./my-script.sh    # Show all logs
# GUM_LOG_LEVEL=warn ./my-script.sh     # Only warnings and errors
# GUM_LOG_LEVEL=error ./my-script.sh    # Only errors
```

Document this in the script's `--help` output.

## Workflow: Spinners for Long Operations

### Step 1: Use gum spin with TTY Fallback

```bash
run_with_spinner() {
    local title="$1"; shift
    if is_interactive_stdout; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        log_info "$title"
        "$@"
    fi
}
```

### Step 2: Usage

```bash
run_with_spinner "Downloading artifacts..." curl -sL "$url" -o "$output"
run_with_spinner "Running tests..." make test
run_with_spinner "Building image..." docker build -t myapp .
```

Available spinner styles: `line`, `dot`, `minidot`, `jump`, `pulse`, `points`, `globe`, `moon`, `monkey`, `meter`, `hamburger`. Default to `dot` for a clean look.

## Workflow: Styled Output Blocks

### Step 1: Banners and Headers

```bash
show_banner() {
    if is_interactive_stdout; then
        gum style \
            --foreground 212 --border double --border-foreground 57 \
            --align center --width 50 --margin "1 0" --padding "1 2" \
            "$SCRIPT_NAME" "v$VERSION"
    else
        echo >&2 "$SCRIPT_NAME v$VERSION"
    fi
}
```

### Step 2: Tables

```bash
show_table() {
    # Arg: path to CSV file with header row
    if is_interactive_stdout; then
        gum table < "$1"
    else
        column -t -s',' < "$1"
    fi
}
```

### Step 3: Joining Blocks

Always quote `gum style` output to preserve newlines when passing to `gum join`:

```bash
show_summary() {
    if is_interactive_stdout; then
        local left right
        left="$(gum style --border rounded --padding "0 2" \
            "Files: $file_count" "Errors: $error_count")"
        right="$(gum style --border rounded --padding "0 2" \
            "Duration: ${duration}s" "Status: $status")"
        gum join --horizontal "$left" "$right" >&2
    else
        echo >&2 "Files: $file_count | Errors: $error_count | Duration: ${duration}s | Status: $status"
    fi
}
```

## Workflow: Environment Variable Customization

Gum supports theming via environment variables with the pattern `GUM_<COMMAND>_<OPTION>`.

### Step 1: Define Script Defaults

```bash
# Set gum defaults for consistent branding (users can override)
export GUM_INPUT_PLACEHOLDER="${GUM_INPUT_PLACEHOLDER:-Type here...}"
export GUM_CONFIRM_AFFIRMATIVE="${GUM_CONFIRM_AFFIRMATIVE:-Yes}"
export GUM_CONFIRM_NEGATIVE="${GUM_CONFIRM_NEGATIVE:-No}"
export GUM_SPIN_SPINNER="${GUM_SPIN_SPINNER:-dot}"
```

### Step 2: Document in Help

Include a section in `--help` about customizable environment variables:

```bash
usage() {
    cat <<EOF
...

Environment Variables:
    GUM_LOG_LEVEL       Log verbosity: debug, info, warn, error (default: info)
    GUM_SPIN_SPINNER    Spinner style: dot, line, minidot, pulse (default: dot)
    NO_COLOR            Disable all color output (standard convention)
EOF
}
```

## Emoji Guidelines

When integrating gum emoji rendering (`gum format -t emoji`), follow these rules:

**Appropriate uses:**

- Final status line: `:white_check_mark: All checks passed` or `:x: 3 errors found`
- Section separators in verbose output: `:rocket: Deploying...`
- Summary headers: `:bar_chart: Results`

**Avoid:**

- Every log line (creates visual noise, distracts from content)
- Data output on stdout (breaks parsability)
- Error messages (plain text is clearer for debugging)
- When `NO_COLOR` is set (respect the convention)

**Implementation pattern:**

```bash
show_status() {
    local emoji="$1" plain="$2" text="$3"
    if is_interactive_stdout; then
        gum format -t emoji ":${emoji}: ${text}" >&2
    else
        echo >&2 "${plain} ${text}"
    fi
}

# Usage
show_status "white_check_mark" "OK" "Build completed"
show_status "x" "FAIL" "Tests failed"
show_status "warning" "WARN" "Deprecated API in use"
```

## Complete Integration Example

A full script skeleton combining all patterns:

```bash
#!/bin/bash
# description: Example script with gum integration
# usage: example.sh [OPTIONS] <target>

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"

# --- TTY Detection ---
is_interactive_stdin()  { [ -t 0 ]; }
is_interactive_stdout() { [ -t 1 ]; }
is_interactive() { is_interactive_stdin && is_interactive_stdout; }

# --- Dependency Check ---
require_gum() {
    if ! command -v gum >/dev/null 2>&1; then
        echo >&2 "Error: gum is not installed."
        echo >&2 "Install: https://github.com/charmbracelet/gum#installation"
        exit 1
    fi
}

# --- Logging (gum log -> stderr, always safe) ---
log_info()  { gum log --level info "$@"; }
log_warn()  { gum log --level warn "$@"; }
log_error() { gum log --level error "$@"; }

# --- Display (TTY-aware, to stderr) ---
show_header() {
    if is_interactive_stdout; then
        gum style --foreground 212 --border rounded --padding "0 2" --bold "$1" >&2
    else
        echo >&2 "=== $1 ==="
    fi
}

show_success() {
    if is_interactive_stdout; then
        gum format -t emoji ":white_check_mark: $1" >&2
    else
        echo >&2 "OK $1"
    fi
}

# --- Interaction (requires full TTY) ---
prompt_choose() {
    if is_interactive; then
        gum choose "$@"
    else
        echo "$1"
    fi
}

run_with_spinner() {
    local title="$1"; shift
    if is_interactive_stdout; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        log_info "$title"
        "$@"
    fi
}

# --- Cleanup ---
cleanup() { :; }

# --- Main ---
usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] <target>

Options:
    -h, --help    Show help
    -v, --verbose Verbose output

Environment:
    GUM_LOG_LEVEL  Log level (debug|info|warn|error)
EOF
}

main() {
    require_gum
    trap cleanup EXIT

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) log_error "Unknown option: $1"; usage; exit 2 ;;
            *) break ;;
        esac
    done

    show_header "My Tool v$VERSION"
    local env
    env=$(prompt_choose "production" "staging" "development")
    run_with_spinner "Deploying to $env..." sleep 2
    show_success "Deployed to $env"

    # Data output goes to stdout (clean, pipeable)
    echo "$env"
}

main "$@"
```

## Error Handling

| Condition | Action |
|-----------|--------|
| gum not installed | Abort with install instructions (see `require_gum`). Never attempt to install gum automatically. |
| Not a TTY (stdout piped) | Skip `gum style`, `gum format`, `gum spin` display; use plain text to stderr. `gum log` is always safe. |
| Not a TTY (stdin piped) | Skip `gum input`, `gum choose`, `gum confirm`, `gum filter`, `gum write`, `gum file`; use defaults or `read`. |
| `NO_COLOR` env set | Respect the standard: skip color flags, emojis, and styled output. |
| gum command fails | Log the error, fall back to plain text equivalent. Never let a gum failure crash the script. |
| User cancels gum prompt (Ctrl+C) | gum returns non-zero; handle in the trap or check exit code and exit gracefully. |
