---
name: golangci-lint
description: Initialize or update golangci-lint configuration for Go projects with comprehensive code quality checks, static analysis, and best practices enforcement
---

# golangci-lint Setup Skill

Configure professional-grade linting for Go projects with sensible defaults that balance code quality with pragmatic development.

## Overview

[golangci-lint](https://golangci-lint.run) is a fast, parallel linter aggregator for Go that runs multiple linters simultaneously. It's the industry standard for Go code quality enforcement.

**Benefits:**
- **Speed**: Runs linters in parallel, caches results (5x faster than running linters individually)
- **Comprehensive**: Bundles 90+ linters covering code quality, bugs, performance, style
- **Configurable**: Highly customizable via YAML configuration
- **CI/CD Ready**: Seamless integration with GitHub Actions, GitLab CI, pre-commit hooks
- **Editor Integration**: Works with VS Code, GoLand, Vim, Emacs

This skill provides a battle-tested configuration optimized for golangci-lint v2.4.0+ that enables all linters by default while disabling overly strict or opinionated ones.

## Prerequisites

Before using this skill, ensure:

1. **Go installed**: Go 1.21+ recommended
   - Check: `go version`
2. **golangci-lint installed**: Version 2.4.0 or higher
   - Install: `brew install golangci-lint` (macOS)
   - Or: `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest`
   - Check: `golangci-lint --version`
3. **Go module**: Project uses Go modules (`go.mod` exists)

## Instructions

### Step 1: Verify Project Setup

Check current state:
```bash
# Verify Go module
ls go.mod

# Check for existing linter config
ls -la .golangci.yml .golangci.yaml

# Test if golangci-lint is installed
golangci-lint --version
```

### Step 2: Copy Configuration File

Copy the base configuration from this skill's assets:

```bash
# Copy template to project root
cp assets/.golangci.yml .golangci.yml

# Or rename if you prefer .yaml extension
cp assets/.golangci.yml .golangci.yaml
```

The configuration will be placed in the repository root where golangci-lint expects it.

### Step 3: Run Initial Lint Check

Test the configuration:

```bash
# Run linter on entire project
golangci-lint run ./...

# Run with verbose output to see which linters are active
golangci-lint run -v ./...

# Run specific linter only
golangci-lint run --disable-all --enable=govet ./...
```

### Step 4: Review and Fix Issues

Address linting issues:

```bash
# Show detailed issue information
golangci-lint run --print-issued-lines=false ./...

# Focus on specific severity
golangci-lint run --max-issues-per-linter=0 ./...

# See suggested fixes
golangci-lint run --issues-exit-code=0 ./...
```

Some issues can be auto-fixed:
```bash
# Apply automatic fixes (when available)
golangci-lint run --fix ./...
```

### Step 5: Customize Configuration (Optional)

Adjust `.golangci.yml` based on your project needs:

#### A. Enable Additional Linters
```yaml
linters:
  default: all
  enable:
    - gofumpt      # Stricter gofmt
    - godot        # Comment punctuation
    - testpackage  # Separate test packages
```

#### B. Disable More Linters
```yaml
linters:
  disable:
    - lll          # Line length (already disabled)
    - funlen       # Function length
    - cyclop       # Cyclomatic complexity
```

#### C. Configure Linter Settings
```yaml
linters-settings:
  errcheck:
    check-blank: true
  govet:
    check-shadowing: true
  gocyclo:
    min-complexity: 15
```

#### D. Exclude Specific Files/Patterns
```yaml
issues:
  exclude-dirs:
    - vendor
    - third_party
    - generated
  exclude-files:
    - ".*_test.go"
    - "mock_.*\\.go"
```

### Step 6: Integrate with CI/CD

#### GitHub Actions

Already configured if using the `github-workflows` skill. The linter workflow uses:

```yaml
- name: Install golangci-lint
  uses: jaxxstorm/action-install-gh-release@v2.1.0
  with:
    repo: golangci/golangci-lint
    tag: v2.4.0

- name: Run linter
  run: golangci-lint run --timeout=5m ./...
```

#### GitLab CI

```yaml
lint:
  stage: test
  image: golangci/golangci-lint:v2.4.0
  script:
    - golangci-lint run -v ./...
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

#### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/golangci/golangci-lint
    rev: v2.4.0
    hooks:
      - id: golangci-lint
        args: [--timeout=5m]
```

#### Taskfile

```yaml
version: '3'

tasks:
  lint:
    desc: Run golangci-lint
    cmds:
      - golangci-lint run --timeout=5m ./...

  lint:fix:
    desc: Run golangci-lint with auto-fix
    cmds:
      - golangci-lint run --fix --timeout=5m ./...
```

### Step 7: Document in README

Add linting requirements to your project's README.md to ensure all contributors follow code quality standards:

```markdown
## Development Guidelines

### Code Quality

This project uses [golangci-lint](https://golangci-lint.run) for code quality enforcement.

**⚠️ Important: All linting issues MUST be fixed before pushing commits.**

#### Running the Linter

```bash
# Check for linting issues
golangci-lint run ./...

# Auto-fix issues where possible
golangci-lint run --fix ./...
```

#### Pre-commit Checklist

Before pushing any commit:
1. ✅ Run `golangci-lint run ./...`
2. ✅ Fix all reported issues
3. ✅ Ensure tests pass: `go test ./...`
4. ✅ Commit and push

#### CI/CD Integration

All pull requests are automatically checked by golangci-lint in CI. PRs with linting errors will be blocked from merging.

#### Editor Integration

For real-time linting feedback, configure your editor:
- **VS Code**: Install the Go extension
- **GoLand**: Built-in support
- **Vim/Neovim**: Use ALE or similar plugin

See [Editor Integration](#editor-integration) section below for setup instructions.
\```

#### Optional: Add Pre-commit Hook

Automatically run linter before each commit:

```bash
# Create .git/hooks/pre-commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running golangci-lint..."
golangci-lint run ./...
if [ $? -ne 0 ]; then
    echo "❌ Linting failed. Please fix issues before committing."
    exit 1
fi
echo "✅ Linting passed"
EOF

chmod +x .git/hooks/pre-commit
```

Or use [pre-commit framework](https://pre-commit.com):

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/golangci/golangci-lint
    rev: v2.4.0
    hooks:
      - id: golangci-lint
```

Then install: `pre-commit install`

### Step 8: Configure Editor Integration

#### VS Code

Install the [Go extension](https://marketplace.visualstudio.com/items?itemName=golang.go) and add to `settings.json`:

```json
{
  "go.lintTool": "golangci-lint",
  "go.lintFlags": ["--fast"],
  "go.lintOnSave": "workspace"
}
```

#### GoLand/IntelliJ IDEA

1. Settings � Tools � File Watchers � Add (+)
2. Select "golangci-lint"
3. Configure: `golangci-lint run $FileDir$`

#### Vim/Neovim

With `ale` plugin:
```vim
let g:ale_linters = {'go': ['golangci-lint']}
let g:ale_go_golangci_lint_options = '--fast'
```

## Configuration Explained

### Base Configuration Philosophy

The provided `.golangci.yml` follows these principles:

1. **Enable all by default**: Start with maximum coverage
2. **Disable the noisy**: Remove linters that produce false positives or are too opinionated
3. **Pragmatic over perfect**: Balance quality with development velocity
4. **Project-agnostic**: Works for most Go projects out of the box

### Disabled Linters Explained

#### Style/Formatting (Opinionated)

- **`wsl`, `wsl_v5`** (Whitespace Linter)
  - Forces specific whitespace rules (blank lines before blocks)
  - Too opinionated, conflicts with team preferences
  - Alternative: Use `gofmt` or `gofumpt` for consistent formatting

- **`nlreturn`** (New Line Before Return)
  - Requires blank line before every return statement
  - Style preference, not a real issue
  - Teams vary on this convention

- **`lll`** (Line Length Limit)
  - Enforces maximum line length (default 120 characters)
  - Modern screens handle longer lines
  - Can break naturally long import paths or strings

#### Strictness (Too Restrictive)

- **`varnamelen`** (Variable Name Length)
  - Requires minimum variable name lengths
  - Breaks idiomatic Go (short names in small scopes)
  - Example: `i`, `j`, `v` are perfectly fine in loops

- **`exhaustruct`** (Exhaustive Struct Fields)
  - Requires all struct fields to be explicitly set
  - Too verbose, especially with large structs
  - Zero values are a Go feature, not a bug

- **`noinlineerr`** (No Inline Error)
  - Disallows inline error creation
  - Forces error variables for simple cases
  - Reduces code readability

#### Project-Specific (Not Universal)

- **`depguard`** (Dependency Guard)
  - Blocks specific package imports
  - Requires project-specific configuration
  - Not useful without custom rules

- **`tagliatelle`** (Struct Tag Format)
  - Enforces specific struct tag naming (camelCase, snake_case)
  - Project-specific preference
  - APIs often dictate tag format

- **`forbidigo`** (Forbid Identifiers)
  - Blocks specific function calls (e.g., `fmt.Print`)
  - Requires custom configuration per project
  - Not universally applicable

#### Architecture (Allow Flexibility)

- **`gochecknoinits`** (No Init Functions)
  - Disallows `init()` functions
  - Init functions are valid Go feature
  - Useful for package initialization, flag parsing

- **`gochecknoglobals`** (No Global Variables)
  - Disallows package-level variables
  - Too strict for practical Go code
  - Globals are necessary for configs, singletons

### Enabled Linters (Partial List)

With `default: all`, you get these essential linters:

**Bug Detection:**
- `govet`: Official Go vet tool (shadowing, unreachable code)
- `errcheck`: Ensures error returns are checked
- `staticcheck`: Comprehensive static analysis
- `gosimple`: Simplification suggestions
- `unused`: Detects unused code

**Code Quality:**
- `gofmt`: Code formatting
- `goimports`: Import organization
- `ineffassign`: Ineffectual assignments
- `misspell`: Spelling mistakes in comments/strings

**Security:**
- `gosec`: Security issues (SQL injection, weak crypto)
- `G101-G602`: Various security checks

**Performance:**
- `prealloc`: Slice pre-allocation
- `unconvert`: Unnecessary type conversions

**Best Practices:**
- `gocyclo`: Cyclomatic complexity
- `goconst`: Repeated strings that should be constants
- `godox`: TODO/FIXME/BUG comments
- `gocritic`: Opinionated checks

See full list: `golangci-lint linters`

## Troubleshooting

### Issue: "golangci-lint: command not found"

**Solution**: Install golangci-lint

```bash
# macOS
brew install golangci-lint

# Linux
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.4.0

# Windows
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

### Issue: "context loading failed: no go files to analyze"

**Solution**: Ensure you're in a directory with Go files or use `./...`

```bash
# Wrong
golangci-lint run

# Right
golangci-lint run ./...
```

### Issue: "timeout exceeded"

**Solution**: Increase timeout, especially for large projects

```bash
golangci-lint run --timeout=10m ./...
```

Or in `.golangci.yml`:
```yaml
run:
  timeout: 10m
```

### Issue: "too many issues detected"

**Solution**: Incrementally enable linters

```bash
# Start with critical issues only
golangci-lint run --disable-all --enable=govet,errcheck,staticcheck ./...

# Gradually add more
golangci-lint run --disable-all --enable=govet,errcheck,staticcheck,gosimple,unused ./...
```

Or configure in `.golangci.yml`:
```yaml
issues:
  max-issues-per-linter: 50
  max-same-issues: 3
```

### Issue: "false positives from specific linter"

**Solution**: Disable the problematic linter

```yaml
linters:
  disable:
    - problematic-linter
```

Or exclude specific issues:
```yaml
issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - errcheck
        - dupl
```

### Issue: "conflicts with existing code style"

**Solution**: Customize linter settings

```yaml
linters-settings:
  gofmt:
    simplify: false  # Disable simplification
  govet:
    check-shadowing: false  # Allow variable shadowing
```

### Issue: "linter running on vendor or generated code"

**Solution**: Exclude directories

```yaml
run:
  skip-dirs:
    - vendor
    - third_party
    - generated
    - .git
```

## Best Practices

### 1. Enforce Pre-commit Linting

**Critical**: Make linting mandatory before pushing code.

**Why it matters:**
- Prevents broken CI builds
- Maintains consistent code quality
- Catches bugs early
- Reduces code review overhead

**How to enforce:**

```bash
# Option 1: Git pre-commit hook (recommended)
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
golangci-lint run ./...
EOF
chmod +x .git/hooks/pre-commit

# Option 2: pre-commit framework
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/golangci/golangci-lint
    rev: v2.4.0
    hooks:
      - id: golangci-lint

# Option 3: Make/Task command
# Always run 'make lint' or 'task lint' before git push
```

**Document in README.md:**
```markdown
⚠️ **Important**: All linting issues MUST be fixed before pushing commits.
Run `golangci-lint run ./...` before every push.
```

**Enforce in CI:**
```yaml
# GitHub Actions / GitLab CI
- name: Lint
  run: golangci-lint run ./...
  # Fails the build if issues found
```

### 2. Start Strict, Loosen as Needed

```yaml
# Begin with all linters
linters:
  default: all

# Disable only when they cause real problems
  disable:
    - specific-noisy-linter
```

### 3. Use Linter Comments Sparingly

Disable linters inline only when absolutely necessary:

```go
//nolint:errcheck // Acceptable: closing read-only file
file.Close()

//nolint:gosec // G304: Acceptable: user controls file path
content, _ := os.ReadFile(userPath)
```

Avoid blanket disables:
```go
// BAD: Too broad
//nolint:all
func problematicCode() {}

// GOOD: Specific
//nolint:gocyclo // Complexity acceptable for state machine
func stateMachine() {}
```

### 4. Configure for Your Team

```yaml
# Adjust complexity thresholds to team standards
linters-settings:
  gocyclo:
    min-complexity: 15  # Default is 10
  funlen:
    lines: 100
    statements: 50
```

### 5. Separate Test Configuration

```yaml
issues:
  exclude-rules:
    # More lenient for tests
    - path: _test\.go
      linters:
        - errcheck      # Allow unchecked errors in tests
        - funlen        # Tests can be longer
        - goconst       # Duplication OK in table tests
```

### 6. Fast Mode for Development

```yaml
run:
  # Fast mode: only new issues on changed files
  fast: true
```

Or use flag:
```bash
golangci-lint run --fast ./...
```

### 7. Incremental Adoption

For existing projects with many issues:

```yaml
issues:
  # Only show new issues, ignore existing ones
  new: true
  new-from-rev: main  # Compare against main branch
```

### 8. Cache for Speed

```bash
# Enable caching (default)
golangci-lint cache status

# Clear cache if needed
golangci-lint cache clean
```

### 9. Run Different Checks in CI vs Local

```yaml
# .golangci.yml for local (fast)
run:
  fast: true

# .golangci-ci.yml for CI (thorough)
run:
  fast: false
```

Then in CI:
```bash
golangci-lint run -c .golangci-ci.yml ./...
```

## Advanced Configuration

### Custom Linter Settings

```yaml
linters-settings:
  # Error checking
  errcheck:
    check-blank: true
    check-type-assertions: true

  # Variable shadowing
  govet:
    check-shadowing: true
    settings:
      printf:
        funcs:
          - (github.com/golangci/golangci-lint/pkg/logutils.Log).Infof

  # Cyclomatic complexity
  gocyclo:
    min-complexity: 15

  # Cognitive complexity
  gocognit:
    min-complexity: 20

  # Function length
  funlen:
    lines: 80
    statements: 40

  # Line length
  lll:
    line-length: 120
    tab-width: 4

  # Misspelling
  misspell:
    locale: US

  # Naming conventions
  revive:
    rules:
      - name: exported
        severity: warning
```

### Issue Exclusions

```yaml
issues:
  # Exclude specific text in issues
  exclude:
    - "Error return value of .((os\\.)?std(out|err)\\..*|.*Close|.*Flush|os\\.Remove(All)?|.*printf?|os\\.(Un)?Setenv). is not checked"

  # Exclude by path
  exclude-dirs:
    - vendor
    - testdata

  exclude-files:
    - ".*\\.pb\\.go$"
    - ".*_gen\\.go$"

  # Exclude by rule
  exclude-rules:
    # Exclude some linters from running on tests
    - path: _test\.go
      linters:
        - gocyclo
        - errcheck
        - dupl
        - gosec

    # Exclude known issues
    - linters:
        - staticcheck
      text: "SA9003:"

    # Exclude by source
    - source: "^//go:generate "
      linters:
        - lll
```

### Output Configuration

```yaml
output:
  format: colored-line-number  # Options: colored-line-number, line-number, json, tab, checkstyle, code-climate
  print-issued-lines: true
  print-linter-name: true
  uniq-by-line: true
  sort-results: true
```

## Integration Examples

### GitHub Actions with Caching

```yaml
- name: golangci-lint
  uses: golangci/golangci-lint-action@v6
  with:
    version: v2.4.0
    args: --timeout=5m
    # Optional: show only new issues
    only-new-issues: true
```

### GitLab CI with Artifacts

```yaml
lint:
  image: golangci/golangci-lint:v2.4.0
  script:
    - golangci-lint run --out-format checkstyle ./... > report.xml
  artifacts:
    reports:
      junit: report.xml
```

### Docker Container

```dockerfile
FROM golangci/golangci-lint:v2.4.0 AS linter
WORKDIR /app
COPY . .
RUN golangci-lint run ./...
```

### Pre-commit with Auto-fix

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/golangci/golangci-lint
    rev: v2.4.0
    hooks:
      - id: golangci-lint
        args: [--fix, --timeout=5m]
```

## Additional Resources

- **Official documentation**: https://golangci-lint.run
- **Configuration reference**: https://golangci-lint.run/usage/configuration/
- **Linters list**: https://golangci-lint.run/usage/linters/
- **GitHub**: https://github.com/golangci/golangci-lint
- **VS Code extension**: https://marketplace.visualstudio.com/items?itemName=golang.go
- **Editor integrations**: https://golangci-lint.run/usage/integrations/

## Expected Output

After using this skill, your project will have:
-  Professional `.golangci.yml` configuration
-  90+ linters checking code quality, bugs, and performance
-  Balanced configuration (strict but pragmatic)
-  CI/CD integration ready
-  Editor integration support
-  Fast, cached linting
-  Customizable to project needs
-  Industry-standard code quality enforcement

Your Go code will meet professional quality standards with automated enforcement of best practices, security checks, and bug detection.
