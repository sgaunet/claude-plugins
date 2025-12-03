---
description: Verify task implementation quality and completeness using TDD methodology validation, Go library documentation alignment, and comprehensive testing
argument-hint: "<task-id>"
allowed-tools: Read, Grep, Glob, Bash, WebFetch, mcp__task-master__
---

# Verify Task

Verify the quality and completeness of a task implementation using the task-master MCP integration. This command validates TDD methodology compliance, Go library documentation alignment, and comprehensive quality gates.

## Arguments

- `$argument`: Task ID to verify (required)

## Process

1. **Retrieve Task Information**
   - Use `mcp__task-master__get_task` with the task ID from `$argument`
   - Review requirements, test strategy, and success criteria
   - Note any subtasks and their individual requirements

2. **Verify File Structure**
   - Use `ls` to verify all required directories and files exist
   - Use `Read` to examine created/modified files
   - Check file structure matches specifications
   - Verify all required methods/functions are implemented

3. **Validate Library Usage with Context7**

   If the task uses third-party Go libraries:
   - Use `mcp__context7__resolve-library-id` to identify libraries
   - Use `mcp__context7__get-library-docs` to fetch official documentation
   - Verify code follows official library patterns and best practices
   - Check for deprecated APIs or outdated usage
   - Validate proper usage of library features and idioms
   - Ensure imports and function signatures match official documentation

4. **Validate Implementation**
   - Use `Grep` to search for required patterns and implementations
   - Check against requirements checklist
   - Verify all subtasks are complete
   - Ensure no breaking changes to existing code

5. **Run Comprehensive Tests**
   ```bash
   # Run all tests with verbose output
   go test -v ./...

   # Run tests with race detection
   go test -race ./...

   # Run tests with coverage report
   go test -cover ./... -coverprofile=coverage.out
   go tool cover -func=coverage.out

   # Run specific test files or packages if needed
   go test -v ./path/to/package
   go test -v -run TestSpecificFunction

   # Run benchmarks if present
   go test -bench=. ./...

   # Static analysis and vetting
   go vet ./...

   # Build verification (ensure no compilation errors)
   go build ./...

   # Linting (if golangci-lint is configured)
   golangci-lint run ./...
   ```

6. **Validate Go Library Documentation**
   - Identify Go libraries used in the implementation
   - Use `WebFetch` to retrieve documentation from pkg.go.dev
   - Example: `WebFetch("https://pkg.go.dev/github.com/sgaunet/perplexity-go/v2", "Extract API usage patterns, best practices, and implementation examples")`
   - Validate implementation against documented patterns:
     - Check function signatures match documentation
     - Verify correct error handling patterns
     - Ensure proper context usage
     - Validate configuration and initialization patterns

7. **Verify Quality Standards**
   - **TDD Methodology**: Confirm RED-GREEN-REFACTOR workflow was followed
   - **Documentation Compliance**: Implementation follows pkg.go.dev best practices
   - **Code Standards**: Implementation follows collective agent patterns
   - **Quality Gates**: All mandatory validation checkpoints passed
   - **Dependencies**: All task dependencies were actually completed

8. **Generate Verification Report**

## Report Format

Generate a structured report in the following YAML format:

```yaml
verification_report:
  task_id: [Task ID from $argument]
  status: PASS | FAIL | PARTIAL
  score: [1-10]

  requirements_met:
    - ✅ [Requirement that was satisfied]
    - ✅ [Another satisfied requirement]

  issues_found:
    - ❌ [Issue description with file:line references]
    - ⚠️  [Warning or minor issue]

  files_verified:
    - path: [file path]
      status: [created/modified/verified]
      issues: [any problems found]

  tests_run:
    - command: [test command executed]
      result: [pass/fail]
      output: [relevant output summary]

  library_validation:
    - library: [Go library name]
      documentation_url: [pkg.go.dev URL]
      compliance: [compliant/non-compliant]
      issues: [any deviations from documented patterns]

  recommendations:
    - [Specific fix needed with file:line reference]
    - [Improvement suggestion]

  verdict: |
    [Clear statement on whether task should be marked 'done' or sent back to 'pending']
    [If FAIL: Specific list of what must be fixed]
    [If PASS: Confirmation that all requirements are met]
```

## Decision Criteria

### Mark as PASS (ready for 'done')
- **TDD Compliance**: RED-GREEN-REFACTOR methodology verified
- **pkg.go.dev Documentation Compliance**: Implementation follows official Go library documentation patterns and best practices
- **Test Coverage**: >90% coverage achieved with passing tests
- **Quality Gates**: All validation checkpoints passed
- **Agent Standards**: Implementation follows collective agent patterns
- **Documentation Validation**: Task demonstrates documentation-backed development using pkg.go.dev

### Mark as PARTIAL (may proceed with warnings)
- Core functionality is implemented
- Minor issues that don't block functionality
- Missing nice-to-have features
- Documentation could be improved
- Tests pass but coverage could be better

### Mark as FAIL (must return to 'pending')
- Required files are missing
- Compilation or build errors
- Tests fail
- Core requirements not met
- Security vulnerabilities detected
- Breaking changes to existing code

## Verification Guidelines

- **BE THOROUGH**: Check every requirement systematically
- **BE SPECIFIC**: Provide exact file paths and line numbers for issues (format: `path/to/file.go:123`)
- **BE FAIR**: Distinguish between critical issues and minor improvements
- **BE CONSTRUCTIVE**: Provide clear guidance on how to fix issues
- **BE EFFICIENT**: Focus on requirements, not perfection

## Tools to Use

- `mcp__task-master__get_task`: Retrieve task details
- `Read`: Examine implementation files (read-only)
- `Bash`: Run tests and verification commands
- `Grep`: Search for patterns in code
- `WebFetch`: Fetch Go library documentation from pkg.go.dev
- **DO NOT use Write/Edit**: This is verification only, not implementation

## Example Usage

```bash
# Verify task with ID 12345
/verify-task 12345

# Verify task with ID ABC-789
/verify-task ABC-789
```

After verification, update the task status using the appropriate MCP tool if you have permission to do so.
