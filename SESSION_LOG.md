# Session Log
**Updated:** 2026-08-29
**Active skill:** software-project (v0.2 execution — next thread enters the Antigravity loop at M12)
**Last confirmed state:** v0.2 planning complete. No task in progress — M12 not yet started. (Task 075 parked, see below.)

## What happened this session
Resumed FigureViews and finished v0.2 planning. Wrote ADR-024 (Bug F root cause = two coupled defects: structural mutations issued from the REPL contend with the GLib event loop for the main thread, AND the renderer full-rebuilds via empty! on every change; fix = g_idle_add-drained mutation queue + incremental add/remove renderer ops). Confirmed from src/FigureViews.jl that makieviews() embeds via the unstable Gtk4Makie.GtkMakieWidget (upstream issue #14 blocks plot-add — this is a real blocker, not hypothetical). Amended DESIGN.md §8/§9 for ADR-024, and wrote docs/PLAN-v0.2.md (milestones M12–M18, continuous numbering).

## Decisions made (not yet in an ADR)
- v0.2 milestone spine: M12 embedding spike (gates the release) → M13 incremental renderer (Bug F fix) → M14 live GUI structural editing → M15 GUI surface; M16 (.mvz data round-trip) and M17 (macOS CI + conditional backend) as parallel tracks; M18 release prep. Recorded in PLAN-v0.2.md.
- M12 is a deliberately throwaway spike with its own gate — it front-loads the release's highest risk (whether any embedding route supports live plot-add). A negative finding triggers re-planning before M13.
- M12's exit deliverable is a NEW ADR — ADR-025 (embedding path for live editing) — naming the chosen route (drive Gtk4Makie #14 / GTKScreen-in-grid / custom GLMakie.Screen). Not yet written; it comes out of the spike, not planning.
- Milestone numbering continues the single v0.1 sequence (M12+), not a v0.2-M1 restart.
- The GUI panes (tree_pane.jl, property_pane.jl) already exist and work for selection + attribute edits in the v0.1 demo — so M14 is "let existing panes mutate structure," and M15 is thin UI over M5/M6 plumbing. v0.2 is smaller than it looks IF the M12 spike succeeds.

Commits this session (all pushed to XerxesZorgon/FigureViews.jl, main):
- a8a98a7 — ADR-024 + Makie_Functions.mdx (committed the previously-untracked inventory)
- de8d5ae — DESIGN.md §8/§9 amendments
- 20e1115 — PLAN-v0.2.md

## Blocked on / open question
- **Task 075 is PARKED** (not blocked-needing-action). It waits on General registry PR #166500 to merge (expected ~Sept 1; John says a few days). Could not confirm merge status this session — web fetch refused the PR URL, GitHub API rate-limited on the shared IP. ON MERGE: run `] add FigureViews` in a fresh Julia env, confirm it resolves, mark Task 075 [x] Done in tasks.md, commit + push. M11 is complete only after that.
- Open forks recorded in PLAN-v0.2.md §6, to resolve during M12/M13 (not now): queue data structure (Channel vs locked Vector vs per-mutation g_idle_add); data_inline large-array threshold (M16); conditional-backend mechanism ENV vs Preferences.jl (M17); plot-type first tranche (M18).

## Next action
Begin M12 (embedding spike) via the Antigravity loop. Two housekeeping items first:
1. When Task 075's registry merge lands (independent of M12), close it per the steps above.
2. To start M12: this is execution, not planning — re-read the antigravity skill before generating any instruction. M12 is a scratch-script spike (throwaway code, outside the package) that evaluates the three embedding routes from ADR-024 constraint 2 and must demonstrate adding one plot to an already-displayed window via g_idle_add without deadlock. tasks.md has no M12 tasks yet — write the M12 task block(s) first (software-project Step 1), starting with route evaluation, then hand the first task to Antigravity. Remember: tasks.md must be committed after every edit session (M10 incident).
