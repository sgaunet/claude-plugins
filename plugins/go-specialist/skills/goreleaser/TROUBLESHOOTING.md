# GoReleaser Troubleshooting

Common issues and solutions when setting up and using GoReleaser for Go project releases.

## Installation Issues

### Issue: "Command not found: goreleaser"

**Symptoms**:
- Running `goreleaser` command fails
- Error: "command not found" or "goreleaser: not found"

**Solution**: Install GoReleaser

**macOS (Homebrew)**:
```bash
brew install goreleaser
```

**Linux (snap)**:
```bash
snap install --classic goreleaser
```

**Any OS (Go install)**:
```bash
go install github.com/goreleaser/goreleaser@latest

# Ensure $GOPATH/bin is in PATH
export PATH=$PATH:$(go env GOPATH)/bin
```

**Verify installation**:
```bash
goreleaser --version
```

### Issue: "GoReleaser version too old"

**Symptoms**:
- Configuration uses v2 features but GoReleaser is v1
- Error: "unknown field" or "unsupported version"

**Solution**: Upgrade to latest version

```bash
# Homebrew
brew upgrade goreleaser

# Go install
go install github.com/goreleaser/goreleaser@latest

# Check version (should be 2.x+)
goreleaser --version
```

## Configuration Issues

### Issue: "No Git tags found"

**Symptoms**:
- GoReleaser fails immediately
- Error: "git describe failed" or "no tags found"

**Solution**: Create initial Git tag

```bash
# Create first tag
git tag -a v0.1.0 -m "Initial release"

# Push tag to remote
git push origin v0.1.0

# Verify tag exists
git tag -l
```

### Issue: "Invalid configuration"

**Symptoms**:
- `goreleaser check` fails
- Syntax errors in `.goreleaser.yml`

**Solution**: Validate and fix configuration

```bash
# Check configuration
goreleaser check

# Common issues:
# 1. Wrong YAML indentation
# 2. Missing required fields
# 3. Invalid field names
# 4. Version mismatch (v1 vs v2)
```

**Example fix**:
```yaml
# Wrong (v1 syntax)
archive:
  format: tar.gz

# Correct (v2 syntax)
archives:
  - format: tar.gz
```

### Issue: "Build directory not found"

**Symptoms**:
- Error: "main.go not found" or "no Go files in directory"
- Build fails to find source files

**Solution**: Configure correct build directory

```yaml
builds:
  - dir: cmd/myapp        # If main.go is in cmd/myapp/
    main: ./main.go

  # OR for root-level main.go
  - dir: .
    main: ./main.go

  # OR for cmd/ directory
  - dir: ./cmd
```

## Docker Issues

### Issue: "Docker buildx not available"

**Symptoms**:
- Error: "buildx: command not found"
- Multi-architecture builds fail

**Solution**: Enable Docker buildx

```bash
# Check if buildx is available
docker buildx version

# Create new builder
docker buildx create --name mybuilder --use

# Bootstrap builder
docker buildx inspect --bootstrap

# Verify
docker buildx ls
```

**For older Docker versions**:
```bash
# Update Docker to latest version
# macOS: Update Docker Desktop
# Linux: Follow https://docs.docker.com/engine/install/
```

### Issue: "Permission denied pushing to registry"

**Symptoms**:
- Docker images build successfully
- Push fails with "permission denied" or "unauthorized"

**Solution**: Authenticate with container registry

**GitHub Container Registry (GHCR)**:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Or in CI/CD
docker login ghcr.io -u ${{ github.actor }} -p ${{ secrets.GITHUB_TOKEN }}
```

**GitLab Container Registry**:
```bash
echo $GITLAB_TOKEN | docker login registry.gitlab.com -u USERNAME --password-stdin

# Or in GitLab CI
docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
```

**Docker Hub**:
```bash
docker login -u USERNAME

# Or with token
echo $DOCKER_TOKEN | docker login -u USERNAME --password-stdin
```

### Issue: "Multi-platform build fails"

**Symptoms**:
- Build fails for arm64 or other architectures
- Error: "exec format error" or "platform not supported"

**Solution**: Set up QEMU and verify platform support

```bash
# Install QEMU
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Verify platform support
docker buildx inspect | grep Platforms

# Should show: linux/amd64, linux/arm64, linux/arm/v7, etc.
```

**In CI/CD (GitHub Actions)**:
```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
```

### Issue: "Docker image too large"

**Symptoms**:
- Docker images are hundreds of MB
- Slow push/pull times

**Solution**: Use minimal base images

```dockerfile
# Bad: Full OS (hundreds of MB)
FROM ubuntu:latest

# Good: Distroless (tens of MB)
FROM gcr.io/distroless/static:nonroot

# Best: Scratch (only your binary)
FROM scratch
COPY --from=builder /app/myapp /myapp
ENTRYPOINT ["/myapp"]
```

**Also optimize build**:
```yaml
# .goreleaser.yml
builds:
  - env:
      - CGO_ENABLED=0  # Static binary
    ldflags:
      - -s -w          # Strip debug info
```

## Build Issues

### Issue: "Build failed for specific architecture"

**Symptoms**:
- amd64 builds succeed but arm64 fails
- Error during cross-compilation

**Solution**: Test architecture-specific builds

```bash
# Test arm64 build
GOOS=linux GOARCH=arm64 go build -o test ./cmd

# Check for CGO dependencies
go list -f '{{if .CgoFiles}}{{.ImportPath}}{{end}}' ./...

# If CGO is required, configure per-architecture
```

**Fix in .goreleaser.yml**:
```yaml
builds:
  - env:
      - CGO_ENABLED=0  # Disable CGO for pure Go
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]

  # Or separate builds for CGO
  - id: with-cgo
    env:
      - CGO_ENABLED=1
    goos: [linux]
    goarch: [amd64]
```

### Issue: "Missing dependencies in Docker image"

**Symptoms**:
- Binary runs locally but fails in Docker
- Error: "shared library not found"

**Solution**: Use static compilation or include dependencies

```yaml
# Static compilation (preferred)
builds:
  - env:
      - CGO_ENABLED=0
    ldflags:
      - -extldflags "-static"

# Or use base image with dependencies
```

```dockerfile
# If dynamic linking required
FROM gcr.io/distroless/base-debian11  # Includes libc
# Instead of
# FROM scratch  # No libraries
```

## Homebrew Issues

### Issue: "Homebrew formula creation failed"

**Symptoms**:
- Release succeeds but Homebrew tap not updated
- Error: "permission denied" or "repository not found"

**Solution**: Verify Homebrew tap configuration

1. **Check token permissions**:
   - Token needs `repo` scope
   - Token must have write access to tap repository

2. **Verify tap repository exists**:
   ```bash
   # Repository must exist and follow naming convention
   # Format: owner/homebrew-{name}
   # Example: johndoe/homebrew-tools
   ```

3. **Check .goreleaser.yml configuration**:
   ```yaml
   brews:
     - repository:
         owner: johndoe
         name: homebrew-tools  # Not "tools"
         token: "{{ .Env.HOMEBREW_TAP_TOKEN }}"
       folder: Formula
       homepage: "https://github.com/johndoe/myapp"
       description: "My application"
   ```

4. **Ensure token is set in CI/CD**:
   ```bash
   # GitHub Actions
   HOMEBREW_TAP_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}

   # GitLab CI
   HOMEBREW_TAP_TOKEN: $HOMEBREW_TAP_TOKEN  # Set in CI/CD variables
   ```

### Issue: "Homebrew formula testing fails"

**Symptoms**:
- Formula created but `brew install` fails
- Error: "bottle" or "dependency" issues

**Solution**: Test formula locally

```bash
# Install from local tap
brew tap johndoe/tools https://github.com/johndoe/homebrew-tools
brew install myapp

# Test formula
brew test myapp

# Audit formula
brew audit --strict johndoe/tools/myapp
```

## Release Issues

### Issue: "Release notes missing commits"

**Symptoms**:
- Changelog doesn't include all commits
- Some commits filtered out

**Solution**: Check changelog configuration

```yaml
changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'      # Excludes docs commits
      - '^test:'      # Excludes test commits
      - '^ci:'        # Excludes CI commits
  # Remove filters to include all commits
```

### Issue: "Previous release tag not found"

**Symptoms**:
- Error: "previous tag not found"
- Changelog generation fails

**Solution**: This is expected for first release

```bash
# First release (no previous tag)
goreleaser release --clean

# Subsequent releases work automatically
```

### Issue: "Snapshot builds work but release fails"

**Symptoms**:
- `goreleaser release --snapshot` succeeds
- Actual release fails

**Common causes**:

1. **Not on a tag**:
   ```bash
   # Must be on tagged commit
   git tag -a v1.0.0 -m "Release"
   git push origin v1.0.0
   ```

2. **Dirty working directory**:
   ```bash
   # Commit or stash changes
   git status
   git add .
   git commit -m "prepare release"
   ```

3. **Missing environment variables**:
   ```bash
   # Check required tokens are set
   echo $GITHUB_TOKEN
   echo $HOMEBREW_TAP_TOKEN
   ```

## CI/CD Issues

### Issue: "CI/CD release workflow not triggering"

**Symptoms**:
- Tag pushed but workflow doesn't run
- No release created

**Solution**: Check workflow configuration

**GitHub Actions**:
```yaml
on:
  push:
    tags:
      - 'v*'  # Matches v1.0.0, v2.1.3, etc.

# Ensure tag push
git push origin v1.0.0  # Not just: git push
```

**GitLab CI**:
```yaml
release:
  only:
    - tags  # Triggers on tag push
```

### Issue: "CI runs but GoReleaser fails"

**Symptoms**:
- Workflow starts but GoReleaser step fails
- Permissions or authentication errors

**Solution**: Verify CI permissions and tokens

**GitHub Actions**:
```yaml
permissions:
  contents: write    # Required for releases
  packages: write    # Required for Docker/GHCR

steps:
  - name: Run GoReleaser
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      # Not GITHUB_TOKEN: ${{ github.token }} (wrong)
```

## Performance Issues

### Issue: "Release takes too long"

**Symptoms**:
- GoReleaser runs for 30+ minutes
- Builds or Docker pushes are slow

**Solution**: Optimize build configuration

```yaml
# Reduce target platforms (if acceptable)
builds:
  - goos: [linux, darwin, windows]
    goarch: [amd64, arm64]  # Drop armv6, armv7 if not needed

# Use parallel builds
builds:
  - id: fast
    goarch: [amd64, arm64]
    # Each architecture builds in parallel

# Cache Docker layers in CI
# GitHub Actions
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  with:
    buildkitd-flags: --debug
```

## Getting Help

If you encounter issues not covered here:

1. **Enable debug mode**:
   ```bash
   goreleaser release --clean --debug
   ```

2. **Check configuration**:
   ```bash
   goreleaser check
   ```

3. **Test locally**:
   ```bash
   goreleaser release --snapshot --clean --skip=publish
   ```

4. **Review documentation**:
   - https://goreleaser.com/errors/
   - https://goreleaser.com/customization/

5. **Community support**:
   - GitHub Discussions: https://github.com/goreleaser/goreleaser/discussions
   - Discord: https://discord.gg/RGEBtg8vQ6
