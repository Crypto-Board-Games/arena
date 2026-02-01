# Decisions

## 2026-02-01 Database fallback for local dev
- Use SQLite (`Data Source=arena.db`) in Development when `DefaultConnection` is not a Postgres connection string.
- Rationale: this environment has no PostgreSQL server/container runtime available; SQLite keeps local runs and `/health` usable.
