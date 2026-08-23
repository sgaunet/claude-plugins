---
name: go-structure
description: Recommend and scaffold Go project layouts by type (CLI, API, library, monorepo). Use when starting a Go project, when asked about package organization, or when reviewing structure for anti-patterns (utils packages, over-nesting, misused pkg/).
user-invocable: true
allowed-tools: Read, Write, Glob, Grep, Bash(go:*), Bash(mkdir:*)
---

# Go Project Structure

Recommend and scaffold idiomatic Go project layouts. Matches structure to project type and size — start simple, grow when needed.

## When to Use

- Initializing a new Go project or module
- User asks about project layout or directory organization
- Reviewing an existing project for structural anti-patterns
- Migrating from flat layout to a more structured one
- Setting up a monorepo with multiple services

## Prerequisites

1. **go.mod exists or will be created**: The project must be a Go module.
2. **Project type is known or inferrable**: CLI tool, REST API, library, or monorepo.

## Core Principle

**Simplicity first, complexity when necessary.** Do not impose structure upfront. Let it emerge from actual needs. A single `main.go` is a valid starting point.

## Anti-Patterns to Flag

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Generic package names (`utils`, `helpers`, `common`, `base`) | Become dumping grounds, convey no intent | Rename to specific purpose: `validator`, `auth`, `cache` |
| Over-nesting (`internal/services/user/handlers/http/v1/`) | Cognitive load, cumbersome imports | Flatten to `internal/user/handler.go` |
| Circular dependencies (`A` imports `B`, `B` imports `A`) | Compilation error, poor separation | Extract shared types into a separate package or use interfaces |
| Business logic in HTTP handlers | Couples domain to transport, hard to test | Move to service layer, handlers only do HTTP concerns |
| The `main.go` monster (all logic in one file) | Untestable, circular deps, impossible to maintain | Extract into packages; `main.go` only wires deps and starts |
| Shared database across microservices | Distributed monolith, schema changes break all services | Each service owns its data; communicate via APIs |
| Using `pkg/` for non-library code | Misleading signal, unnecessary indirection | Move to `internal/` or project root |
| Premature `cmd/` for single-binary projects | Unnecessary nesting | Keep `main.go` at root until multiple binaries are needed |
| Hardcoded DB credentials / config values | Security risk, not deployable across environments | Use env vars or config system; never commit secrets |

## Workflow: Recommend Structure

### Step 1: Detect Project Type

Analyze the codebase to classify:

| Signal | Project Type |
|---|---|
| Single `main.go` at root, flag/cobra imports | CLI tool |
| `net/http` or framework imports (gin, chi, echo, fiber) | REST API service |
| No `main.go`, only library packages | Reusable library |
| Multiple `main.go` under `cmd/`, one `go.mod` | Monorepo / multi-binary (single module) |
| Several `go.mod` files + a `go.work` | Multi-module workspace |
| `go.mod` only, empty or minimal | New project (ask user) |

### Step 2: Recommend Layout

Based on project type and current size, recommend the appropriate layout from the reference patterns below.

**Sizing rules:**
- **Small** (<10 Go files): Flat layout, no directories needed
- **Medium** (10–30 Go files): Introduce `internal/` with feature-based packages
- **Large** (30+ Go files or multiple binaries): Full `cmd/` + `internal/` structure

### Step 3: Report Findings

For existing projects, present a table of findings:

| Finding | Severity | Recommendation |
|---|---|---|
| `utils/` package detected | Warning | Rename to specific purpose |
| Business logic in `handler.go` | Warning | Extract to `service.go` |
| No `internal/` for private code | Info | Consider `internal/` as project grows |

## Reference Layouts

### Flat Layout (Small CLI / Tool)

For single-purpose tools and prototypes. Grow from here.

```
mytool/
├── main.go
├── go.mod
├── go.sum
└── README.md
```

### CLI Application (Cobra/Viper)

```
mytool/
├── main.go
├── command/
│   ├── root.go
│   └── version.go
├── go.mod
└── README.md
```

### REST API Service

Organize by feature/domain, not by technical layer.

```
myapi/
├── cmd/
│   └── api/
│       └── main.go          # Minimal: wire deps, load config, start
├── internal/
│   ├── config/
│   │   └── config.go
│   ├── middleware/
│   │   └── auth.go
│   ├── user/                 # Feature package
│   │   ├── handler.go        # HTTP concerns only
│   │   ├── handler_test.go
│   │   ├── service.go        # Business logic
│   │   ├── service_test.go
│   │   ├── repository.go     # Data access interface + implementation
│   │   └── repository_test.go
│   └── product/
│       ├── handler.go
│       ├── service.go
│       └── repository.go
├── go.mod
└── README.md
```

**Key rule**: `cmd/*/main.go` is minimal — only dependency wiring, config loading, and server start. All logic lives in `internal/`.

#### Layer Responsibilities Inside a Feature Package

Each file in a feature package (`internal/user/`) has a clear, single responsibility:

| File | Layer | Responsibility | Imports |
|---|---|---|---|
| `handler.go` | Transport | HTTP request/response only: parse input, call service, write response. No business logic. | `net/http`, service interface |
| `service.go` | Business | Domain logic and orchestration. Validates rules, coordinates repositories. Pure Go — no HTTP, no SQL. | Repository interface, domain types |
| `repository.go` | Data access | Defines the `Repository` interface (port) AND its implementation. Talks to DB. | `database/sql`, domain types |
| `model.go` | Domain | Entities, value objects, custom error types. No external dependencies. | Standard library only |

**Dependency flow**: Handler → Service → Repository (interfaces). Dependencies always point inward.

#### Dependency Injection Wiring

Services receive their dependencies as interfaces via constructors — never create them internally:

```go
// internal/user/repository.go — define the interface (port)
type Repository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

// internal/user/service.go — accept interface, not concrete type
type Service struct {
    repo Repository
}

func NewService(repo Repository) *Service {
    return &Service{repo: repo}
}

// cmd/api/main.go — wire everything together
func main() {
    db := connectDB()
    userRepo := user.NewPostgresRepository(db)
    userService := user.NewService(userRepo)
    userHandler := user.NewHandler(userService)
    // ... register routes
}
```

This keeps services testable (mock the interface) and swappable (change DB without touching business logic).

### Hexagonal / DDD (Large Service)

For complex domain logic with clear port/adapter separation.

```
myservice/
├── cmd/
│   └── api/
│       └── main.go
├── internal/
│   ├── domain/
│   │   └── user/
│   │       ├── entity.go       # Domain models, value objects
│   │       ├── repository.go   # Port (interface)
│   │       └── service.go      # Domain services
│   ├── application/
│   │   └── user/
│   │       ├── create_user.go  # Use case
│   │       ├── get_user.go     # Use case
│   │       └── service.go      # Orchestration
│   └── adapter/
│       ├── http/
│       │   └── user_handler.go # Inbound adapter
│       ├── postgres/
│       │   └── user_repo.go    # Outbound adapter (implements port)
│       └── redis/
│           └── cache.go        # Outbound adapter
├── api/
│   └── openapi.yaml
├── go.mod
└── README.md
```

**Dependency rule**: Dependencies flow inward. Domain has zero external imports. Adapters implement domain interfaces.

### Reusable Library

Only use `pkg/` when code is intended for external import.

```
mylib/
├── mylib.go              # Public API at package root
├── mylib_test.go
├── internal/
│   └── parser/           # Private implementation
│       ├── parser.go
│       └── parser_test.go
├── go.mod
└── README.md
```

### Monorepo (Multiple Services)

```
myproject/
├── cmd/
│   ├── api/
│   │   └── main.go
│   ├── worker/
│   │   └── main.go
│   └── scheduler/
│       └── main.go
├── internal/
│   ├── shared/            # Shared internal packages
│   ├── api/               # API-specific code
│   ├── worker/            # Worker-specific code
│   └── scheduler/         # Scheduler-specific code
├── go.mod                 # ONE module for the whole repo
└── README.md
```

**Generator caveat:** `/gen-goreleaser` and `/gen-taskfiles` emit a *single-binary*
build by default. After scaffolding several `cmd/*` binaries, add one `builds:`
entry per binary to `.goreleaser.yml` and extend the `build` task in
`Taskfile.yml`, or those binaries never get built or released.

**No `go.work` here.** A workspace file exists to union *several* modules; a repo
with a single `go.mod` does not need one, and the Go docs advise against
committing `go.work` in the first place. Reach for a workspace only when the repo
genuinely holds multiple `go.mod` files (each service its own module, no shared
root module) — then `go.work` is a local-development convenience, typically
git-ignored rather than checked in.

## Note: `internal/` is enforced, not conventional

`internal/` is a rule the Go compiler applies, not a naming habit: a package under
`.../internal/x` can only be imported by code rooted at `...` — the directory
*containing* `internal` — and this holds at any nesting depth. That is what makes
it a real boundary rather than a hint, and why it is the right home for code you
do not want external consumers importing. See
<https://pkg.go.dev/cmd/go#hdr-Internal_Directories>.

## Workflow: Scaffold Structure

When creating a new project or restructuring:

### Step 1: Confirm Project Type

Ask user to confirm the detected or intended project type if ambiguous.

### Step 2: Create Directories

Create only the directories needed for the chosen layout. Do not create empty placeholder directories.

### Step 3: Create Minimal Files

For new projects, create:
- `main.go` with minimal bootstrap code (for binaries)
- Package files with package declaration and doc comment

### Step 4: Validate

```bash
go build ./...
go vet ./...
```

## Organizing by Feature vs Layer

**Prefer feature-based organization:**

```
# Good: organized by domain
internal/
├── user/
│   ├── handler.go
│   ├── service.go
│   └── repository.go
└── order/
    ├── handler.go
    ├── service.go
    └── repository.go
```

```
# Avoid: organized by layer
internal/
├── handlers/
│   ├── user.go
│   └── order.go
├── services/
│   ├── user.go
│   └── order.go
└── repositories/
    ├── user.go
    └── order.go
```

Feature-based packages are self-contained, reduce cross-package imports, and make it easy to understand a domain in one place.

## Workflow: Review Layer Violations

When reviewing an existing project, check for these structural violations:

### Step 1: Scan for Logic in Handlers

Grep handler files for signs of business logic leaking into the transport layer:

- Direct SQL queries (`db.Query`, `db.Exec`) in handler files
- Complex conditionals or domain validation beyond input parsing
- Direct calls to external services (HTTP clients, message queues)

### Step 2: Scan for Transport in Services

Check service files for HTTP or framework imports that don't belong:

- `net/http` imports in service layer
- Framework-specific types (gin.Context, echo.Context) in service signatures
- JSON marshaling in service code

### Step 3: Check Dependency Direction

Verify dependencies flow inward (handler → service → repository):

- Services must not import handler packages
- Repositories must not import service packages
- Domain types must not import infrastructure packages

### Step 4: Report

| File | Violation | Severity | Fix |
|---|---|---|---|
| `user/handler.go` | Contains `db.Query` call | Error | Move to repository |
| `order/service.go` | Imports `net/http` | Warning | Accept domain types, not HTTP types |
| `auth/handler.go` | 50+ lines of validation logic | Warning | Extract to service method |

## Error Handling

| Condition | Action |
|-----------|--------|
| No `go.mod` found | Ask if user wants to run `go mod init` |
| Project type ambiguous | Ask user to confirm type before recommending |
| Circular dependency detected | Report the cycle and suggest extraction of shared types |
| `utils/` or `helpers/` package found | Flag as anti-pattern, suggest specific name |
