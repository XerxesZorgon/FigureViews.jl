# MakieViews.jl

A Veusz-style desktop GUI (graphical user interface) over Makie for Julia scientific plotting. Click-to-build figures, live property editing, 3D rotation, saveable sessions — no plotting code required.

**Status**: v0.1 in development. Not yet registered.

---

## What MakieViews is for

You have a Julia array, DataFrame, HDF5 file, or CSV. You want a labeled 3D surface, a two-series scatter, or an animated heatmap — and you want to iterate on styling without editing a `.jl` file every time. MakieViews is that iteration loop. When you're done, save the session as `.mvz` and export PNG / SVG / PDF for a paper.

MakieViews is a first-class Julia package. Everything lives inside your existing Julia environment — no Electron, no browser tab, no separate runtime.

## What MakieViews is not

- Not a Python replacement. If you already have a Makie plotting pipeline in code and it works, keep it.
- Not a data-analysis tool. Filter, fit, transform in Julia. MakieViews plots what you hand it.
- Not a collaborative editor. One user, one session.
- Not (yet) a plugin host. v0.1 supports the seven built-in plot types; user recipes are a v0.2 plan.

---

## Install

Once v0.1.0 is registered:

```julia
] add MakieViews
```

Then launch from the REPL:

```julia
using MakieViews
makieviews()
```

MakieViews requires Julia 1.10 or newer; v0.1 is developed and CI-verified on Julia 1.12.

## Quickstart

1. Start Julia in a REPL. Load some data — e.g., `z = randn(50, 50)`.
2. `using MakieViews; makieviews()`.
3. In the variable picker, pick `z`.
4. Add Plot → **Surface**.
5. Drag the viewport to rotate. Edit title / axis labels / camera in the property panel on the right.
6. **File → Save Session As** → `analysis.mvz`.
7. **File → Export → PNG** to render for a paper.

Reopen `analysis.mvz` later and get exactly the same figure.

## Supported plot types (v0.1)

Line, scatter, bar, heatmap, contour, surface (3D), volume (3D). Animations via a time slider bound to any numeric attribute or data slice; export to MP4 or GIF.

## Data sources (v0.1)

- Variables in your running REPL (`Main`) — `Array`, `Matrix`, 3-D `Array`, `DataFrame`.
- CSV files (via CSV.jl + DataFrames.jl).
- HDF5 files (via HDF5.jl).

Parquet, Arrow, JSON, SQLite are on the v0.2 roadmap.

## Preferences

Set your default font, line width, marker, palette, and grid behavior once — MakieViews stores them per user via Scratch.jl. Preferences are **defaults-only**: they seed new figures. Opening a saved figure gives you exactly the figure you saved. If you want to restyle an existing plot to match your current preferences, select it and use **Edit → Reset selection to preferences**. See ADR-006 for why we chose this over live theming.

## Session files (`.mvz`)

`.mvz` is a TOML document. You can inspect and diff it in Git. It stores your tree, styling, camera, and animation bindings — it stores *references* to your data (CSV path, HDF5 dataset), not the arrays themselves. Move the source data and MakieViews will offer to help find it on reload.

## Large datasets

When you load something heavy, MakieViews estimates memory footprint and expected frame rate against your machine. If the estimate is too high, it raises a non-blocking warning and offers three downsampling algorithms: uniform stride, min/max decimation, and LTTB (largest-triangle-three-buckets, for line plots). Accept, adjust, or override.

## Platforms

Windows, macOS, Linux. On Linux with Wayland or NVIDIA drivers, see [`docs/troubleshooting.md`](docs/troubleshooting.md) (Gtk4Makie inherits some upstream quirks in these configurations).

## Documentation

- [`docs/SDD.md`](docs/SDD.md) — Software Description Document (what the software does)
- [`docs/DESIGN.md`](docs/DESIGN.md) — Architecture and mechanisms
- [`docs/PLAN.md`](docs/PLAN.md) — Milestones and pinned versions
- [`docs/TEST_PLAN.md`](docs/TEST_PLAN.md) — Test layers and CI matrix
- [`docs/adr/`](docs/adr/) — Architecture Decision Records (why we chose each thing)

## Contributing

MakieViews follows a documents-first workflow. Before opening a PR that changes behavior, read the relevant ADR — decisions there are load-bearing. New architectural decisions land as new ADRs.

## License

MIT. See [`LICENSE`](LICENSE).
