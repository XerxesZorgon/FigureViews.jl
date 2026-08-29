# SESSION_LOG.md — MakieViews

**Session date:** 2026-08-28 (long session — full M11 execution)
**Active skill:** software-project -> antigravity (for Tasks 068, 073, 073b)
**HEAD:** 7d70d38 (tasks: Task 075 in-progress) — plus uncommitted tasks.md flip pending push
**Tag:** v0.1.0 pushed, pointing to 3d4da4a34c5c6b5aff680ca755b44ffdb7466ba6
**General registry PR:** https://github.com/JuliaRegistries/General/pull/166500

---

## What was completed this session

### Docs reconciliation (pre-M11)
- ADR-022 written: v0.1.0 ships REPL-driven core; interactive Veusz-style GUI is v0.2+. The Veusz north star is unchanged.
- README rewritten (Framing A — verified REPL Quickstart, all calls confirmed against source).
- SDD — Approach 2 status layer: scope banner + §5.4 FR/NFR delivery table + §8 SC status table. Requirements preserved verbatim; GUI-framed items marked Deferred v0.2. SC-003 and SC-004 explicitly recorded as not met by v0.1.
- CHANGELOG — [Unreleased] M11 entry, [0.1.0] reframed, Known limitations added, JSON junk block stripped.
- PLAN.md — §1 goal line rescoped (Veusz vision kept, v0.1.0 = REPL core), M11 reconciliation note marked done, JSON junk stripped.
- DESIGN.md — JSON junk stripped (same ~14:12 batch as CHANGELOG/PLAN/ADR-021).
- ADR-021 — JSON junk was present; restored via git restore at end of session.

Note: four files (CHANGELOG, PLAN, DESIGN, ADR-021) had document-manager JSON metadata blocks prepended at ~14:12 today. All stripped. Cause unknown — watch for recurrence.

### M11 tasks completed
- Task 068 DONE — render_session(session) -> Renderer helper + test. Commit fc25312. 72 testsets green.
- Task 069 DONE — FPS measurement pass deferred to v0.2 (ADR-020 updated: M11 -> v0.2 target; DESIGN §7.2 + §11 ODQ-5 + PLAN M11 carryovers reconciled).
- Task 070 DONE — Release-readiness audit. docs/RELEASE-READINESS.md authored. Decisions: exact Makie/GLMakie/CairoMakie pins retained; version bump plan; LICENSE/README/CHANGELOG confirmed; CHANGELOG finalize plan (dev history -> "Pre-release history" heading). Repo confirmed as XerxesZorgon/MakieViews.jl.
- Task 071 DONE — CI #40 both green on 4d053a7.
- Task 072 DONE — Windows 11 full suite: 72 testsets all pass. Two cosmetic warnings (ModernGL teardown noise at exit; CairoMakie volume unsupported) — both pre-existing, non-blocking. makieviews() launched, demo rendered, 3D rotate + live attribute edit confirmed OK.
- Task 073 DONE (attempted + closed) — Two attempts confirmed macOS CI infeasible for v0.1.0:
  - Task 073: GHA macos-latest fails at GLMakie precompile (NSGL FORMAT_UNAVAILABLE).
  - Task 073b: Separate test/runtests_cairo.jl also fails — using MakieViews at src/MakieViews.jl:3 unconditionally loads GLMakie/Gtk4Makie before any test code runs.
  - ADR-023 written: split macOS verification into headless CI (attempted, failed) + deferred interactive. Final outcome: CI reverted to Ubuntu-only (2 cells). macOS CI requires conditional backend loading — v0.2 backlog. test/runtests_cairo.jl removed. README/CHANGELOG/RELEASE-READINESS updated to say macOS untested for v0.1.0.
- Task 074 DONE — Folded into Task 072. Interactive-fps sanity confirmed (no freeze). VRAM-parsing branch documented as known limitation (no NVIDIA box available; nothing fallback ships per FR-026).
- Task 075 IN PROGRESS — awaiting AutoMerge (see below).

### Task 075 state (release)
- Project.toml bumped to version = "0.1.0".
- CHANGELOG.md finalized: date 2026-08-28, dev history moved under Pre-release development history (M1-M11), [Unreleased] reset to empty, Compat updated to exact pins, two new Known limitations added (ModernGL teardown noise; CairoMakie volume unsupported), PLACEHOLDER-USER -> XerxesZorgon in compare/tag links.
- Release commit: 3d4da4a (release: v0.1.0). CI #49 green.
- Tag v0.1.0 pushed (annotated): 3d4da4a34c5c6b5aff680ca755b44ffdb7466ba6.
- JuliaRegistrator GitHub App installed via https://github.com/JuliaRegistries/Registrator.jl install button.
- General registry PR: https://github.com/JuliaRegistries/General/pull/166500
- Release notes added to the @JuliaRegistrator register commit comment.
- AutoMerge: 3-day new-package waiting period. No action needed until merge.

---

## Next action (next session)

1. Check https://github.com/JuliaRegistries/General/pull/166500 — has it merged?
   - If yes: run ] add MakieViews in a fresh Julia environment. If it resolves -> SC-001 met -> mark Task 075 [x] Done in tasks.md, commit, push. M11 complete. Write final Obsidian log.
   - If pending (within 3-day window): wait. No action.
   - If AutoMerge blocked: paste the blocking comment here. Common causes: naming objection (unlikely), compat issue (unlikely — exact pins pass), or a registry CI failure. Address per the feedback.

2. After Task 075 closes, update SESSION_LOG.md to reflect M11 complete and v0.1.0 registered.

---

## Key facts for the next session

- CI matrix: Ubuntu-only, 2 cells (Julia 1.10 + 1.12). macOS dropped for v0.1.0 (ADR-023).
- Test count: 72 testsets / ~308 assertions. Last green: CI #49 on 3d4da4a.
- macOS CI (v0.2 backlog): requires conditional backend loading — guard GLMakie/Gtk4/Gtk4Makie imports in src/MakieViews.jl:3 behind ENV["MAKIEVIEWS_BACKEND"] or Preferences.jl. Pairs with the GUI/headless split planned for v0.2.
- Interactive macOS verification (deferred, ADR-023): before v0.2.0, run Pkg.test() + makieviews() + 3D rotate + live attribute edit on macOS 12+. Update ADR-023 with outcome.
- v0.2 backlog (key items): interactive Veusz-style GUI (Bug F blocker — renderer redesign for live structural edits); .mvz data round-trip (ADR-017 reserved data_inline slot); FPS measurement pass (ADR-020); macOS CI (conditional backend loading); in-package check_updates() helper; undo/redo; user recipes.
- Patch P2 deferred items (still open): D4 surface colormap lock, Bug D 2D click bleed into 3D, D2 label field no-op.
- ADR-021 was locally modified (JSON junk, same ~14:12 batch). Restored via git restore this session. If it shows modified again in a future git status, restore it immediately.
- Working tree items to ignore (.gitignore updated this session): .codex/, .cursor/, .mcp.json, scratch_test*.jl, test_out.txt, docs/CHANGE-tree-pane-viewport-fix.md, docs/Makie_Functions.mdx. Last two are local-only docs (kept, not committed).
- Remote URL: GitHub still pushes to https://github.com/XerxesZorgon/MakieViews.git (old name) and GitHub redirects. Update local remote to silence the "This repository moved" notice: git remote set-url origin https://github.com/XerxesZorgon/MakieViews.jl.git
