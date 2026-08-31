# Session Log
**Updated:** 2026-08-31
**Active skill:** software-project (v0.2 execution — M13 complete, entering M14)
**Last confirmed state:** M13 complete (Bug F closed, CI 2/2 green on run 33410691779). M14 next.

## What happened this session
Completed Milestone M13 (Incremental Renderer / Bug F fix):
1. **Incremental ops & observer refactor (Tasks 086–087):** Replaced flat observer storage with per-node dicts (`_plot_observers`, `_axis_observers`) to prevent observer leaks on node removal. Built headless-testable incremental operations `_add_plot_handle!`, `_remove_plot_handle!`, `_add_axis!`, `_remove_axis!` mutating only changed Makie handles.
2. **Structural funnel (Task 088):** Introduced `apply_structural!` funnel with four op structs (`AddPlotOp`, `RemovePlotOp`, `AddAxisOp`, `RemoveAxisOp`), providing a single mutation path for headless-direct and live-queued operations.
3. **Interactive-thread requirement (Task 089):** Added `_has_interactive_thread()` check in `makieviews()`, failing fast with actionable instructions if Julia was started without an interactive thread (`--threads N,1`).
4. **Live mutation queue & g_idle_add drain (Task 090):** Implemented thread-safe mutation queue on `Renderer` drained on the GLib main thread via `Gtk4.GLib.g_idle_add()`. Started GLib loop in `makieviews()` for non-interactive test harnesses. Added xvfb-gated smoke test `test/integration/live_structural.jl`.
5. **M13 Exit (Task 091):** Updated `CHANGELOG.md` with the v0.2 / Bug F entry. Verified CI green on GitHub Actions across both Julia 1.10 and 1.12 with all 6 live structural editing assertions executing and passing under `xvfb-run` (Run ID: 33410691779, URL: https://github.com/XerxesZorgon/FigureViews.jl/actions/runs/33410691779).

Commits for M13:
- 1888c97 — render: incremental plot ops + per-node observer storage (M13 Task 086)
- 5850d4b — render: incremental axis ops _add_axis! _remove_axis! (M13 Task 087)
- 0fd156e — render: apply_structural! funnel headless-direct branch (M13 Task 088)
- 1fcb3df — feat: interactive-thread startup check in makieviews() (M13 Task 089)
- cd1aaae — fix: start GLib main loop in makieviews() for g_idle_add drain (M13 Task 090)

## Next action
Begin Milestone M14: Live GUI structural editing (connecting existing tree/property panes to mutate structure live via the `apply_structural!` funnel).

