# MakieViews.jl

A Julia package for building, styling, exporting, and saving [Makie](https://docs.makie.org/) figures as reusable session specs — the REPL foundation of a forthcoming Veusz-style GUI over Makie.

**Status**: v0.1 in development. Not yet registered. v0.1 ships a **REPL-driven core**; the interactive point-and-click GUI is planned for v0.2+ (see [ADR-022](docs/adr/ADR-022-v0-1-ships-repl-driven.md)).

---

## What MakieViews is for

You have a Julia array, DataFrame, HDF5 file, or CSV, and you want a labeled 3D surface, a two-series scatter, or an animated heatmap that you can style, export for a paper, and reopen later — without re-deriving the plot each time.

**In v0.1**, you do this through a small REPL API: build a figure from your data, style it, export it to PNG/SVG/PDF (and MP4/GIF), and save the layout as a `.mvz` session file. `makieviews()` opens a demo window that previews the desktop shell the GUI will use.

**The v0.2+ goal** is the full [Veusz](https://veusz.github.io/)-style GUI on top of this core: a data pane, a tree you build figures in by clicking, property and formatting panels, and a plot-type toolbar — exposing much of Makie's capability (and some of it beyond what Veusz offers) without writing code.

MakieViews is a first-class Julia package. Everything lives inside your existing Julia environment — no Electron, no browser tab, no separate runtime.

## What MakieViews is not

- Not a Python replacement. If you already have a Makie pipeline in code and it works, keep it.
- Not a data-analysis tool. Filter, fit, and transform in Julia. MakieViews plots what you hand it.
- Not a collaborative editor. One user, one session.
- Not (yet) a point-and-click GUI. v0.1 is REPL-driven; the interactive GUI is v0.2+ (ADR-022).
- Not (yet) a plugin host. v0.1 supports the seven built-in plot types; user recipes are a v0.2 plan.

---

## Install

Once v0.1.0 is registered:

```julia
] add MakieViews
```

MakieViews requires Julia 1.10 or newer; v0.1 is developed and CI-verified on Julia 1.10 and 1.12.

## Quickstart (v0.1, REPL)

Build a figure from data in your REPL, export it, and save the session. The builder functions `new_session` / `add_figure!` / `add_axis!` and the `Renderer` are internal in v0.1, so they're called module-qualified.

```julia
using MakieViews

# 1. Build a session: a figure with one 2D axis
s   = MakieViews.new_session()
fig = MakieViews.add_figure!(s; title = "My analysis")
ax  = MakieViews.add_axis!(fig; kind = :axis2d, title = "Signal")

# 2. Ingest data from the REPL (Main). CSV / HDF5 use CsvSource / Hdf5Source.
x = collect(0:0.01:2π)
y = sin.(x)
src   = MainSource()                 # reads variables from Main by name
snapx = ingest!(s, src, "x")         # snapshots a copy; returns a snapshot id
snapy = ingest!(s, src, "y")

# 3. Add a line plot referencing the ingested snapshots
add_plot!(ax, :line,
    [DataRef(:x, snapx, :main, "x"), DataRef(:y, snapy, :main, "y")])

# 4. Render the session into a Makie figure and export it
r = MakieViews.Renderer(s, MakieViews.Makie.Figure())
export_figure(r, "signal.png")       # or "signal.svg" / "signal.pdf"

# 5. Save the session spec (tree + styling) as .mvz
save_session(s, "analysis.mvz")
```

For large arrays, use `add_plot_checked!` instead of `add_plot!` — see [Large datasets](#large-datasets).

## The demo window

`makieviews()` opens the MakieViews desktop shell (1400×900, three panes: a tree pane and property pane on the left, an embedded GLMakie viewport on the right) populated with a built-in **demo** session — a 2D sine line + scatter and a 3D surface. It previews the GUI that v0.2 will build out. You can rotate the 3D axis and live-edit attributes (colors, titles, limits) on the demo. In v0.1 it displays the demo session only; displaying your own built session, and editing a displayed session's structure, arrive in v0.2 (ADR-022).

## Supported plot types (v0.1)

Line, scatter, bar, heatmap, contour, surface (3D), volume (3D). Animations are built with `animate_plot!` (bind a time index over a 3D array `A[x, y, t]`) and exported with `render_animation` to MP4 or GIF.

## Data sources (v0.1)

Ingested via `ingest!(session, source, id)`, which snapshots a **copy** so later changes to the original don't mutate a plotted array:

- `MainSource()` — variables in your running REPL (`Main`): `Vector`, `Matrix`, 3-D `Array` of reals.
- `CsvSource(path)` — CSV files (via CSV.jl + DataFrames.jl); columns become variables.
- `Hdf5Source(path)` — HDF5 files (via HDF5.jl); datasets become variables.

Parquet, Arrow, JSON, and SQLite are on the v0.2 roadmap.

## Preferences

Set default styling (font, line width, marker, palette, grid) once; MakieViews stores it per user via Scratch.jl (`load_preferences` / `save_preferences` / `preferences_path`). Preferences are **defaults-only**: they seed new plots. Opening a saved figure gives you the styling you saved. To restyle an existing plot to your current preferences, call `reset_to_preferences!(plot, prefs)`. See [ADR-006](docs/adr/ADR-006-preferences-defaults-only.md) for why we chose this over live theming.

## Session files (`.mvz`)

`.mvz` is a TOML document you can inspect and diff in Git. It stores your tree, styling, camera, and animation bindings, plus *references* to your data (CSV path, HDF5 dataset, `Main` variable name) — **not** the data arrays themselves.

**v0.1 limitation:** `load_session` restores the tree and styling but not the data — a reloaded session carries provenance references, and you re-ingest the arrays to render it. Embedding data in `.mvz` for a full-fidelity round-trip is a v0.2 feature (the format already reserves a slot for it — [ADR-017](docs/adr/ADR-017-reserve-data-inline-schema-slot.md)).

## Large datasets

`add_plot_checked!` (a drop-in for `add_plot!`) estimates memory footprint and expected frame rate against your machine before adding a plot. If the estimate is high, it emits an advisory warning with the numbers and reason but still adds the plot at full size. To reduce instead, pass a downsampling algorithm:

```julia
add_plot_checked!(ax, :line, refs; session = s, downsample = LTTB(1000))
```

Three algorithms are available: `UniformStride`, `MinMaxDecimation`, and `LTTB` (largest-triangle-three-buckets, for line plots). The interactive Accept/Downsample/Override dialog is a v0.2 feature; the frame-rate estimate ships as a conservative formula in v0.1 ([ADR-020](docs/adr/ADR-020-defer-fps-measurement-to-m11.md)).

## Roadmap (v0.2+)

- The interactive Veusz-style GUI: data pane, click-to-build tree (add/delete/reorder/rename), property + formatting panels, plot-type toolbar, and live editing of a displayed session.
- Data embedded in `.mvz` for a full save/reload round-trip.
- More of Makie's capabilities surfaced to the user (beyond the seven v0.1 plot types).
- Undo/redo; user-defined recipe plot types; additional data formats.

## Platforms

Developed on Windows; continuous integration runs on Linux (Ubuntu, Julia 1.10 + 1.12) headless under xvfb. Windows and macOS are validated manually before release — the macOS live-test is a hard gate before tagging v0.1.0 ([ADR-018](docs/adr/ADR-018-ci-matrix-reduction-ubuntu-only.md)). On Linux with Wayland or NVIDIA drivers, see [`docs/troubleshooting.md`](docs/troubleshooting.md) (Gtk4Makie inherits some upstream quirks in these configurations).

## Documentation

- [`docs/SDD.md`](docs/SDD.md) — Software Description Document (what the software does; v0.1 delivery status marked per requirement)
- [`docs/DESIGN.md`](docs/DESIGN.md) — Architecture and mechanisms
- [`docs/PLAN.md`](docs/PLAN.md) — Milestones and pinned versions
- [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md) — Test layers and CI matrix
- [`docs/adr/`](docs/adr/) — Architecture Decision Records (why we chose each thing)

## Contributing

MakieViews follows a documents-first workflow. Before opening a PR that changes behavior, read the relevant ADR — decisions there are load-bearing. New architectural decisions land as new ADRs.

## License

MIT. See [`LICENSE`](LICENSE).
