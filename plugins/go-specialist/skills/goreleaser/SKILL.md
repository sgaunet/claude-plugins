---
name: goreleaser
description: Initialize or update GoReleaser configuration for automated Go releases with multi-architecture Docker builds, binary distribution, and Homebrew publishing
---

# GoReleaser Setup Skill

Automate Go project releases with cross-platform binaries, multi-architecture Docker images, and package distribution.

## Overview

GoReleaser is a release automation tool for Go projects that handles:
- Building binaries for multiple OS/architectures
- Creating multi-architecture Docker images and manifests
- Publishing to GitHub/GitLab releases
- Generating Homebrew formulas
- Creating automated changelogs
- Calculating checksums and signatures

This skill provides templates and guidance for setting up professional release automation.

## Prerequisites

Before using this skill, ensure:

1. **GoReleaser installed**: `brew install goreleaser` or see https://goreleaser.com/install/
2. **Docker with buildx**: For multi-architecture builds (`docker buildx version`)
3. **Git tags**: GoReleaser works with semantic versioning tags (e.g., `v1.0.0`)
4. **GitHub/GitLab token**: For release creation and Homebrew tap updates
5. **Project structure**: Go module with `cmd/` directory (or adjust `dir` field)

## Instructions

### Step 1: Analyze Project Structure

First, understand the target project:
```bash
# Check for existing .goreleaser.yml
ls -la .goreleaser.yml .goreleaser.yaml

# Identify build entry point
find . -name "main.go" -type f

# Verify Go module
cat go.mod
```

### Step 2: Copy Template Files

Copy the template files from this skill's assets:
- `.goreleaser.yml` → Project root
- `Dockerfile` → Project root
- `resources/etc/passwd` → Project root (if using scratch Docker images)

### Step 3: Customize Configuration

Update `.goreleaser.yml` with project-specific values:

1. **Project name**: Replace `PROJECT_NAME` with actual project name
2. **Build configuration**:
   - Set `dir` if main.go is not in `cmd/`
   - Adjust `ldflags` for version injection
   - Configure target OS/architectures
3. **Docker registry**: Update image templates with correct registry URL
   - GitHub: `ghcr.io/OWNER/PROJECT`
   - GitLab: `registry.gitlab.com/OWNER/PROJECT`
   - Docker Hub: `docker.io/OWNER/PROJECT`
4. **Homebrew tap** (optional): Configure repository and token
5. **Extra files**: Ensure `resources` directory matches your needs

### Step 4: Update Dockerfile

Customize the Dockerfile:
1. Replace `PROJECT_BINARY` with actual binary name
2. Adjust user name in both Dockerfile and `resources/etc/passwd`
3. Add any additional runtime dependencies
4. Configure volumes and working directory

### Step 5: Set Up CI/CD Integration

Add environment variables to CI/CD:
```bash
# GitHub Actions
GITHUB_TOKEN          # Automatic in GitHub Actions
HOMEBREW_TAP_TOKEN    # If publishing to Homebrew

# GitLab CI
GITLAB_TOKEN          # Automatic in GitLab CI
HOMEBREW_TAP_TOKEN    # If publishing to Homebrew
```

### Step 6: Test Configuration

Validate before tagging:
```bash
# Check configuration
goreleaser check

# Create snapshot build (no release)
goreleaser build --snapshot --clean

# Test full release process
goreleaser release --snapshot --clean --skip=publish
```

### Step 7: Create Release

When ready:
```bash
# Create and push tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# Run GoReleaser (usually in CI/CD)
goreleaser release --clean
```

## Common Patterns

### Pattern 1: Simple Binary-Only Release

Minimal config for binaries without Docker:
```yaml
version: 2
project_name: "myapp"
builds:
  - env: [CGO_ENABLED=0]
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
archives:
  - format: tar.gz
    format_overrides:
      - goos: windows
        format: zip
checksum:
  name_template: 'checksums.txt'
```

### Pattern 2: Docker-Only Release

For containerized applications:
```yaml
version: 2
project_name: "myapp"
builds:
  - env: [CGO_ENABLED=0]
    goos: [linux]
    goarch: [amd64, arm64]
dockers:
  - image_templates:
      - "ghcr.io/owner/{{.ProjectName}}:{{.Version}}"
      - "ghcr.io/owner/{{.ProjectName}}:latest"
```

### Pattern 3: Full Release Pipeline

Complete setup with binaries, Docker, and Homebrew (see template in assets).

### Pattern 4: Private Registry

For GitLab Container Registry or private Docker Hub:
```yaml
dockers:
  - image_templates:
      - "registry.gitlab.com/owner/project:{{.Version}}"
    skip_push: false
    dockerfile: Dockerfile
```

## Architecture Support

Template includes these architectures:
- **amd64** (x86_64): Most common, servers and desktops
- **arm64** (aarch64/armv8): Modern ARM (Apple Silicon, AWS Graviton)
- **armv7**: Raspberry Pi 3/4, embedded devices
- **armv6**: Raspberry Pi Zero/1, older ARM devices

Adjust based on target platforms:
```yaml
builds:
  - goarch: [amd64, arm64]  # Drop ARM variants for server-only apps
    goarm: []                # Remove if no ARM32 support needed
```

## Troubleshooting

### Issue: "Command not found: goreleaser"

**Solution**: Install GoReleaser
```bash
brew install goreleaser          # macOS
go install github.com/goreleaser/goreleaser@latest  # Any OS
```

### Issue: "Docker buildx not available"

**Solution**: Enable Docker buildx
```bash
docker buildx version  # Check if installed
docker buildx create --use  # Create and use new builder
```

### Issue: "No Git tags found"

**Solution**: Create initial tag
```bash
git tag -a v0.1.0 -m "Initial release"
git push origin v0.1.0
```

### Issue: "Permission denied pushing to registry"

**Solution**: Authenticate with container registry
```bash
# GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# GitLab Container Registry
echo $GITLAB_TOKEN | docker login registry.gitlab.com -u USERNAME --password-stdin

# Docker Hub
docker login
```

### Issue: "Homebrew formula creation failed"

**Solution**: Verify token permissions
- Token needs `repo` scope for pushing to Homebrew tap
- Ensure tap repository exists: `owner/homebrew-tools`
- Check repository name matches config

### Issue: "Build failed for specific architecture"

**Solution**: Test architecture-specific build
```bash
GOOS=linux GOARCH=arm64 go build -o test ./cmd
./test --version  # Test on target architecture
```

## CI/CD Integration Examples

### GitHub Actions

```yaml
name: Release
on:
  push:
    tags:
      - 'v*'
jobs:
  goreleaser:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-go@v5
        with:
          go-version: '1.23'
      - uses: docker/setup-qemu-action@v3
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: goreleaser/goreleaser-action@v6
        with:
          version: latest
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          HOMEBREW_TAP_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}
```

### GitLab CI

```yaml
release:
  stage: release
  image: goreleaser/goreleaser
  services:
    - docker:dind
  only:
    - tags
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - goreleaser release --clean
  variables:
    GITLAB_TOKEN: $CI_JOB_TOKEN
```

## Best Practices

1. **Semantic Versioning**: Use `v1.2.3` format for tags
2. **Conventional Commits**: Enables automatic changelog generation
3. **Test Snapshots**: Always test with `--snapshot` before tagging
4. **Multi-arch Testing**: Verify builds work on target architectures
5. **Secret Management**: Never commit tokens, use CI/CD secrets
6. **Changelog Curation**: Review auto-generated changelog before release
7. **Docker Security**: Use scratch or distroless base images
8. **Version Injection**: Inject version via ldflags for `--version` flag

## Additional Resources

- Official docs: https://goreleaser.com
- Example configs: https://github.com/goreleaser/goreleaser/tree/main/.github/workflows
- Docker buildx: https://docs.docker.com/buildx/working-with-buildx/
- Conventional commits: https://www.conventionalcommits.org/

## Expected Output

After using this skill, the project will have:
- ✅ `.goreleaser.yml` configured for the project
- ✅ `Dockerfile` for multi-architecture builds
- ✅ `resources/etc/passwd` for non-root container user
- ✅ CI/CD pipeline configured for automated releases
- ✅ Documentation on release process
- ✅ Tested snapshot builds

Users can then create releases by simply pushing Git tags.
