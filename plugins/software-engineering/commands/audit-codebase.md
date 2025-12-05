---
description: Audit codebase for security vulnerabilities, performance issues, and best practices violations. Generate comprehensive report with actionable recommendations.
allowed-tools: Read, Grep, Glob, Bash(find:*), Bash(wc:*), Task
---

Audit the code for potential security vulnerabilities, performance issues, and adherence to best practices. Provide a detailed report with recommendations for improvements.

## Process

1. **Discover Codebase Structure**: Use `Glob` and `Bash` to identify key directories and file types to audit.

2. **Launch 3 parallel Sonnet agents** to independently audit different aspects of the codebase:

   **Agent #1: Security Auditor**
   - Check for exposed secrets or sensitive data
   - Validate input handling to prevent injection attacks
   - Ensure proper authentication and authorization mechanisms
   - Review error handling to avoid information leakage
   - Verify use of secure libraries and dependencies
   - Return findings in format: `{severity: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW", finding: "...", recommendation: "..."}`

   **Agent #2: Performance Analyzer**
   - Identify and optimize slow or inefficient code paths
   - Analyze memory usage and detect potential leaks
   - Review database queries for performance issues
   - Evaluate caching strategies and their effectiveness
   - Return findings in format: `{severity: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW", finding: "...", recommendation: "..."}`

   **Agent #3: Best Practices Reviewer**
   - Ensure adherence to coding standards and style guides
   - Review documentation for completeness and clarity
   - Evaluate test coverage and effectiveness
   - Identify opportunities for code simplification and refactoring
   - Return findings in format: `{severity: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW", finding: "...", recommendation: "..."}`

3. **Aggregate Results**: Collect findings from all 3 agents and merge into unified report.

4. **Prioritize Findings**: Sort by severity (Critical → High → Medium → Low) within each category.

## Agent Invocation Examples

Use the Task tool to launch agents in parallel:

```
Task(subagent_type: "security-auditor", model: "sonnet", prompt: "Audit codebase for security vulnerabilities. Focus on: exposed secrets, injection attacks, auth mechanisms, error handling, dependency security. Return findings with severity levels.")

Task(subagent_type: "general-purpose", model: "sonnet", prompt: "Analyze codebase for performance issues. Focus on: inefficient code paths, memory leaks, database queries, caching strategies. Return findings with severity levels.")

Task(subagent_type: "general-purpose", model: "sonnet", prompt: "Review codebase for best practices adherence. Focus on: coding standards, documentation, test coverage, refactoring opportunities. Return findings with severity levels.")
```

Note: These agents run concurrently and independently, with no cross-dependencies.

## Report Format

Provide a comprehensive report summarizing findings and actionable recommendations for each area reviewed.
Use the following format for the report:

## Security
- [Finding 1]
  - Recommendation: [Actionable recommendation]
- [Finding 2]
  - Recommendation: [Actionable recommendation]

## Performance
- [Finding 1]
  - Recommendation: [Actionable recommendation]
- [Finding 2]
  - Recommendation: [Actionable recommendation]

## Best Practices
- [Finding 1]
  - Recommendation: [Actionable recommendation]
- [Finding 2]
  - Recommendation: [Actionable recommendation]

Ensure the report is clear, concise, and prioritized based on the severity of the findings.