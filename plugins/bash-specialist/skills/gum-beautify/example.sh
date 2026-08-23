#!/bin/bash
# description: Example script with gum integration
# usage: example.sh [OPTIONS] <target>

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"   # split assignment/readonly: SC2155
readonly SCRIPT_NAME
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
