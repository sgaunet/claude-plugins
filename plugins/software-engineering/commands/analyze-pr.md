---
name: analyze-pr
description: Review PR for quality, security, and coverage
argument-hint: "<pr-number>"
allowed-tools: Read, Grep, Glob, Skill, Task, Bash(gh:*), Bash(glab:*), AskUserQuestion
---

# Analyze Pull Request Command

Perform comprehensive analysis of a pull request including code review, security scan, and test coverage.

## Process

1. **Detect Repository Type**: Use the `detect-repo-host` skill to identify the hosting service (GitHub or GitLab) and extract owner/repo details.

2. **Fetch PR Details**: Use the appropriate CLI
   - GitHub: `gh pr view <number> --json title,body,author,files,commits`, `gh pr diff <number>`
   - GitLab: `glab mr view <number>`, `glab mr diff <number>`

3. **Analyze Changes**: Launch 4 parallel Sonnet agents to independently review the pull request:

   **Agent #1: Code Quality Review** (`code-review-enforcer` agent)
   - Review modified files for code quality issues
   - Check for logic errors, error handling, performance issues
   - Verify adherence to coding standards
   - Return: list of issues with severity levels and line numbers

   **Agent #2: Security Analysis** (`security-auditor` agent)
   - Scan for security vulnerabilities in modified files
   - Focus on auth/crypto changes, input validation, SQL injection
   - Check for exposed secrets or sensitive data
   - Return: list of security findings with CVSS-like severity ratings

   **Agent #3: Test Coverage Assessment**
   - Analyze modified files to identify new functionality
   - Check if corresponding tests were added
   - Evaluate test quality and edge case coverage
   - Return: coverage report with missing test scenarios

   **Agent #4: Documentation Validation**
   - Detect if public API or user-facing features changed
   - Verify README.md, API docs, CHANGELOG updated
   - Check for inline code documentation completeness
   - Return: list of missing or outdated documentation

4. **Validate Findings with Haiku Agents**: For each issue found by the 4 agents above, launch a parallel Haiku agent to score confidence (0-100):
   - 0: False positive or pre-existing issue
   - 25: Somewhat confident, might be false positive
   - 50: Moderately confident, real but minor issue
   - 75: Highly confident, real issue impacting functionality
   - 100: Absolutely certain, critical issue

   Filter out issues with confidence score < 80 before including in report.

## Parallel Agent Invocation

Launch agents concurrently using the Task tool:

```
# Fetch PR details first
pr_details = Bash("gh pr view ${pr_number} --json title,body,author,headRefName,baseRefName,files,commits,labels,reviewDecision")
pr_diff = Bash("gh pr diff ${pr_number}")
# For GitLab: glab mr view ${mr_number}, glab mr diff ${mr_number}

# Launch 4 parallel Sonnet agents for analysis
Task(subagent_type: "code-review-enforcer", model: "sonnet", prompt: "Review PR #${pr_number} for code quality issues. Modified files: ${pr_files}. Diff: ${pr_diff}. Return findings with severity and line numbers.")

Task(subagent_type: "security-auditor", model: "sonnet", prompt: "Scan PR #${pr_number} for security vulnerabilities. Focus on auth/crypto changes. Files: ${pr_files}. Return security findings with severity.")

Task(subagent_type: "general-purpose", model: "sonnet", prompt: "Analyze PR #${pr_number} test coverage. New functionality: ${extract_new_features(pr_diff)}. Verify tests added. Return missing test scenarios.")

Task(subagent_type: "general-purpose", model: "sonnet", prompt: "Validate PR #${pr_number} documentation. API changes: ${extract_api_changes(pr_diff)}. Check README/docs updated. Return missing docs.")
```

These agents run independently and results are aggregated in step 5.

5. **Generate Report**: Create structured markdown report with:
   - PR summary (title, description, files changed, commits)
   - Code quality findings (issues, suggestions)
   - Security findings (vulnerabilities, risks)
   - Test coverage analysis
   - Overall recommendation (approve/request changes/comment)

6. **Optional**: Ask user if they want to post review comments to PR

## Output Format

```markdown
# Pull Request Analysis: #123

## Summary
- **Title**: [PR title]
- **Author**: [author]
- **Files Changed**: X files (+Y, -Z lines)
- **Commits**: N commits

## Code Quality ⭐⭐⭐⭐☆
- ✅ Follows coding standards
- ⚠️ Missing error handling in auth.go:45
- ⚠️ Consider extracting helper function in parser.go:120

## Security 🔒
- ✅ No security vulnerabilities detected
- ✅ Authentication changes properly reviewed

## Test Coverage 🧪
- ✅ Unit tests added for new functionality
- ❌ Missing integration tests for API endpoints

## Documentation 📚
- ✅ README.md updated with new feature
- ✅ API documentation current

## Overall Recommendation
**REQUEST CHANGES** - Address error handling and add integration tests

## Action Items
1. Add error handling in auth.go:45
2. Add integration tests for /api/users endpoint
3. Consider refactoring parser.go:120-150
```

## Examples

```bash
# Analyze GitHub PR
/analyze-pr 123

# Analyze GitLab MR
/analyze-pr 456
```
