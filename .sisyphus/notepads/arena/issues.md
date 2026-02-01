# Issues

## 2026-02-01 Gemini/Antigravity
- `stitch_check_antigravity_auth` can report status=valid, but `stitch_generate_design_asset` fails with "Antigravity project ID not found".
- Side effect: a stray `nul` file can appear (ignored via `.gitignore`).

## 2026-02-01 delegate_task instability
- `delegate_task` frequently fails immediately (e.g. "Send prompt failed" / JSON parse error) and can still mutate files unexpectedly.
- Treat subagent delegation as unreliable in this workspace; prefer direct local verification and edits until fixed.

## 2026-02-01 .NET runtime mismatch
- Plan targets .NET 8, but this environment only has .NET 10 runtime (`Microsoft.NETCore.App 10.0.0`).
- Downgrading projects to net8 breaks `dotnet test` with missing framework 8.0.0.
- Current workaround: keep projects on net10 so tests/build can run here.
