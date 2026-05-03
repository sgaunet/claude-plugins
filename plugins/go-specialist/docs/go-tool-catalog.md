# Go Tool Catalog

Reference catalog for the `go-tool` skill. Contains detailed module paths, detection heuristics, `go:generate` patterns, and configuration requirements for each supported tool.

## Summary

| Tool | Module Path | Category |
|------|-------------|----------|
| sqlc | `github.com/sqlc-dev/sqlc/cmd/sqlc` | SQL code generation |
| moq | `github.com/matryer/moq` | Mock generation |
| templ | `github.com/a-h/templ/cmd/templ` | HTML templating |
| swag | `github.com/swaggo/swag/cmd/swag` | Swagger/OpenAPI docs (code-first) |
| stringer | `golang.org/x/tools/cmd/stringer` | Enum string generation |
| enumer | `github.com/dmarkham/enumer` | Enhanced enum generation |

---

## sqlc

**Install:** `go get -tool github.com/sqlc-dev/sqlc/cmd/sqlc`

**Detection heuristics:**
- Config file: `sqlc.yml`, `sqlc.yaml`, or `sqlc.json`
- SQL query files: `**/*.sql` alongside a sqlc config

**go:generate directive:**
```go
//go:generate go tool sqlc generate
```

**Config required:** Yes. A `sqlc.yml` (or `.yaml`/`.json`) must define SQL engine, queries path, and output package. Example:
```yaml
version: "2"
sql:
  - engine: "postgresql"
    queries: "query/"
    schema: "schema/"
    gen:
      go:
        package: "db"
        out: "internal/db"
```

**Notes:** Place the `go:generate` directive in the package that owns the generated code (e.g., `internal/db/generate.go`).

---

## moq

**Install:** `go get -tool github.com/matryer/moq`

**Detection heuristics:**
- Existing `*_moq_test.go` files
- Interfaces that need mock implementations for testing
- Existing `//go:generate` directives referencing moq

**go:generate directive:**
```go
//go:generate go tool moq -out mock_store_test.go -pkg mypackage . Store
```

Arguments:
- `-out <file>`: Output file path
- `-pkg <name>`: Package name for generated mocks
- `.`: Source directory containing the interface
- `Store`: Interface name to mock (can list multiple)

**Notes:** Generate mocks in `_test.go` files so they don't ship in production binaries. Prefer moq over gomock for simpler interfaces — no framework dependency required.

---

## templ

**Install:** `go get -tool github.com/a-h/templ/cmd/templ`

**Detection heuristics:**
- Template files: `**/*.templ`

**go:generate directive:**
```go
//go:generate go tool templ generate
```

**Notes:** The `templ generate` command processes all `.templ` files in the module and produces `*_templ.go` files alongside them. Run from the module root. The generated Go files should be committed to version control.

---

## swag

**Install:** `go get -tool github.com/swaggo/swag/cmd/swag`

**Detection heuristics:**
- Swagger annotations in Go source: `// @Summary`, `// @Description`, `// @Router`
- Existing `docs/swagger.json` or `docs/swagger.yaml`

**go:generate directive:**
```go
//go:generate go tool swag init
```

Common flags:
- `-g <file>`: Main API handler file (default: `main.go`)
- `-o <dir>`: Output directory (default: `docs/`)
- `--parseDependency`: Parse dependencies for models

**Notes:** Code-first approach — annotate Go handlers with Swagger comments, then generate the OpenAPI spec. Use swag when your Go code is the source of truth for the API.

---

## stringer

**Install:** `go get -tool golang.org/x/tools/cmd/stringer`

**Detection heuristics:**
- `const` blocks with `iota` patterns (enum-like types)
- Existing `*_string.go` generated files

**go:generate directive:**
```go
//go:generate go tool stringer -type=Color
```

Arguments:
- `-type=<Name>`: Type name to generate `String()` for (comma-separated for multiple)
- `-output=<file>`: Custom output file name

**Notes:** Place the directive in the same file as the type definition. Generates a `String()` method that returns the constant name. Only generates `String()` — for JSON/SQL/text marshaling, use enumer instead.

---

## enumer

**Install:** `go get -tool github.com/dmarkham/enumer`

**Detection heuristics:**
- Same as stringer but when marshaling support is needed (JSON, SQL, text)
- Existing `*_enumer.go` generated files

**go:generate directive:**
```go
//go:generate go tool enumer -type=Color -json -sql -text
```

Common flags:
- `-json`: Generate `MarshalJSON`/`UnmarshalJSON`
- `-sql`: Generate `Scan`/`Value` for database drivers
- `-text`: Generate `MarshalText`/`UnmarshalText`
- `-yaml`: Generate YAML marshaling
- `-trimprefix=<prefix>`: Strip prefix from string representation

**Notes:** Superset of stringer — use one or the other, not both for the same type. Prefer enumer when you need serialization beyond `String()`.

---

## Choosing Between Overlapping Tools

### stringer vs enumer
- **stringer**: Minimal — generates only `String()` method. Use for display-only enums.
- **enumer**: Full-featured — generates `String()` plus JSON, SQL, text, YAML marshaling. Use when enums cross serialization boundaries.

### moq vs gomock/mockery
- **moq**: Simple, no framework. Generates standalone mock structs. Best for small interfaces and unit tests.
- **gomock/mockery**: Framework-based with expectations, call ordering, argument matchers. Better for complex interaction testing.
