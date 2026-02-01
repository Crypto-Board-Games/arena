# Learnings

## 2026-02-01 Plan Scan
- Plan file: `.sisyphus/plans/arena.md`
- Main TODO checkboxes (top-level): checked: 28, unchecked: 0

## 2026-02-01 Local verification
- `client`: `flutter test` passes; `flutter build web --release` succeeds.
- `server`: `dotnet test` passes; `/health` returns database Connected (SQLite dev fallback).

## 2026-02-01 API smoke
- `POST /api/auth/google` with `dev_bypass_token` returns `access_token`.
- `GET /api/users/me` and `GET /api/rankings` succeed with that token.

## 2026-02-01 Docs
- Added `README.md` with basic run/build instructions and dev auth bypass.
