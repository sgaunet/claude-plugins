---
description: Audit all plugins for adherence to Claude Code official best practices
allowed-tools: Read, Grep, Glob, Bash(find:*), Bash(wc:*), Task, WebFetch
---

# Audit Plugins Command

Scan all plugin definitions in this marketplace and compare them against official Claude Code documentation. Produce a scored audit report with prioritized findings.

## Process

### Step 1: Discover Plugin Structure

Use `Glob` to enumerate all files to audit:

- `plugins/*/agents/*.md` — agent definitions
- `plugins/*/commands/*.md` — command definitions
- `plugins/*/skills/*/SKILL.md` — skill definitions
- `plugins/*/.claude-plugin/plugin.json` — plugin manifests
- `.claude-plugin/marketplace.json` — marketplace manifest
- `plugins/*/mcp.json` — MCP server configurations

Count totals (plugins, agents, commands, skills) for the report summary.

### Step 2: Launch 3 Parallel Sonnet Agents

Launch all 3 agents concurrently using the Task tool. Each agent must **first fetch the relevant official documentation** via WebFetch before performing its analysis.

---

**Agent 1: Agent & Subagent Auditor** (`general-purpose`, model: `sonnet`)

Prompt the agent to:

1. Fetch official docs using WebFetch:
   - `https://docs.claude.com/en/docs/claude-code/plugins-reference` — extract agent frontmatter fields, required vs optional, content structure
   - `https://docs.claude.com/en/docs/claude-code/sub-agents` — extract sub-agent best practices, model selection guidance
2. Read all files matching `plugins/*/agents/*.md`
3. For each agent file, check:
   - **Frontmatter fields**: `name` (required), `description` (required), `model` (required, valid values: sonnet/opus/haiku), `allowed-tools` (recommended), `color` (optional), `context` (optional), `permissionMode` (optional), `capabilities` (optional), `skills` (optional)
   - **Description quality**: Should clearly state WHEN to use the agent (shown in Claude Code UI)
   - **Model appropriateness**: `sonnet` for code/speed tasks, `opus` for complex analysis/docs, `haiku` for fast/simple tasks
   - **Content structure**: Should include role statement, proactive triggers, core capabilities, implementation patterns, deliverables
   - **Proactive triggers**: File patterns and keyword triggers for automatic activation
   - **Tool restrictions**: `allowed-tools` should be scoped appropriately (not overly broad)
4. Return findings with severity levels and file references

---

**Agent 2: Command & Skill Auditor** (`general-purpose`, model: `sonnet`)

Prompt the agent to:

1. Fetch official docs using WebFetch:
   - `https://docs.claude.com/en/docs/claude-code/plugins-reference` — extract command frontmatter fields, required vs optional
   - `https://docs.claude.com/en/docs/claude-code/skills` — extract skill structure requirements
2. Read all files matching `plugins/*/commands/*.md` and `plugins/*/skills/*/SKILL.md`
3. For each command file, check:
   - **Frontmatter fields**: `name` (required), `description` (required), `argument-hint` (recommended for parameterized commands), `allowed-tools` (recommended)
   - **Description quality**: Should be concise and action-oriented
   - **Process section**: Should have clear numbered steps
   - **Output format**: Should specify expected output structure
   - **Tool usage**: Tools listed in `allowed-tools` should match what the process section references
4. For each skill file, check:
   - **SKILL.md structure**: Should have clear description, usage instructions, and supporting file references
   - **Naming conventions**: Directory name should match skill purpose
5. Return findings with severity levels and file references

---

**Agent 3: Manifest, Structure & Ecosystem Auditor** (`general-purpose`, model: `sonnet`)

Prompt the agent to:

1. Fetch official docs using WebFetch:
   - `https://docs.claude.com/en/docs/claude-code/plugins` — extract plugin structure requirements, marketplace format
   - `https://docs.claude.com/en/docs/claude-code/plugins-reference` — extract manifest field specifications
2. Read all manifest and config files:
   - `plugins/*/.claude-plugin/plugin.json`
   - `.claude-plugin/marketplace.json`
   - `plugins/*/mcp.json`
3. For each plugin.json, check:
   - **Required fields**: `name`, `version`, `description`
   - **Version format**: Should follow semver
   - **Description quality**: Should include keywords for discoverability and list MCP servers
   - **Completeness**: Should reference all agents, commands, skills in the plugin directory
4. For marketplace.json, check:
   - **Required fields**: name, version, plugins list
   - **Plugin references**: All plugins in `plugins/` should be listed
   - **Version consistency**: Marketplace version should be coherent with plugin versions
5. For mcp.json, check:
   - **Server declarations**: Should match servers actually used in agent/command `allowed-tools`
6. **Cross-cutting ecosystem checks**:
   - Correct categorization (agent vs skill vs command — no misplaced files)
   - Naming conventions consistency across all plugins
   - No orphaned files (agents/commands referenced nowhere)
   - Inter-agent coordination patterns (context field usage)
7. Return findings with severity levels and file references

### Step 3: Aggregate Results

Collect findings from all 3 agents and merge into a unified list. Deduplicate any overlapping findings.

### Step 4: Prioritize and Score

- Sort findings by severity: Critical > High > Medium > Low
- Calculate scores (1-5 stars) for each category based on finding density and severity:
  - 0 Critical + 0 High = 5 stars
  - 0 Critical + 1-2 High = 4 stars
  - 1 Critical or 3+ High = 3 stars
  - 2+ Critical = 2 stars
  - 3+ Critical = 1 star

### Step 5: Generate Report

## Report Format

```markdown
# Plugin Marketplace Audit Report

## Summary
- **Plugins Analyzed**: N
- **Agents Analyzed**: N
- **Commands Analyzed**: N
- **Skills Analyzed**: N
- **Total Findings**: N (🔴 X Critical, 🟠 Y High, 🟡 Z Medium, 🟢 W Low)
- **Overall Score**: X/5 ⭐

## Agent Definitions [Score: X/5]
- 🔴 **CRITICAL** `plugins/foo/agents/bar.md` — [Finding description]
  - Recommendation: [Actionable fix]
- 🟠 **HIGH** `plugins/foo/agents/baz.md` — [Finding description]
  - Recommendation: [Actionable fix]
...

## Commands & Skills [Score: X/5]
- 🟠 **HIGH** `plugins/foo/commands/qux.md` — [Finding description]
  - Recommendation: [Actionable fix]
...

## Manifests & Structure [Score: X/5]
- 🟡 **MEDIUM** `plugins/foo/.claude-plugin/plugin.json` — [Finding description]
  - Recommendation: [Actionable fix]
...

## Improvement Roadmap (Prioritized)
1. 🔴 [Most critical fix with file reference]
2. 🔴 [Next critical fix]
3. 🟠 [High priority fix]
4. 🟡 [Medium priority fix]
5. 🟢 [Low priority enhancement]

## Reference Documentation
- [Plugins Overview](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugins Reference](https://docs.claude.com/en/docs/claude-code/plugins-reference)
- [Sub-agents](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [Skills](https://docs.claude.com/en/docs/claude-code/skills)
```

## Severity Levels

- 🔴 **CRITICAL**: Violates required fields or breaks plugin validation (e.g., missing `name`, invalid `model` value)
- 🟠 **HIGH**: Missing recommended fields or significant best practice violations (e.g., no `allowed-tools`, poor description)
- 🟡 **MEDIUM**: Missing optional but beneficial fields or moderate improvements (e.g., no `argument-hint`, no proactive triggers)
- 🟢 **LOW**: Minor enhancements or polish (e.g., inconsistent naming, missing `color` field)
