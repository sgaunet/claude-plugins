# GitHub Workflows Reference

Detailed configuration and customization guide for GitHub Actions workflows in Go projects.

## Workflow Files Reference

All workflow templates are available in the `assets/workflows/` directory:
- `linter.yml` - Code quality checks with golangci-lint
- `snapshot.yml` - Test release builds
- `coverage.yml` - Coverage badge generation
- `release.yml` - Production releases with GoReleaser

## Detailed Workflow Configurations

### 1. Linter Workflow

**Purpose**: Enforce code quality standards on every push.

**What it does**:
- Checks out code
- Sets up Go environment
- Installs Task and golangci-lint
- Runs linting via `task linter`

**Customization**:
```yaml
# Use specific golangci-lint version
- name: Install golangci-lint
  with:
    repo: golangci/golangci-lint
    tag: v2.2.2  # Pin to specific version

# Or use latest
    tag: latest
```

**Requirements**:
- `.golangci.yml` or `.golangci.yaml` in repository root
- Task defined: `linter`

### 2. Snapshot Workflow

**Purpose**: Test release builds on every push without publishing.

**Benefits**:
- Catches GoReleaser config errors early
- Validates Docker builds
- Tests cross-compilation
- Prevents broken releases

**Customization**:
```yaml
# Cache dependencies for faster builds
- name: Install task
  with:
    cache: true  # Enable caching

# Skip Docker builds in snapshot
# Edit Taskfile.yml:
snapshot:
  cmds:
    - goreleaser release --snapshot --clean --skip=publish,docker
```

### 3. Coverage Workflow

**Purpose**: Generate and display test coverage badges.

**What it does**:
- Runs tests with coverage profiling
- Excludes `cmd` package from coverage (mains typically aren't tested)
- Generates SVG badge
- Commits badge to repository

**Customization**:
```yaml
# Include cmd in coverage
- name: coverage
  run: |
    go test -coverpkg=./... -coverprofile=profile.cov ./...
    # sed -i '/cmd/d' profile.cov    # REMOVE THIS LINE

# Change coverage threshold
- name: Generate coverage badge
  with:
    limit-coverage: "80"  # Set threshold (badge color changes)

# Test different packages
- name: coverage
  run: |
    go test -coverpkg=./pkg/... -coverprofile=profile.cov ./pkg/...
```

**Badge Colors**:
- Green: Coverage ≥ threshold
- Yellow: Coverage < threshold
- Red: Coverage significantly below threshold

### 4. Release Workflow

**Purpose**: Create production releases on tag push.

**What it does**:
- Triggers on any Git tag push
- Sets up Go, Task, and GoReleaser
- Configures multi-platform Docker builds (QEMU + Buildx)
- Authenticates with GitHub Container Registry
- Runs `task release` (which calls GoReleaser)
- Publishes:
  - GitHub Release with binaries
  - Docker images to GHCR
  - Homebrew formula (if configured)

**Customization**:
```yaml
# Release only on semantic version tags
on:
  push:
    tags:
      - 'v*.*.*'  # Only v1.0.0, v2.1.3, etc.

# Use GoReleaser Pro
- name: Create release
  env:
    GORELEASER_KEY: ${{ secrets.GORELEASER_KEY }}

# Use specific Go version
- name: Install Go
  with:
    go-version: '1.24.1'  # Pin exact version
```

**Permissions**:
- `contents: write`: Create GitHub releases
- `packages: write`: Push Docker images to GHCR

## Dependabot Configuration

**What it monitors**:
1. **Go modules** (`go.mod`): Go dependencies
2. **Docker**: Base images in Dockerfiles
3. **GitHub Actions**: Workflow action versions

**Configuration**:
```yaml
version: 2
updates:
  - package-ecosystem: gomod
    directory: "/"
    schedule:
      interval: monthly  # Options: daily, weekly, monthly
    open-pull-requests-limit: 10  # Max concurrent PRs

  - package-ecosystem: docker
    directory: "/"  # Searches all Dockerfiles
    schedule:
      interval: monthly

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: monthly
```

**Advanced Customization**:
```yaml
# Update more frequently
schedule:
  interval: weekly

# Group related updates
groups:
  go-dependencies:
    patterns:
      - "golang.org/x/*"

# Ignore specific updates
ignore:
  - dependency-name: "github.com/some/package"
    versions: ["2.x"]
```

## Task Runner Integration

All workflows use [Task](https://taskfile.dev) for consistent build commands.

### Why Task?

1. **Consistency**: Same commands work locally and in CI
2. **Flexibility**: Easy to customize build process
3. **Dependencies**: Task handles task dependencies
4. **Cross-platform**: Works on all OS

### Example Taskfile.yml

```yaml
version: '3'

vars:
  BINARY_NAME: myapp

tasks:
  # Development tasks
  dev:
    desc: Run in development mode
    cmds:
      - go run ./cmd

  # CI tasks (used by workflows)
  linter:
    desc: Run golangci-lint
    cmds:
      - golangci-lint run --timeout=5m ./...

  test:
    desc: Run all tests
    cmds:
      - go test -v -race -coverprofile=coverage.out ./...

  test:cover:
    desc: Show coverage report
    deps: [test]
    cmds:
      - go tool cover -html=coverage.out

  snapshot:
    desc: Create snapshot build
    cmds:
      - goreleaser release --snapshot --clean --skip=publish

  release:
    desc: Create production release
    cmds:
      - goreleaser release --clean

  # Build tasks
  build:
    desc: Build binary
    cmds:
      - go build -o {{.BINARY_NAME}} ./cmd

  install:
    desc: Install binary
    cmds:
      - go install ./cmd
```

## Best Practices

### 1. Branch Protection

Require CI checks before merging:
- Settings → Branches → Add rule
- Require status checks:
  - `linter`
  - `goreleaser-snapshot`
- Require branches to be up to date

### 2. Workflow Optimization

**Caching**: Speed up workflows
```yaml
- name: Install task
  uses: jaxxstorm/action-install-gh-release@v2.1.0
  with:
    repo: go-task/task
    cache: enable  # Cache downloaded binaries
```

**Conditional execution**: Skip unnecessary runs
```yaml
# Skip workflows on documentation changes
on:
  push:
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

**Concurrency control**: Cancel outdated runs
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 3. Security

**Least privilege**: Minimal permissions
```yaml
permissions:
  contents: read  # Default to read-only
  # Add write only when needed
```

**Dependabot auto-merge**: For patch updates only
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: gomod
    directory: "/"
    schedule:
      interval: weekly
```

### 4. Monitoring

**Failure notifications**: Get alerted on failures
- Settings → Notifications → Actions → Email notifications

**Status badges**: Show CI health in README
```markdown
[![CI](https://github.com/OWNER/REPO/actions/workflows/linter.yml/badge.svg)](https://github.com/OWNER/REPO/actions)
```

### 5. Documentation

Document workflows in README.md:
```markdown
## Development

### Prerequisites
- Go 1.24+
- Task: `brew install go-task/tap/go-task`

### Running Tests
```bash
task test
```

### Running Linter
```bash
task linter
```

### Creating Releases
Tag and push:
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```
\```
```

## Integration Examples

### With Pull Requests

Automatically run checks on PRs:
```yaml
# Add to linter.yml and snapshot.yml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

### With Slack Notifications

Notify team of releases:
```yaml
# Add to release.yml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "New release: ${{ github.ref_name }}"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### With Security Scanning

Add vulnerability scanning:
```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: securego/gosec@master
        with:
          args: './...'
```

### With Code Review Automation

Auto-assign reviewers on dependency updates:
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: gomod
    reviewers:
      - "team-leads"
    labels:
      - "dependencies"
```

## Additional Resources

- **GitHub Actions**: https://docs.github.com/en/actions
- **Task Runner**: https://taskfile.dev
- **golangci-lint**: https://golangci-lint.run
- **GoReleaser**: https://goreleaser.com
- **Dependabot**: https://docs.github.com/en/code-security/dependabot
- **GHCR**: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
