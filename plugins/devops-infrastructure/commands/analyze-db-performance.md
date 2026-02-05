---
name: analyze-db-performance
description: Analyze PostgreSQL performance with query and index insights
argument-hint: "<db-connection-string-or-log-file>"
allowed-tools: Read, Grep, Glob, Bash(psql:*), Bash(pg_dump:*), Task
---

# Analyze Database Performance Command

Analyze PostgreSQL database performance using pg_stat_statements, slow query logs, and system metrics.

## Process

1. **Validate Input**: Check if argument is:
   - Database connection string (postgres://...)
   - Path to slow query log file
   - None (will look for local log files)

2. **Gather Performance Data**: Launch 3 parallel Haiku agents to collect database metrics concurrently:

   **Agent #1: Slow Query Analyzer**
   - If connection string: Execute query against pg_stat_statements
     ```sql
     SELECT query, calls, total_exec_time, mean_exec_time, max_exec_time
     FROM pg_stat_statements
     ORDER BY mean_exec_time DESC
     LIMIT 20;
     ```
   - If log file: Parse slow query log and extract patterns
   - Return: list of top 20 slowest queries with execution stats

   **Agent #2: Table Size Analyzer**
   - If connection string: Execute table size query
     ```sql
     SELECT schemaname, tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
     FROM pg_tables
     ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
     ```
   - Return: list of tables sorted by size

   **Agent #3: Index Usage Analyzer**
   - If connection string: Execute index usage query
     ```sql
     SELECT schemaname, tablename, indexname, idx_scan
     FROM pg_stat_user_indexes
     WHERE idx_scan = 0
     ORDER BY pg_relation_size(indexrelid) DESC;
     ```
   - Return: list of unused indexes (candidates for removal)

3. **Launch 2 parallel Sonnet agents** to analyze performance data:

   **Agent #4: PostgreSQL Specialist** (`postgresql-specialist` agent)
   - Analyze slow queries from Agent #1
   - Review table sizes from Agent #2
   - Evaluate index usage from Agent #3
   - Generate optimization recommendations specific to PostgreSQL
   - Return: PostgreSQL-specific findings (indexes, query rewrites, config tuning)

   **Agent #5: General Database Specialist** (`database-specialist` agent)
   - Perform cross-platform analysis of performance patterns
   - Identify anti-patterns (N+1 queries, missing indexes, bloat)
   - Suggest architectural improvements
   - Return: general database optimization recommendations

4. **Aggregate Analysis**: Merge findings from both specialists, prioritizing PostgreSQL-specific recommendations.

## Parallel Data Collection & Analysis Pattern

```
# Step 1: Validate input (sequential)
connection_string = validate_input($argument)

# Step 2: Launch 3 parallel Haiku agents for data collection
if connection_string:
    Task(subagent_type: "general-purpose", model: "haiku", tool: "Bash", command: "psql ${connection_string} -c 'SELECT query, calls, total_exec_time, mean_exec_time, max_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 20;'")

    Task(subagent_type: "general-purpose", model: "haiku", tool: "Bash", command: "psql ${connection_string} -c 'SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(...)) FROM pg_tables ORDER BY ... DESC;'")

    Task(subagent_type: "general-purpose", model: "haiku", tool: "Bash", command: "psql ${connection_string} -c 'SELECT schemaname, tablename, indexname, idx_scan FROM pg_stat_user_indexes WHERE idx_scan = 0 ORDER BY ... DESC;'")

# Wait for all 3 data collection agents to complete
slow_queries = get_task_result(agent1)
table_sizes = get_task_result(agent2)
index_usage = get_task_result(agent3)

# Step 3: Launch 2 parallel Sonnet agents for analysis
Task(subagent_type: "database-specialist", model: "sonnet", prompt: "Analyze PostgreSQL performance data: Slow queries: ${slow_queries}, Table sizes: ${table_sizes}, Index usage: ${index_usage}. Generate optimization recommendations.")

Task(subagent_type: "database-specialist", model: "sonnet", prompt: "Analyze database performance patterns: Slow queries: ${slow_queries}, Table sizes: ${table_sizes}, Index usage: ${index_usage}. Identify anti-patterns and suggest improvements.")

# Step 4: Aggregate analysis from both specialists
# Step 5: Generate unified report (next section)
```

Note: Data collection agents (Haiku) run concurrently since SQL queries are independent. Analysis agents (Sonnet) run concurrently after data collection completes.

5. **Generate Report**:
   - Top N slowest queries with EXPLAIN plans
   - Unused indexes (candidates for removal)
   - Missing indexes (based on WHERE/JOIN patterns)
   - Table bloat analysis
   - Configuration recommendations

5. **Provide Actionable Recommendations**:
   - CREATE INDEX statements
   - DROP INDEX statements (for unused)
   - Query rewrites
   - Configuration changes (shared_buffers, work_mem, etc.)

## Output Format

```markdown
# PostgreSQL Performance Analysis

## Summary
- **Database**: my_app_production
- **Analysis Date**: 2025-12-03
- **Total Queries Analyzed**: 1,234
- **Slow Queries (>1s)**: 15

## Critical Issues 🔴

### 1. Missing Index on users.email
**Query**: `SELECT * FROM users WHERE email = $1`
**Calls**: 10,234 | **Avg Time**: 2,450ms | **Impact**: HIGH

**Recommendation**:
```sql
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

**Expected Improvement**: 95% reduction in query time

---

### 2. Unused Index: idx_posts_legacy
**Size**: 245 MB | **Scans**: 0

**Recommendation**:
```sql
DROP INDEX CONCURRENTLY idx_posts_legacy;
```

**Storage Saved**: 245 MB

---

## Configuration Recommendations

```ini
# Current vs Recommended
shared_buffers = 128MB → 2GB  # 25% of RAM
effective_cache_size = 4GB → 12GB  # 75% of RAM
work_mem = 4MB → 16MB  # For sorting/hashing
```

## Monitoring Queries

```sql
-- Add to monitoring system (run every 5 minutes)
SELECT COUNT(*) as slow_queries
FROM pg_stat_statements
WHERE mean_exec_time > 1000;
```

## Next Steps
1. Apply recommended indexes in order of impact
2. Test query performance in staging
3. Monitor pg_stat_statements after changes
4. Schedule VACUUM ANALYZE
```

## Examples

```bash
# Analyze using connection string
/analyze-db-performance postgres://user:pass@localhost:5432/mydb

# Analyze slow query log file
/analyze-db-performance /var/log/postgresql/slow-queries.log

# Auto-detect local PostgreSQL
/analyze-db-performance
```
