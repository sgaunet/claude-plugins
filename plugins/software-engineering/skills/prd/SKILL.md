---
name: prd
description: Create or Update Product Requirement Documents (PRDs) for software projects. Gather requirements, define features, and outline specifications to guide development teams.
---

# PRD Creation Skill

Create structured, dependency-aware Product Requirement Documents using the RPG (Repository Planning Graph) methodology.

## Overview

PRDs bridge the gap between product vision and implementation. This skill uses the RPG method to create PRDs that:
- Separate **WHAT** (functional capabilities) from **HOW** (code structure)
- Define explicit dependencies between components
- Enable topological task ordering for development
- Integrate with task management tools like Task Master

## When to Use

- Starting a new software project
- Planning a major feature or refactor
- Documenting existing system architecture
- Breaking down complex requirements into actionable tasks

## Workflow

### Step 1: Define the Problem (Overview Section)

Gather requirements by answering:
- **Problem**: What pain point exists? Be concrete.
- **Users**: Who experiences it? Define personas.
- **Success metrics**: How do we measure success? Quantifiable outcomes.
- **Why now**: Why don't existing solutions work?

### Step 2: Functional Decomposition (Capabilities)

Think about **what the system does**, not code structure yet.

1. Identify high-level capability domains (e.g., "Data Management", "Authentication")
2. For each capability, enumerate features using explore-exploit:
   - **Exploit**: Required features for core value
   - **Explore**: Features that make the domain complete
3. For each feature, define:
   - Description (one sentence)
   - Inputs (what it needs)
   - Outputs (what it produces)
   - Behavior (key logic)

**Good example:**
```
Capability: Data Validation
  Feature: Schema validation
    - Description: Validate JSON against schemas
    - Inputs: JSON object, schema definition
    - Outputs: Validation result + error details
    - Behavior: Check types, enforce constraints
```

**Bad example:**
```
Capability: validation.js  # This is a FILE, not a capability
Feature: Make sure data is good  # Too vague, no inputs/outputs
```

### Step 3: Structural Mapping (Modules)

Map capabilities to code organization:

1. Each capability → module (folder or file)
2. Each feature → functions/classes within module
3. Define module boundaries (single responsibility)
4. List public exports

```
Capability: Data Validation
  → Maps to: src/validation/
    ├── schema-validator.js
    ├── rule-validator.js
    └── index.js (exports)
```

### Step 4: Dependency Graph (Critical Section)

Define explicit dependencies between modules. This creates the topological order.

**Rules:**
1. List modules in dependency order (foundation first)
2. Foundation modules have NO dependencies
3. Every non-foundation module depends on at least one other
4. No circular dependencies

**Example:**
```
Foundation Layer (no dependencies):
  - error-handling
  - config-manager
  - base-types

Data Layer:
  - schema-validator: Depends on [base-types, error-handling]
  - data-ingestion: Depends on [schema-validator, config-manager]

Core Layer:
  - pipeline-orchestrator: Depends on [data-ingestion]
```

### Step 5: Implementation Roadmap (Phases)

Convert dependency graph into development phases:

1. **Entry criteria**: What must exist before starting
2. **Tasks**: Can be parallelized within phase (no inter-dependencies)
3. **Exit criteria**: Observable outcome proving completion
4. **Delivers**: What users/developers can do after this phase

```
Phase 0: Foundation
  Entry: Clean repository
  Tasks: [error handling, base types, config system]
  Exit: Other modules can import foundation
  Delivers: Development infrastructure ready

Phase 1: Data Layer
  Entry: Phase 0 complete
  Tasks: [schema validator, data ingestion]
  Exit: End-to-end data flow validated
  Delivers: Can ingest and validate data
```

## Template Options

Two templates in `assets/` directory:

| Template | Lines | Use Case |
|----------|-------|----------|
| `example_prd.txt` | ~47 | Quick PRDs, small features |
| `example_prd_rpg.txt` | ~512 | Comprehensive, Task Master integration |

Copy and customize based on project complexity.

## Key Principles

1. **Dual-Semantics**: Think functional AND structural separately, then map them
2. **Explicit Dependencies**: Never assume - always state what depends on what
3. **Topological Order**: Build foundation first, then layers on top
4. **Progressive Refinement**: Start broad, refine iteratively
5. **Atomic Features**: Each feature should be independently testable

## Expected Output

A PRD document containing:
- Problem statement with success metrics
- Capability tree (functional decomposition)
- Repository structure (structural mapping)
- Dependency chain with clear phases
- Implementation roadmap with entry/exit criteria
- Risk assessment and mitigations

The resulting PRD can be parsed into dependency-aware tasks for systematic implementation.

## Resources

- **RPG Method**: Microsoft Research Repository Planning Graph methodology
- **Task Master**: `task-master parse-prd` for automated task generation
- **Conventional Commits**: For changelog integration
