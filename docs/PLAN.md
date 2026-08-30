# PLAN.md — FigureViews v0.1

**Status**: Draft **Date**: 2026-08-24 **Companion documents**: SDD.md, DESIGN.md, ADR-001..010, ADR-011..017, **ADR-018 (CI matrix reduction)**, **ADR-019 (reactive state model: Observables.jl)**, TEST_PLAN.md **Template basis**: Adapted from `.specify/templates/plan-template.md` (Spec Kit), with Summary / Technical Context / Structure retained and Milestones / Compat Pins added.

---

## 1. Summary

Ship FigureViews v0.1.0 to Julia's General registry. FigureViews' goal is a Veusz-style desktop GUI over Makie for Julia scientific plotting, running on Windows, macOS, and Linux; **v0.1.0 delivers the REPL-driven core of that tool** — build, style, export, and save figures from the REPL — with the interactive point-and-click GUI arriving in v0.2+ ([ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md)). Eleven milestones (M1–M11) from empty shell to registered package. Test-first at every milestone per TEST_PLAN.md.

---

## 2. Technical Context

**Language / Version**: Julia. Primary target Julia 1.12.6; LTS validation on Julia 1.10.11. Compat range in `Project.toml`: `julia = "1.10"`. See ADR-001.

**Primary Dependencies** (all pinned, see §3 for exact versions):

- Makie, GLMakie, CairoMakie (plotting engine)
- Gtk4.jl, Gtk4Makie.jl (desktop shell + Makie embed)
- CSV.jl, DataFrames.jl (CSV ingestion)
- HDF5.jl (HDF5 ingestion)
- Scratch.jl (per-user preferences directory)
- TOML (Julia stdlib; no compat entry needed)
- FFMPEG_jll (transitive of Makie; used explicitly for MP4 export)

**Storage**: `.mvz` TOML session files (user-supplied paths). Per-user preferences: `Scratch.jl`-managed TOML file. No database.

**Testing**: `Pkg.test`-invoked `Test` stdlib suite; layers per TEST_PLAN.md §2; `xvfb-run` on Linux for the GUI-smoke layer.

**Target Platform**: Windows 10+, macOS 12+, Linux (any distro that Gtk4.jl supports; documented Wayland/NVIDIA caveats).

**Project Type**: Single Julia package (source layout below).

**Performance Goals**: Blank window ≤10 s from `makieviews()` after precompile (SDD NFR-005). Property-panel edits reflect in viewport within one frame at 60 Hz.

**Constraints**: Cross-OS install must work on a fresh Julia 1.12 without OS-level setup steps beyond what the OS provides. See SDD NFR-003, NFR-004.

**Scale/Scope**: ≈5–8 kLOC of Julia in v0.1; ≈50 concrete test cases across 4 layers.

---

## 3. Pinned Dependency Versions (`Project.toml` compat block)

The pins below reflect the current General-registry state as of 2026-08-24 and match the compat bounds each of these packages declares in its own `Project.toml`.

```toml
[compat]
julia            = "1.10"                # ADR-001
Makie            = "0.24"                # 0.24.13 current
GLMakie          = "0.13"                # 0.13.13 current, pins Makie = "=0.24.13" upstream
CairoMakie       = "0.15"                # 0.15.13 current, pins Makie = "=0.24.13" upstream
Gtk4             = "0.7"                 # 0.7.12 current
Gtk4Makie        = "0.3"                 # 0.3.9 current; upstream compat: Makie = "0.24", GLMakie = "0.13.7"
CSV              = "0.10"                # 0.10.16 current
DataFrames       = "1.8"                 # 1.8.2 current
HDF5             = "0.17"                # 0.17.x current
Scratch          = "1"                   # 1.3.0 current
Colors           = "0.13"                # required by Gtk4Makie transitively
```

Rationale for the caret-style entries: Julia's `[compat]` interprets a bare `"0.24"` as `>= 0.24.0, < 0.25.0`, which matches the release cadence of these packages (breaking changes on minor). Bumping past a minor version requires a coordinated FigureViews release — an explicit gate rather than a silent update.

Stdlib (no compat entry): `TOML`, `UUIDs`, `SHA`, `Test`, `Sys`, `LinearAlgebra`.

CI verification job runs `] up` in a scratch environment weekly and opens a PR if upstream dependencies moved and CI stays green — never auto-merged (per ADR-002 stability caveat).

---

## 4. Repository Structure

```
FigureViews.jl/
├── Project.toml
├── LICENSE                       # MIT (registry submission requirement)
├── README.md
├── CHANGELOG.md
├── src/
│   ├── FigureViews.jl             # module root, exports makieviews()
│   ├── state/
│   │   ├── nodes.jl              # Session, Figure, Axis, Plot, UnknownNode
│   │   ├── schema.jl             # PLOT_SCHEMAS, AttrSpec
│   │   └── session.jl            # SessionState, observers
│   ├── data/
│   │   ├── source.jl             # abstract DataSource
│   │   ├── main_source.jl
│   │   ├── csv_source.jl
│   │   └── hdf5_source.jl
│   ├── preflight/
│   │   ├── detect.jl             # Sys/GPU probes
│   │   ├── estimate.jl           # footprint + fps model (coarse fallback; fps_lookup.jl deferred to M11 per ADR-020)
│   │   ├── downsample.jl         # UniformStride, MinMaxDecimation, LTTB
│   │   └── check.jl              # threshold decision, apply_downsample!, add_plot_checked!
│   ├── persistence/
│   │   ├── mvz_save.jl
│   │   ├── mvz_load.jl
│   │   └── preferences.jl        # Scratch.jl-backed TOML
│   ├── render/
│   │   ├── renderer.jl           # observes SessionState, updates Makie.Figure
│   │   └── export.jl             # CairoMakie PNG/SVG/PDF + FFMPEG MP4/GIF
│   ├── ui/
│   │   ├── window.jl             # Gtk4 top-level
│   │   ├── tree_pane.jl
│   │   ├── property_pane.jl      # schema-driven; NO per-plot branching
│   │   ├── viewport_pane.jl      # Gtk4Makie embed
│   │   └── dialogs.jl
│   └── util/
│       ├── threading.jl          # main-thread assertions
│       └── uuid.jl
├── test/                          # layout per TEST_PLAN.md §12
└── docs/
    ├── SDD.md
    ├── DESIGN.md
    ├── TEST_PLAN.md
    ├── PLAN.md
    ├── README-embedded.md         # source for the README section on architecture
    └── adr/
        ├── ADR-001-julia-runtime.md
        └── ... (through ADR-010)
```

**Structure Decision**: Single-project layout (Spec Kit "Option 1"). No frontend/backend split — this is a desktop app.

---

## 5. Milestones

Each milestone ends with a passing CI matrix (all layers per TEST_PLAN.md that apply at that stage) and a `CHANGELOG.md` entry. No milestone lands with red CI.

### M0 — ADR closure (blocking gate before any code) — **COMPLETE (2026-08-24)**

Resolve the seven Open Design Questions in DESIGN.md §11 into ADR-011..ADR-017. Do not begin M1 with unresolved architectural questions.

**Exit** (met): DESIGN.md §11 shows all seven ODQs closed and cross-referenced to their ADRs; ADR-011..017 present and Accepted; DESIGN.md §3, §4.3, §6, §7.2, §9 updated to fold in the ADR decisions.

### M1 — Shell

Gtk4 top-level window with an embedded GLMakie viewport (empty). No tree, no property panel, no plots. `makieviews()` entry point.

**Exit**: Layer-3 GUI smoke green on the v0.1 CI matrix (2 cells: `ubuntu-latest × {Julia 1.10, 1.12}`, per ADR-018); SDD SC-002 (blank session) partially met. Windows and macOS coverage is developer-machine-verified, not CI-verified, for v0.1 (see ADR-018 rationale).

### M2 — Tree + one plot type

`SessionState` with Session/Figure/Axis/Plot tree; `PLOT_SCHEMAS[:line]` populated; tree pane + property pane wired; end-to-end for a hand-constructed line plot.

**Exit**: Layer-2 integration passes for line; property panel schema-driven test passes for line.

### M3 — Remaining 2D plot types

Schemas + rendering for `:scatter`, `:bar`, `:heatmap`, `:contour`.

**Exit**: Layer-2 covers all four; goldens present for each.

### M4 — 3D plot types + camera controls

Schemas + rendering for `:surface`, `:volume`. Camera azimuth/elevation/zoom in the property panel for `:axis3d`.

**Exit**: Layer-2 covers both; goldens present; interactive rotate tested manually.

### M5 — Data ingestion — **COMPLETE (2026-08-26)**

`MainSource`, `CsvSource`, `Hdf5Source`. Data variable picker in the UI. Snapshot-by-copy invariant enforced.

**Exit** (met): M5 complete 2026-08-26. Data ingestion layer: MainSource, CsvSource, Hdf5Source, DataRef, ingest!, add_plot!; \_DEMO_DATA retired; 162 tests passing.

### M6 — Session persistence — **COMPLETE (2026-08-26)**

`.mvz` TOML save/load; `schema_version` handling; unknown-node preservation.

**Exit** (met): M6 complete 2026-08-26. Session persistence: save_session/load_session, schema version check, unknown-node preservation, DataRef provenance, build_dataref. 189 tests passing.

### M7 — Animations — **COMPLETE (2026-08-26)**

Time slider bound to a numeric attribute or data slice; `AnimBinding` in the Plot schema; MP4 + GIF export.

**Exit** (met): M7 complete 2026-08-26. AnimBinding struct, animate_plot!, render_animation (.gif/.mp4 via Makie.record), GtkScale time-slider in property pane, animation_binding renderer observer. 200 tests passing.

### M8 — Static export — **COMPLETE (2026-08-26)**

PNG/SVG/PDF export via CairoMakie in the export dialog. Layer 4 golden-image hashes committed.

**Exit** (met): M8 complete 2026-08-26. Static export: export_figure (PNG/SVG/PDF via CairoMakie), golden-image SHA-256 hashes for all 7 plot types. 225 tests passing.

### M9 — Preferences

`Scratch.jl`-backed `preferences.toml`; seed-on-new behavior; "Reset selection to preferences" action.

**Exit** (met): M9 complete 2026-08-26. Preferences: Scratch.jl-backed preferences.toml (independent schema_version), seed-on-new from prefs, reset_to_preferences!, set_theme! grep-gate. 236 tests passing.

### M10 — Pre-flight dataset check — **COMPLETE (2026-08-27)**

`detect_host_specs`, `estimate_footprint` + `estimate_fps`, `UniformStride` / `MinMaxDecimation` / `LTTB`, the `preflight_decision` threshold + `apply_downsample!`, and the REPL-facing `add_plot_checked!` warning surface.

**Exit** (met): TEST_PLAN.md §8 pre-flight tests green on the 2-cell v0.1 CI matrix (294 tests total). Per **ADR-020** (option C, 2026-08-27), v0.1 ships the coarse fallback FPS formula (`REFERENCE_VRAM_BYTES = 8 GiB`; `user_scale` clamp; 0.5 when VRAM undetectable); the full measurement pass is deferred to the M11 QA sweep, and ODQ-5 is resolved-with-fallback in DESIGN §7/§11. The Gtk4 warning modal is deferred to v0.2 (v0.1 has no GUI load flow); the v0.1 surface is the advisory `@warn` in `add_plot_checked!`. Manual spot-check on the Windows box (surface/volume at \~1e6 and \~1e7 points) confirms the fallback under-predicts fps.

### M11 — Cross-OS packaging + registration

Registrator.jl submission dry-run; CI green on the 2-cell v0.1 matrix (per ADR-018) for the full suite; LICENSE / README / semver check. **Pre-release manual verification protocol (per ADR-018): maintainer runs the full test suite manually on a Windows 11 machine and on macOS before tagging v0.1.0. Failure on either → fix or document as known limitation in release notes.**

**M10 carryovers to fold into this QA pass** (deferred from M10 per ADR-020 / spot-check on 2026-08-27): (a) **interactive-fps** sanity of the pre-flight fallback through the embedded viewport (now unblocked — Bug E fixed 2026-08-27, Task 067); (b) verify `detect_host_specs`' **VRAM-parsing branch** on a real NVIDIA box — only the `nothing` fallback has run (no `nvidia-smi` on the dev machine). The FPS **measurement pass** (three-OS reference table → `src/preflight/fps_lookup.jl`, previously carryover (a)) has been further deferred to v0.2 per ADR-020 updated 2026-08-28 — the multi-OS timing runs are disproportionate for a first release and the M10 spot-check confirmed the coarse fallback under-predicts (never over-predicts).

**Pre-tag docs reconciliation (DONE 2026-08-28, [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md)):** The README, SDD, CHANGELOG, and this PLAN described an **interactive GUI** (variable picker, Add Plot / File / Export menus, the warning-with-buttons modal) that v0.1-as-built does **not** have. ADR-022 records the scope decision: v0.1.0 ships the **REPL-driven core** — build a session with `new_session` / `add_figure!` / `add_axis!` / `ingest!` / `add_plot!` / `add_plot_checked!`, render and export via a `Renderer` + `export_figure` / `render_animation`, and `save_session` to `.mvz`; `makieviews()` previews the built-in **demo** session only. Reconciled: README (Framing-A REPL Quickstart, corrected "Large datasets" and tagline), SDD (§5.4 / §8 delivery-status layer), CHANGELOG, and this PLAN §1. The interactive GUI layer (menus, load flow, modal, live structural mutation — Bug F) is the v0.2 story; `.mvz` data round-trip (SC-004) is v0.2 too (ADR-017).

**Exit**: SDD SC-001 met (registered as v0.1.0); tagged release; pre-release manual QA report attached to release notes.

---

## 6. Constitution Check

There is no formal constitution file for FigureViews (this is a new project). If one is later added to `.specify/memory/constitution.md` for FigureViews, re-run this gate at Phase 0 and Phase 1 per Spec Kit convention.

---

## 7. Complexity Tracking

No approved deviations from architectural constraints yet. Any future deviation from SDD §7 (Forward-Looking Constraint), ADR-006 (never call `set_theme!`), or the tree-model / schema-driven rules must be recorded here with justification and a rejected simpler alternative.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *(none yet)* | | |
