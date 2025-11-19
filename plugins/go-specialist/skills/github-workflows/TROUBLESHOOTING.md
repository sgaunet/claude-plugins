# GitHub Workflows Troubleshooting

Common issues and solutions when setting up GitHub Actions workflows for Go projects.

## Permission Issues

### Issue: "Permission denied" pushing Docker images

**Symptoms**:
- Release workflow fails when pushing Docker images to GHCR
- Error message contains "permission denied" or "unauthorized"

**Solution**: Enable GHCR and set correct permissions

```yaml
# Ensure workflow has packages permission
permissions:
  contents: write
  packages: write  # Required for GHCR

# Verify registry authentication
- name: Login to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

**Also check**:
- Settings → Actions → General → Workflow permissions
- Set to "Read and write permissions"
- Enable "Allow GitHub Actions to create and approve pull requests"

### Issue: Coverage badge not updating

**Symptoms**:
- Coverage workflow runs successfully
- Badge file not committed to repository
- Badge shows outdated coverage

**Solution**: Ensure workflow has write permissions

```yaml
permissions:
  contents: write  # Required to commit badge

# Also check branch protection doesn't block badge commits
# Settings → Branches → Edit protection rule
# Enable "Allow force pushes" for the coverage workflow
```

**Alternative**: Use orphan badge branch
```yaml
- name: Generate coverage badge
  with:
    badge-filename: coverage-badge.svg
    badge-branch: badges  # Store badges in separate branch
```

## Tool Installation Issues

### Issue: "task: command not found"

**Symptoms**:
- Workflow fails with "task: command not found"
- Steps after Task installation fail

**Solution**: Workflow installs Task automatically, but verify:

```yaml
- name: Install task
  uses: jaxxstorm/action-install-gh-release@v2.1.0
  with:
    repo: go-task/task
    cache: enable  # Cache for faster subsequent runs
```

**Manual installation alternative**:
```yaml
- name: Install Task
  run: |
    sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
```

**Verify Task is in PATH**:
```yaml
- name: Verify Task installation
  run: |
    which task
    task --version
```

## Linting Issues

### Issue: Linter fails with "no Go files"

**Symptoms**:
- Linter workflow fails
- Error: "no Go files to analyze"
- Works locally but fails in CI

**Solution**: Ensure `.golangci.yml` is properly configured

```yaml
# .golangci.yml
run:
  skip-dirs:
    - vendor
    - third_party
  timeout: 5m

linters:
  enable:
    - gofmt
    - govet
    - errcheck
    - staticcheck
    - unused
```

**Check**:
- Verify `.golangci.yml` is committed to repository
- Ensure Go files exist in analyzed directories
- Check `go.mod` is present in repository root

### Issue: Linter timeout

**Symptoms**:
- Linter workflow times out
- Large codebase takes too long

**Solution**: Increase timeout and enable caching

```yaml
# In .golangci.yml
run:
  timeout: 10m  # Increase from default 1m

# In workflow
- name: golangci-lint
  uses: golangci/golangci-lint-action@v4
  with:
    args: --timeout=10m
    skip-cache: false  # Enable caching
```

## GoReleaser Issues

### Issue: Snapshot builds fail but local works

**Symptoms**:
- `goreleaser release --snapshot` fails in CI
- Works on local machine
- Docker-related errors

**Solution**: Check GoReleaser config for CI-specific issues

```yaml
# .goreleaser.yml
builds:
  - env:
      - CGO_ENABLED=0  # Ensure static builds for Docker
    goos:
      - linux
      - darwin
      - windows
    goarch:
      - amd64
      - arm64

# Verify Docker login happens before GoReleaser runs
```

**Common causes**:
- Missing environment variables
- Docker not configured for multi-platform builds
- GHCR authentication missing

### Issue: Release workflow triggers on unwanted tags

**Symptoms**:
- Release workflow runs on test tags
- Unwanted releases created
- CI runs on every tag push

**Solution**: Filter tags in workflow trigger

```yaml
on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'  # Only semantic versions (v1.2.3)
      # NOT:
      # - '**'  # All tags (too broad)
      # - 'v*'  # Any tag starting with v (includes v0.1.0-test)
```

**Use regex for precise matching**:
```yaml
tags:
  - 'v[0-9]+\.[0-9]+\.[0-9]+$'  # v1.0.0 only
  - 'v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$'  # Include release candidates
```

### Issue: GoReleaser can't push to Homebrew

**Symptoms**:
- Release succeeds but Homebrew formula not updated
- Error: "permission denied" for tap repository

**Solution**: Configure Homebrew token

1. Create personal access token with `repo` scope
2. Add to repository secrets as `HOMEBREW_TAP_TOKEN`
3. Update `.goreleaser.yml`:

```yaml
brews:
  - repository:
      owner: your-username
      name: homebrew-tap
      token: "{{ .Env.HOMEBREW_TAP_TOKEN }}"
```

4. Update workflow:
```yaml
- name: Create release
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    HOMEBREW_TAP_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}
```

## Coverage Issues

### Issue: Coverage badge shows 0%

**Symptoms**:
- Tests run successfully
- Coverage badge shows 0% or N/A
- `profile.cov` is empty

**Solution**: Verify coverage commands

```yaml
- name: Run tests with coverage
  run: |
    go test -v -coverprofile=profile.cov -covermode=atomic ./...
    # Check profile exists and has content
    cat profile.cov
```

**Common causes**:
- No tests in repository
- Tests in different directory than specified
- Coverage profile not generated before badge creation

### Issue: Coverage excludes important packages

**Symptoms**:
- Some packages not included in coverage
- Coverage seems artificially high

**Solution**: Adjust coverage scope

```yaml
# Include all packages
- name: coverage
  run: |
    go test -coverpkg=./... -coverprofile=profile.cov ./...

# Or include specific packages
- name: coverage
  run: |
    go test -coverpkg=./pkg/...,./internal/... -coverprofile=profile.cov ./...
```

## Workflow Execution Issues

### Issue: Workflows not triggering

**Symptoms**:
- Push to main but workflows don't run
- No workflow runs appear in Actions tab

**Possible causes and solutions**:

1. **Workflows disabled**:
   - Settings → Actions → General
   - Enable "Allow all actions and reusable workflows"

2. **Invalid YAML syntax**:
   - Check workflow files for syntax errors
   - Use YAML validator or GitHub's workflow editor

3. **Branch name mismatch**:
```yaml
# Workflow configured for 'main'
on:
  push:
    branches: [main]

# But repository uses 'master'
# Solution: Update workflow or rename branch
```

4. **Path filters excluding changes**:
```yaml
# If workflow has paths filter:
on:
  push:
    paths:
      - '**.go'
      - 'go.mod'
# Changes to other files won't trigger workflow
```

### Issue: Workflow runs but jobs skip

**Symptoms**:
- Workflow triggered but all jobs skip
- Status: "Skipped" with no logs

**Solution**: Check job conditions

```yaml
jobs:
  build:
    # This condition might skip the job
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
```

## Dependency Issues

### Issue: Dependabot PRs failing checks

**Symptoms**:
- Dependabot creates PRs
- All CI checks fail on Dependabot PRs
- Error: "Resource not accessible by integration"

**Solution**: Grant Dependabot access to Actions

```yaml
# .github/workflows/dependabot.yml
name: Dependabot auto-merge
on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  auto-merge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
      - uses: fastify/github-action-merge-dependabot@v3
```

### Issue: Dependabot not creating PRs

**Symptoms**:
- Dependabot configured but no PRs created
- Dependencies outdated

**Check**:
1. Verify `.github/dependabot.yml` syntax
2. Check Dependabot is enabled: Settings → Code security → Dependabot
3. Review Dependabot logs: Insights → Dependency graph → Dependabot

**Common issues**:
```yaml
# Incorrect directory (needs leading slash)
directory: "/"  # Correct
directory: ""   # Incorrect

# Invalid interval
schedule:
  interval: daily  # Correct: daily, weekly, monthly
  interval: hourly  # Incorrect: not supported
```

## Docker Issues

### Issue: Multi-platform builds failing

**Symptoms**:
- Release fails during Docker build
- Error: "platform not supported"

**Solution**: Ensure QEMU and buildx are set up

```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  with:
    platforms: linux/amd64,linux/arm64
```

**Also check .goreleaser.yml**:
```yaml
dockers:
  - image_templates:
      - "ghcr.io/{{ .Env.GITHUB_REPOSITORY }}:{{ .Tag }}-amd64"
      - "ghcr.io/{{ .Env.GITHUB_REPOSITORY }}:{{ .Tag }}-arm64"
    use: buildx
    build_flag_templates:
      - "--platform=linux/amd64"  # or linux/arm64
```

## Getting Help

If you encounter issues not covered here:

1. Check workflow logs: Actions → Select workflow run → View logs
2. Enable debug logging:
   - Settings → Secrets → Actions
   - Add `ACTIONS_RUNNER_DEBUG` = `true`
   - Add `ACTIONS_STEP_DEBUG` = `true`

3. Validate configurations:
   - Use `task --list` locally to verify Taskfile
   - Run `goreleaser check` to validate .goreleaser.yml
   - Test locally: `act` (https://github.com/nektos/act)

4. Review GitHub Actions documentation:
   - https://docs.github.com/en/actions/troubleshooting
