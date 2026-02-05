---
name: check-claude-md-tokens
description: Monitor and optimize CLAUDE.md token count to stay under 2500 token limit
allowed-tools: Read, Edit, Bash(wc:*), Bash(awk:*)
---

# CLAUDE.md Token Counter Command

Monitor the token count of CLAUDE.md files to ensure they stay within the recommended 2500 token limit. This command analyzes the current token usage and provides reduction recommendations when the limit is exceeded.

## Process

1. **Locate CLAUDE.md Files**: Find all CLAUDE.md files in the repository:
   - Project-level: `./CLAUDE.md`
   - Global user config: `~/.claude/CLAUDE.md`

2. **Calculate Token Count**: Use character-based estimation (~4 characters per token):
   ```bash
   wc -c CLAUDE.md | awk '{print int($1/4)}'
   ```

3. **Evaluate Against Limit**: Check if token count exceeds 2500 tokens

4. **Report Status**: Display current token usage with clear status indicator:
   - ✅ Under limit (< 2500 tokens)
   - ⚠️ Near limit (2000-2500 tokens)
   - ❌ Over limit (> 2500 tokens)

5. **Offer Reduction**: If over limit, analyze content and propose specific reductions

## Token Count Formula

**Estimation**: `tokens ≈ characters ÷ 4`

This rough estimate works well for English text. The actual token count may vary slightly based on:
- Word length and complexity
- Technical terminology
- Code snippets
- Formatting characters

## Reduction Strategies

When CLAUDE.md exceeds the token limit, apply these optimization techniques:

### 1. Remove Redundancy
- Eliminate duplicate instructions
- Consolidate similar rules
- Remove verbose explanations

### 2. Use Concise Language
- Replace verbose phrases with concise alternatives
- Remove filler words and redundant modifiers
- Use bullet points instead of paragraphs

### 3. Externalize Content
- Move detailed examples to separate documentation
- Reference external guides instead of duplicating content
- Create auxiliary files for extensive specifications

### 4. Prioritize Critical Instructions
- Keep only essential directives
- Remove nice-to-have preferences
- Focus on behavior-changing instructions

### 5. Optimize Formatting
- Use abbreviations for repeated terms
- Reduce whitespace and empty lines
- Compress nested lists

## Output Format

```
📊 CLAUDE.md Token Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: ./CLAUDE.md
Characters: 12,450
Estimated Tokens: 3,112
Limit: 2,500
Status: ❌ OVER LIMIT (+612 tokens)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Recommendation: Reduce by approximately 2,448 characters (612 tokens)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Automatic Reduction

When offering to reduce CLAUDE.md, analyze the content and propose specific edits:

1. **Identify Verbose Sections**: Find areas with high word count but low information density
2. **Propose Specific Cuts**: Show exact lines or sections to remove
3. **Maintain Functionality**: Ensure core instructions remain intact
4. **Preview Changes**: Show before/after comparison
5. **Request Approval**: Always get user confirmation before editing

## Best Practices

- **Run Regularly**: Check token count when updating CLAUDE.md
- **Preemptive Optimization**: Stay well under 2500 to allow for growth
- **Quality Over Quantity**: Focus on high-impact instructions
- **Version Control**: Commit before making large reductions
- **Track History**: Document what was removed and why

## Example Usage

```bash
# Check current project CLAUDE.md
/check-claude-md-tokens

# Check global CLAUDE.md
/check-claude-md-tokens ~/.claude/CLAUDE.md

# Check specific file
/check-claude-md-tokens path/to/CLAUDE.md
```

## Error Handling

- **File Not Found**: Inform user if CLAUDE.md doesn't exist
- **Permission Issues**: Handle read/write permission errors
- **Invalid Path**: Validate file paths before processing
- **Backup Failures**: Ensure safe editing with fallback options

## Integration Notes

This command works alongside:
- **audit-codebase**: Ensures CLAUDE.md follows best practices
- **create-prd**: Helps maintain concise project documentation
- **commit**: Documents CLAUDE.md changes with proper commit messages
