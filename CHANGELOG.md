# Changelog

All notable changes to MakieViews will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

*No changes yet.*

## Pre-release development history (M1–M11)
### M11 — Pre-tag docs reconciliation (2026-08-28)
- **ADR-022**: v0.1.0 ships the REPL-driven core; the interactive Veusz-style GUI is deferred to v0.2+. README, SDD (§5.4 / §8 delivery-status layer), CHANGELOG, and PLAN reconciled to the REPL-driven scope. The Veusz-style GUI remains the project's north star.
- Surfaced v0.1 limitations in-doc: `.mvz` load restores tree+styling but not data (full round-trip is v0.2, ADR-017); `makieviews()` displays the built-in demo session only; live structural edits to a displayed window hang (Bug F, v0.2).
- Removed a stray document-manager JSON metadata block that had been prepended to this file.
### M10 — Pre-flight dataset check (2026-08-27)
- Added `detect_host_specs()` → `HostSpecs` (total RAM, CPU threads, best-effort GPU VRAM/name via nvidia-smi / system_profiler; never throws, degrades to `nothing` on missing GPU per FR-026).
- Added `estimate_footprint(array)` (bytes = length × sizeof(eltype)) and `estimate_fps(plot_type, n, host)` — coarse fallback `60/√(n/1e6)` (2D) / `30/√(n/1e6)` (3D) × `user_scale` (`REFERENCE_VRAM_BYTES = 8 GiB`; `user_scale = 0.5` when VRAM undetectable).
- Added three downsampling algorithms over 1-D (x,y): `UniformStride`, `MinMaxDecimation`, `LTTB` (Steinarsson 2013); all preserve first/last points and monotonic x (ADR-010).
- Added `preflight_decision(host, array, plot_type)` → `(:accept | :warn, reason, est_fps, est_bytes)` with the threshold `est_fps < 15 OR bytes > 60% VRAM` (VRAM term skipped when undetectable); `record_downsample!` and `apply_downsample!` (materialize reduced snapshots, repoint `:x`/`:y` refs, retain the full arrays — DESIGN §7.1).
- Added exported `add_plot_checked!(ax, type, refs; session, host, downsample)` — the v0.1 REPL pre-flight surface: advisory `@warn` (est MB/fps/reason) on `:warn`, `downsample=<algo>` reduces (option C, ADR-020). The Gtk4 warning modal is deferred to v0.2 (no GUI load flow in v0.1).
- **ADR-020**: the FPS measurement pass is deferred to the M11 pre-release QA sweep; v0.1 ships the coarse fallback formula guarded by a manual spot-check. ODQ-5 resolved-with-fallback (DESIGN §7/§11).
### M9 — Preferences (2026-08-26)
- Added Scratch.jl-backed preferences.toml (load_preferences, save_preferences, preferences_path) with its own schema_version independent of .mvz (ADR-016).
- New plots seed attrs from preferences (default_<attr> keys; palette cycles for :color across plots in an axis), falling back to spec defaults; add_plot! gains an optional prefs kwarg.
- Added reset_to_preferences!(plot, prefs) — overwrites a plot's attrs from preferences.
- ADR-006 grep-gate test: set_theme!( appears nowhere in src/. Preferences are defaults-only; the theme is never mutated.
- Added Scratch as a direct dependency.
### M8 — Static export (2026-08-26)
- Added `export_figure(renderer, path)` — exports renderer.fig to PNG, SVG, or PDF via CairoMakie (format inferred from extension). Switches to CairoMakie and restores GLMakie in try/finally. Main-thread, synchronous (ADR-014).
- Golden-image SHA-256 hashes committed for all 7 plot types (test/goldens/hashes.toml). PNG output confirmed deterministic across 3 runs on this machine.
- Hash-verification testset re-renders each plot type with fill(1.0) arrays and checks exact SHA-256 match.
- Note: hashes must be regenerated on Makie minor version bumps.
- CairoMakie added as explicit direct dep (was transitive). SHA added to test extras.
- Key learning: CairoMakie requires explicit `using CairoMakie` in MakieViews.jl even when already a transitive dep.
### M7 — Animations (2026-08-26)
- Added `AnimBinding` struct: snapshot_id, frame_count, fps, current_frame (immutable; time slider swaps via observable replacement).
- Added `animate_plot!(session, plot_node, snapshot_id, frame_count; fps=30)` — validates 3D array A[x,y,t] and sets the animation binding observable.
- Added `render_animation(session, renderer, plot_node, path; fps)` — headless frame export to .gif or .mp4 via Makie.record/recordframe!. Main-thread only (ADR-014).
- Added GtkScale time-slider to property pane: shown when selected plot has an AnimBinding; dragging replaces the binding with updated current_frame.
- Renderer observes `animation_binding` and swaps the :matrix Observable in the Makie handle per frame.
- AnimBinding serialized/deserialized in .mvz [animation] sub-table.
- Three Layer 2 integration tests: AnimBinding fields, save/load round-trip, GIF export file size > 0.
- Key finding: FFMPEG_jll accessible via Makie.FFMPEG_jll (not as a direct dep); Makie.record(func, fig, path; framerate=fps) confirmed API.
### M6 — Session persistence (2026-08-26)
- Added `save_session(session, path)` — serializes full Session tree to `.mvz` TOML (schema_version = "1.0").
- Added `load_session(path)` — reconstructs Session from `.mvz`; major-version mismatch errors; same-major newer-minor warns; `data_inline` rejected with explicit error.
- Unknown plot/axis type strings wrapped in `UnknownNode` and round-tripped verbatim.
- `Axis.plots` and `Figure.axes` updated to `Union{..., UnknownNode}` vector types.
- Color attrs serialized as hex strings; coerced back to `Colors.RGB` on load. Tuple attrs (colorrange) serialized as arrays.
- Added `build_dataref(source, id, role, snapshot_id)` — fills provenance fields (absolute_path, relative_path, column, dataset, variable) from source type.
- Public API exported: `save_session`, `load_session`, `add_plot!`, `ingest!`, `build_dataref`, `DataRef`, `MainSource`, `CsvSource`, `Hdf5Source`, `DataVar`.
- Seven integration test suites: round-trip tree structure, all 7 plot types, camera state, color hex, unknown-node preservation + re-save, major-version error, data_inline rejection.
- Pre-M6 fixes: D1 color picker (92c95f0), D3 tree selection pos vs Gtk4.selected (3a9f517).
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

## [0.1.0] — 2026-08-28

Initial release scope. See `docs/SDD.md` §5 for the full requirement list and `docs/PLAN.md` for the M1–M11 breakdown. **v0.1.0 ships the REPL-driven core; the interactive point-and-click GUI is v0.2+ ([ADR-022](docs/adr/ADR-022-v0-1-ships-repl-driven.md)).**

### Added
- Gtk4.jl + Gtk4Makie.jl desktop shell with an embedded GLMakie viewport (displays the built-in demo session in v0.1; the interactive GUI is v0.2).
- Tree model: Session → Figure → Axis → Plot, with `UnknownNode` escape hatch for forward-compatible session files.
- Seven plot types: line, scatter, bar, heatmap, contour, surface (3D), volume (3D).
- Schema-driven property panel — no per-plot-type UI branching (see ADR-002, DESIGN.md §5).
- Three data ingestion sources: Julia REPL `Main`, CSV (CSV.jl + DataFrames.jl), HDF5 (HDF5.jl).
- `.mvz` session save/load with `schema_version` and unknown-node preservation.
- Static export: PNG, SVG, PDF via CairoMakie.
- Animation: `animate_plot!` time-index binding over a 3D array `A[x, y, t]`, with MP4/GIF export via `render_animation`.
- Per-user preferences via Scratch.jl-backed TOML; defaults-only, with a `reset_to_preferences!` action.
- Pre-flight dataset check: host-spec detection, footprint and FPS estimate, an advisory `@warn` via `add_plot_checked!`, and downsampling via `downsample=` (uniform stride, min/max decimation, LTTB).

### Compat
- Julia 1.10+ (primary target: 1.12).
- Makie 0.24.13 (exact pin), GLMakie 0.13.13 (exact pin), CairoMakie 0.15.13 (exact pin), Gtk4 0.7.12+, Gtk4Makie 0.3.9+, CSV 0.10.16+, DataFrames 1.8.2+, HDF5 0.17+, Scratch 1.3.0+. Exact pins on Makie/GLMakie/CairoMakie are intentional for v0.1.0 reproducibility; see `docs/RELEASE-READINESS.md` §1.

### Known limitations
- No undo/redo (planned for v0.2).
- No user-defined `@recipe` types exposed through the GUI (users extend via code).
- No in-GUI data transformations.
- No WGLMakie / web viewport.
- Interactive point-and-click GUI is v0.2+; v0.1 is REPL-driven (ADR-022).
- `.mvz` load restores the tree and styling but not data arrays; full save/reload round-trip is v0.2 (ADR-017).
- `makieviews()` displays the built-in demo session only; displaying a user-built session, and live structural edits to a displayed window, are v0.2 (Bug F).
- macOS untested for v0.1.0 — GHA headless runners cannot initialize GLMakie (NSGL pixel-format failure on Apple Silicon VMs); macOS CI requires conditional backend loading (v0.2 backlog). Interactive macOS verification also deferred. See [ADR-023](docs/adr/ADR-023-defer-interactive-macos-to-post-v0-1.md).
- Linux Wayland + NVIDIA driver quirks inherited from Gtk4Makie (see `docs/troubleshooting.md`).
- On Windows, a cosmetic `ModernGL.ContextNotAvailable` stacktrace appears at process exit after `Pkg.test()` (GLMakie/Gtk4Makie teardown ordering; no test is affected).
- CairoMakie does not support volume rendering; volume PNG/SVG/PDF export produces a blank canvas (CairoMakie upstream limitation).

[Unreleased]: https://github.com/XerxesZorgon/MakieViews.jl/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/XerxesZorgon/MakieViews.jl/releases/tag/v0.1.0
