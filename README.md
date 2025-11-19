# Claude Code Plugin Marketplace

A curated collection of specialized Claude Code plugins designed to enhance your development workflow with intelligent agents, skills, and commands.

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

