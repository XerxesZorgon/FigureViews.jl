# Session Log
**Updated:** 2026-08-28
**Active skill:** software-project
**Last confirmed state:** Task 075 — in progress (awaiting General registry AutoMerge)

## What happened this session

M11 executed in full: docs reconciled (ADR-022, README, SDD, CHANGELOG, PLAN), Tasks 068–075 completed or closed, Windows QA passed, macOS CI confirmed infeasible for v0.1 (ADR-023 — using MakieViews unconditionally loads GLMakie; reverted to Ubuntu-only CI). Release commit 3d4da4a tagged as v0.1.0 and pushed. JuliaRegistrator opened General registry PR #166500; AutoMerge confirmed all guidelines met and is waiting out the mandatory 3-day new-package window (opened Aug 29, merge expected ~Sept 1). John also built docs/Makie_Functions.mdx — a full tree-list of Makie's public API surface (Blocks, 40+ plot types, attributes, transforms, lighting, SSAO) — as the v0.2 feature inventory.

## Decisions made (not yet in an ADR)

- macOS CI (conditional backend loading — guard GLMakie/Gtk4Makie imports behind ENV["MAKIEVIEWS_BACKEND"] or Preferences.jl) is a v0.2 backlog item; pairs with the GUI/headless split.
- Exact Makie/GLMakie/CairoMakie compat pins retained for v0.1.0 (reproducibility; AutoMerge accepts them; GLMakie upstream-pins Makie anyway).
- Makie_Functions.mdx to be committed to docs/ and used as the v0.2 feature inventory before v0.2 planning begins.

## Blocked on / open question

- Task 075 not fully done: waiting on General PR #166500 to merge (~Sept 1). On merge: run ] add MakieViews in a fresh Julia env, confirm it resolves, mark Task 075 [x] Done, commit tasks.md, push.
- v0.2 planning hasn't started — no Cowork session, no ADRs. The Makie_Functions.mdx inventory and the v0.2 backlog items in RELEASE-READINESS.md §Post-v0.1.0 are the starting materials.

## Next action

Two things, in order:

1. Confirm Task 075: check https://github.com/JuliaRegistries/General/pull/166500 — if merged, run ] add MakieViews in a fresh Julia REPL, confirm it resolves, mark Task 075 [x] Done in tasks.md, commit + push. M11 is then complete.

2. Begin v0.2 planning: start a new session, use /resume to re-establish ground truth, then use the project-intake or software-project skill to draft v0.2 scope. Key inputs: Makie_Functions.mdx (commit it first so it is tracked), RELEASE-READINESS.md §Post-v0.1.0 backlog, ADR-022/023 (deferred items), Bug F (the renderer redesign that unblocks live structural edits — the central v0.2 engineering problem).
