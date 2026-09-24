# d2 Cheatsheet (for `/gen-diagram`)

This is the runtime reference the `gen-diagram` command reads when synthesizing a `.d2` file. It captures the d2 syntax surface area and icon conventions actually used in production diagrams. Source of truth for d2 itself is https://d2lang.com/.

## Minimal example

```d2
# Top-level config (optional)
vars: {
  d2-config: {
    layout-engine: dagre
    theme-id: 0
  }
}
direction: right

client: Browser {shape: person}
api: API Server
db: Database {shape: cylinder}

client -> api: HTTPS
api -> db: SQL
```

## Nodes and labels

```d2
short_id: "Human Readable Label"
api_gateway.shape: cloud
api_gateway.style.fill: "#eef"
```

- IDs are short snake_case (`api_gw`, `users_db`).
- Labels go on the right of `:` and may contain spaces and punctuation in quotes.
- Dot notation reaches into containers (`prod.api`).

## Connections

```d2
a -> b              # one-way
a <-> b             # bidirectional
a -- b              # undirected
a -> b: "Label"     # labeled edge
a -> b: {           # styled edge
  style.stroke: red
  style.stroke-dash: 3
}
a -> b -> c         # chained
```

Always label edges with the protocol, payload, or trigger: `HTTPS`, `gRPC`, `Kafka: order.created`, `cron 5m`, `webhook`.

## Containers (groups)

```d2
prod: {
  api
  worker
  cache: {shape: cylinder}
}
prod.api -> prod.cache
```

Use containers for trust boundaries (VPC, namespace, account, on-prem). Nest at most 2-3 levels deep.

## Shapes

| Shape | Use for |
| --- | --- |
| `rectangle` (default) | services, generic components |
| `cylinder` | databases, persistent stores |
| `queue` | message queues, streams |
| `cloud` | external services, internet, SaaS |
| `person` | actors, users |
| `c4-person` | C4-style actor |
| `package` | modules, libraries, deployable units |
| `step` | pipeline stages |
| `document` | files, configs |
| `sql_table` | ER diagram tables |
| `class` | UML classes |
| `image` | a node rendered as an icon (use with `icon:`) |

## Icons (icons.terrastruct.com)

Apply with the `icon:` attribute. Confirmed working URL patterns:

```
https://icons.terrastruct.com/aws/<Category>/<Service>_light-bg.svg
https://icons.terrastruct.com/aws/<Category>/<Service>.svg
https://icons.terrastruct.com/gcp/Products%20and%20services/<Category>/<Service>.svg
https://icons.terrastruct.com/dev/<tool>.svg
```

Verified examples:
- AWS EC2: `https://icons.terrastruct.com/aws/Compute/Amazon-EC2_light-bg.svg`
- GCP Compute Engine: `https://icons.terrastruct.com/gcp/Products%20and%20services/Compute/Compute%20Engine.svg`
- PostgreSQL: `https://icons.terrastruct.com/dev/postgresql.svg`
- Redis: `https://icons.terrastruct.com/dev/redis.svg`
- Docker: `https://icons.terrastruct.com/dev/docker.svg`
- Nginx: `https://icons.terrastruct.com/dev/nginx.svg`

```d2
db: PostgreSQL {
  shape: image
  icon: https://icons.terrastruct.com/dev/postgresql.svg
}
```

Notes:
- Spaces in paths must be `%20`-encoded.
- Not every guess works — `dev/kafka` and `tech/kubernetes` 404. When unsure, browse https://icons.terrastruct.com/ first or omit the icon.
- Prefer `_light-bg` variants for embedding on white backgrounds.

## ER diagrams

```d2
users: {
  shape: sql_table
  id: int {constraint: primary_key}
  email: text
  created_at: timestamp
}

orders: {
  shape: sql_table
  id: int {constraint: primary_key}
  user_id: int {constraint: foreign_key}
  total_cents: int
}

orders.user_id -> users.id
```

## Sequence diagrams

```d2
shape: sequence_diagram

client -> api: POST /login
api -> db: SELECT user
db -> api: row
api -> client: 200 OK + JWT
```

The top-level `shape: sequence_diagram` switches the whole diagram into sequence mode.

## Styles

```d2
api.style: {
  fill: "#f0f9ff"
  stroke: "#0369a1"
  stroke-width: 2
  border-radius: 8
  shadow: true
  bold: true
}
```

Common keys: `fill`, `stroke`, `stroke-width`, `stroke-dash`, `border-radius`, `shadow`, `font-color`, `font-size`, `bold`, `italic`, `opacity`, `multiple`, `3d`.

## Layout engines

| Engine | Best for | Notes |
| --- | --- | --- |
| `dagre` | default, most graphs | bundled, fast |
| `elk` | dense graphs, many edges | bundled, more compute |
| `tala` | polished publication-grade | paid, requires Terrastruct account |

```d2
vars: {
  d2-config: {layout-engine: elk}
}
```

## Themes

`theme-id` values worth remembering: `0` (neutral light), `100` (flagship light), `200+` (dark variants), `300+` (terminal). Browse https://d2lang.com/tour/themes for the full catalog.

## Idiomatic templates

### Web app (3-tier)

```d2
direction: right

user: User {shape: person}

cdn: CDN {shape: cloud}

web: {
  lb: Load Balancer
  app1: App Server 1
  app2: App Server 2
  lb -> app1
  lb -> app2
}

data: {
  db: Postgres {
    shape: image
    icon: https://icons.terrastruct.com/dev/postgresql.svg
  }
  cache: Redis {
    shape: image
    icon: https://icons.terrastruct.com/dev/redis.svg
  }
}

user -> cdn: HTTPS
cdn -> web.lb: HTTPS
web.app1 -> data.db: SQL
web.app2 -> data.db: SQL
web.app1 -> data.cache: GET/SET
web.app2 -> data.cache: GET/SET
```

### Microservices (event-driven)

```d2
direction: right

gateway: API Gateway

services: {
  orders: Orders Service
  payments: Payments Service
  shipping: Shipping Service
}

bus: Event Bus {shape: queue}

stores: {
  orders_db: orders.db {shape: cylinder}
  payments_db: payments.db {shape: cylinder}
}

gateway -> services.orders: REST
services.orders -> stores.orders_db: SQL
services.orders -> bus: "order.created"
bus -> services.payments: "order.created"
bus -> services.shipping: "order.created"
services.payments -> stores.payments_db: SQL
```

### C4 container view

```d2
direction: down

user: Customer {shape: c4-person}

system: E-commerce Platform {
  spa: Web SPA
  api: API {shape: package}
  worker: Background Worker {shape: package}
  db: Database {shape: cylinder}
}

stripe: Stripe {shape: cloud}

user -> system.spa: HTTPS
system.spa -> system.api: HTTPS/JSON
system.api -> system.db: SQL
system.api -> stripe: "Charge card"
system.worker -> system.db: SQL
```

### Sequence (auth flow)

```d2
shape: sequence_diagram

user: User
spa: SPA
api: API
db: DB

user -> spa: enter credentials
spa -> api: POST /login
api -> db: SELECT user WHERE email=
db -> api: row + hash
api -> api: bcrypt.compare
api -> spa: 200 OK + JWT
spa -> user: redirect /home
```

### Deployment (AWS)

```d2
direction: down

aws: AWS us-east-1 {
  vpc: VPC {
    public: Public Subnet {
      alb: ALB {
        shape: image
        icon: https://icons.terrastruct.com/aws/Networking%20%26%20Content%20Delivery/Elastic-Load-Balancing_light-bg.svg
      }
    }
    private: Private Subnet {
      ec2: App {
        shape: image
        icon: https://icons.terrastruct.com/aws/Compute/Amazon-EC2_light-bg.svg
      }
      rds: RDS {
        shape: image
        icon: https://icons.terrastruct.com/aws/Database/Amazon-RDS_light-bg.svg
      }
    }
    public.alb -> private.ec2
    private.ec2 -> private.rds
  }
}

internet: Internet {shape: cloud}
internet -> aws.vpc.public.alb: HTTPS
```

### CI/CD pipeline

```d2
direction: right

dev: Developer {shape: person}
repo: GitHub
ci: GitHub Actions {
  build: Build {shape: step}
  test: Test {shape: step}
  lint: Lint {shape: step}
  deploy: Deploy {shape: step}
  build -> test
  test -> lint
  lint -> deploy
}
prod: Production {shape: cloud}

dev -> repo: git push
repo -> ci: webhook
ci.deploy -> prod: kubectl apply
```

## Rules of thumb the LLM must follow

1. One purpose per diagram. Refuse to mix sequence and architecture in the same file.
2. ≤12 primary nodes per view. Use containers (C4-style) when topology is dense.
3. Always label edges with protocol or payload.
4. Snake_case IDs, human-readable labels.
5. Only include icons whose URL is confirmed in this cheatsheet, or omit the icon.
6. Pick `direction: right` for left-to-right flows (request/response, pipelines), `down` for hierarchies (deployment, C4).
7. Default layout: `dagre`. Switch to `elk` only if the result has overlapping edges.
8. Begin every generated `.d2` file with a 1-3 line comment header stating scope and audience.
