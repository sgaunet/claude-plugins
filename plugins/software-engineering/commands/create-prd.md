---
description: Create Product Requirement Document using PRD methodology. Invokes the prd skill to gather requirements and define features.
argument-hint: "<feature-to-design>"
allowed-tools: Read, Grep, Glob, Write, Skill, AskUserQuestion
---

# Create PRD Command

Create a PRD (Product Requirement Document) for the current software project.

## Process

1. Think hard about the product requirements using the RPG (Repository Planning Graph) methodology. The feature you are think about is: `$argument`

When thinking, do not make assumptions, always ask clarifying questions about:
- Problem statement
- User personas
- Functional capabilities
- Dependencies between features

Don't overengineer, focus on core value first.

2. Initialize PRD Creation: Use the `prd` skill to gather requirements and define features.
3. Review and Refine: Iterate on the PRD structure, ensuring clarity and completeness.

