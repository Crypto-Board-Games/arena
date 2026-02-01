# Problems

## 2026-02-01 PostgreSQL not available
- Plan requires PostgreSQL (and `/health` must report database Connected).
- This environment has no `psql` and no `postgresql.service`, and port 5432 is closed.
- Current `/health` output is Unhealthy: "Failed to connect to 127.0.0.1:5432".

## 2026-02-01 Update
- Mitigation implemented: SQLite dev fallback + auto-create schema.
- `/health` now reports database Connected when using SQLite.
