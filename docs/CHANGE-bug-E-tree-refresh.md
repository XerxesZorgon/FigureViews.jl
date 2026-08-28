# Bug E Fix: tree pane refresh! uses empty!

**Date**: 2026-08-27
**Component**: `src/ui/tree_pane.jl`

## Root Cause
In Gtk4.jl, `splice!(model, 1:length(model))` is not defined for `GtkStringList` (and no `splice!` method accepts a `UnitRange` for it). Thus, any post-launch node addition (e.g. `add_figure!`, `add_axis!`, `add_plot!`) that fired the `session.figures`, `fig.axes`, or `ax.plots` observers triggered `refresh!()` and threw a `MethodError: splice!`.

## Fix
Replaced the `splice!(model, 1:length(model))` call with `empty!(model)` inside the `refresh!()` closure of `build_tree_pane`. `empty!(model)` is properly exposed by Gtk4.jl for `GtkStringList` and successfully clears the list before it is repopulated in the subsequent `push!(model, l)` loop.

## Regression Test
Added `test/integration/tree_refresh.jl` (included in `test/runtests.jl`). It verifies that calling `add_figure!` and `add_axis!` after launching the app window via `makieviews()` does not throw an error and that the tree rows grow appropriately.
