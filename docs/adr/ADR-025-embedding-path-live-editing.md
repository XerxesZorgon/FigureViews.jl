# ADR-025 — Embedding path for live structural editing

**Status**: Accepted (2026-08-29)
**Date**: 2026-08-29
**Deciders**: John Peach
**Related**: [ADR-024](ADR-024-incremental-render-path-bug-f.md) (Bug F root cause and fix strategy), [ADR-002](ADR-002-ui-stack-gtk4-glmakie.md) (UI stack), PLAN-v0.2.md §3 M12, `spike/m12_route1_widget.jl`, `spike/m12_route1_stress.jl`

## Decision

**Retain the existing `GtkMakieWidget` embedding** (`src/FigureViews.jl`) as the v0.2 viewport host. No shell rewrite is required. The upstream instability described in JuliaGtk/Gtk4Makie.jl issue #14 does not reproduce under the correct threading configuration.

## Context

ADR-024 constraint 2 identified the current `GtkMakieWidget` embed as a suspected blocker for live plot-add, citing issue #14. The M12 spike was designed to evaluate three alternative embedding routes before committing to M13 renderer work. The spike question was: *can a plot be added to an already-displayed window without deadlock, and by which route?*

Three routes were on the table: (1) retain `GtkMakieWidget`, confirming or working around #14; (2) switch to a `GTKScreen`-in-grid arrangement; (3) use a custom `GLMakie.Screen` against a `GtkGLArea`.

## Evidence

**Route 1 — `GtkMakieWidget` (retained):** `spike/m12_route1_widget.jl` showed that adding a `lines!` plot to an already-displayed axis from the script thread succeeded without freeze or error when the GLib loop runs on a spawned interactive thread (`--threads 4,1`). `spike/m12_route1_stress.jl` then exercised the full structural-mutation sequence needed by M13: add a second plot to an existing axis (`scatter!`), add a new axis (`Axis(fig[2,1])`), delete the scatter plot (`GLMakie.delete!(ax, sc)`), and delete the new axis (`GLMakie.delete!(ax2)`). All four steps passed on Windows with Gtk4Makie.jl v0.3.9 — no freeze, no error, no corruption of unrelated plot objects. Issue #14 did not reproduce.

**Route 2 — `GTKScreen`-in-grid:** Not evaluated. Route 1 passed the full stress test, making Route 2 unnecessary.

**Route 3 — Custom `GLMakie.Screen`:** Not evaluated. Route 1 passed the full stress test, making Route 3 unnecessary.

## Consequences

- **`src/FigureViews.jl` shell is unchanged.** No embedding migration required for M13.
- **Confirmed delete! API for M13:** `GLMakie.delete!(ax, plot_handle)` removes a plot from an axis; `GLMakie.delete!(ax)` removes an axis. These are the signatures to use in the incremental renderer operations (`_remove_plot_handle!`, `_remove_axis!`).
- **Interactive thread is mandatory.** The spike ran with `--threads 4,1`. Without an interactive thread the GLib loop starves. `makieviews()` must check for an interactive thread at startup and refuse with an actionable message if absent (ADR-024 constraint 1, carried into M13).
- **Linux confirmation deferred to M13 CI.** The spike ran on Windows only. The `--threads N,1` fix is expected to be OS-agnostic (it operates at the Julia scheduler level, not the OS level), but the Ubuntu CI job for M13 is the formal confirmation. If M13's CI fails with a threading-related freeze on Ubuntu, this ADR will be amended with the correct Linux mitigation.
- **M13 proceeds on the Route 1 basis.** The incremental renderer (`_add_plot_handle!`, `_remove_plot_handle!`, `_add_axis!`, `_remove_axis!`) targets the existing `GtkMakieWidget` GLArea handle. The mutation queue and `g_idle_add` drain (ADR-024 Part A) are added in M13 alongside the incremental ops (ADR-024 Part B).
