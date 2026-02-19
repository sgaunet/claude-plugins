# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code Plugin Marketplace** repository that contains specialized agent definitions for DevOps and software engineering workflows. The repository follows the Claude Code plugin ecosystem structure, providing reusable agents that can be proactively activated based on context.

## Architecture

### Marketplace Structure
```
.claude-plugin/
└── marketplace.json          # Marketplace definition and plugin registry

plugins/
├── devops-infrastructure/    # Infrastructure & operations agents
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── agents/               # Agent definitions (5 agents)
│   ├── commands/             # Custom slash commands (1 command)
│   └── .mcp.json             # MCP server integration (4 servers)
│
├── software-engineering/     # General engineering workflows
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── agents/               # Agent definitions (7 agents)
│   ├── commands/             # Custom slash commands (9 commands)
│   └── .mcp.json             # MCP server integration (4 servers)
│
└── go-specialist/            # Go language expertise
    ├── .claude-plugin/
    │   └── plugin.json
    ├── agents/               # Agent definitions (1 agent)
    ├── commands/             # Custom slash commands (10 commands)
    └── .mcp.json             # MCP server integration (4 servers)
```

### Agent Architecture

Agents are defined in **markdown files with YAML frontmatter** in `plugins/*/agents/`. Each agent follows this structure:

**Frontmatter fields:**
- `name`: Agent identifier
- `description`: When to use this agent (shown in Claude Code UI)
- `model`: LLM model to use (sonnet/opus/haiku)
- `allowed-tools`: Optional tool restrictions (standardized field name)
- `capabilities`: Optional list of agent-specific capabilities (for UI display and documentation)
- `color`: UI color for visual identification
- `context`: Optional context sharing description for multi-agent coordination
- `permissionMode`: Optional permission mode (manual/acceptAll)
- `skills`: Optional skill references for specialized workflows

**Content sections:**
1. **Proactive Triggers**: Automatic activation conditions based on file patterns or keywords
2. **Core Capabilities**: Domain expertise and technical knowledge
3. **Implementation Patterns**: Best practices and approach
4. **Deliverables**: Expected outputs and artifacts

### Available Plugins & Agents

#### devops-infrastructure
Infrastructure, deployment, and operations specialists.

| Agent | Purpose | Proactive Activation |
|-------|---------|---------------------|
| `aws-specialist` | AWS cloud architecture, Well-Architected Framework, cost optimization | .tf (AWS), cloudformation, "aws", ARNs |
| `cicd-specialist` | CI/CD pipelines (GitHub Actions, GitLab CI, Forgejo) | .github/workflows, pipeline terms |
| `database-specialist` | Schema design, query optimization, migrations | .sql files, "slow query", "index" |
| `devops-specialist` | Infrastructure as Code (Terraform, Ansible, CloudFormation) | .tf, .yml files, cloud terms |
| `postgresql-specialist` | PostgreSQL 16+ advanced features, query optimization, replication | .sql, migrations, "postgresql", slow query |

#### software-engineering
General development workflows and best practices.

| Agent | Purpose | Proactive Activation |
|-------|---------|---------------------|
| `code-review-enforcer` | Code quality, security, best practices review | After file modifications |
| `debugger` | Root cause analysis, error resolution | Errors, test failures |
| `docs-architect` | Long-form technical documentation generation | Documentation requests (uses Opus model) |
| `html-first-frontend` | HTMX, Alpine.js, Tailwind/Bootstrap | HTML/CSS without frameworks |
| `license-specialist` | Open source license compliance for SaaS | Dependency files, license terms |
| `payment-integrator` | Stripe, PayPal, subscription billing | Payment SDKs, checkout flows |
| `security-auditor` | Security vulnerability detection, OWASP compliance, auth/crypto review | After auth/crypto/API changes |

#### go-specialist
Go language expertise and optimization.

| Agent | Purpose | Proactive Activation |
|-------|---------|---------------------|
| `golang-pro` | Go 1.25+ development, concurrency, performance | .go files, go.mod |

## Development Commands

### Task Runner (Task)
This project uses [Task](https://taskfile.dev) for automation:

```bash
# List all available tasks
task

# Validate plugin structure
task check
```

### Plugin Validation

```bash
# Validate individual plugin
cd plugins/<plugin-name> && claude plugin validate .

# Validate marketplace
claude plugin validate .claude-plugin/marketplace.json
```

### Plugin Installation (End Users)

Add this marketplace to Claude Code:
```bash
/plugin marketplace add sgaunet/claude-plugins
```

Or link locally for development:
```bash
/plugin marketplace add ./path/to/claude-plugins
```

## Working with Agents

### Creating New Agents

1. Choose appropriate plugin:
   - `devops-infrastructure` for infrastructure/operations agents
   - `software-engineering` for general development workflows
   - `go-specialist` for Go-specific expertise
2. Create `plugins/<plugin-name>/agents/<name>.md`
3. Add YAML frontmatter with required fields
4. Structure content with clear sections:
   - Proactive Triggers (for automatic activation)
   - Core Capabilities
   - Implementation patterns or approach
   - Expected deliverables or output format
5. Validate: `cd plugins/<plugin-name> && claude plugin validate .`

### Agent Design Principles

1. **Proactive Activation**: Define clear file patterns and keyword triggers so agents activate automatically
2. **Scoped Expertise**: Each agent should have a focused domain (DevOps, database, payments, etc.)
3. **Actionable Outputs**: Specify concrete deliverables (code, configs, documentation)
4. **Tool Restrictions**: Use `allowed-tools` field to limit capabilities when appropriate
5. **Model Selection**: Use `sonnet` for code/speed, `opus` for complex analysis/documentation, `haiku` for fast/simple tasks
6. **Context Sharing**: Document multi-agent collaboration patterns in `context` field

### Agent Frontmatter Examples

**Basic:**
```yaml
---
name: example-agent
description: What this agent does and when to use it
model: sonnet
---
```

**With tool restrictions:**
```yaml
---
name: review-agent
description: Code review specialist
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
color: purple
---
```

See existing agents in `plugins/*/agents/*.md` for advanced patterns (context sharing, permissionMode, skills).

## Plugin Manifest Schema

- **marketplace.json**: See `.claude-plugin/marketplace.json` for complete schema
- **plugin.json**: See `plugins/*/.claude-plugin/plugin.json` for examples

**Note**: Include keywords and MCP server lists in plugin description field for discoverability.

## File Locations

- **Marketplace metadata**: `.claude-plugin/marketplace.json`
- **Plugin metadata**: `plugins/*/\.claude-plugin/plugin.json`
- **Agent definitions**: `plugins/*/agents/*.md` (13 total agents)
- **Commands**: `plugins/*/commands/*.md` (20 custom commands)
- **MCP config**: `plugins/*/.mcp.json` (4 MCP servers integrated)

## Design Patterns

### Multi-Agent Collaboration
Agents can work together:
- `code-review-enforcer` reviews after `golang-pro` implements features
- `license-specialist` audits dependencies chosen by `devops-specialist`
- `docs-architect` documents architecture designed by `cicd-specialist`

### Proactive vs Reactive
- **Proactive**: Agent activates automatically based on triggers (preferred)
- **Reactive**: User explicitly invokes agent by name

Most agents in this collection are designed for proactive activation to reduce friction.

## 2026 Feature Adoption

This marketplace implements modern Claude Code best practices for enhanced reliability and discoverability:

### Context Sharing
Agents coordinate via the `context` field for multi-agent workflows:
- **code-review-enforcer**: Shares quality standards with other agents
- **debugger**: Shares diagnostic findings with implementing agents
- **golang-pro**: Documents skill invocation patterns

### Enhanced Discoverability
Plugin descriptions include inline keywords and MCP server lists for better search and documentation:
```json
{
  "description": "Infrastructure as Code (Terraform, Ansible), CI/CD pipelines. MCP: github, gitlab-mcp",
  "repository": "https://github.com/..."
}
```

### Standardized Tool Field
Unified `allowed-tools` field across all agents and commands (previously `tools` in some agents). 4 agents updated for consistency.

### MCP Integration
All plugins declare MCP server dependencies:
- **github**: GitHub API integration
- **gitlab-mcp**: GitLab API integration
- **perplexity-ai**: Research and documentation
- **context7**: Library documentation lookup

## Commands vs Skills vs Agents

### Commands
User-invoked workflows in `plugins/*/commands/`:
- `/commit`: Generate git commits with conventional format
- `/create-issue`: Create GitHub/GitLab issues
- `/analyze-pr`: Comprehensive PR review
- `/analyze-db-performance`: PostgreSQL performance analysis

### Skills
Reusable sub-workflows invoked by agents or commands:
- `linter`: Initialize golangci-lint configuration
- `github-workflows`: Setup GitHub Actions CI/CD
- `gitlab-ci`: Configure GitLab pipelines
- `goreleaser`: Setup automated releases

### Agents
Proactive specialists in `plugins/*/agents/` that auto-activate based on context:
- File patterns (.go, .tf, .sql)
- Keywords (payment, authentication, slow query)
- Events (file modifications, test failures)
- User requests (debugging, code review)
