# Mermaid Cheatsheet (for `/gen-readme-diagram`)

Verified Mermaid syntax for README-embedded diagrams. Every construct here renders on
GitHub, GitLab and Forgejo without a build step. Prefer these patterns over invented
syntax — a malformed block renders as a red error box, which is worse than no diagram.

## Minimal example

````markdown
```mermaid
flowchart LR
  user([User]) -->|HTTPS| app[My Service]
  app -->|"TCP 5432: read/write"| db[(PostgreSQL)]
```
````

The fence must be exactly ` ```mermaid ` — lowercase, no attributes, no `{...}`.

## Node shapes

```mermaid
flowchart LR
  a[Rectangle]
  b(Rounded)
  c([Stadium])
  d[[Subroutine]]
  e[(Database)]
  f((Circle))
  g{Decision}
  h{{Hexagon}}
  i[/Parallelogram/]
  j[/Trapezoid\]
```

Conventional mapping used by this command:

| Element | Shape | Example |
|---|---|---|
| Human actor / client | stadium | `user([User])` |
| The application itself | rectangle | `app[Order API]` |
| Internal module | rounded | `store(store)` |
| Relational / document store | cylinder | `db[(PostgreSQL)]` |
| Cache | cylinder | `cache[(Redis)]` |
| Queue / topic / broker | hexagon | `bus{{Kafka}}` |
| Third-party SaaS API | rectangle | `stripe[Stripe API]` |
| Object storage | cylinder | `s3[(S3)]` |
| Scheduled trigger | circle | `cron((cron))` |

## Edges and labels

```mermaid
flowchart LR
  a --> b
  c --- d
  e -->|inline label| f
  g -- spaced label --> h
  i -.-> j
  k -. dotted label .-> l
  m ==> n
  o1 <--> p
```

- `-->` solid arrow (default; use for "calls" / "writes to")
- `-.->` dotted (use for async / event / optional)
- `==>` thick (use for the primary happy path)
- `<-->` bidirectional (use for read-through caches, duplex streams)

**Label every edge** with protocol and purpose: `-->|"HTTPS: submit order"|`, not a bare `-->`.

## Subgraphs and direction

```mermaid
flowchart TB
  user([User]) --> lb[Load balancer]

  subgraph app["Order Service"]
    direction TB
    http(http) --> svc(service)
    svc --> store(store)
  end

  lb --> http
  store --> db[(PostgreSQL)]
```

- Quote the subgraph title when it contains spaces: `subgraph app["Order Service"]`.
- Every `subgraph` needs a matching `end`.
- A nested `direction` applies inside that subgraph only.
- Edges may cross subgraph boundaries; declare them after the subgraph closes.

## Styling (theme-safe)

READMEs are read in both light and dark themes. A hardcoded light `fill` with no `color`
makes label text invisible in dark mode.

```mermaid
flowchart LR
  classDef external fill:#e8e8e8,stroke:#666,color:#111
  classDef datastore fill:#dbeafe,stroke:#3b82f6,color:#111

  app[My Service]
  db[(PostgreSQL)]:::datastore
  stripe[Stripe API]:::external

  app --> db
  app --> stripe
```

**Rule: set `fill`, `stroke` and `color` together, or set none of them.** Omitting styling
entirely is always safe and usually looks better — the host renderer picks theme-aware
defaults. Never use `style` on an id you also target with `classDef`.

## Sequence diagrams

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant API as Order API
  participant DB as PostgreSQL
  participant PAY as Stripe

  U->>API: POST /orders
  API->>DB: INSERT order (pending)
  DB-->>API: order_id
  API->>PAY: create PaymentIntent
  alt payment authorized
    PAY-->>API: succeeded
    API->>DB: UPDATE order SET paid
  else declined
    PAY-->>API: card_declined
    API->>DB: UPDATE order SET failed
  end
  API-->>U: 201 Created
```

Arrows: `->>` solid with head (request), `-->>` dotted with head (response),
`-x` / `--x` async terminated, `-)` / `--)` async open.

Blocks that each require a closing `end`: `alt`/`else`, `opt`, `loop`, `par`/`and`,
`critical`/`option`, `break`, `rect`.

- Declare every lifeline with `participant` or `actor` **before first use**, using
  `participant SHORT as Long Label` so the arrows stay readable.
- Keep to <= 6 lifelines and <= 15 messages. One flow per diagram.
- `Note over A,B: text` for constraints worth calling out.

## ER diagrams

```mermaid
erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ ORDER_LINE : contains
  PRODUCT ||--o{ ORDER_LINE : "appears in"

  CUSTOMER {
    uuid id PK
    text email
    timestamptz created_at
  }
  ORDER {
    uuid id PK
    uuid customer_id FK
    numeric total
    text status
  }
```

Cardinality tokens (left glyph mirrors the right):

| Token | Meaning |
|---|---|
| `\|o` / `o\|` | zero or one |
| `\|\|` | exactly one |
| `}o` / `o{` | zero or more |
| `}\|` / `\|{` | one or more |

`--` identifying relationship, `..` non-identifying. The `: label` is required — quote it
if it contains spaces. Entity names are conventionally UPPER_SNAKE_CASE.

## Syntax footguns

These are the failures that actually happen. Check every generated block against them.

1. **Reserved words as node ids.** `end` is the worst offender — it silently breaks the
   whole flowchart. Also avoid `graph`, `subgraph`, `class`, `classDef`, `click`, `style`,
   `linkStyle`, `direction`, `default`, and bare `o` / `x` (which parse as edge endings in
   `A---oB`). Suffix instead: `end_node`, `style_mod`.
2. **Unquoted punctuation in labels.** Any label containing `()`, `[]`, `{}`, `:`, `;`,
   `,`, `#`, `"`, `/` or `-->` must be quoted: `api["/v1/orders (public)"]`.
3. **Line breaks.** Use `<br/>`, never `\n`: `db[("PostgreSQL<br/>primary")]`.
4. **Literal quotes** inside a quoted label need the entity: `a["say &quot;hi&quot;"]`.
5. **Unbalanced `subgraph` / `end`**, and unclosed `alt` / `loop` / `opt` / `par`.
6. **Missing flowchart direction.** Always declare `flowchart LR` or `flowchart TB`.
7. **Undeclared sequence lifelines** — a typo'd participant silently creates a new column.
8. **Semicolons** are optional; do not mix styles within one diagram.
9. **Comments** are `%% comment` on their own line — `#` and `//` are not comments.
10. **Blank lines inside a `subgraph` body** render inconsistently on older GitLab; keep
    subgraph bodies contiguous.

## Renderer support

| Target | Renders ` ```mermaid `? |
|---|---|
| GitHub (repo README, issues, PRs) | Yes, native |
| GitLab (self-managed and .com) | Yes, native |
| Forgejo / Gitea | Yes, when enabled in `app.ini` markup settings (default on in recent releases) |
| <https://mermaid.live/> | Yes — use to debug a parser error |
| npm / PyPI / crates.io README viewers | **No** — block shows as plain text |
| VS Code preview | With the Markdown Preview Mermaid extension |

If the project publishes to npm or PyPI, mention in the section prose that the rendered
diagrams live on the repository page.

## Idiomatic templates

### System context — web service

The global view. The application is **one** node; actors left, dependencies right.

```mermaid
flowchart LR
  user([Customer])
  admin([Operator])

  app[Order Service]

  db[(PostgreSQL)]
  cache[(Redis)]
  stripe[Stripe API]
  mail[SendGrid]

  user -->|"HTTPS: browse, order"| app
  admin -->|"HTTPS: admin UI"| app
  app -->|"TCP 5432: orders, customers"| db
  app <-->|"sessions, rate limits"| cache
  app -->|"REST: charge card"| stripe
  app -.->|"SMTP: receipts"| mail
```

### System context — CLI tool

```mermaid
flowchart LR
  user([Operator]) -->|"argv, stdin"| cli[mytool]
  cli -->|"read/write"| fs[(Local filesystem)]
  cli -->|"HTTPS: REST v3"| gh[GitHub API]
  cli -->|"stdout, exit code"| user
  cfg[(~/.mytool.yaml)] -.->|"defaults"| cli
```

### System context — library

Only worth drawing when the library has real external dependencies.

```mermaid
flowchart LR
  host[Consuming application] -->|"import, call API"| lib[mylib]
  lib -->|"database/sql driver"| db[(PostgreSQL)]
  lib -.->|"optional: metrics"| prom[Prometheus]
```

### Component view — layered service

Second diagram at tier `component`: opens the box, shows which module owns which dependency.

```mermaid
flowchart TB
  client([Client])

  subgraph svc["Order Service"]
    direction TB
    http(http<br/>handlers) --> usecase(service<br/>business rules)
    usecase --> store(store<br/>repositories)
    usecase --> pub(events<br/>publisher)
  end

  client -->|HTTPS| http
  store -->|"SQL"| db[(PostgreSQL)]
  pub -.->|"publish order.created"| bus{{Kafka}}
  usecase -->|"REST"| stripe[Stripe API]
```

### Component view — multi-service

```mermaid
flowchart TB
  user([User])
  gw[API Gateway]

  subgraph services["Deployable services"]
    direction LR
    api[order-api]
    worker[order-worker]
    sched[reconciler]
  end

  user -->|HTTPS| gw
  gw -->|"HTTP: /v1/*"| api
  api -->|"SQL"| db[(PostgreSQL)]
  api -.->|"publish"| bus{{Kafka}}
  bus -.->|"consume order.created"| worker
  worker -->|"SQL"| db
  sched -->|"nightly: settle"| db
```

### Primary flow — sequence

Third diagram at tier `full`. Pick the single most important end-to-end path.

```mermaid
sequenceDiagram
  autonumber
  actor U as User
  participant API as order-api
  participant DB as PostgreSQL
  participant B as Kafka
  participant W as order-worker

  U->>API: POST /v1/orders
  API->>DB: INSERT order (pending)
  DB-->>API: order_id
  API->>B: publish order.created
  API-->>U: 202 Accepted
  B-->>W: order.created
  W->>DB: reserve inventory
  alt reserved
    W->>DB: UPDATE order SET confirmed
  else out of stock
    W->>DB: UPDATE order SET rejected
  end
```

### Data model — ER

Fourth diagram at tier `full`, and only when >= 3 related entities were discovered.

```mermaid
erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ ORDER_LINE : contains
  PRODUCT ||--o{ ORDER_LINE : "appears in"

  CUSTOMER {
    uuid id PK
    text email
  }
  ORDER {
    uuid id PK
    uuid customer_id FK
    text status
  }
  ORDER_LINE {
    uuid id PK
    uuid order_id FK
    uuid product_id FK
    int quantity
  }
```

## Complexity to diagram set

| Score | Tier | Diagrams |
|---|---|---|
| 0, no external systems | `none` | none — prose only |
| 1-3 | `context` | system context |
| 4-7 | `component` | system context + component view |
| >= 8 | `full` | + primary flow, + data model (only if >= 3 related entities) |

## Rules of thumb the LLM must follow

1. One purpose per diagram. Never mix a flow and a topology in the same block.
2. The system context diagram renders the application as exactly **one** node. Internals
   belong in the component view.
3. <= 15 nodes per diagram, <= 4 diagrams total. Beyond that, point the reader at
   `/gen-diagram` instead of cramming the README.
4. Every edge carries a label naming the protocol and the purpose.
5. Short lowercase ids, human-readable quoted labels: `db[("PostgreSQL 16")]`.
6. `flowchart LR` for request/response and context views, `flowchart TB` for layering and
   containment.
7. Prefer no `classDef` at all; when styling, set `fill`, `stroke` and `color` together.
8. Never invent a dependency. Only draw systems that were actually found in the repo.
9. Precede each diagram with one sentence saying what the reader should take from it.
10. If a diagram would only restate the prose, omit it and say why.
