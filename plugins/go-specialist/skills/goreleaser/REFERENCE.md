# GoReleaser Reference

Detailed configuration patterns, CI/CD integration, and best practices for GoReleaser.

## Template Files

All configuration templates are available in the `assets/` directory:
- `.goreleaser.yml` - Complete GoReleaser configuration
- `Dockerfile` - Multi-architecture Docker build
- `resources/etc/passwd` - Non-root container user configuration

## Configuration Patterns

### Pattern 1: Simple Binary-Only Release

Minimal configuration for binaries without Docker images:

```yaml
version: 2
project_name: "myapp"

builds:
  - env:
      - CGO_ENABLED=0
    goos:
      - linux
      - darwin
      - windows
    goarch:
      - amd64
      - arm64

archives:
  - format: tar.gz
    format_overrides:
      - goos: windows
        format: zip
    files:
      - LICENSE
      - README.md

checksum:
  name_template: 'checksums.txt'

changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'
      - '^test:'
```

**Use case**: Command-line tools that don't need containerization.

### Pattern 2: Docker-Only Release

For containerized applications without binary distribution:

```yaml
version: 2
project_name: "myapp"

builds:
  - env:
      - CGO_ENABLED=0
    goos:
      - linux
    goarch:
      - amd64
      - arm64

dockers:
  - image_templates:
      - "ghcr.io/{{.Env.GITHUB_REPOSITORY_OWNER}}/{{.ProjectName}}:{{.Version}}-amd64"
      - "ghcr.io/{{.Env.GITHUB_REPOSITORY_OWNER}}/{{.ProjectName}}:{{.Version}}-arm64"
    use: buildx
    dockerfile: Dockerfile
    build_flag_templates:
      - "--pull"
      - "--platform=linux/amd64"
    skip_push: false

docker_manifests:
  - name_template: "ghcr.io/{{.Env.GITHUB_REPOSITORY_OWNER}}/{{.ProjectName}}:{{.Version}}"
    image_templates:
      - "ghcr.io/{{.Env.GITHUB_REPOSITORY_OWNER}}/{{.ProjectName}}:{{.Version}}-amd64"
      - "ghcr.io/{{.Env.GITHUB_REPOSITORY_OWNER}}/{{.ProjectName}}:{{.Version}}-arm64"
  - name_template: "ghcr.io/{{.Env.GITHUB_REPOSITORY_OWNER}}/{{.ProjectName}}:latest"
    image_templates:
      - "ghcr.io/{{.Env.GITHUB_REPOSITORY_OWNER}}/{{.ProjectName}}:{{.Version}}-amd64"
      - "ghcr.io/{{.Env.GITHUB_REPOSITORY_OWNER}}/{{.ProjectName}}:{{.Version}}-arm64"
```

**Use case**: Microservices and containerized applications.

### Pattern 3: Full Release Pipeline

Complete setup with binaries, Docker images, and Homebrew formula (available in `assets/.goreleaser.yml`).

**Includes**:
- Multi-OS/architecture binaries
- Multi-architecture Docker images with manifests
- Homebrew formula generation
- Changelog automation
- Archive customization

**Use case**: Full-featured CLI tools with multiple distribution channels.

### Pattern 4: Private Registry

For GitLab Container Registry or private Docker Hub:

```yaml
dockers:
  - image_templates:
      - "registry.gitlab.com/{{.Env.CI_PROJECT_PATH}}:{{.Version}}"
      - "registry.gitlab.com/{{.Env.CI_PROJECT_PATH}}:latest"
    skip_push: false
    dockerfile: Dockerfile

# For Docker Hub private registry
dockers:
  - image_templates:
      - "docker.io/{{.Env.DOCKER_USERNAME}}/{{.ProjectName}}:{{.Version}}"
      - "docker.io/{{.Env.DOCKER_USERNAME}}/{{.ProjectName}}:latest"
```

### Pattern 5: GoReleaser Pro Features

With GoReleaser Pro license:

```yaml
version: 2

# Docker image signing
docker_signs:
  - cmd: cosign
    artifacts: all
    args:
      - "sign"
      - "${artifact}"

# Artifacts attestation
sboms:
  - artifacts: archive

# Custom publishers
publishers:
  - name: custom-s3
    cmd: aws s3 cp {{ .ArtifactPath }} s3://bucket/{{ .ProjectName }}/
```

## Architecture Support

### Supported Architectures

| Architecture | GOARCH | Use Case |
|--------------|--------|----------|
| x86_64 | amd64 | Servers, desktops, most common |
| ARM64 | arm64 | Apple Silicon, AWS Graviton, modern ARM |
| ARMv7 | armv7 | Raspberry Pi 3/4, embedded devices |
| ARMv6 | armv6 | Raspberry Pi Zero/1, older ARM |

### Configuration Examples

**Server-only (most common)**:
```yaml
builds:
  - goarch:
      - amd64
      - arm64
```

**Full ARM support**:
```yaml
builds:
  - goarch:
      - amd64
      - arm64
      - arm
    goarm:
      - "6"
      - "7"
```

**Desktop-only**:
```yaml
builds:
  - goos:
      - linux
      - darwin
      - windows
    goarch:
      - amd64
      - arm64
    ignore:
      - goos: windows
        goarch: arm64  # Windows on ARM64 is uncommon
```

### Testing Cross-Compilation

```bash
# Test amd64 build
GOOS=linux GOARCH=amd64 go build -o test-amd64 ./cmd

# Test arm64 build
GOOS=linux GOARCH=arm64 go build -o test-arm64 ./cmd

# Test ARM32 build
GOOS=linux GOARCH=arm GOARM=7 go build -o test-armv7 ./cmd

# Verify with file command
file test-*
```

## CI/CD Integration

### GitHub Actions

Complete workflow for GitHub releases:

```yaml
name: Release
on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write
  packages: write

jobs:
  goreleaser:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.24'

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Run GoReleaser
        uses: goreleaser/goreleaser-action@v6
        with:
          version: latest
          args: release --clean
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          HOMEBREW_TAP_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}
```

### GitLab CI

Complete pipeline for GitLab releases:

```yaml
stages:
  - release

release:
  stage: release
  image: goreleaser/goreleaser:latest
  services:
    - docker:dind
  only:
    - tags
  variables:
    DOCKER_HOST: tcp://docker:2375
    DOCKER_TLS_CERTDIR: ""
    GITLAB_TOKEN: $CI_JOB_TOKEN
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - goreleaser release --clean
```

### Task Runner Integration

Integrate with Taskfile for local and CI use:

```yaml
# Taskfile.yml
version: '3'

tasks:
  release:check:
    desc: Validate GoReleaser configuration
    cmds:
      - goreleaser check

  release:snapshot:
    desc: Create snapshot build (no publish)
    cmds:
      - goreleaser release --snapshot --clean --skip=publish

  release:build:
    desc: Build binaries only (no publish)
    cmds:
      - goreleaser build --snapshot --clean

  release:
    desc: Create production release
    cmds:
      - goreleaser release --clean
    preconditions:
      - sh: git describe --exact-match --tags HEAD
        msg: "Not on a tagged commit"
```

## Best Practices

### 1. Semantic Versioning

Always use semantic versioning for tags:

```bash
# Format: v{MAJOR}.{MINOR}.{PATCH}
git tag -a v1.0.0 -m "Release v1.0.0"
git tag -a v1.2.3 -m "Release v1.2.3"

# Pre-releases
git tag -a v2.0.0-beta.1 -m "Beta release"
git tag -a v2.0.0-rc.1 -m "Release candidate"
```

### 2. Conventional Commits

Use conventional commit format for automatic changelog generation:

```bash
# Feature
git commit -m "feat: add user authentication"

# Bug fix
git commit -m "fix: resolve memory leak in parser"

# Breaking change
git commit -m "feat!: redesign API endpoints"

# Documentation
git commit -m "docs: update installation guide"
```

### 3. Test Before Release

Always test snapshot builds:

```bash
# 1. Check configuration
goreleaser check

# 2. Build only (fast)
goreleaser build --snapshot --clean

# 3. Full release test (no publish)
goreleaser release --snapshot --clean --skip=publish

# 4. Test resulting binaries
./dist/myapp_linux_amd64/myapp --version

# 5. Test Docker image
docker run --rm dist/myapp:latest --version
```

### 4. Multi-architecture Testing

Verify builds work on all target architectures:

```bash
# Use QEMU for testing
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Test ARM64 image
docker run --platform linux/arm64 --rm myapp:latest --version

# Test ARMv7 image
docker run --platform linux/arm/v7 --rm myapp:latest --version
```

### 5. Secret Management

Never commit sensitive data:

```bash
# Use environment variables
export GITHUB_TOKEN="ghp_..."
export HOMEBREW_TAP_TOKEN="ghp_..."

# Or use CI/CD secrets
# GitHub: Settings → Secrets → Actions
# GitLab: Settings → CI/CD → Variables
```

### 6. Changelog Curation

Review and edit auto-generated changelogs:

```yaml
# .goreleaser.yml
changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'
      - '^test:'
      - '^ci:'
      - '^chore:'
  groups:
    - title: Features
      regexp: "^feat:"
    - title: Bug Fixes
      regexp: "^fix:"
    - title: Breaking Changes
      regexp: "^\\w+!:"
```

### 7. Docker Security

Use minimal base images:

```dockerfile
# Good: scratch (most secure)
FROM scratch
COPY resources/etc/passwd /etc/passwd
USER nonroot:nonroot

# Good: distroless (includes CA certs)
FROM gcr.io/distroless/static:nonroot

# Avoid: full OS images (larger attack surface)
# FROM ubuntu:latest  # Don't use
```

### 8. Version Injection

Inject version info via ldflags:

```yaml
# .goreleaser.yml
builds:
  - ldflags:
      - -s -w
      - -X main.version={{.Version}}
      - -X main.commit={{.Commit}}
      - -X main.date={{.Date}}
      - -X main.builtBy=goreleaser
```

Then in your code:
```go
var (
    version = "dev"
    commit  = "none"
    date    = "unknown"
)

func main() {
    fmt.Printf("%s version %s (commit: %s, built: %s)\n",
        os.Args[0], version, commit, date)
}
```

## Additional Resources

- **Official Documentation**: https://goreleaser.com
- **Configuration Reference**: https://goreleaser.com/customization/
- **Example Configs**: https://github.com/goreleaser/goreleaser/tree/main/.github/workflows
- **Docker Buildx**: https://docs.docker.com/buildx/working-with-buildx/
- **Conventional Commits**: https://www.conventionalcommits.org/
- **Semantic Versioning**: https://semver.org/
- **GitHub Container Registry**: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
