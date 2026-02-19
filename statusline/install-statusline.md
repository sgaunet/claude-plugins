# Custom Claude Code Statusline

A lightweight bash statusline for Claude Code that displays the active model, context window usage with a color-coded progress bar, and total context size.

## Example Output

```
[Opus] ▓▓▓░░░░░░░ 30% | 200k ctx     (green)
[Sonnet] ▓▓▓▓▓▓░░░░ 60% | 200k ctx   (yellow)
[Opus] ▓▓▓▓▓▓▓▓░░ 85% | 200k ctx     (red)
```

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
./claude-statusline/configure-statusline.sh
```

This will:
1. Copy `statusline.sh` to `~/.claude/statusline.sh`
2. Back up your current `~/.claude/settings.json`
3. Update the `statusLine` key in settings (all other keys are preserved)

### Manual

1. Copy the script:
   ```bash
   cp claude-statusline/statusline.sh ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

2. Edit `~/.claude/settings.json` and set the `statusLine` key:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline.sh",
       "padding": 0
     }
   }
   ```

3. Restart Claude Code.

## Testing

Pipe mock JSON to verify each color threshold:

```bash
# Green (< 50%)
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":25,"context_window_size":200000}}' | ~/.claude/statusline.sh

# Yellow (50-75%)
echo '{"model":{"display_name":"Sonnet"},"context_window":{"used_percentage":60,"context_window_size":200000}}' | ~/.claude/statusline.sh

# Red (> 75%)
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":85,"context_window_size":200000}}' | ~/.claude/statusline.sh
```

## Customization

Edit `~/.claude/statusline.sh` to adjust:

| Setting | Location | Default |
|---------|----------|---------|
| Bar width | `bar_width=10` | 10 characters |
| Green threshold | `used_pct > 75` / `used_pct >= 50` | < 50% |
| Yellow threshold | `used_pct >= 50` | 50-75% |
| Red threshold | `used_pct > 75` | > 75% |
| Filled character | `bar+="▓"` | `▓` |
| Empty character | `bar+="░"` | `░` |

### Adding extra info

To add git branch to the output, append to the `printf` line:

```bash
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ -n "$branch" ]]; then
  printf '%b' " ${dim}| ${branch}${reset}"
fi
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| No statusline shown | Script not executable | `chmod +x ~/.claude/statusline.sh` |
| `jq not found` displayed | jq not installed | Install jq (see Prerequisites) |
| Old npm statusline still shows | settings.json not updated | Re-run `configure-statusline.sh` or edit manually |
| Garbled characters | Terminal doesn't support Unicode | Replace `▓`/`░` with `#`/`-` in the script |
| No colors | Terminal doesn't support ANSI | Check `$TERM` is set to a color-capable terminal |

## Reverting

Restore from the timestamped backup created during installation:

```bash
# Find your backup
ls ~/.claude/settings.json.bak.*

# Restore it
cp ~/.claude/settings.json.bak.YYYYMMDDHHMMSS ~/.claude/settings.json
```

Or manually set the statusLine back to the npm package:

```json
{
  "statusLine": {
    "type": "command",
    "command": "npx -y ccstatusline@latest",
    "padding": 0
  }
}
```
