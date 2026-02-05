---
name: verify-task
description: Verify Go task quality using TDD validation and doc alignment
argument-hint: "<task-id>"
allowed-tools: Read, Grep, Glob, Bash(ls:*), Bash(go test:*), Bash(go vet:*), Bash(go build:*), Bash(golangci-lint:*), WebFetch, mcp__task-master__get_task, mcp__context7__resolve-library-id, mcp__context7__get-library-docs
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

3. **Launch 3 parallel Sonnet agents** to independently validate implementation quality:

   **Agent #1: Library Usage Validator (Context7 Integration)**
   - Extract all third-party Go libraries from import statements
   - For each library, use `mcp__context7__resolve-library-id` to identify library
   - Use `mcp__context7__get-library-docs` to fetch official documentation
   - Verify code follows official library patterns and best practices
   - Check for deprecated APIs or outdated usage
   - Validate proper usage of library features and idioms
   - Ensure imports and function signatures match official documentation
   - Return: list of compliance issues with library name, line number, and recommendation

   **Agent #2: Test Suite Executor**
   - Run comprehensive test suite in parallel batches:
     ```bash
     # Concurrent test execution
     go test -v ./... &
     go test -race ./... &
     go test -cover ./... -coverprofile=coverage.out &
     go test -bench=. ./... &
     wait
     ```
   - Analyze test results and coverage reports
   - Return: test pass/fail status, coverage percentage, benchmark results

   **Agent #3: Static Analysis & Code Quality**
   - Run static analysis tools concurrently:
     ```bash
     go vet ./... &
     go build ./... &
     golangci-lint run ./... &
     wait
     ```
   - Check for compilation errors, vet warnings, linter issues
   - Return: list of code quality issues with severity levels

4. **Validate Go Library Documentation (pkg.go.dev)**
   - Use `WebFetch` to retrieve documentation from pkg.go.dev
   - Example: `WebFetch("https://pkg.go.dev/github.com/sgaunet/perplexity-go/v2", "Extract API usage patterns, best practices, and implementation examples")`
   - Cross-reference with Agent #1 findings
   - Validate implementation against documented patterns:
     - Function signatures match documentation
     - Correct error handling patterns
     - Proper context usage
     - Configuration and initialization patterns

5. **Aggregate Results & Verify Quality Standards**
   - Merge findings from all 3 agents
   - **TDD Methodology**: Confirm RED-GREEN-REFACTOR workflow was followed
   - **Documentation Compliance**: Implementation follows pkg.go.dev best practices
   - **Code Standards**: Implementation follows collective agent patterns
   - **Quality Gates**: All mandatory validation checkpoints passed
   - **Dependencies**: All task dependencies were actually completed

## Parallel Agent Invocation Pattern

```
# Step 1 & 2: Retrieve task and verify file structure (sequential)
task_info = mcp__task-master__get_task(task_id)
file_structure_check = verify_files_exist(task_info.requirements)

# Step 3: Launch 3 parallel Sonnet agents
Task(subagent_type: "general-purpose", model: "sonnet", prompt: "Validate Go library usage for task ${task_id}. Files: ${implementation_files}. Use Context7 to fetch official docs and verify compliance. Return library validation issues.")

Task(subagent_type: "general-purpose", model: "sonnet", prompt: "Run comprehensive Go test suite for task ${task_id}. Execute: go test -v, -race, -cover, -bench in parallel. Return test results and coverage report.")

Task(subagent_type: "general-purpose", model: "sonnet", prompt: "Run Go static analysis for task ${task_id}. Execute: go vet, go build, golangci-lint concurrently. Return code quality issues.")

# Step 4: Library documentation validation (can run concurrently with step 3)
Task(subagent_type: "general-purpose", model: "sonnet", prompt: "Fetch Go library documentation from pkg.go.dev for libraries in ${task_id}. Validate implementation patterns match official examples.")

# Step 5: Aggregate results from all agents
# Step 6: Generate report
```

Note: If task uses multiple third-party libraries (e.g., 5+ imports), fetch Context7 documentation in parallel batches:

```
# Example: 3 libraries
Task(tool: "mcp__context7__get-library-docs", library: "/gin-gonic/gin")
Task(tool: "mcp__context7__get-library-docs", library: "/go-chi/chi")
Task(tool: "mcp__context7__get-library-docs", library: "/gorilla/mux")
# Results aggregated after all complete
```

6. **Generate Verification Report**

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
