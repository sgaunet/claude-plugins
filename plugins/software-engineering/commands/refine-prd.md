---
description: Review and refine existing PRD by identifying unclear statements, gaps, and ambiguities. Ask clarifying questions and update document.
argument-hint: "<path-to-prd-file>"
---

# Refine PRD Command

Review and refine an existing PRD document by identifying unclear statements, gaps, and ambiguities.

## Process

1. **Read PRD**: Load the PRD file: `$ARGUMENTS`

2. **Analyze for Issues**: Systematically review each section for:

   **Clarity Issues**
   - Vague language ("should work well", "handle appropriately")
   - Undefined terms or acronyms
   - Ambiguous requirements ("fast", "scalable", "user-friendly")

   **Completeness Gaps**
   - Missing inputs/outputs for features
   - Undefined behaviors or edge cases
   - Incomplete success metrics (not quantifiable)
   - Missing dependency declarations

   **Structural Problems**
   - Circular dependencies between modules
   - Missing phases or unclear phase boundaries
   - No entry/exit criteria for phases

   **Technical Concerns**
   - Unstated assumptions
   - Missing error handling considerations
   - Unclear integration points

3. **Ask Clarifying Questions**: For each identified issue, use AskUserQuestion to gather specific information. Group related questions together (max 4 per interaction).

4. **Update PRD**: Integrate the user's answers into the document:
   - Replace vague statements with concrete specifications
   - Add missing information inline
   - Fix structural issues
   - Document assumptions explicitly

5. **Validate**: After refinement, verify:
   - All capabilities have inputs/outputs/behaviors defined
   - All dependencies are explicit and non-circular
   - All phases have entry/exit criteria
   - Success metrics are quantifiable

## Analysis Checklist

| Section | Check For |
|---------|-----------|
| Problem Statement | Concrete pain point, specific users |
| Success Metrics | Quantifiable, measurable outcomes |
| Capabilities | Clear descriptions, defined I/O |
| Features | Inputs, outputs, behaviors specified |
| Dependencies | Explicit, no circular refs |
| Phases | Entry/exit criteria, deliverables |
| Risks | Mitigations defined |

## Output

A refined PRD with:
- Clear, unambiguous language
- Complete feature specifications
- Explicit dependencies
- Validated structure
