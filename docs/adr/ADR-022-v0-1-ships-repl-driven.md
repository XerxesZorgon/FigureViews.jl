# ADR-022 — v0.1.0 ships REPL-driven; the interactive GUI is deferred to v0.2+

**Status**: Accepted (2026-08-27).
**Date**: 2026-08-27
**Deciders**: John Peach
**Related**: [ADR-011](ADR-011-non-repl-launch-semantics.md) (REPL-only launch), [ADR-002](ADR-002-ui-stack-gtk4-glmakie.md) (UI stack), [ADR-017](ADR-017-reserve-data-inline-schema-slot.md) (reserved `data_inline` slot — the v0.2 path SC-004 needs), [ADR-018](ADR-018-ci-matrix-reduction-ubuntu-only.md) (Ubuntu-only CI / macOS gate), [ADR-020](ADR-020-defer-fps-measurement-to-m11.md) (prior scope-deferral, same pattern), Bug F (tasks.md), SDD §1/§4/§5/§8, SESSION_LOG 2026-08-27.

## Context

The SDD describes FigureViews as a Veusz-style GUI: a variable picker, an Add Plot menu, click-to-build figures, property-panel editing as the primary interaction, File→Save/Export dialogs, and a data pane (SDD §1, §4 User Stories 1–6, §5 FR-001…FR-026). That is the project's north star and remains so.

By the end of M10, what the code actually delivers is a **REPL API**, not that GUI:

- Figures are built by REPL calls (`new_session` / `add_figure!` / `add_axis!` / `ingest!` / `add_plot!`), not a picker or menu.
- `makieviews()` takes no arguments and always displays a fixed **demo** session (a 2D line+scatter and a 3D surface). It has no method that displays a user-built session.
- Structural mutation of an already-displayed window (adding/removing a figure/axis/plot after `makieviews()`) deadlocks the renderer — **Bug F**, a genuine live-update redesign, deferred to v0.2. Live *attribute* edits (color, title, limits) on the displayed demo work, because they mutate the Makie handle in place without a rebuild.
- `.mvz` load restores the tree and styling but **not** the data arrays (`snapshot_id` is empty on load; DataRefs carry provenance paths only). A saved session reopens as a dataless skeleton in v0.1.

Building the full menu/picker/dialog surface, plus the incremental live-update renderer Bug F requires, is more than v0.1 can carry. But the REPL core is complete, tested (~294 tests, CI green), and independently useful: it builds a figure from arrays / CSV / HDF5, renders and exports it (PNG/SVG/PDF via CairoMakie; MP4/GIF via `Makie.record`), and saves the spec to `.mvz`.

## Decision

**v0.1.0 ships the REPL-driven core. The interactive Veusz-style GUI — variable picker, Add Plot menu, property-panel-as-primary-flow, File menus, in-app data pane, and live structural editing of a displayed window — is deferred to v0.2+.** The project's purpose (SDD §1) is unchanged; only the v0.1.0 delivery scope narrows.

What v0.1.0 delivers:

- A REPL API to build a figure spec from in-memory arrays, CSV (CSV.jl), or HDF5 (HDF5.jl): `new_session`, `add_figure!`, `add_axis!`, `ingest!`, `add_plot!` / `add_plot_checked!`, `animate_plot!`.
- Render + static export: `export_figure` → PNG/SVG/PDF (CairoMakie); `render_animation` → MP4/GIF.
- Session persistence: `save_session` / `load_session` for the `.mvz` spec (tree + styling; **not** data — v0.1 limitation).
- Pre-flight surface: `add_plot_checked!` emits an advisory `@warn` on a large array; `downsample=` reduces (ADR-020).
- `makieviews()` opens a **demo window** that previews the eventual GUI shell (three-pane layout, tree/property panes, embedded GLMakie viewport) on a canned demo session, and supports live attribute edits on it.

The GUI is built on top of this core in v0.2, not rebuilt.

## Consequences

- **SDD (Approach 2 — status layer):** the SDD keeps its requirements as the project target, gains a scope banner stating v0.1.0 ships the REPL core, and marks each requirement *Delivered v0.1* / *Deferred v0.2*. GUI-framed requirements (FR-001 picker, FR-005/006 "through the GUI" + tree add/delete/reorder, FR-007/008 property panel as primary, FR-013 GUI slider binding, FR-022 GUI reset action, FR-024 non-blocking *dialog*) are *Deferred v0.2*; their underlying capabilities ship as REPL functions where they exist.
- **Success Criteria:** SC-002, SC-003, SC-005, SC-006 describe the GUI flow and are **not v0.1.0 gates** — they move to v0.2. The v0.1.0 gate becomes: the REPL end-to-end (build → export → save/reload spec), General-registry registration, and cross-platform install/launch-to-demo.
- **SC-004 flagged explicitly:** `.mvz` round-trip restores tree + styling but not data, so the load→render→golden-image path is not closed in v0.1. Full data round-trip is v0.2, pairing with ADR-017's reserved `data_inline` slot.
- **README / CHANGELOG / PLAN** are reconciled to this scope; PLAN's v0.1.0 goal line keeps the Veusz vision but scopes v0.1.0 to the REPL core.
- **No code change** and **no public-API change** from this ADR — it records scope, not behavior.

## Alternatives Considered

- **(a) Hold v0.1.0 until the GUI is built** — rejected: indefinitely delays a registered, useful package; the REPL core is independently valuable and de-risks the Makie/Gtk4/CairoMakie foundation; Bug F is a renderer redesign, not a quick fix.
- **(b) Rewrite the SDD requirements down to the REPL reality (Approach 1)** — rejected: discards the Veusz spec that is the project's actual target. A status layer tells the v0.1 truth without losing the north star.
- **(c) Ship the partial GUI as-is** — rejected: structural mutation of a displayed window hangs (Bug F). A GUI that freezes when you add a plot is a worse first impression than an honest, working REPL API.
