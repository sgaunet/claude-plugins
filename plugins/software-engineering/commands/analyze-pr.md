---
description: Comprehensive PR review including code quality, security, and test coverage analysis
argument-hint: "<pr-number>"
allowed-tools: Read, Grep, Glob, Bash, mcp__github__, mcp__gitlab-mcp__
---

# Analyze Pull Request Command

Perform comprehensive analysis of a pull request including code review, security scan, and test coverage.

## Process

1. **Detect Repository Type**: Check git remote for GitHub or GitLab
   ```bash
   git remote -v
   ```

2. **Fetch PR Details**: Use appropriate MCP server
   - GitHub: `mcp__github__pull_request_read` (method: get, get_files, get_diff)
   - GitLab: `mcp__gitlab-mcp__get_merge_request`

3. **Analyze Changes**:
   - **Code Quality**: Invoke `code-review-enforcer` agent on modified files
   - **Security**: Invoke `security-auditor` agent if auth/crypto files changed
   - **Test Coverage**: Check if tests added for new functionality
   - **Documentation**: Verify README/docs updated if public API changed

4. **Generate Report**: Create structured markdown report with:
   - PR summary (title, description, files changed, commits)
   - Code quality findings (issues, suggestions)
   - Security findings (vulnerabilities, risks)
   - Test coverage analysis
   - Overall recommendation (approve/request changes/comment)

5. **Optional**: Ask user if they want to post review comments to PR

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
