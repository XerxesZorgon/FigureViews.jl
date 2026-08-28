# Bug E Fix: tree pane refresh! uses empty!

**Date**: 2026-08-27
**Component**: `src/ui/tree_pane.jl`

## Root Cause
In Gtk4.jl, `splice!(model, 1:length(model))` is not defined for `GtkStringList` (and no `splice!` method accepts a `UnitRange` for it). Thus, any post-launch node addition (e.g. `add_figure!`, `add_axis!`, `add_plot!`) that fired the `session.figures`, `fig.axes`, or `ax.plots` observers triggered `refresh!()` and threw a `MethodError: splice!`.

## Fix
Replaced the `splice!(model, 1:length(model))` call with `empty!(model)` inside the `refresh!()` closure of `build_tree_pane`. `empty!(model)` is properly exposed by Gtk4.jl for `GtkStringList` and successfully clears the list before it is repopulated in the subsequent `push!(model, l)` loop.

## Regression Test
Added `test/integration/tree_refresh.jl` (included in `test/runtests.jl`). It launches the window via `makieviews()`, then does a post-launch `add_figure!` — which fires the `refresh!` observer that previously threw — and asserts no error plus tree-row growth. **Only `add_figure!` is exercised:** post-launch `add_axis!` triggers a separate renderer deadlock (**Bug F**, deferred to v0.2), so it cannot run in an automated test.

## Related
Bug F — the renderer hangs on structural mutation of a *displayed* window (filed in `tasks.md`, deferred to v0.2). v0.1 is build-then-display: construct the session before `makieviews()`.
