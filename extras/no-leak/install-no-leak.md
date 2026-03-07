# No-Leak Hook for Claude Code

A `PreToolUse` hook that prevents Claude Code from reading or modifying sensitive files (`.env`, credentials, private keys, vault files). Unlike CLAUDE.md instructions which Claude may overlook, hooks are **deterministic** — the LLM cannot bypass them.

## What Gets Blocked

| Pattern | Examples |
|---------|----------|
| `.env`, `.env.*` | `.env`, `.env.local`, `.env.production` |
| `.envrc` | direnv configuration |
| `*.vault.*` | `config.vault.yml`, `secrets.vault.json` |
| `credentials.json` | GCP/Firebase credentials |
| `*.pem`, `*.key` | TLS certificates, private keys |
| `*secret*` | `secret.yaml`, `db-secret.json` |

Applies to: **Read**, **Edit**, **Write**, **Bash**, and **Glob** tool calls.

## Prerequisites

- **jq** — JSON processor

```bash
# Ubuntu / Debian
sudo apt install jq

# macOS
brew install jq

# Rocky / RHEL / Fedora
sudo dnf install jq
```

## Installation

### Automatic

```bash
./no-leak/configure-no-leak.sh
```

This will:
1. Copy `no-leak.sh` to `~/.claude/no-leak.sh`
2. Back up your current `~/.claude/settings.json`
3. Merge the `PreToolUse` hook into settings (all other keys are preserved)

### Manual

1. Copy the script:
   ```bash
   cp no-leak/no-leak.sh ~/.claude/no-leak.sh
   chmod +x ~/.claude/no-leak.sh
   ```

2. Edit `~/.claude/settings.json` and add the hook:
   ```json
   {
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
   }
   ```

3. Restart Claude Code.

## Testing

Pipe mock JSON to verify blocking and allowing:

```bash
# Should BLOCK (exit code 2)
echo '{"tool_name":"Read","tool_input":{"file_path":"/app/.env"}}' | ~/.claude/no-leak.sh
echo $?  # 2

echo '{"tool_name":"Read","tool_input":{"file_path":"/app/.env.production"}}' | ~/.claude/no-leak.sh
echo $?  # 2

echo '{"tool_name":"Read","tool_input":{"file_path":"config.vault.yml"}}' | ~/.claude/no-leak.sh
echo $?  # 2

echo '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}' | ~/.claude/no-leak.sh
echo $?  # 2

echo '{"tool_name":"Read","tool_input":{"file_path":"server.key"}}' | ~/.claude/no-leak.sh
echo $?  # 2

# Should ALLOW (exit code 0)
echo '{"tool_name":"Read","tool_input":{"file_path":"main.go"}}' | ~/.claude/no-leak.sh
echo $?  # 0

echo '{"tool_name":"Bash","tool_input":{"command":"go test ./..."}}' | ~/.claude/no-leak.sh
echo $?  # 0
```

## Customization

Edit `~/.claude/no-leak.sh` to adjust the `BLOCKED_PATTERNS` array:

```bash
BLOCKED_PATTERNS=(
  '\.env$'
  '\.env\.'
  '\.envrc$'
  '\.vault\.'
  'credentials\.json$'
  '\.pem$'
  '\.key$'
  'secret'
  # Add your own patterns:
  '\.tfvars$'          # Terraform variables
  'kubeconfig'         # Kubernetes config
  '\.docker/config'    # Docker credentials
)
```

## Reverting

Restore from the timestamped backup created during installation:

```bash
# Find your backup
ls ~/.claude/settings.json.bak.*

# Restore it
cp ~/.claude/settings.json.bak.YYYYMMDDHHMMSS ~/.claude/settings.json
```

Or manually remove the `PreToolUse` hook entry from `~/.claude/settings.json`.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Hook not triggering | Script not executable | `chmod +x ~/.claude/no-leak.sh` |
| `jq not found` in stderr | jq not installed | Install jq (see Prerequisites) |
| False positive on normal file | Pattern too broad | Narrow the regex in `BLOCKED_PATTERNS` |
| Hook not active after install | Claude Code not restarted | Restart Claude Code |
| Existing hooks overwritten | Manual edit conflict | Re-run `configure-no-leak.sh` (uses smart merge) |
