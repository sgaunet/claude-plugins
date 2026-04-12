# No-Leak Hook for Claude Code

A `PreToolUse` hook that prevents Claude Code from reading or modifying sensitive files and content. Unlike CLAUDE.md instructions which Claude may overlook, hooks are **deterministic** — the LLM cannot bypass them.

## Two-Layer Protection

| Layer | What it checks | Dependency |
|-------|---------------|------------|
| **1. Filename patterns** | Blocks files matching sensitive names (`.env`, `.pem`, `.key`, etc.) | jq (required) |
| **2. Content scanning** | Scans file content for secrets (API keys, tokens, DSNs with credentials) | gitleaks (optional) |

If gitleaks is not installed, the hook degrades gracefully to filename-only checks.

## What Gets Blocked

### Layer 1: Filename Patterns

| Pattern | Examples |
|---------|----------|
| `.env`, `.env.*` | `.env`, `.env.local`, `.env.production` |
| `.envrc` | direnv configuration |
| `*.vault.*` | `config.vault.yml`, `secrets.vault.json` |
| `credentials.json` | GCP/Firebase credentials |
| `*.pem`, `*.key` | TLS certificates, private keys |
| `*secret*` | `secret.yaml`, `db-secret.json` |

### Layer 2: Content Scanning (gitleaks)

Detects 150+ secret types via built-in gitleaks rules, plus custom rules for:

| Pattern | Examples |
|---------|----------|
| Database DSNs | `postgres://admin:s3cr3t@prod.db.com:5432/mydb` |
| Redis DSNs | `redis://user:pass@cache.prod.com:6379` |
| MongoDB DSNs | `mongodb+srv://admin:pass@cluster.mongodb.net` |
| AMQP DSNs | `amqp://user:pass@rabbitmq.prod.com:5672` |
| AWS keys | `AKIAIOSFODNN7EXAMPLE` |
| GitHub tokens | `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| Private keys | `-----BEGIN RSA PRIVATE KEY-----` |
| ...and 150+ more | See [gitleaks rules](https://github.com/gitleaks/gitleaks#rules) |

Scanning applies to: **Read** (file content), **Write** (content to write), **Edit** (replacement text).

**Allowlisted** (not blocked): localhost DSNs, common test credentials (`user:password`), Docker Compose service names (`@db:5432`), example domains.

## Prerequisites

- **jq** — JSON processor (required)
- **gitleaks** — Secret scanner (optional, recommended)

```bash
# Ubuntu / Debian
sudo apt install jq

# macOS
brew install jq
brew install gitleaks

# Rocky / RHEL / Fedora
sudo dnf install jq
# gitleaks: https://github.com/gitleaks/gitleaks#installation
```

## Installation

### Automatic

```bash
./no-leak/configure-no-leak.sh
```

This will:
1. Copy `no-leak.sh` to `~/.claude/no-leak.sh`
2. Copy `gitleaks.toml` to `~/.claude/gitleaks.toml`
3. Back up your current `~/.claude/settings.json`
4. Merge the `PreToolUse` hook into settings (all other keys are preserved)

### Manual

1. Copy the scripts:
   ```bash
   cp no-leak/no-leak.sh ~/.claude/no-leak.sh
   chmod +x ~/.claude/no-leak.sh
   cp no-leak/gitleaks.toml ~/.claude/gitleaks.toml
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

### Filename pattern checks

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

### Content scanning (requires gitleaks)

```bash
# Should BLOCK — Write containing an AWS key
echo '{"tool_name":"Write","tool_input":{"file_path":"config.yml","content":"aws_key = AKIAIOSFODNN7EXAMPLO"}}' | ~/.claude/no-leak.sh
echo $?  # 2

# Should BLOCK — Write with production DSN
echo '{"tool_name":"Write","tool_input":{"file_path":"app.yml","content":"dsn: postgres://admin:s3cr3t@prod.db.company.com:5432/mydb"}}' | ~/.claude/no-leak.sh
echo $?  # 2

# Should BLOCK — Read a file containing secrets
echo 'AKIAIOSFODNN7EXAMPLO' > /tmp/test-leak.txt
echo '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test-leak.txt"}}' | ~/.claude/no-leak.sh
echo $?  # 2
rm /tmp/test-leak.txt

# Should ALLOW — localhost DSN (allowlisted)
echo '{"tool_name":"Write","tool_input":{"file_path":"dev.yml","content":"dsn: postgres://user:password@localhost:5432/mydb"}}' | ~/.claude/no-leak.sh
echo $?  # 0

# Should ALLOW — Docker Compose service name (allowlisted)
echo '{"tool_name":"Write","tool_input":{"file_path":"docker-compose.yml","content":"DATABASE_URL=postgres://user:pass@db:5432/mydb"}}' | ~/.claude/no-leak.sh
echo $?  # 0

# Should ALLOW — clean content
echo '{"tool_name":"Write","tool_input":{"file_path":"main.go","content":"package main"}}' | ~/.claude/no-leak.sh
echo $?  # 0
```

## Customization

### Filename patterns

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

### Gitleaks rules

Edit `~/.claude/gitleaks.toml` to customize content scanning:

```toml
[extend]
useDefault = true

# Disable a noisy built-in rule
# disabledRules = ["generic-api-key"]

# Add project-specific allowlist
[[allowlists]]
description = "Allow test fixtures"
paths = ['''tests/fixtures/.*''']
```

See the [gitleaks configuration docs](https://github.com/gitleaks/gitleaks#configuration) for the full schema.

### Disabling gitleaks temporarily

Set the environment variable before running Claude Code:

```bash
GITLEAKS_DISABLED=1 claude
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
| False positive on filename | Pattern too broad | Narrow the regex in `BLOCKED_PATTERNS` |
| False positive on content | Gitleaks rule too strict | Add allowlist entry in `~/.claude/gitleaks.toml` |
| Hook not active after install | Claude Code not restarted | Restart Claude Code |
| Existing hooks overwritten | Manual edit conflict | Re-run `configure-no-leak.sh` (uses smart merge) |
| Content scan not working | gitleaks not installed | `brew install gitleaks` or see Prerequisites |
| Want to skip content scan | Temporary bypass needed | `GITLEAKS_DISABLED=1 claude` |
