# MakieViews — project index

**Purpose**: A Veusz-style desktop GUI over Makie for Julia scientific plotting. **Status**: v0.1 **M2 (Tree + one plot type) COMPLETE 2026-08-24** — 73 tests green locally + CI 2/2 green on Ubuntu (v0.1 matrix per ADR-018). macOS QA deferred per maintainer decision (hard gate at M11). **Docs location on device**: `C:\Users\johnx\Documents\WildPeaches\Projects\MakieViews\` *(WildPeaches path is authoritative)*

## Planning documents

* `docs/SDD.md` — Software Description Document (problem, users, scope, requirements, success criteria, forward-looking constraint).
* `docs/DESIGN.md` — Architecture: tree model, schema-driven property panel, `.mvz` layout, pre-flight state machine, `Main`-namespace access, preferences-seed behavior. **§11 shows all ODQs closed with ADR cross-references.**
* `docs/TEST_PLAN.md` — Four test layers. **v0.1 CI matrix reduced from 6 cells to 2 cells (Ubuntu × Julia 1.10, 1.12) per ADR-018** — GitHub Actions Windows/macOS runners lack accessible GL contexts; Windows and macOS support is developer-machine-verified for v0.1. Session round-trip, golden images, cross-OS install.
* `docs/PLAN.md` — Pinned dependency versions, 11 milestones (**M0 complete**; M1 in progress; M2..M11 upcoming), repository structure.
* `docs/adr/ADR-001..019` — Architecture Decision Records.
* `README.md`, `CHANGELOG.md` — user-facing.

## Load-bearing decisions

* Julia 1.12 primary, `julia = "1.10"` compat range (ADR-001).
* Gtk4.jl + Gtk4Makie.jl shell, GLMakie viewport, CairoMakie for export (ADR-002, ADR-003).
* `.mvz` = TOML with `schema_version` and unknown-node preservation (ADR-004); reserves `data_inline` slot for v0.2 (ADR-017).
* Preferences via Scratch.jl, defaults-only, never `set_theme!` (ADR-005, ADR-006); independent schema\_version from `.mvz` (ADR-016).
* Data sources v0.1: REPL `Main`, CSV, HDF5 (ADR-007). Distribution via General registry (ADR-008).
* Non-REPL launch: REPL-only for v0.1 with detection warning (ADR-011).
* Data-ref paths stored dual (relative first, then absolute) (ADR-012).
* MP4/GIF export: fps configurable default 30 (ADR-013); modal on main thread for v0.1, background export deferred to v0.2 (ADR-014).
* Pre-flight FPS: measurement-driven lookup populated in M10, conservative bias (ADR-015).
* **CI matrix for v0.1: Ubuntu-only, 2 cells (Julia 1.10, 1.12) (ADR-018).** Reduction from ADR-009's original 6-cell intent after empirical CI failure (run 32780549703) confirmed GitHub Actions Windows/macOS runners cannot load GLMakie. Matches upstream Makie CI. Windows/macOS support is developer-machine-verified for v0.1; M11 pre-release manual QA required before v0.1.0 tag. Restoration path to 6 cells deferred to v0.2 once Layer 1/2 (headless-safe) tests exist.
* **Reactive state model: `Observables.jl` + `mutable struct` with per-field `Observable` fields (ADR-019).** Mirrors Makie's own internal reactive plumbing. `Plot.attrs::Dict{Symbol, Observable{Any}}` for per-attribute observation. Debouncing via `Observables.throttle(1/60, ...)`. Applies to all M2–M10 code that mutates the SessionState tree.

## Open Design Questions

**None open.** All seven ODQs are ADRs (ADR-011..ADR-017). DESIGN.md §11 has the closure table.

## Tech pins (2026-08-24)

Julia 1.12.6 primary, 1.10.11 LTS validated. Makie 0.24.13, GLMakie 0.13.13, CairoMakie 0.15.13, Gtk4.jl 0.7.12, Gtk4Makie.jl 0.3.9, CSV.jl 0.10.16, DataFrames.jl 1.8.2, HDF5.jl 0.18.0, Scratch.jl 1.3.0.

## What's next

M2 shipped and CI green. Three-pane `makieviews()` with schema-driven property panel, Observables reactive state (ADR-019), and end-to-end attribute propagation. 73 tests. Begin M3: scatter, bar, heatmap, contour plot types — pure `PLOT_SCHEMAS` additions using M2's established pattern, the easiest milestone so far.
