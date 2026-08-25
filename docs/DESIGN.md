# DESIGN.md — MakieViews v0.1

**Status**: Draft
**Date**: 2026-08-24
**Companion documents**: SDD.md, ADR-001..010, TEST_PLAN.md, PLAN.md
**Template basis**: Custom (Spec Kit's plan-template.md is oriented to feature specs, not architecture design). This document adopts an arc42-inspired structure: model, mechanism, state machines, integrations, non-functional constraints, open questions.

---

## 0. Non-Functional Constraint This Whole Document Is Built Around

Restated from SDD §7. Everything downstream honors these three:

1. **Tree model generalizes**: node type is *data*, not a hard-coded enum.
2. **Property panel is schema-driven**: fields derive from the plot object's attribute schema; no per-plot-type UI branches.
3. **`.mvz` is forward- and backward-compatible**: `schema_version` present; unknown node types preserved on load and round-tripped on save.

These are non-functional requirements NFR-001, NFR-002 in the SDD.

---

## 1. Component Diagram (words)

```
                   ┌──────────────────────────────────────────┐
                   │              Gtk4 top-level window       │
                   │  ┌──────────┐  ┌──────────────────────┐  │
                   │  │ TreePane │  │  ViewportPane        │  │
                   │  │ (Gtk4)   │  │  (Gtk4Makie embed →  │  │
                   │  │          │  │   GLMakie Figure)    │  │
                   │  ├──────────┤  ├──────────────────────┤  │
                   │  │ Property │  │  StatusBar (Gtk4)    │  │
                   │  │ Pane     │  └──────────────────────┘  │
                   │  │ (Gtk4)   │                            │
                   │  └──────────┘                            │
                   └──────────────────────────────────────────┘
                                     ▲
                                     │  observes/mutates
                                     ▼
       ┌─────────────────────────────────────────────────────┐
       │  SessionState (pure Julia)                          │
       │  ─ tree: Session { Figures [ Axes [ Plots ] ] }     │
       │  ─ preferences (Scratch.jl-backed TOML)             │
       │  ─ data snapshots (Dict{DataRef, AbstractArray})    │
       └─────────────────────────────────────────────────────┘
                     ▲                          ▲
                     │                          │
        ┌────────────┴──────────┐   ┌───────────┴──────────┐
        │  DataSource layer     │   │  Persistence layer   │
        │  ─ MainSource         │   │  ─ .mvz TOML         │
        │  ─ CsvSource          │   │  ─ CairoMakie export │
        │  ─ Hdf5Source         │   │    (PNG/SVG/PDF)     │
        └───────────────────────┘   └──────────────────────┘
```

Two invariants:
- `SessionState` is a **pure Julia object graph** — no Gtk4 or GLMakie references. The GUI observes it and calls setters; nothing in `SessionState` calls the GUI. This is what makes headless integration tests possible (ADR-009, TEST_PLAN.md §2).
- The `ViewportPane` holds *one* `Makie.Figure`. Both GLMakie (interactive) and CairoMakie (export) render this same `Figure` — no duplicate figure state.

---

## 2. Tree Model

### 2.1 Node schemas

Nodes are Julia `mutable struct`s with per-field `Observable` wrapping per **[ADR-019](adr/ADR-019-reactive-state-observables.md)**. Each carries a `type` tag serialized into `.mvz` (never inferred from Julia type name on load — see §3). `id` and `type`/`kind` fields are plain (non-Observable) and immutable after node creation; everything mutable is an `Observable`.

> **Note on code declaration order.** The declarations below are shown in top-down conceptual order (root → leaves) for human readability. **In `src/state/nodes.jl`, the physical order is reversed — leaf-first (Plot → Axis → Figure → Session → UnknownNode)** because Julia's parametric types (e.g. `Observable{Vector{Figure}}` in `Session.figures`) require the referenced type to be already declared at the point of use. This is a language constraint, not a design choice.

```julia
abstract type Node end

mutable struct Session <: Node
    schema_version::VersionNumber                    # e.g. v"1.0.0"
    figures::Observable{Vector{Figure}}
    preferences_snapshot::Dict{String,Any}           # copy taken at session creation
    selection::Observable{Union{Nothing, String}}    # id of currently-selected node
end

mutable struct Figure <: Node
    id::String                                       # UUIDv4, immutable
    title::Observable{String}
    layout::Observable{LayoutSpec}                   # rows/cols/positions per Makie
    axes::Observable{Vector{Axis}}
end

mutable struct Axis <: Node
    id::String                                       # immutable
    kind::Symbol                                     # :axis2d | :axis3d, immutable
    title::Observable{String}
    xlabel::Observable{String}
    ylabel::Observable{String}
    zlabel::Observable{String}                       # unused for :axis2d
    xlim::Observable{Union{Nothing, Tuple{Float64,Float64}}}
    ylim::Observable{Union{Nothing, Tuple{Float64,Float64}}}
    xscale::Observable{Symbol}                       # :linear | :log10 | :log2 | :ln
    yscale::Observable{Symbol}
    gridlines::Observable{Bool}
    legend::Observable{Bool}
    tickformat::Observable{Union{Nothing, String}}
    camera::Observable{Union{Nothing, CameraSpec}}   # :axis3d only
    plots::Observable{Vector{Plot}}
end

mutable struct Plot <: Node
    id::String                                       # immutable
    type::Symbol                                     # :line | :scatter | :bar | :heatmap | :contour | :surface | :volume, immutable
    data_refs::Observable{Vector{DataRef}}           # e.g. [DataRef(:x), DataRef(:y)]
    attrs::Dict{Symbol, Observable{Any}}             # one Observable per attribute; keys match PLOT_SCHEMAS[type]; validated at every set
    animation_binding::Observable{Union{Nothing, AnimBinding}}
end

# Escape hatch for forward compatibility (ADR-004, §3.5):
mutable struct UnknownNode <: Node
    original_type::String
    payload::Dict{String, Any}                       # verbatim TOML sub-table
end
```

`Plot.attrs` is `Dict{Symbol, Observable{Any}}` — not `Observable{Dict{Symbol, Any}}` — so the property panel observes individual attributes (change linewidth → one observer fires) rather than the whole dict (change linewidth → every observer of the dict fires and diffs to find what changed). See ADR-019 for full rationale.

### 2.2 Why `type::Symbol`, not `type::Type`

Serializing a Julia `Type` object into TOML requires resolving it back on load — which fails if the resolving package is a different version. A `Symbol` (`:surface`) is a stable identifier decoupled from Julia's type system. When we load `type = "custom_recipe_xyz"` from a v0.2 file into v0.1, we don't need to know what type that is; we wrap it in `UnknownNode` and preserve the sub-table. This is the mechanism the SDD's Forward-Looking Constraint asks for.

### 2.3 Adding a new node type in v0.2 (dry-run)

To add a `:violin` plot in v0.2:
1. Register `Schema(:violin)` (see §2.4).
2. Add a rendering function `render!(::MakieAxis, ::Plot{type=:violin}, data)`.
3. That's it. No UI code changes. No `.mvz` schema-version bump.

This dry run is the SDD's goal G-002.

### 2.4 Schema registry

Each plot type declares its attribute schema:

```julia
struct AttrSpec
    name::Symbol
    kind::Symbol       # :color | :number | :int | :enum | :bool | :string | :vec2 | :vec3
    default::Any
    range::Any         # nothing, or (lo, hi), or Vector for :enum
    label::String
    tooltip::String
end

const PLOT_SCHEMAS = Dict{Symbol, Vector{AttrSpec}}()

PLOT_SCHEMAS[:line] = [
    AttrSpec(:color,     :color,  RGB(0.1,0.4,0.8), nothing,     "Color",     "Line color"),
    AttrSpec(:linewidth, :number, 1.5,              (0.1, 20.0), "Linewidth", "Line width in points"),
    AttrSpec(:linestyle, :enum,   :solid,           [:solid,:dash,:dot,:dashdot], "Style", "Dash pattern"),
    # ...
]
# Similarly for :scatter, :bar, :heatmap, :contour, :surface, :volume.
```

Per **[ADR-021](adr/ADR-021-axis-schema-driven-property-editing.md)**, `Axis` attributes (starting with camera controls) use a parallel registry keyed by `Axis.kind`:

```julia
const AXIS_SCHEMAS = Dict{Symbol, Vector{AttrSpec}}()

AXIS_SCHEMAS[:axis3d] = [
    AttrSpec(:azimuth,   :number, 45.0, (0.0, 360.0), "Azimuth",   "Camera azimuth in degrees"),
    AttrSpec(:elevation, :number, 30.0, (0.0, 360.0), "Elevation", "Camera elevation in degrees"),
    AttrSpec(:zoom,      :number, 1.0,  (0.1, 10.0),  "Zoom",      "Camera zoom multiplier")
]
```

The property panel iterates the schema for the selected plot type or axis kind. No `if plot.type == :surface ... elseif plot.type == :line ...` branches anywhere in UI code.

---

## 3. `.mvz` File Layout

### 3.1 Example

```toml
schema_version = "1.0"

[preferences_snapshot]
default_linewidth = 1.5
default_marker = "circle"
palette = ["#4e79a7","#f28e2b","#e15759","#76b7b2","#59a14f","#edc948","#af7aa1","#ff9da7","#9c755f","#bab0ab"]
font_family = "Arial"
font_size = 12

[[figure]]
id = "9c5a0f4a-…"
title = "Q3 pressure sweep"

  [figure.layout]
  rows = 1; cols = 1

  [[figure.axis]]
  id = "b2e1…"
  kind = "axis3d"
  title = "Pressure surface"
  xlabel = "T (K)"; ylabel = "V (L)"; zlabel = "P (Pa)"
  xscale = "linear"; yscale = "linear"
  gridlines = true; legend = false

    [figure.axis.camera]
    azimuth = 45.0; elevation = 30.0; zoom = 1.0

    [[figure.axis.plot]]
    id = "77aa…"
    type = "surface"
    data_refs = [
      { role = "x", source = "csv", path = "runs/q3.csv", column = "T" },
      { role = "y", source = "csv", path = "runs/q3.csv", column = "V" },
      { role = "z", source = "csv", path = "runs/q3.csv", column = "P" },
    ]
      [figure.axis.plot.attrs]
      colormap = "viridis"; shading = "smooth"
```

### 3.2 What is stored, what is not

- **Stored**: tree, styling, camera, layout, animation bindings, downsampling parameters (algorithm + target n) if applied, `data_refs` (source + **both `absolute_path` and `relative_path`** + column/dataset; see §3.6 and ADR-012), preferences snapshot at figure creation time.
- **Not stored in v0.1**: raw data arrays. A `.mvz` file is small and portable; if the source file moves, the loader flags each broken reference and offers a "browse for source" dialog.
- **Reserved for v0.2 (per ADR-017)**: `[[figure.axis.plot.data_inline]]` sub-table. v0.1 does not write it; v0.1's loader rejects any `.mvz` containing it with a specific error message (§3.3).

### 3.3 `schema_version` handling on load

```
loader_supported = v"1.0.0"

on load(file):
  s = read_toml(file)
  file_ver = parse(VersionNumber, s["schema_version"])

  if file_ver.major > loader_supported.major:
      raise "This file requires MakieViews vX or newer. Please upgrade."
  end
  if file_ver > loader_supported and file_ver.major == loader_supported.major:
      warn "This file was saved by a newer minor version. Unknown fields will be preserved but may not render."
  end

  # ADR-017: reserved slot check — v0.1 refuses inline data.
  for each plot in s.figure[*].axis[*].plot[*]:
      if "data_inline" in plot:
          raise "This .mvz contains inline data (data_inline), which requires MakieViews v0.2 or later. Loading aborted."
      end
  end

  build_tree(s)                          # unknown node types → UnknownNode
```

### 3.4 Unknown-node-type preservation

When encountering a `type` string the loader does not recognize, it constructs an `UnknownNode` (§2.1) that stores the original type name plus the *verbatim* sub-table. The tree view shows a greyed-out placeholder ("Unknown: custom_recipe_xyz — cannot render"). Save writes the sub-table back exactly, so `save → load in v0.1 → save → load in v0.2` recovers the original v0.2 node.

### 3.5 Round-trip guarantee (backing SC-004)

Any tree built through the GUI, saved, and loaded MUST produce a figure whose CairoMakie static export is pixel-hash-identical to the original's. TEST_PLAN.md §3 codifies this as a property test.

### 3.6 Data-reference path handling (per ADR-012)

Every `DataRef` written into `.mvz` stores **two paths** — an `absolute_path` (from the workstation where the session was saved) and a `relative_path` (from the `.mvz` file's own directory). The loader resolves in this precedence:

1. `relative_path` relative to the `.mvz` file's directory (handles the portable-folder case: user emails `analysis.mvz` alongside `data/`).
2. `absolute_path` as stored (handles the fixed-workstation case: user reopens from a different `cwd`).
3. If both fail: "file not found" dialog listing both paths tried, with a Browse button and a "Skip this plot" option.

TOML shape:

```toml
[[figure.axis.plot.data_refs]]
role = "z"
source = "csv"
absolute_path = "C:\\Users\\johnx\\Documents\\research\\q3\\runs\\q3.csv"
relative_path = "runs/q3.csv"
column = "P"
```

Content-hash verification is deferred to v0.2+.

---

## 4. Data Ingestion Layer

### 4.1 The `DataSource` abstraction

```julia
abstract type DataSource end

# Enumerate what this source can offer.
"""Return a Vector of NamedTuple{(:key, :kind, :size), ...} — kind ∈ (:vector, :matrix, :array3, :dataframe)."""
enumerate_variables(::DataSource)::Vector{DataVar}

# Snapshot one variable as a plain Julia array.
snapshot(::DataSource, key::String)::AbstractArray
```

### 4.2 Three concrete sources

- **`MainSource`** — enumerates `Main`'s bindings, filters to plottable array-likes and `DataFrame`. Snapshot uses `deepcopy` for arrays and `copy(df)` for DataFrames.
- **`CsvSource(path)`** — parses the CSV once with `CSV.File(path) |> DataFrame`, then enumerates columns. Snapshot returns the column vector by copy.
- **`Hdf5Source(path)`** — walks the HDF5 tree via `HDF5.File`, enumerates numeric datasets, snapshots by `read(dataset)`.

New sources (Parquet, Arrow, JSON, SQLite — deferred to v0.2 per ADR-007) implement this same two-method interface with no changes to the tree or property panel.

### 4.3 Reaching into the calling REPL's `Main` (with non-REPL detection — per ADR-011)

`makieviews()` is called from the REPL as `using MakieViews; makieviews()`. Julia's `Main` module is a first-class value; anything defined at the REPL is a binding of `Main`.

```julia
function main_source()
    plottable_names = filter(names(Main; all=false, imported=false)) do name
        val = getproperty(Main, name)
        val isa AbstractArray || val isa DataFrame
    end
    return MainSource(plottable_names)
end

function makieviews()
    if !(isinteractive() && isdefined(Base, :active_repl))
        @warn "MakieViews v0.1 reads variables from REPL Main. You appear to be running outside a REPL. " *
              "Variables defined in this script/context so far are visible; variables you define later will not appear. " *
              "File loading (CSV / HDF5) works normally."
    end
    _open_main_window(main_source())
end
```

`names(Main; all=false, imported=false)` returns user-defined bindings; `getproperty(Main, name)` fetches them; the filter keeps only plottable types. Stdlib Julia — no macros, no special-casing.

Non-REPL launches open normally but emit the one-line warning above (ADR-011). A `source_module=` kwarg is deferred to v0.2.

Snapshotting takes a `deepcopy` at ingest time so later mutation of the REPL variable does not silently change the plot (SDD FR-004).

---

## 5. Property Panel — Schema-Driven

The panel is one function of one input: the currently-selected node (Plot *or* Axis, identified by `session.selection[]`). 

Per **[ADR-021](adr/ADR-021-axis-schema-driven-property-editing.md)**, the panel dispatches on the selected node's Julia type:
- `Plot` node → iterates `PLOT_SCHEMAS[plot.type]`
- `Axis` node → iterates `AXIS_SCHEMAS[axis.kind]`

For each `AttrSpec` in the chosen schema, it creates the appropriate Gtk4 widget:

| `kind`   | Widget                              |
| -------- | ----------------------------------- |
| `:color` | Gtk4 color button                   |
| `:number`| Gtk4 spin button with `range`       |
| `:int`   | Gtk4 spin button (integer)          |
| `:enum`  | Gtk4 drop-down populated from `range` |
| `:bool`  | Gtk4 toggle                         |
| `:string`| Gtk4 entry                          |
| `:vec2`  | Two spin buttons                    |
| `:vec3`  | Three spin buttons                  |

Adding a new plot type in v0.2 means registering its `PLOT_SCHEMAS[:new_type]` — the panel picks it up automatically. This satisfies the NFR-002 forward-looking constraint.

**Value flow** (per **[ADR-019](adr/ADR-019-reactive-state-observables.md)**):

```
widget onchange → validate(schema, name, new_value) → plot.attrs[name][] = new_value
                                                       └─→ Renderer's on(plot.attrs[name]) do v ... end fires;
                                                          renderer updates the Makie plot handle.
```

Each attribute is its own `Observable{Any}` (per ADR-019 struct declaration in §2.1), so a single-attribute edit fires only that attribute's observers — not every observer of the whole plot. Validation happens synchronously at the widget-callback boundary before the `[]=` assignment; on validation failure the widget reverts to the prior valid value and the status bar shows a one-line message.

Callbacks are debounced at 60 Hz via `Observables.throttle(1/60, observable)` applied at the widget-callback boundary (not at every observation site).

---

## 6. Preferences — Defaults-Only

Per ADR-005 and ADR-006. Two locations:

- **On disk** — `Scratch.jl` scratch space, file `preferences.toml`. Read once at startup, kept in memory as `SessionState.preferences_disk`.
- **In-memory snapshot for the current session** — `SessionState.tree.preferences_snapshot`, taken at *session creation* time. This is what gets serialized into `.mvz`.

Behavior:
- **New figure**: seed from `preferences_disk`.
- **Load `.mvz`**: read `preferences_snapshot` back into the figure; the figure's plots use their own saved attributes (which were seeded from that snapshot originally); `preferences_disk` is not consulted. **The app never calls `set_theme!`.**
- **"Reset selection to preferences"** menu action: walks selected tree nodes; for each `Plot`, iterates `PLOT_SCHEMAS[plot.type]` and overwrites `plot.attrs[name]` with the current preferences value (or the spec default if the preference does not declare that field).

Preference migration (schema change to `preferences.toml` between MakieViews versions):
- `preferences.toml` also carries a `schema_version` at the top.
- Loader reads it; unknown fields are preserved and passed through on the next save.
- Missing fields resolve to the spec default.
- **`preferences.toml`'s `schema_version` is independent of `.mvz`'s `schema_version`** (per ADR-016). Each file's loader checks only its own version; the two evolve on different schedules.

---

## 7. Pre-Flight Dataset Check

### 7.1 State machine

```
                       ┌─────────────────────┐
                       │ dataset load        │
                       │ requested           │
                       └──────────┬──────────┘
                                  ▼
                       ┌─────────────────────┐
                       │ detect_host_specs   │
                       │ Sys.total_memory()  │
                       │ GPU VRAM (best-eff) │
                       │ Sys.CPU_THREADS     │
                       └──────────┬──────────┘
                                  ▼
                       ┌─────────────────────┐
                       │ estimate_footprint  │
                       │ ─ bytes = size(A)*  │
                       │   sizeof(eltype(A)) │
                       │ ─ target_fps est.   │
                       └──────────┬──────────┘
                                  ▼
                        ┌─────────┴──────────┐
                        │ over threshold?    │
                        │  (>60% VRAM OR     │
                        │   est_fps < 15?)   │
                        └────┬─────────┬─────┘
                             │no       │yes
                             ▼         ▼
                       ┌───────┐  ┌──────────────────────────┐
                       │ load  │  │ non-blocking WARN dialog │
                       │ full  │  │ ─ estimated MB           │
                       └───────┘  │ ─ estimated fps          │
                                  │ ─ Accept | Downsample |  │
                                  │   Override               │
                                  └─────┬───────┬────────┬───┘
                                        │       │        │
                                        ▼       ▼        ▼
                                  ┌───────┐ ┌────────┐ ┌────────┐
                                  │ load  │ │ pick   │ │ load   │
                                  │ full  │ │ algo   │ │ full   │
                                  └───────┘ │ + tgt n│ └────────┘
                                            └───┬────┘
                                                ▼
                                          ┌──────────┐
                                          │ apply    │
                                          │ + hold   │
                                          │ full ref │
                                          └──────────┘
```

### 7.2 GPU VRAM detection and FPS estimate (per ADR-015)

VRAM detection is best-effort. On Linux with NVIDIA, `nvidia-smi` is queried in a subprocess; on Windows, DXGI query if available; on macOS Metal, IOKit query. On any failure, the check falls back to the message `"GPU unknown, proceeding without VRAM estimate"` and does not block (SDD FR-026).

The FPS estimate is **measurement-driven with a conservative bias** (ADR-015):

```
estimated_fps = fps_ref[plot_type][ceil(log10(n_points))] * user_scale
user_scale    = clamp(user_gpu_score / reference_gpu_score, 0.1, 10.0)
              # if VRAM undetectable → user_scale = 0.5  (conservative: assume ½ reference)
```

`fps_ref[plot_type][log10_n]` is a lookup table populated during **M10** by a measurement pass on three reference machines (one per OS) for the seven v0.1 plot types across point counts 10³..10⁸. Lives at `src/preflight/fps_lookup.jl`.

Until M10 lands the measured table, a coarse fallback holds:

```
estimated_fps (2D) = 60 / sqrt(n_points / 1e6)
estimated_fps (3D) = 30 / sqrt(n_points / 1e6)
```

Same `user_scale` applies. Conservative bias: over-warning on a plot that would have run fine costs one dialog click; under-warning and freezing the GUI costs trust.

### 7.3 Downsampling API (backing ADR-010)

```julia
abstract type DownsampleAlgorithm end
struct UniformStride    <: DownsampleAlgorithm; k::Int end
struct MinMaxDecimation <: DownsampleAlgorithm; n_buckets::Int end
struct LTTB             <: DownsampleAlgorithm; n_target::Int end

downsample(algo::DownsampleAlgorithm, x::AbstractVector, y::AbstractVector) -> (x′, y′)
```

`Plot.attrs[:downsample_algorithm]` records what was applied; a full-resolution re-render is a v0.2 add.

---

## 8. Rendering

`SessionState` never renders directly. A `Renderer` observes it (via **[ADR-019](adr/ADR-019-reactive-state-observables.md)**'s Observables.jl mechanism) and updates the shared `Makie.Figure`:

```julia
mutable struct Renderer
    fig::Makie.Figure
    axis_handles::Dict{String, Union{Makie.Axis, Makie.Axis3}}   # by Axis.id
    plot_handles::Dict{String, Any}                              # Makie plot object by Plot.id
    _observer_handles::Vector{Any}                               # Observables.jl `ObserverFunction` refs, kept alive by holding refs
end
```

On `Renderer` construction, it walks the `SessionState` tree and registers `on(...)` handlers on:
- Each `Figure`'s `axes` observable (structural: add/remove axis).
- Each `Axis`'s `plots` observable (structural: add/remove plot) and per-attribute observables (title, xlabel, xlim, etc.).
- Each `Plot`'s `attrs` per-attribute observables (styling changes) and `data_refs` observable (data changes).

All handler refs are kept in `_observer_handles` so garbage collection does not silently disconnect them. When a node is removed from the tree, its handlers are explicitly `off(...)`'d.

On each observed change:
- Structural changes (add/remove axis or plot) → replay the affected subtree.
- Attribute changes → `set!(plot_handle, attr, value)` via Makie's own Observable pipeline (Makie plot objects already carry Observables for every attribute).
- Data changes (rare — mostly downsample toggles) → replace the plot handle.

CairoMakie static export operates on the same `Renderer.fig`: `CairoMakie.activate!(); save("out.pdf", fig); GLMakie.activate!()`.

---

## 9. Threading & Event Loop

Gtk4 requires all UI mutations to happen on its main thread. GLMakie renders on that thread too. MakieViews' choices:

- Data ingestion runs on a Julia task; the resulting snapshot is handed back to the main thread via `Gtk4.@idle_add` for insertion into `SessionState`.
- Downsampling for large datasets runs on a worker task with progress reporting; on completion, apply on the main thread.
- HDF5 reads are on a worker task; CSV parsing is on a worker task.
- **Animation export runs on the main thread inside a modal dialog for v0.1** (per ADR-014). Frames are rendered sequentially via GLMakie (or CairoMakie for MP4 export), then encoded via FFMPEG. The "Exporting animation…" modal shows `current_frame / total_frames` and a Cancel button; cancel deletes the partial file. Background/off-thread export is a named v0.2 project — GLMakie's main-thread OpenGL context makes background rendering a real engineering investment.

Every callback that mutates `SessionState` is documented as "runs on the Gtk4 main thread" and is asserted to be so with `@assert Gtk4.is_main_thread()` in debug builds.

---

## 10. Error Model

- **Load errors** (unknown file version, missing source): surface a Gtk4 message dialog with the specific message. Never silently degrade.
- **Runtime rendering errors** (Makie throws): catch at the renderer boundary, log the stack, replace the axis with a red-outlined placeholder that shows the exception text. The tree view marks the axis with an error indicator.
- **Ingest errors** (CSV parse fail): dialog with the file path and the parser's message.

Nothing is caught silently.

---

## 11. Open Design Questions — CLOSED

All seven v0.1 open design questions are resolved. Each is now an ADR (ADR-011..ADR-017); the specifics are folded into the sections referenced below.

| ODQ | Decision | ADR | DESIGN section that specifies the behavior |
|---|---|---|---|
| ODQ-1 | Non-REPL launch: REPL-only for v0.1, with detection + one-line warning on non-REPL launch. `source_module=` deferred to v0.2. | [ADR-011](adr/ADR-011-non-repl-launch-semantics.md) | §4.3 |
| ODQ-2 | Data-ref paths: store both absolute and relative-to-mvz; loader tries relative first, then absolute; missing → dialog with Browse + Skip. Content-hash deferred to v0.2. | [ADR-012](adr/ADR-012-data-ref-path-precedence.md) | §3.2, §3.6 |
| ODQ-3 | MP4/GIF fps: user-configurable in export dialog (1–60), default 30. Not stored in `.mvz`. | [ADR-013](adr/ADR-013-mp4-fps-configurable.md) | (export dialog UI, not per-plot schema) |
| ODQ-4 | Animation export runs modal on main thread for v0.1 with progress + cancel; snapshot at export-start. Background export deferred to v0.2. | [ADR-014](adr/ADR-014-animation-export-modal-v0-1.md) | §9 |
| ODQ-5 | Pre-flight FPS: measurement-driven lookup populated in M10, `user_scale` clamp, conservative-bias fallback = 0.5 when VRAM undetectable. Coarse fallback formula documented until M10. | [ADR-015](adr/ADR-015-preflight-fps-formula-conservative.md) | §7.2 |
| ODQ-6 | `preferences.toml` and `.mvz` carry **independent** `schema_version` fields. | [ADR-016](adr/ADR-016-independent-schema-versions.md) | §3, §6 |
| ODQ-7 | Reserve `[[figure.axis.plot.data_inline]]` in v0.1 schema. v0.1 loader refuses with specific message: `"This .mvz contains inline data (data_inline), which requires MakieViews v0.2 or later. Loading aborted."` v0.2 defines the sub-table. | [ADR-017](adr/ADR-017-reserve-data-inline-schema-slot.md) | §3.2, §3.3 |

No open design questions remain for v0.1. `tasks.md` writing is unblocked; M1 may begin per PLAN.md §5.
