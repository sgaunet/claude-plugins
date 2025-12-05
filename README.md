# Claude Code Plugin Marketplace

A curated collection of specialized Claude Code plugins designed to enhance your development workflow with intelligent agents, skills, and commands.

Official claude code marketplace: [https://github.com/anthropics/claude-code](https://github.com/anthropics/claude-code)

## Overview

This marketplace provides three comprehensive plugin collections:

- **devops-infrastructure**: Infrastructure as Code (IaC), CI/CD pipeline specialists, and database optimization experts for DevOps workflows
- **software-engineering**: Code review, debugging, documentation, license compliance, payment integration, and HTML-first frontend development tools
- **go-specialist**: Advanced Go 1.25+ development with modern patterns, concurrency optimization, and production-ready tooling (linting, GitHub workflows, GitLab CI, GoReleaser)

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

## MCP Server Requirements

These plugins leverage **Model Context Protocol (MCP) servers** to provide powerful integrations with external services. You must install and configure these MCP servers before using the plugins.

### Required MCP Servers

All three plugins depend on the following MCP servers:

#### 1. **perplexity-ai** - AI-Powered Research

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
export PERPLEXITY_API_KEY="your-perplexity-api-key"
```

**Environment Variables**:
- `PPLX_API_KEY` - Your Perplexity AI API key (get from [perplexity.ai](https://www.perplexity.ai/settings/api))

---

#### 2. **gitlab-mcp** - GitLab Integration

**Repository**: [sgaunet/gitlab-mcp](https://github.com/sgaunet/gitlab-mcp)

Enables GitLab operations including issues, merge requests, projects, and CI/CD pipelines.

**Installation**:
```bash
# Install from source
git clone https://github.com/sgaunet/gitlab-mcp.git
cd gitlab-mcp
go install

# Or download pre-built binary from releases
```

**Configuration**:
```bash
# Add to Claude Code MCP configuration
claude mcp add gitlab-mcp -- gitlab-mcp

# Set environment variables
export GITLAB_TOKEN="your-gitlab-token"
# export GITLAB_API_URL="https://gitlab.com/api/v4"  # If self-hosted GitLab URL
```

**Environment Variables**:
- `GITLAB_TOKEN` - GitLab Personal Access Token with `api` scope
- `GITLAB_API_URL` - GitLab API endpoint (default: `https://gitlab.com/api/v4`)

**Generate GitLab Token**:
1. Go to GitLab Settings → Access Tokens
2. Create token with `api` scope
3. Copy and set as environment variable

---

#### 3. **github** - GitHub Copilot Integration

**Official GitHub Integration** via GitHub Copilot MCP server (HTTP transport).

**Configuration**:
```bash
# Set environment variable
export GITHUB_TOKEN="your-github-personal-access-token"
```

**Environment Variables**:
- `GITHUB_TOKEN` - GitHub Personal Access Token with appropriate scopes

**Generate GitHub Token**:
1. Go to GitHub Settings → Developer Settings → Personal Access Tokens → Tokens (classic)
2. Create token with scopes: `repo`, `read:org`, `workflow`
3. Copy and set as environment variable

---

#### 4. **task-master-ai** - Task Management & Validation

**NPM Package**: [task-master-ai](https://www.npmjs.com/package/task-master-ai)

Provides task management, validation, and TDD methodology compliance checking.

**Configuration**:
The plugins include this configuration automatically. It will be installed via `npx` on first use.

**No additional setup required** - runs via `npx -y task-master-ai`

---

### Environment Variable Setup

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`, or `~/.profile`):

```bash
# Perplexity AI
export PPLX_API_KEY="pplx-xxxxxxxxxxxxxxxxxxxx"

# GitLab
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
export GITLAB_API_URL="https://gitlab.com/api/v4"

# GitHub
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
```

Reload your shell:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Verifying MCP Server Installation

Test that each MCP server is installed and configured correctly:

```bash
# Test perplexity-ai
pplx --version

# Test gitlab-mcp
gitlab-mcp --version

# Test GitHub token
curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user

# Test task-master-ai (will auto-install via npx)
npx -y task-master-ai --help
```

### MCP Server Features by Plugin

| Plugin | task-master-ai | github | gitlab-mcp | perplexity-ai |
|--------|---------------|--------|------------|---------------|
| **devops-infrastructure** | ✅ Task validation | ✅ CI/CD workflows | ✅ Pipeline management | ✅ Research & docs |
| **software-engineering** | ✅ Task tracking | ✅ PR/Issue management | ✅ MR/Issue management | ✅ Library research |
| **go-specialist** | ✅ TDD validation | ✅ Go workflows | ✅ Go CI/CD | ✅ Go library docs |

---

## Plugin Details

### devops-infrastructure (v0.2.0)

**Agents**:
- `cicd-specialist` - GitHub Actions, GitLab CI, Forgejo Actions expert
- `database-specialist` - PostgreSQL, MySQL optimization and schema design
- `devops-specialist` - Terraform, Ansible, CloudFormation, cloud automation

**Commands**: None yet

**Skills**: None yet

**Use Cases**:
- Infrastructure as Code (Terraform, Ansible)
- CI/CD pipeline creation and debugging
- Database performance optimization

---

### software-engineering (v0.8.0)

**Agents**:
- `code-review-enforcer` - Code quality, security, best practices
- `debugger` - Error analysis and root cause investigation
- `docs-architect` - Long-form technical documentation (uses Opus model)
- `html-first-frontend` - HTMX, Alpine.js, Tailwind development
- `license-specialist` - Open source license compliance for SaaS
- `payment-integrator` - Stripe, PayPal, subscription billing
- `security-auditor` - Security vulnerability detection
- `task-checker` - Task validation and QA

**Commands**:
- `/analyze-and-create-issue` - Analyze codebase issues and create GitHub/GitLab issues
- `/audit-codebase` - Security and performance audit
- `/commit` - Generate conventional commit messages
- `/create-issue` - Create GitHub or GitLab issue
- `/create-prd` - Create Product Requirement Document
- `/refine-prd` - Review and improve existing PRD
- `/upd-project-description` - Update GitHub/GitLab project metadata

**Skills**:
- `prd` - Product requirement document templates

**Use Cases**:
- Automated code review and security scanning
- Technical documentation generation
- License compliance checking
- Payment integration implementation

---

### go-specialist (v0.7.0)

**Agents**:
- `golang-pro` - Go 1.25+ expert with generics, concurrency, performance optimization

**Commands**:
- `/verify-task` - Verify Go task implementation quality with TDD validation

**Skills**:
- `linter` - golangci-lint configuration
- `github-workflows` - GitHub Actions workflows for Go
- `gitlab-ci` - GitLab CI/CD pipelines for Go
- `goreleaser` - GoReleaser configuration for releases

**Use Cases**:
- Go project scaffolding with best practices
- CI/CD pipeline generation (GitHub Actions or GitLab CI)
- Automated releases with GoReleaser
- Code quality enforcement with golangci-lint

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
├── plugins/
│   ├── devops-infrastructure/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json      # Plugin metadata
│   │   ├── agents/               # Agent definitions (*.md)
│   │   ├── commands/             # Slash commands (*.md)
│   │   ├── hooks.json            # Event hooks
│   │   └── mcp.json              # MCP server config
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
  - [sgaunet/gitlab-mcp](https://github.com/sgaunet/gitlab-mcp) - GitLab MCP server
  - [task-master-ai](https://www.npmjs.com/package/task-master-ai) - Task management MCP server

- **Documentation**:
  - [Claude Code Docs](https://docs.claude.ai/claude-code)
  - [MCP Protocol](https://modelcontextprotocol.io/)
  - [Plugin Development Guide](https://docs.claude.ai/claude-code/plugins)

- **Tools**:
  - [Task](https://taskfile.dev)
  - [semver](https://github.com/ffurrer2/semver)