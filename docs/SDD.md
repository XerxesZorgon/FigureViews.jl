# Software Description Document: FigureViews

**Version**: v0.1 (initial release scope)
**Created**: 2026-08-24
**Status**: Draft — pending review
**Template basis**: Adapted from `.specify/templates/spec-template.md` (Spec Kit), extended with Problem/Users/Scope/Forward-Looking Constraint sections.

---

> **v0.1.0 delivery scope.** FigureViews v0.1.0 ships a **REPL-driven core**, not the interactive GUI. The requirements below remain the project's target and describe the Veusz-style GUI that is the north star; they are **not** rewritten. Instead, each is marked with its v0.1 delivery status — **Delivered (v0.1)**, **Partial**, **Deferred (v0.2)**, or **Pending (M11)** — in §5.4 (functional/non-functional) and §8 (success criteria). The GUI affordances the requirements name (variable picker, Add Plot menu, property-panel-as-primary-flow, File dialogs, non-blocking warning dialog) are Deferred (v0.2); their underlying capabilities ship in v0.1 as REPL functions where noted. See [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md).

---

## 1. Problem Statement

Julia's Makie ecosystem is the most capable scientific plotting library in Julia, but every plot requires code. Julia users who want interactive, exploratory plotting — the [Veusz](https://veusz.github.io/) workflow: click-to-build figures, live property editing, saveable sessions, 3D rotation — have no equivalent Julia-native tool. FigureViews closes this gap with a first-class Julia package: a Veusz-style GUI (graphical user interface) over Makie's public API, preserving GLMakie's full 3D and animation capability while eliminating the code-writing friction for standard plotting workflows. In v0.1, this capability is delivered through a REPL API (build → style → export → save); the click-to-build GUI described here is the v0.2+ target (see the v0.1.0 delivery-scope note above and [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md)).

## 2. Primary Users

Julia users doing scientific plotting who want to reduce friction on exploratory work — including current Veusz-plus-Python users who want to stay in Julia end-to-end.

## 3. Terms

- **GUI**: graphical user interface — the point-and-click desktop application.
- **REPL**: read-eval-print loop — Julia's interactive command prompt.
- **Makie**: the underlying Julia plotting engine that FigureViews drives.
- **GLMakie**: Makie's OpenGL backend (interactive window, 3D, animation).
- **CairoMakie**: Makie's Cairo backend (static export to PNG/SVG/PDF).
- **Gtk4**: the GNOME toolkit version 4, used for the desktop shell (menus, docking, tree view, dialogs).
- **`.mvz` file**: FigureViews' saved session format — a TOML (Tom's Obvious Minimal Language) document.
- **LTTB**: largest-triangle-three-buckets, a line-plot downsampling algorithm that preserves visual shape.

---

## 4. User Scenarios *(mandatory)*

> **v0.1 note.** These journeys describe the **v0.2 GUI target**. In v0.1 the same capabilities are exercised through the REPL API (see the README Quickstart): the GUI affordances named below — variable picker, Add Plot menu, property panel, File→Save/Export dialogs, time slider — are Deferred (v0.2) per [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md). The per-requirement status is in §5.4 and §8.

### User Story 1 — Build and save a labeled 3D surface (Priority: P1)

**Journey**: A user launches FigureViews from the Julia REPL, picks a matrix variable already in their session, chooses "Surface" from the Add Plot menu, edits title/axis labels/camera angle in the property panel, drags the plot to rotate it, saves the session as `analysis.mvz`, and exports a PNG.

**Why this priority**: This is the atomic v0.1 success criterion. If a user cannot do this end-to-end, FigureViews has not shipped.

**Independent Test**: On a fresh install, launch → ingest a `Matrix{Float64}` from `Main` → build a surface plot with a title → save `.mvz` → export PNG. Verify PNG contents visually and `.mvz` round-trips.

**Acceptance Scenarios**:
1. **Given** the user runs `using FigureViews; makieviews()` in a REPL with `z = randn(50, 50)` defined, **When** they select `z` in the variable picker and click Add Plot → Surface, **Then** a 3D surface renders in the viewport.
2. **Given** a surface plot is selected, **When** the user edits the "Camera azimuth" numeric field to 45°, **Then** the viewport updates to that camera angle within one frame.
3. **Given** the user clicks Save As → `analysis.mvz`, closes FigureViews, then reopens and loads `analysis.mvz`, **Then** the resulting figure is visually identical to the saved one.

### User Story 2 — Build 2D exploratory plots from a CSV (Priority: P1)

**Journey**: A user loads a CSV, drags a column to the X-axis, another to Y, chooses "Scatter", adds a second series with a different color, and exports SVG for a paper.

**Why this priority**: The most common Veusz workflow. Covers CSV ingestion + 2D property editing + static export together.

**Independent Test**: Load a CSV with two numeric columns → build a two-series scatter plot with distinct colors → export SVG → open the SVG externally and verify both series render.

**Acceptance Scenarios**:
1. **Given** a CSV with columns `x, y1, y2`, **When** the user opens File → Load CSV and points at the file, **Then** the column names appear in the variable picker as selectable arrays.
2. **Given** two scatter series exist, **When** the user changes series 1's color in the property panel from default to `#e15759`, **Then** the viewport reflects the change immediately.
3. **Given** the user clicks File → Export → SVG, **Then** a valid SVG file is produced by CairoMakie containing both series.

### User Story 3 — Animate a time-varying dataset and export MP4 (Priority: P2)

**Journey**: A user loads an HDF5 dataset with a time axis, binds the time slider to the time index, previews the animation in the viewport, and exports `.mp4`.

**Why this priority**: Animations are a Makie strength; keeping them GUI-accessible in v0.1 differentiates FigureViews from any code-free alternative that lacks them.

**Independent Test**: Load a 3D array `f[x, y, t]` from HDF5 → build a heatmap of `f[:, :, t]` → bind t to the time slider (1..T) → play → export MP4 → verify MP4 duration matches T/fps.

**Acceptance Scenarios**:
1. **Given** an HDF5 file containing a 3D array, **When** the user selects it via File → Load HDF5, **Then** its datasets appear in the variable picker.
2. **Given** a heatmap plot exists with a `t` slice attribute, **When** the user drags the time slider, **Then** the viewport heatmap updates in real time.
3. **Given** the user clicks Export → MP4 with fps=30, **Then** a valid `.mp4` is written with duration = frames/30 seconds.

### User Story 4 — Preferences seed new figures without disturbing saved ones (Priority: P2)

**Journey**: A user sets preferred font family, line width, and color palette. They open a saved figure with old styling — it loads exactly as saved. They create a new figure — it uses the new preferences. They select the old plot and click "Reset selection to preferences" — it now uses new preferences.

**Why this priority**: Preserves the "the plot I saved is the plot I get back" contract while making preferences useful. Non-obvious behavior that must be explicit.

**Independent Test**: Save a red-line figure. Change palette preference to blue-first. Reopen the file → line is still red. Create new figure → line is blue. Click "Reset to preferences" on the old line → line becomes blue.

**Acceptance Scenarios**:
1. **Given** preferences declare `default_linewidth = 3`, **When** the user creates a new line plot, **Then** the new plot's linewidth is 3.
2. **Given** a saved figure with `linewidth = 1`, **When** the user opens it after changing the preference to 3, **Then** the plot renders with linewidth 1.
3. **Given** the user selects that saved plot and clicks "Reset selection to preferences", **Then** the plot's linewidth becomes 3.

### User Story 5 — Large-dataset pre-flight warns and offers downsampling (Priority: P2)

**Journey**: A user loads a 10-million-point scatter dataset. FigureViews estimates GPU memory and frame rate, raises a non-blocking warning, and offers three downsampling options with previews of resulting point count.

**Why this priority**: Protects against the "GUI hangs and I can't recover" experience that would kill trust on first use. Frames the trade-off explicitly and lets the user override.

**Independent Test**: Load a synthetic 10M-point dataset on a laptop-class GPU → confirm warning appears with estimate → accept LTTB downsampling → verify resulting plot has the promised point count.

**Acceptance Scenarios**:
1. **Given** an incoming dataset whose estimated VRAM footprint exceeds 60% of detected VRAM, **When** the user confirms loading, **Then** a non-blocking dialog reports estimated VRAM MB, estimated FPS, and offers Accept / Downsample / Override.
2. **Given** the user picks LTTB with target 100k points on a 10M line plot, **When** they confirm, **Then** the plot renders with exactly 100k retained points and the underlying data reference is preserved for later re-render at full resolution.
3. **Given** the host driver does not report VRAM, **When** a large dataset is loaded, **Then** the warning falls back to `"GPU unknown, proceeding without VRAM estimate"` and does not block.

### User Story 6 — Fresh Windows/macOS/Linux install works (Priority: P1)

**Journey**: A new user on any of the three supported OSes runs `] add FigureViews`, then `using FigureViews; makieviews()`, and sees a blank FigureViews window within a minute of package precompilation.

**Why this priority**: If installation is broken on any platform, no other story matters for that user.

**Independent Test**: On a clean CI runner for each of Windows, macOS, and Linux (headless Linux under xvfb), `] add FigureViews` and launch to a blank session. No manual steps.

**Acceptance Scenarios**:
1. **Given** a clean Julia 1.12 install, **When** the user runs `] add FigureViews`, **Then** the package resolves and precompiles without error.
2. **Given** FigureViews is installed, **When** the user runs `makieviews()`, **Then** a Gtk4 window opens with an embedded (empty) Makie viewport.

---

### Edge Cases

- **Empty `Main`**: user launches with no variables defined → variable picker shows an explicit empty state, not an error.
- **REPL variable renamed/deleted between load and re-render**: FigureViews holds a snapshot of the data at ingest time; a later change in `Main` does not silently mutate the plot.
- **HDF5 file contains non-numeric datasets** (strings, compound types): picker lists them but greys them out with an explanatory tooltip; user cannot accidentally load an unplottable dataset.
- **CSV with mixed types in a column** (e.g., `"1", "2", "n/a"`): CSV.jl types the column as `String`; the picker greys it out for numeric plots and offers a note about cleaning in Julia.
- **Session file from a future schema version**: on load, FigureViews inspects `schema_version` and refuses with a clear message ("this file was saved by FigureViews vX.Y, please upgrade") rather than best-effort loading.
- **Session file with unknown node type** (e.g., a future custom recipe): the tree preserves the node as an opaque record with a "cannot render — unknown type" placeholder, and the file round-trips without dropping it.
- **GPU driver crash while resizing viewport**: the app catches the OpenGL context loss and offers a "restart viewport" action rather than dying.
- **User exports to a directory they cannot write**: caught before rendering; error dialog names the path.
- **User saves `.mvz` mid-animation**: the current frame's rendered state is not saved; the animation binding *is* saved so reload restores the same time slider position.

---

## 5. Requirements *(mandatory)*

### 5.1 Functional Requirements

#### Data ingestion (v0.1 sources)

- **FR-001**: FigureViews MUST enumerate variables in the calling Julia session's `Main` namespace when launched as `makieviews()` from the REPL, filtering to array-like types plottable by Makie (`AbstractVector`, `AbstractMatrix`, `AbstractArray{<:Real, 3}`, `DataFrame`).
- **FR-002**: FigureViews MUST support loading CSV files via CSV.jl + DataFrames.jl, with the resulting columns appearing as selectable variables.
- **FR-003**: FigureViews MUST support loading HDF5 files via HDF5.jl, with datasets appearing as selectable variables preserving their group path.
- **FR-004**: On ingest, FigureViews MUST snapshot the data by copy — later mutations of the underlying variable in `Main` do not affect already-plotted data.

#### Plot types (v0.1)

- **FR-005**: FigureViews MUST support the following seven plot types, each configurable through the GUI without writing code: line, scatter, bar, heatmap, contour, surface (3D), volume (3D).
- **FR-006**: FigureViews MUST allow the user to add, delete, reorder, and rename plots and axes through the tree view.

#### Property editing

- **FR-007**: The property panel MUST expose, for each plot type: titles, axis labels, axis limits, log/linear scale, gridline visibility, tick format, legend visibility, per-series color, marker shape/size, and line width.
- **FR-008**: For 3D plots, the property panel MUST expose numeric camera azimuth, elevation, and zoom fields whose edits are reflected in the viewport within one frame.
- **FR-009**: The property panel's field set MUST be schema-driven — derived from the plot object's Makie attribute set — so that new plot types added in future versions require declaring a schema, not writing new UI code (see Forward-Looking Constraint in §7).

#### Tree model

- **FR-010**: FigureViews MUST maintain a tree with node types Session, Figure, Axis, Plot (with subtypes for the seven plot types).
- **FR-011**: The tree node schema MUST generalize to additional node types in later versions without a redesign (see §7).

#### 3D interaction

- **FR-012**: The GLMakie viewport MUST support mouse-driven rotate, pan, and zoom for 3D plots using Makie's standard camera controls.

#### Animation

- **FR-013**: FigureViews MUST allow binding a time slider to any numeric attribute or data slice through the GUI.
- **FR-014**: FigureViews MUST export animations to `.mp4` and `.gif` at a user-specified frame rate.

#### Session persistence

- **FR-015**: FigureViews MUST save sessions as a `.mvz` TOML file including a top-level `schema_version` field.
- **FR-016**: FigureViews MUST reload a saved `.mvz` and produce a figure tree visually identical to the one saved.
- **FR-017**: FigureViews MUST reject `.mvz` files whose `schema_version` is higher than the loader's supported version, with a clear error naming the required version.
- **FR-018**: FigureViews MUST preserve unknown-node-type entries when loading a `.mvz` file from a future compatible version, rendering them as opaque placeholders and round-tripping them on save (see §7).

#### Static export

- **FR-019**: FigureViews MUST export the current figure to PNG, SVG, and PDF via CairoMakie.

#### Preferences

- **FR-020**: FigureViews MUST persist user preferences (font family/size, line width, marker types, color palette, grid defaults) in a per-user TOML file managed via Scratch.jl.
- **FR-021**: Preferences MUST seed new figures only — existing figures load with their saved styling untouched.
- **FR-022**: FigureViews MUST provide a "Reset selection to preferences" action that applies current preferences to selected tree nodes on demand.

#### Pre-flight dataset check

- **FR-023**: On dataset load, FigureViews MUST inspect host specs (`Sys.total_memory()`, GPU VRAM if detectable, CPU count) and estimate memory footprint and expected frame rate.
- **FR-024**: If the estimate exceeds a threshold (>60% of available VRAM, or estimated <15 fps sustained over a 2-second window), FigureViews MUST raise a non-blocking warning showing the estimate and offering Accept / Downsample / Override.
- **FR-025**: Downsampling options MUST include uniform stride, min/max decimation, and LTTB (for line plots only).
- **FR-026**: If GPU VRAM cannot be detected, FigureViews MUST fall back to the message "GPU unknown, proceeding without VRAM estimate" and permit loading without blocking.

### 5.2 Non-Functional Requirements

- **NFR-001** (Forward compatibility of session format): The `.mvz` schema MUST use a versioned schema and MUST reserve unknown-node-type handling on load. See §7.
- **NFR-002** (Schema-driven UI): The property panel's implementation MUST NOT branch on hard-coded plot-type names. See §7 and FR-009.
- **NFR-003** (Cross-platform): The v0.1 release MUST install and launch to a blank session on Windows, macOS, and Linux (Linux headless via xvfb for CI).
- **NFR-004** (Distribution): The v0.1 release MUST be installable via `] add FigureViews` from Julia's General registry.
- **NFR-005** (Startup): First launch after precompilation MUST reach a blank interactive window in under 10 seconds on a laptop-class machine (2020 or newer).

### 5.3 Key Entities

- **Session**: root of the tree; holds a list of Figures and the session-level preferences snapshot used to seed new figures.
- **Figure**: a Makie `Figure`; holds a list of Axes and figure-level layout data.
- **Axis**: a Makie `Axis` (2D) or `Axis3` (3D); holds a list of Plots and axis-level configuration (titles, limits, scale).
- **Plot**: a typed leaf (line, scatter, bar, heatmap, contour, surface, volume); holds a reference to its data snapshot and a bag of styling attributes conforming to its schema.
- **Data snapshot**: an immutable copy of the ingested data plus provenance (`{source: "Main"|"csv"|"hdf5", key, ingested_at}`).
- **Preferences**: a per-user TOML document (styling defaults) plus a UI action ("Reset selection to preferences") that applies them on demand.
- **`.mvz` file**: TOML document with `schema_version`, a preferences snapshot, and the serialized tree.

### 5.4 v0.1.0 Delivery Status

v0.1.0 ships the REPL-driven core (ADR-022). Legend: **Delivered** = works in v0.1; **(REPL)** = delivered as a REPL call, GUI affordance deferred; **Partial** = capability present, full requirement not met; **Deferred v0.2**; **Pending M11** = release-task not yet done; **Unverified** = not yet measured.

| Requirement | v0.1 status | Note |
|---|---|---|
| FR-001 | Partial | `MainSource` enumerates `Main`; GUI variable picker deferred v0.2 |
| FR-002 | Delivered (REPL) | `CsvSource`; GUI load dialog deferred v0.2 |
| FR-003 | Delivered (REPL) | `Hdf5Source`; GUI load dialog deferred v0.2 |
| FR-004 | Delivered | snapshot-by-copy in `ingest!` |
| FR-005 | Partial | 7 types via `add_plot!`; "through the GUI" deferred v0.2 |
| FR-006 | Deferred v0.2 | tree add/delete/reorder/rename is a GUI action; live structural edit blocked by Bug F |
| FR-007 | Partial | property schema + panel exist (demo window); user-data editing flow deferred v0.2 |
| FR-008 | Partial | camera azimuth/elevation wired; property-panel flow deferred v0.2 |
| FR-009 | Delivered | schema-driven panel (architecture) |
| FR-010 | Delivered | tree model Session→Figure→Axis→Plot |
| FR-011 | Delivered | node type is data; generalizes |
| FR-012 | Delivered | GLMakie rotate/pan/zoom on the displayed window |
| FR-013 | Partial | `animate_plot!` binds a time index (REPL); general GUI slider binding deferred v0.2 |
| FR-014 | Delivered | `render_animation` → MP4/GIF at fps |
| FR-015 | Delivered | `save_session` + `schema_version` |
| FR-016 | Deferred v0.2 | load restores tree+styling, **not data**; full round-trip deferred v0.2 (ADR-017) |
| FR-017 | Delivered | future-major `.mvz` rejected with a clear error |
| FR-018 | Delivered | unknown nodes preserved and round-tripped |
| FR-019 | Delivered | `export_figure` → PNG/SVG/PDF |
| FR-020 | Delivered | preferences TOML via Scratch.jl |
| FR-021 | Delivered | preferences seed new plots only |
| FR-022 | Delivered (REPL) | `reset_to_preferences!`; GUI action deferred v0.2 |
| FR-023 | Delivered | host detection + footprint/fps estimate |
| FR-024 | Partial | decision + advisory `@warn` (REPL); non-blocking dialog deferred v0.2 (ADR-020) |
| FR-025 | Delivered | UniformStride / MinMaxDecimation / LTTB |
| FR-026 | Delivered | VRAM-undetectable fallback message |
| NFR-001 | Delivered | versioned `.mvz` + unknown-node preservation |
| NFR-002 | Delivered | no hard-coded per-plot-type UI branching |
| NFR-003 | Partial | Linux (CI) + Windows (dev) verified; macOS pending pre-release gate (ADR-018); v0.1 launches to a demo session, not a blank one |
| NFR-004 | Pending M11 | General-registry registration is an M11 task |
| NFR-005 | Unverified | startup budget not yet measured across OSes |

---

## 6. Out of Scope for v0.1

- Undo / redo (planned for v0.2).
- User-defined `@recipe` plot types exposed through the GUI (users extend via code).
- Reactive callbacks or arbitrary Observable wiring through the GUI.
- In-GUI data transformations (filtering, fitting, smoothing, unit conversion) — do these in Julia.
- Multi-user or collaborative editing.
- Plugin API.
- Custom themes beyond Makie's built-ins and the user's preferences.
- Web deployment / WGLMakie viewport (GLMakie only for v0.1).

---

## 7. Forward-Looking Architectural Constraint *(mandatory, v0.2+)*

Makie's plotting ecosystem is broad and will continue to grow — user recipes, complex compound widgets, richer interaction models. The v0.1 architecture **must not paint us into a corner**. Three constraints hold:

1. **Tree model generalizes**: node type is data, not a hard-coded enum. Adding a "custom recipe node" or "compound plot node" in v0.2 must be a schema declaration, not a UI rewrite.
2. **Property panel is schema-driven**: fields are derived from the plot object's attribute schema at render time. Hard-coded per-plot-type UI code is forbidden.
3. **`.mvz` is forward- and backward-compatible**: top-level `schema_version` present; unknown node types preserved on load as opaque records with a placeholder in the tree; save round-trips them exactly.

These constraints are referenced from ADR-004 (session format), ADR-006 (property panel derivation strategy), and DESIGN.md §2 and §3.

---

## 8. Success Criteria *(mandatory)*

### Measurable Outcomes (v0.1)

- **SC-001** (Registered): FigureViews is registered in Julia's General registry as v0.1.0; `] add FigureViews` resolves without error on Windows, macOS, and Linux with Julia 1.12.
- **SC-002** (Blank session): A new user on any of the three OSes reaches a blank interactive FigureViews window within one minute of `] add FigureViews` completing (excluding first-time precompilation).
- **SC-003** (End-to-end atomic test): A new user can ingest a matrix from either the REPL or a CSV/HDF5 file and produce, save, and reload a labeled 3D surface plot with a rotated camera and PNG/SVG/PDF export — without writing any plotting code.
- **SC-004** (Round-trip fidelity): Session round-trip (save → close → reopen) produces a figure that passes a golden-image test against the original at pixel-hash equality via CairoMakie static export.
- **SC-005** (Seven plot types): All seven plot types (line, scatter, bar, heatmap, contour, surface, volume) can be created through the GUI, styled through the property panel, and exported statically.
- **SC-006** (Pre-flight warns): Loading a dataset that exceeds thresholds triggers the non-blocking warning; declining the offered downsampling still permits loading; accepting produces a plot with the promised point count.
- **SC-007** (Preferences are defaults-only): A saved figure with old styling opens with that styling; a new figure created afterward uses the current preferences.

#### v0.1.0 Success-Criteria Status

Per [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md), the **v0.1.0 release gate** is: the REPL end-to-end (build → export → save/reload the session spec), General-registry registration, and cross-platform install + launch-to-demo. The GUI-flow criteria below are re-scoped to v0.2.

| Criterion | v0.1 status | Note |
|---|---|---|
| SC-001 | Pending M11 | registration + cross-OS resolve is an M11 task |
| SC-002 | Deferred v0.2 | GUI window across 3 OSes; v0.1 launches to a demo, not blank |
| SC-003 | Deferred v0.2 | "without writing plotting code" is the GUI goal; v0.1 is REPL |
| SC-004 | Deferred v0.2 | `.mvz` load doesn't restore data, so the load→render→golden path isn't closed in v0.1 |
| SC-005 | Partial | 7 types created + styled + exported via REPL; "through the GUI" deferred v0.2 |
| SC-006 | Delivered (REPL) | advisory warning + downsample; interactive dialog deferred v0.2 |
| SC-007 | Delivered | preferences are defaults-only |

### Non-Measurable Goals (informing but not gating v0.1)

- **G-001** (Feel): For a Veusz-plus-Python user, the "click-to-build" mental model transfers cleanly. Assessed through informal user testing on 3+ scientists; no numeric threshold in v0.1.
- **G-002** (Extensibility): Adding an 8th plot type in v0.2 should require only declaring a schema entry, no UI code changes. Verified by writing the extension in a dry run before v0.1 ships.

---

## 9. Open Questions Deferred to DESIGN.md

Any remaining design questions surfaced during v0.1 detailed design are captured in `DESIGN.md` §"Open Design Questions" and MUST become ADRs before coding starts. This SDD does not itself carry open questions.
