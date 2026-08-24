# PLAN.md — MakieViews v0.1

**Status**: Draft
**Date**: 2026-08-24
**Companion documents**: SDD.md, DESIGN.md, ADR-001..010, TEST_PLAN.md
**Template basis**: Adapted from `.specify/templates/plan-template.md` (Spec Kit), with Summary / Technical Context / Structure retained and Milestones / Compat Pins added.

---

## 1. Summary

Ship MakieViews v0.1.0 to Julia's General registry: a Veusz-style desktop GUI over Makie for Julia scientific plotting, running on Windows, macOS, and Linux. Eleven milestones (M1–M11) from empty shell to registered package. Test-first at every milestone per TEST_PLAN.md.

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
HDF5             = "0.18"                # 0.18.0 current
Scratch          = "1"                   # 1.3.0 current
Colors           = "0.13"                # required by Gtk4Makie transitively
```

Rationale for the caret-style entries: Julia's `[compat]` interprets a bare `"0.24"` as `>= 0.24.0, < 0.25.0`, which matches the release cadence of these packages (breaking changes on minor). Bumping past a minor version requires a coordinated MakieViews release — an explicit gate rather than a silent update.

Stdlib (no compat entry): `TOML`, `UUIDs`, `SHA`, `Test`, `Sys`, `LinearAlgebra`.

CI verification job runs `] up` in a scratch environment weekly and opens a PR if upstream dependencies moved and CI stays green — never auto-merged (per ADR-002 stability caveat).

---

## 4. Repository Structure

```
MakieViews.jl/
├── Project.toml
├── LICENSE                       # MIT (registry submission requirement)
├── README.md
├── CHANGELOG.md
├── src/
│   ├── MakieViews.jl             # module root, exports makieviews()
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
│   │   ├── estimate.jl           # footprint + fps model
│   │   └── downsample.jl         # UniformStride, MinMaxDecimation, LTTB
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

**Exit**: Layer-3 GUI smoke green on all 6 CI cells; SDD SC-002 (blank session) partially met.

### M2 — Tree + one plot type
`SessionState` with Session/Figure/Axis/Plot tree; `PLOT_SCHEMAS[:line]` populated; tree pane + property pane wired; end-to-end for a hand-constructed line plot.

**Exit**: Layer-2 integration passes for line; property panel schema-driven test passes for line.

### M3 — Remaining 2D plot types
Schemas + rendering for `:scatter`, `:bar`, `:heatmap`, `:contour`.

**Exit**: Layer-2 covers all four; goldens present for each.

### M4 — 3D plot types + camera controls
Schemas + rendering for `:surface`, `:volume`. Camera azimuth/elevation/zoom in the property panel for `:axis3d`.

**Exit**: Layer-2 covers both; goldens present; interactive rotate tested manually.

### M5 — Data ingestion
`MainSource`, `CsvSource`, `Hdf5Source`. Data variable picker in the UI. Snapshot-by-copy invariant enforced.

**Exit**: Layer-2 covers all three sources including edge cases from TEST_PLAN.md §6.

### M6 — Session persistence
`.mvz` TOML save/load; `schema_version` handling; unknown-node preservation.

**Exit**: Round-trip test (TEST_PLAN.md §3) green for every plot type + `:axis3d`; unknown-node preservation test green.

### M7 — Animations
Time slider bound to a numeric attribute or data slice; `AnimBinding` in the Plot schema; MP4 + GIF export.

**Exit**: Layer-2 animation-export test green; manual QA of one time-varying dataset.

### M8 — Static export
PNG/SVG/PDF export via CairoMakie in the export dialog. Layer 4 golden-image hashes committed.

**Exit**: All 7 golden images match on all 6 cells; PDF/SVG validity checks pass.

### M9 — Preferences
`Scratch.jl`-backed `preferences.toml`; seed-on-new behavior; "Reset selection to preferences" action.

**Exit**: All layer-9 preferences tests (TEST_PLAN.md §9) pass; the grep-gate for `set_theme!` passes.

### M10 — Pre-flight dataset check
`detect_host_specs`, `estimate_footprint`, warning dialog, `UniformStride` / `MinMaxDecimation` / `LTTB`. ODQ-5 formula (from DESIGN.md §11) measured and published.

**Exit**: TEST_PLAN.md §8 tests green; measurement pass documented; DESIGN.md §7 ODQ-5 marked resolved with a new ADR-018.

### M11 — Cross-OS packaging + registration
Registrator.jl submission dry-run; CI green on all 6 cells for the full suite; LICENSE / README / semver check.

**Exit**: SDD SC-001 met (registered as v0.1.0); tagged release.

---

## 6. Constitution Check

There is no formal constitution file for MakieViews (this is a new project). If one is later added to `.specify/memory/constitution.md` for MakieViews, re-run this gate at Phase 0 and Phase 1 per Spec Kit convention.

---

## 7. Complexity Tracking

No approved deviations from architectural constraints yet. Any future deviation from SDD §7 (Forward-Looking Constraint), ADR-006 (never call `set_theme!`), or the tree-model / schema-driven rules must be recorded here with justification and a rejected simpler alternative.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *(none yet)* | | |
