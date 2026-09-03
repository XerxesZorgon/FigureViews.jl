# PLAN-v0.2.md — FigureViews v0.2

**Status**: Draft
**Date**: 2026-08-29
**Companion documents**: SDD.md, DESIGN.md (§8.1, §9.1 amended for ADR-024), TEST_PLAN.md, PLAN.md (v0.1, M0–M11), **[ADR-024](adr/ADR-024-incremental-render-path-bug-f.md) (incremental render path / Bug F — the spine of this release)**, [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md) (v0.1 scope; its deferred list is this release's backlog), [ADR-023](adr/ADR-023-defer-interactive-macos-to-post-v0-1.md) (macOS CI + interactive verification, deferred here), [ADR-017](adr/ADR-017-reserve-data-inline-schema-slot.md) (reserved `data_inline` slot for `.mvz` data round-trip), [ADR-020](adr/ADR-020-defer-fps-measurement-to-m11.md) (FPS measurement pass, deferred here).
**Milestone numbering**: continues the single v0.1 sequence. v0.1 ended at M11; v0.2 runs **M12–M18**.

---

## 1. Summary

v0.1.0 shipped the REPL-driven core (build → style → export → save from the REPL); `makieviews()` displays a canned demo only, and structural editing of a live window deadlocks (Bug F, [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md)). **v0.2 turns FigureViews into the interactive Veusz-style tool the SDD describes**: a live window that displays a user-built session and accepts add / remove / reorder of figures, axes, and plots through the GUI.

The whole release hangs on one engineering problem. **Bug F ([ADR-024](adr/ADR-024-incremental-render-path-bug-f.md)) is the spine**: until structural mutation of a displayed window works, none of the GUI surface (variable picker, Add Plot menu, property-panel-as-primary flow, File menus, data pane) can become the primary interaction. So v0.2 is sequenced **spike → renderer → live GUI editing → GUI surface**, with three independent tracks (`.mvz` data round-trip, macOS CI, release-prep polish) that can run in parallel once the spine is underway.

Seven milestones (M12–M18). Test-first at every milestone per TEST_PLAN.md, same as v0.1. No milestone lands with red CI.

---

## 2. Technical Context — deltas from v0.1

Only what changes from PLAN.md §2 is listed here; everything unstated carries forward.

**New hard prerequisite — interactive thread ([ADR-024](adr/ADR-024-incremental-render-path-bug-f.md) constraint 1).** Live structural editing requires Julia started with an interactive thread pool (`--threads N,1` or `JULIA_NUM_THREADS="N,1"`). Without it the GLib idle-drain has no thread to run on and the UI freezes; on Julia 1.11 the REPL freezes outright. v0.2 `makieviews()` gains a startup check that refuses to open a live window when no interactive thread is present, with an actionable message. Verified on both compat ends (Julia 1.10 LTS, 1.12).

**Embedding path under review ([ADR-024](adr/ADR-024-incremental-render-path-bug-f.md) constraint 2).** v0.1 embeds the viewport via `Gtk4Makie.GtkMakieWidget` (`src/FigureViews.jl`), documented upstream as unstable with open issue JuliaGtk/Gtk4Makie.jl **#14** on *adding a plot to an existing widget* — exactly the operation v0.2 needs. M12 resolves this before any renderer work. The chosen path may change the shell's construction (`GTKScreen`-in-grid or a custom `GLMakie.Screen` window instead of the widget).

**New structural-mutation entry point.** A single `apply_structural!(session, op)` funnel becomes the only way to add/remove/reorder a node once a window is live. It branches on "is a window displayed?": headless → apply directly (v0.1 behavior, unchanged for REPL export/animation); live → post to a thread-safe queue drained on the main thread via `Gtk4.GLib.g_idle_add`.

**Dependencies.** No new *required* deps anticipated for the spine (queue is `Base.Channel` or a plain `Vector` + lock; `g_idle_add` is already in Gtk4.jl). M17 may add a `Preferences.jl` dep for conditional backend loading if that route is chosen over an `ENV` guard. M16 touches only persistence. Any new dep is added in the milestone that needs it, stdlib deps placed in `[deps]` (never removed).

**CI.** Reverts toward the ADR-023 target: M17 re-enables macOS CI once backend imports are guarded, taking the matrix from 2 cells (Ubuntu × {1.10, 1.12}) toward 4 (+ macOS × {1.10, 1.12}).

---

## 3. Milestones

Each milestone ends with a passing CI matrix (all applicable TEST_PLAN.md layers) and a `CHANGELOG.md` entry. No milestone lands with red CI. Milestones on the spine (M12→M13→M14→M15) are strictly gated; the parallel track (M16, M17) may proceed alongside once M12 is done.

### M12 — Embedding spike (throwaway; gates the release)

**This is a spike, not a feature milestone.** Its purpose is to answer one question before any production code is written: **can a plot be added to the live embedded viewport without deadlock or crash, and by which route?** Throwaway code is expected and acceptable.

Evaluate the three routes from [ADR-024](adr/ADR-024-incremental-render-path-bug-f.md) constraint 2, in a scratch script outside the package:

1. **Drive upstream #14** — reproduce the `GtkMakieWidget` plot-add failure minimally; assess whether a local workaround or an upstream fix is tractable on this release's timeline.
2. **`GTKScreen`-in-grid** — build the three-pane shell around `Gtk4Makie.GTKScreen`, hosting the tree/property panes in `grid(screen)` alongside the GLMakie area; test `empty!(ax); plot!(ax, …); Gtk4.queue_render(glarea)` from inside a button callback (known-working per Gtk4Makie's own docs) and then from a `g_idle_add` drain.
3. **Custom `GLMakie.Screen`** — `GLMakie.Screen(; window=…, start_renderloop=false)` embedding into a Gtk4 `GtkGLArea`, per GLMakie's documented custom-window route.

**Exit**: a one-page written finding (new ADR, **ADR-025 — embedding path for live editing**) that names the chosen route, shows a working scratch demo of *adding one plot to an already-displayed window* via `g_idle_add`, and records why the other two routes were rejected. **If no route works on this timeline, the finding says so and v0.2's GUI scope is re-planned before M13** — this is the milestone's entire reason for existing as a separate gate.

### M13 — Incremental renderer (Bug F fix)

Replace the v0.1 full-rebuild observers with the incremental path from [ADR-024](adr/ADR-024-incremental-render-path-bug-f.md), on the embedding route M12 chose.

- Thread-safe mutation queue + `g_idle_add` drain on the main thread.
- Incremental renderer ops: `_add_plot_handle!`, `_remove_plot_handle!`, `_add_axis!`, `_remove_axis!` — each mutating only the changed node's Makie handle, ending in `Gtk4.queue_render`. Removed nodes get their observers `off(...)`'d (closing the v0.1 handle-accumulation leak).
- `apply_structural!(session, op)` funnel with the headless-vs-live branch.
- Interactive-thread startup check in `makieviews()` (refuse-with-message when absent).

**Exit**: an automated test (headless where possible; `xvfb-run` GUI-smoke on Linux CI) that opens a window, adds a plot, removes a plot, and adds an axis **after** display, with no deadlock and the correct final figure. The v0.1 attribute-edit path still passes unchanged. Interactive-thread check verified on Julia 1.10 and 1.12. This closes Bug F.

### M14 — Live GUI structural editing

Wire the **existing** `tree_pane.jl` and `property_pane.jl` (already live in the v0.1 demo for selection + attribute edits) to `apply_structural!`. This is where `makieviews()` gains the ability to display a **user-built** session, not just the demo.

- `makieviews(session)` method (or equivalent) that displays an arbitrary `Session`.
- Tree-pane context actions: add plot, delete node, reorder — routed through `apply_structural!`.
- Property-pane "add plot to this axis" affordance.
- Structural edits reflect in the viewport within the incremental path (no full rebuild, no lost camera state on untouched axes).

**Exit**: Layer-3 GUI-smoke test drives a tree add/delete/reorder through the pane callbacks and asserts the viewport updates correctly; SDD SC-002/SC-003/SC-005 (the GUI-flow criteria deferred by ADR-022) begin to be met. Manual verification on Windows.

### M15 — GUI entry surface

The thin UI layer on top of M14's plumbing — the parts of ADR-022's deferred list that are *presentation*, not *mechanism*.

- Variable picker (enumerate `Main` / CSV / HDF5 sources into a selectable list — the `DataSource` layer already exists from M5).
- Add Plot menu (plot-type selection → `apply_structural!`).
- File menu: Open / Save `.mvz` (the persistence layer exists from M6; this wires it to menu actions and dialogs).
- Data pane (in-app view of ingested variables).

**Exit**: SDD SC-002/SC-003/SC-005/SC-006 met through the GUI (not just the REPL); the pre-flight warning modal (deferred from M10 — v0.1 had no GUI load flow) lands here as the Gtk4 dialog DESIGN §7.1 specifies. Manual verification on Windows.

### M16 — `.mvz` data round-trip (parallel track; independent of the spine) — COMPLETE

Implement the reserved `data_inline` slot ([ADR-017](adr/ADR-017-reserve-data-inline-schema-slot.md)) so a saved session reopens *with its data*, not as a dataless skeleton. Closes SC-004, the one v0.1 success criterion ADR-022 explicitly left open.

- Define the `[[figure.axis.plot.data_inline]]` sub-table shape v0.1's loader reserved and refuses.
- Save writes array data inline (with a size threshold / external-file option for large arrays — design decision to record).
- Load restores arrays into `data_snapshots`, so `load → render → golden-image` closes.
- Bump `.mvz` `schema_version` minor; v0.1's loader already refuses `data_inline` with a specific message, so forward-compat is clean.

**Exit**: TEST_PLAN §3 round-trip property test extended — build → save → load → export is pixel-hash-identical *including data* (SC-004 closed). May start any time after M12; does not gate M13–M15.

---

## REVISION — 2026-09-02

**M12–M16 were executed as planned. The following milestones are renumbered and rescoped based on decisions made after the Science Council meeting on GUI layout (2026-09-02). The original M17 and M18 descriptions below are superseded; they are preserved for historical reference.**

Summary of changes:
- **M17 (new)** = GUI redesign (tri-pane layout, toolbar, undo/redo, drop-to-add with AI-assisted recommendation engine). Informally labelled "M18" in the session log before this renumbering.
- **M18 (new)** = macOS CI + conditional backend loading (was original M17).
- **M19 (new)** = Release prep + v0.2.0 (was original M18).

See `docs/adr/ADR-028-*.md` (to be written in M17 Phase 3) for the AI assistant design decisions. See `SESSION_LOG.md` for the full confirmed M17 layout spec.

---

### M17 — GUI redesign: tri-pane layout, toolbar, drop-to-add, AI assistant

**Supersedes the original M17. This is the milestone that turns FigureViews from a functional scaffold into the tool the project set out to build.**

Five phases (Tasks 116–125):

- **Phase 1 (116–117):** Restructure window to confirmed tri-pane layout. Left: Variables/Snapshots notebook (top) + Derived Variable drawer (foldable, bottom). Center: canvas. Right: tree pane (top) + property inspector + Recipe Drawer (foldable, bottom). Add toolbar with icon+label buttons: Document group (New, Open, Save, Export), Structure group (Add Figure, Add 2D Axis, Add 3D Axis, Delete Selected, Move Up, Move Down), History group (Undo, Redo).
- **Phase 2 (118):** Undo/Redo — shallow ~20-step command stack for structural ops and property changes.
- **Phase 3 (119–122):** ADR-028 + drop-to-add gesture with three-tier recommendation engine: Tier 1 (deterministic rule-based by data shape), Tier 2 (categorized browser by visual question with static thumbnails from Makie docs), Tier 3 (pluggable AI provider via OpenRouter/Claude/OpenAI/Gemini with adaptive sampling).
- **Phase 4 (123–124):** Derived Variable drawer + Recipe Drawer (one-way code emission only — bi-directionality is a deliberate non-goal).
- **Phase 5 (125):** M17 integration test + Windows manual verification.

Key confirmed decisions: tree pane moves to RIGHT column above property inspector; axis transforms live as hover gear icon on canvas; thumbnails fetched from Makie docs + cached via Scratch.jl; AI sampling is opt-in adaptive (200-pt subsample for 1D, max 20×20 for 2D, 10k-value hard cap, full-data override available).

**Exit:** Tasks 116–125 all green; CI 2/2; Windows manual verification passed.

---

### M18 — macOS CI + conditional backend loading (was original M17, parallel track)

Enable macOS CI by guarding backend imports, per [ADR-023](adr/ADR-023-defer-interactive-macos-to-post-v0-1.md)'s v0.2 commitment.

- Guard `GLMakie` / `Gtk4` / `Gtk4Makie` imports behind `ENV["MAKIEVIEWS_BACKEND"]` or `Preferences.jl`, so `using FigureViews` can load a data-only path without OpenGL (this is what blocked headless macOS CI in v0.1 — `using FigureViews` unconditionally loaded GLMakie and failed on GHA Apple Silicon).
- Re-add the `macos-latest × {Julia 1.10, 1.12}` CI cells (matrix 2→4).
- **Interactive macOS verification** (the manual gate deferred from v0.1 per ADR-023): mouse-driven 3D rotation, live attribute + structural editing, window dragging, `export_figure` from a displayed window — on a real Mac. This is a committed pre-v0.2.0 gate.

**Exit**: 4-cell CI green; interactive macOS pass documented. Pairs naturally with the GUI/headless split M13 introduces. Does not gate the spine.

### M19 — Release prep + v0.2.0 (was original M18)

Fold in the remaining v0.1 carryovers and the release mechanics.

- **FPS measurement pass** ([ADR-020](adr/ADR-020-defer-fps-measurement-to-m11.md), deferred from v0.1): three-OS reference table → `src/preflight/fps_lookup.jl`, replacing the coarse fallback formula. Now unblocked by macOS CI (M17) and the live viewport (M14).
- **VRAM-parsing branch** verification on a real NVIDIA box (only the `nothing` fallback ran in v0.1 — no `nvidia-smi` on the dev machine).
- **`FigureViews.check_updates()`** helper (RELEASE-READINESS §Post-v0.1.0): queries General for a newer FigureViews version, prints an update hint. Motivated by the exact-pin decision that puts `] up` responsibility on the user.
- **Additional plot types** from `docs/Makie_Functions.mdx` — *selected*, not wholesale. Candidate first tranche (record the selection as a short ADR): the statistical family (`hist`, `density`, `boxplot`) and `band`/`errorbars`, since they reuse the existing 2D axis + schema machinery. Each new type is register-schema + render-function only (DESIGN §2.3 dry-run), no UI change.
- Compat pins refreshed; CHANGELOG `[0.2.0]`; semver bump; Registrator submission.

**Exit**: SDD SC-001 met for v0.2.0 (registered + tagged); pre-release manual QA report (Windows + macOS) attached to release notes; all spine + parallel-track exits green.

---

## 4. Dependency Graph (milestone gating)

**Revised 2026-09-02:** M17 is now the GUI redesign (Tasks 116-125). Old M17 (macOS CI) is now M18. Old M18 (release prep) is now M19. The ASCII graph below is from the original plan and uses old numbers; treat M17/M18/M19 per the REVISION section above.

```
M12 (spike) ──▶ M13 (renderer) ──▶ M14 (live GUI edit) ──▶ M15 (GUI surface) ──▶ M18 (release)
   │                                                                                  ▲
   ├──────────────▶ M16 (.mvz data round-trip) ─────────────────────────────────────┤
   │                                                                                  │
   └──────────────▶ M17 (macOS CI + conditional backend) ────────────────────────────┘
```

- **Spine (strict gate):** M12 → M13 → M14 → M15. No milestone starts until the prior is green.
- **Parallel tracks:** M16 and M17 may begin any time after M12 and merge before M18. M17's conditional-backend work *complements* M13's headless-vs-live split — coordinate so the two don't diverge.
- **M18** requires everything.

---

## 5. Risk & Complexity Tracking

The single highest risk is concentrated in M12, by design — the release surfaces it first and gates on it rather than discovering it mid-renderer-work.

| Risk | Milestone | Why it matters | Mitigation |
|---|---|---|---|
| No embedding route supports live plot-add | M12 | Invalidates the entire GUI plan (M13–M15) | M12 is a throwaway spike that gates the release; a negative finding triggers re-planning *before* production code |
| `GtkMakieWidget` #14 unfixable on timeline | M12 | v0.1's current embedding can't do the job | Two fallback routes (GTKScreen-in-grid, custom GLMakie.Screen) evaluated in the same spike |
| Interactive-thread requirement surprises users | M13 | Silent deadlock if launched without `--threads N,1` | Startup check refuses with an actionable message; documented as a launch prerequisite; verified on 1.10 + 1.12 |
| Off-main-thread figure mutation crashes | M13 | GLMakie figures aren't thread-safe to update off the render thread | `apply_structural!` funnel makes the queue the *only* live-mutation entry point; no direct renderer shortcut in GUI mode |
| Incremental `_add_axis!` layout placement | M13/M14 | v0.1 sidesteps general layout with a one-row-per-axis rule | Carry the one-row rule into v0.2 as an explicit interim constraint, or land general `LayoutSpec` placement alongside |
| macOS interactive issues found late | M17 | No Mac hardware during v0.1; first real interactive test | Headless macOS CI (M17) catches ~99%; the committed interactive gate catches the rest before v0.2.0 |
| Plot-type scope creep | M18 | `Makie_Functions.mdx` lists 40+ types; shipping all is unbounded | Select a small first tranche; record the selection as an ADR; each type is schema + render only |

---

## 6. Open questions to resolve before or during M12

These are genuine forks that shouldn't be pre-decided in this plan — they surface as design work in their milestones (per the project convention that design decisions surface during task writing, not speculatively):

- **Queue data structure**: `Base.Channel` (blocking, task-friendly) vs. a plain locked `Vector` drained by `g_idle_add` (simpler, no reader task). ADR-024 alternative (a) even allows skipping the explicit queue for a v0.2 first cut (one `g_idle_add` closure per mutation). Decide in M13.
- **`data_inline` large-array threshold** (M16): inline everything, or spill arrays above N bytes to a sidecar file referenced from the `.mvz`? Interacts with ADR-012's path handling.
- **Conditional backend mechanism** (M17): `ENV` var (runtime, no recompile) vs. `Preferences.jl` (compile-time, cleaner but needs a restart). ADR-023 names both.
- **Plot-type first tranche** (M18): confirm the statistical family is the right first selection from the inventory, or prioritize by user demand.

---

## 7. What this plan does NOT change

- The SDD's north star (Veusz-style GUI) is unchanged — v0.2 delivers more of it, per ADR-022's status layer.
- The tree-model / schema-driven / forward-compat constraints (DESIGN §0) are untouched. New plot types remain register-schema + render-function only.
- ADR-006 (never call `set_theme!`) and the reactive-state model (ADR-019) stand.
- The one-task-at-a-time execution gate and the `tasks.md`-always-committed rule (AGENTS.md) carry forward verbatim.
