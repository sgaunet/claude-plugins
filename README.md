# Claude Code Plugin Marketplace

[![Plugins](https://img.shields.io/badge/plugins-4-blue)](./plugins)
[![Agents](https://img.shields.io/badge/agents-15-green)](./plugins)
[![Commands](https://img.shields.io/badge/commands-21-orange)](./plugins)
[![License](https://img.shields.io/badge/license-MIT-purple)](./LICENSE)

A curated collection of specialized Claude Code plugins designed to enhance your development workflow with intelligent agents, skills, and commands.

Official claude code marketplace: [https://github.com/anthropics/claude-code](https://github.com/anthropics/claude-code)

## Overview

This marketplace provides three comprehensive plugin collections:

- **devops-infrastructure**: Infrastructure as Code (IaC), CI/CD pipeline specialists, and database optimization experts for DevOps workflows
- **software-engineering**: Code review, debugging, documentation, license compliance, payment integration, and HTML-first frontend development tools
- **go-specialist**: Advanced Go 1.25+ development with modern patterns, concurrency optimization, and production-ready tooling (linting, GitHub workflows, GitLab CI, Forgejo Actions, GoReleaser)

Each plugin includes proactive agents that automatically assist with their specialized domains, plus skills and commands to streamline common development tasks.

## Adding this Marketplace

```bash
/plugin marketplace add sgaunet/claude-plugins
```

For local development, you can also link a local folder:

```bash
git clone git@github.com:sgaunet/claude-plugins.git
claude
```

within claude:

```
/plugin marketplace add ./claude-plugins
```

## Listing

```bash
/plugin
```

## Prerequisites

### CLI Tools

These plugins use `gh`, `glab`, and `fgj` CLIs for GitHub/GitLab/Forgejo operations:

- **[gh](https://cli.github.com/)** — GitHub CLI (for GitHub repositories)
- **[glab](https://gitlab.com/gitlab-org/cli)** — GitLab CLI (for GitLab repositories)
- **[fgj](https://codeberg.org/forgejo-contrib/forgejo-cli)** — Forgejo CLI 

Authenticate after installation:
```bash
gh auth login
glab auth login
fgj auth login
```

Platform-aware commands detect the repository host from the git remote and route to the matching CLI (`git.sylvlab.fr` → `fgj`).

### MCP Server (Optional)

#### perplexity-ai — AI-Powered Research

**Repository**: [sgaunet/pplx](https://github.com/sgaunet/pplx)

Provides AI-powered web search and question-answering capabilities through Perplexity AI.

**Installation**:
```bash
# Install from source
git clone https://github.com/sgaunet/pplx.git
cd pplx
go install

# Or download pre-built binary from releases
```

**Configuration**:
```bash
# Add to Claude Code MCP configuration
claude mcp add perplexity-ai -- pplx mcp-stdio

# Set environment variable
export PPLX_API_KEY="your-perplexity-api-key"
```

**Environment Variables**:
- `PPLX_API_KEY` - Your Perplexity AI API key (get from [perplexity.ai](https://www.perplexity.ai/settings/api))

---

## Plugin Details

### devops-infrastructure

**Agents**:
- `aws-specialist` - AWS cloud architecture, Well-Architected Framework, cost optimization
- `cicd-specialist` - GitHub Actions, GitLab CI, Forgejo Actions (via `fgj`) expert
- `database-specialist` - PostgreSQL, MySQL optimization and schema design
- `devops-specialist` - Terraform, Ansible, CloudFormation, cloud automation
- `postgresql-specialist` - PostgreSQL 16+ advanced features, query optimization, replication

**Commands**:
- `/analyze-db-performance` - PostgreSQL performance analysis with query and index insights

**Skills**: None yet

**Use Cases**:
- Infrastructure as Code (Terraform, Ansible)
- CI/CD pipeline creation and debugging
- Database performance optimization

---

### software-engineering

**Agents**:
- `code-review-enforcer` - Code quality, security, best practices
- `debugger` - Error analysis and root cause investigation
- `diagram-architect` - Software and infrastructure architecture diagrams via d2
- `docs-architect` - Long-form technical documentation (uses Opus model)
- `html-first-frontend` - HTMX, Alpine.js, Bootstrap development
- `license-specialist` - Open source license compliance for SaaS
- `payment-integrator` - Stripe, PayPal, subscription billing
- `security-auditor` - Security vulnerability detection

**Commands**:
- `/analyze-and-create-issue` - Analyze codebase issues and create GitHub/GitLab/Forgejo issues
- `/analyze-pr` - Comprehensive PR/MR review for quality, security, and coverage (GitHub/GitLab/Forgejo)
- `/audit-codebase` - Security and performance audit
- `/check-claude-md-tokens` - Monitor and optimize CLAUDE.md token count
- `/commit` - Generate conventional commit messages
- `/create-issue` - Create GitHub, GitLab, or Forgejo issue
- `/feature-flow` - Complete git workflow orchestration (branch, issue, commit)
- `/feature-flow-w` - Same workflow, isolated in a git worktree
- `/gen-claude` - Generate or enhance CLAUDE.md with project guidance
- `/gen-diagram` - Generate a d2 architecture diagram with icons.terrastruct.com
- `/gen-readme-diagram` - Add or update a README Architecture section with Mermaid diagrams
- `/gen-vhs-demo` - Record a verified CLI demo GIF with VHS and embed it in the README
- `/upd-project-description` - Update GitHub/GitLab/Forgejo project metadata

**Skills**:
- `auto-mr` - Push, open MR/PR, wait for CI, merge, and clean up the branch
- `detect-repo-host` - Detect GitHub/GitLab/Forgejo from the git remote
- `run-lint` - Auto-detect and run the project linter
- `run-tests` - Auto-detect and run the project test runner

Platform-aware commands detect the host from the git remote and route to `gh` (GitHub), `glab` (GitLab), or `fgj` (Forgejo, `git.sylvlab.fr`).

**Use Cases**:
- Automated code review and security scanning
- Technical documentation generation
- License compliance checking
- Payment integration implementation

---

### go-specialist

**Agents**:
- `golang-pro` - Go 1.25+ expert with generics, concurrency, performance optimization

**Commands**:
- `/gen-github-dir` - Generate complete .github directory with workflows and configs
- `/gen-gitlab-ci` - Generate GitLab CI/CD pipeline for Go projects
- `/gen-forgejo-dir` - Generate complete .forgejo/workflows directory with Forgejo Actions for Go projects
- `/gen-goreleaser` - Generate GoReleaser configuration with multi-arch builds
- `/gen-linter` - Generate .golangci.yml with 90+ linters
- `/gen-taskfiles` - Generate Taskfile.yml and .pre-commit-config.yaml
- `/go-tdd` - Implement a Go feature with TDD using up-to-date library docs

**Skills**:
- `go-blackbox` - Detect white box tests and convert to black box (`package foo_test`)
- `go-bulma` - Scaffold Bulma CSS into a Go web app with embedded assets
- `go-structure` - Recommend and scaffold Go project layouts by project type
- `go-tool` - Manage Go tool dependencies via the `tool` directive (Go 1.24+)

**Use Cases**:
- Go project scaffolding with best practices
- CI/CD pipeline generation (GitHub Actions, GitLab CI, or Forgejo Actions)
- Automated releases with GoReleaser
- Code quality enforcement with golangci-lint

---

### bash-specialist

**Agents**:
- `bash-pro` - Production-quality bash, shellcheck compliance, gum-based terminal UX

**Commands**: None

**Skills**:
- `gum-beautify` - Integrate Charmbracelet gum for TTY-safe terminal output

**Use Cases**:
- Shell script authoring and hardening
- Interactive CLI tooling with a polished terminal UX

---

## Extras

The `extras/` directory contains standalone utilities for Claude Code that are **not plugins** — they are helper scripts you install independently.

### statusline

A lightweight bash statusline for Claude Code that displays the active model, context window usage with a color-coded progress bar, and total context size.

```
[Opus] ▓▓▓░░░░░░░ 30% | 200k ctx
```

**Install**: `./extras/statusline/configure-statusline.sh`
**Details**: [extras/statusline/install-statusline.md](extras/statusline/install-statusline.md)

### no-leak

A `PreToolUse` hook that prevents Claude Code from reading or modifying sensitive files (`.env`, credentials, private keys, vault files). Unlike CLAUDE.md instructions, hooks are **deterministic** — the LLM cannot bypass them.

**Install**: `./extras/no-leak/configure-no-leak.sh`
**Details**: [extras/no-leak/install-no-leak.md](extras/no-leak/install-no-leak.md)

---

## Development

### Prerequisites

- [Task](https://taskfile.dev) - Task runner (optional but recommended)
- [semver](https://github.com/ffurrer2/semver) - Semantic version tool

### Local Development

```bash
# Clone repository
git clone https://github.com/sgaunet/claude-plugins.git
cd claude-plugins

# List available tasks
task

# Validate plugin structure
task check

# Or validate individually
cd plugins/devops-infrastructure && claude plugin validate .
cd plugins/software-engineering && claude plugin validate .
cd plugins/go-specialist && claude plugin validate .
```

### Project Structure

```
.
├── .claude-plugin/
│   └── marketplace.json          # Marketplace definition
├── extras/
│   ├── statusline/              # Custom statusline script
│   └── no-leak/                 # Sensitive file protection hook
├── plugins/
│   ├── devops-infrastructure/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json      # Plugin metadata
│   │   ├── agents/               # Agent definitions (*.md)
│   │   ├── commands/             # Slash commands (*.md)
│   │   ├── hooks.json            # Event hooks
│   │   └── .mcp.json             # MCP server config
│   ├── software-engineering/
│   │   └── [same structure]
│   └── go-specialist/
│       └── [same structure]
└── README.md
```

### Creating New Agents

1. Choose appropriate plugin directory
2. Create `plugins/<plugin>/agents/<name>.md`
3. Add YAML frontmatter with `name`, `description`, `model`, `color`
4. Define proactive triggers (file patterns, keywords)
5. Document capabilities and deliverables
6. Validate: `claude plugin validate .`

## Links

- **MCP Servers**:
  - [sgaunet/pplx](https://github.com/sgaunet/pplx) - Perplexity AI MCP server

- **Documentation**:
  - [Claude Code Docs](https://docs.claude.ai/claude-code)
  - [MCP Protocol](https://modelcontextprotocol.io/)
  - [Plugin Development Guide](https://docs.claude.ai/claude-code/plugins)

- **Tools**:
  - [Task](https://taskfile.dev)
  - [semver](https://github.com/ffurrer2/semver)