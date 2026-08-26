# Changelog

All notable changes to MakieViews will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### M5 — Data ingestion (2026-08-26)
- Added CSV.jl, DataFrames.jl, HDF5.jl as direct dependencies (HDF5 compat corrected to 0.17).
- Added `DataSource` abstract interface and `DataVar` struct (`src/data/source.jl`).
- Added `Session.data_snapshots::Dict{String,AbstractArray}` field.
- Implemented `MainSource`, `CsvSource`, `Hdf5Source` with `enumerate_variables`/`snapshot`.
- Added `ingest!(session, source, id)` and `add_plot!(ax, type, data_refs)` as the stable programmatic API.
- `DataRef` updated with `snapshot_id` and `label` fields; 4-arg convenience constructor added.
- `_DEMO_DATA` scaffolding and all seven per-type `add_*_plot!` demo functions deleted.
- `makieviews()` demo now uses a module-level synthetic dataset + `MainSource` + `ingest!`.
- Layer 2 integration tests added for all three sources; all tests updated to use `add_plot!` + `DataRef`. 162 total passes.
- Key learnings: `Core.eval` into a fresh Module inside a running function causes a world-age error — use module-level static definition instead. `convert(Vector{Float64}, col)` on a same-type DataFrame column aliases rather than copies — always `copy()` for snapshot independence.

- 2026-08-25 — Task 032: fixed tree-pane row instantiation and string access; extracted `_build_tree_rows` with unit test.
- 2026-08-25 — Task 033: fixed viewport layout to grant Makie canvas the majority width; added Manual GUI launch gate to TEST_PLAN.
- 2026-08-24 — M0 (ADR closure) complete: ADR-011..ADR-017 written for the seven open design questions; DESIGN.md §11 cleared. `tasks.md` writing is unblocked.
- 2026-08-24 — Planning documents (SDD, DESIGN, ADR-001..010, TEST_PLAN, PLAN, README, CHANGELOG) drafted.

## [0.1.0] — TBD

Initial release scope. See `docs/SDD.md` §5 for the full requirement list and `docs/PLAN.md` for the M1–M11 breakdown.

### Added
- Gtk4.jl + Gtk4Makie.jl desktop shell with an embedded GLMakie viewport.
- Tree model: Session → Figure → Axis → Plot, with `UnknownNode` escape hatch for forward-compatible session files.
- Seven plot types: line, scatter, bar, heatmap, contour, surface (3D), volume (3D).
- Schema-driven property panel — no per-plot-type UI branching (see ADR-002, DESIGN.md §5).
- Three data ingestion sources: Julia REPL `Main`, CSV (CSV.jl + DataFrames.jl), HDF5 (HDF5.jl).
- `.mvz` session save/load with `schema_version` and unknown-node preservation.
- Static export: PNG, SVG, PDF via CairoMakie.
- Animation: time slider binding + MP4 and GIF export.
- Per-user preferences via Scratch.jl-backed TOML; defaults-only behavior with a "Reset selection to preferences" action.
- Pre-flight dataset check: host-spec detection, footprint and FPS estimate, non-blocking warning, downsampling offer (uniform stride, min/max decimation, LTTB).

### Compat
- Julia 1.10+ (primary target: 1.12).
- Makie 0.24.x, GLMakie 0.13.x, CairoMakie 0.15.x, Gtk4 0.7.x, Gtk4Makie 0.3.x, CSV 0.10.x, DataFrames 1.8.x, HDF5 0.18.x, Scratch 1.x.

### Known limitations
- No undo/redo (planned for v0.2).
- No user-defined `@recipe` types exposed through the GUI (users extend via code).
- No in-GUI data transformations.
- No WGLMakie / web viewport.
- Linux Wayland + NVIDIA driver quirks inherited from Gtk4Makie (see `docs/troubleshooting.md`).

[Unreleased]: https://github.com/PLACEHOLDER-USER/MakieViews.jl/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/PLACEHOLDER-USER/MakieViews.jl/releases/tag/v0.1.0
