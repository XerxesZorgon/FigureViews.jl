# ADR-024 — Incremental render path for live structural edits (Bug F)

**Status**: Accepted (2026-08-29).
**Date**: 2026-08-29
**Deciders**: John Peach
**Related**: [ADR-019](ADR-019-reactive-state-observables.md) (reactive state model — this ADR completes the `Channel`-path reasoning ADR-019 deferred), [ADR-002](ADR-002-ui-stack-gtk4-glmakie.md) (Gtk4 + GLMakie UI stack), [ADR-022](ADR-022-v0-1-ships-repl-driven.md) (v0.1.0 ships REPL-driven precisely because Bug F is unsolved), DESIGN.md §8 (renderer), DESIGN.md §9 (threading), `src/render/renderer.jl`, SESSION_LOG 2026-08-29. **This ADR is the spine of v0.2: the GUI surface (variable picker, Add Plot menu, property-panel-as-primary, File menus) cannot become the primary flow until this is solved.**

## Context

v0.1.0 ships `makieviews()` as **display-only** for a canned demo session (ADR-022). The reason is Bug F: any attempt to add, remove, or reorder a figure, axis, or plot in a session that `makieviews()` is already displaying deadlocks the window.

### Symptom

- **Live *attribute* edits work** on a displayed window — color, title, axis limits. They write to an `Observable` the already-rendered Makie handle is watching; Makie updates the existing rendered object in place, on the render thread, with no scene rebuild and no main-thread re-acquisition.
- **Live *structural* edits deadlock** — anything that adds or removes a node from the `Session` tree after the window is open (`add_figure!`, `add_axis!`, `add_plot!`).

### Root cause — two coupled defects, not one

**Defect 1 — wrong thread.** `makieviews()` builds the Gtk4 window and the embedded GLMakie viewport on the main thread, then hands control to the Gtk4/GLib event loop, which now owns the main thread. A subsequent REPL call (`add_plot!`) also needs the main thread — to push changes into Makie's Observable graph and trigger a re-render. Two main-thread claimants issued from different execution contexts (the GLib loop vs. the REPL task) block each other; the window freezes.

The evidence that this is a *thread-origin* problem, not an *operation* problem: Gtk4Makie's own documentation shows a structural mutation that works — a button callback running `empty!(ax); lines!(ax, rand(10)); Gtk4.queue_render(glarea)`. That is a full teardown-and-rebuild of an axis, and it does **not** deadlock, because it runs *inside a GTK signal callback* — i.e. on the main thread, from within the event loop that already owns it. The same mutation issued from the REPL deadlocks. The operation is identical; only the originating thread differs.

**Defect 2 — wrong granularity.** FigureViews' current renderer (`src/render/renderer.jl`) wires every structural observer to a blunt full-figure rebuild:

```julia
h = on(ax_node.plots) do _
    empty!(renderer.fig)          # tear down the ENTIRE figure
    _rebuild_from_session!(renderer)   # rebuild every axis and every plot
end
```

Adding one plot to one axis re-runs `empty!` on the whole figure and rebuilds all axes and all plots. Headless (the v0.1 REPL path, before any window opens) this is merely wasteful. Live, it is both wasteful *and* — because it fires from the REPL — the trigger for Defect 1. Even if Defect 1 were fixed (mutation moved onto the main thread), this full-rebuild-on-every-change pattern would make every structural edit re-render the entire figure, which does not scale and discards camera/interaction state on unrelated axes.

**Both defects must be fixed. Neither alone resolves Bug F.** Fixing the thread without fixing granularity yields a working-but-janky renderer that rebuilds everything on each edit; fixing granularity without fixing the thread still deadlocks.

### Reconciliation with ADR-019

ADR-019 considered a `Channel{Event}` + reader task for the reactive layer and **rejected it for v0.1**, on the grounds that a reader task "fights Gtk4's main-thread-only mutation rule" and "introduces race conditions between main-thread widget callbacks and reader-thread event processing." That reasoning was correct for v0.1's scope (no live structural editing) and for a channel drained on *its own* thread.

This ADR does not overturn ADR-019 — it completes it. The mechanism below drains the queue **on the main thread via `g_idle_add`**, which is exactly the primitive that makes a queue *comply* with Gtk4's main-thread-only rule instead of fighting it. ADR-019 explicitly left this door open: *"a command pattern on top of Observables.jl … satisfies it without a channel"* for undo/redo, and noted the channel's async cost "is not justified when [its main benefit] is v0.2 deferred anyway." v0.2 is now here, and the benefit at stake is no longer undo/redo but Bug F itself.

## Decision

**v0.2 introduces an incremental render path with two parts, both required.**

### Part A — a main-thread-drained mutation queue

Structural mutation requests do not execute in the caller's context. They are posted to a thread-safe queue; a `g_idle_add` callback drains the queue on the main thread at event-loop idle and executes each mutation there.

```
REPL / GUI callback                    Main (GLib) thread
───────────────────                    ──────────────────
add_plot!(session, …)  ──post──▶  [ thread-safe queue ]
                                          │
                                   g_idle_add drain  ◀── fires when loop idle
                                          │
                                   run mutation on main thread:
                                     • apply incremental renderer op (Part B)
                                     • Gtk4.queue_render(glarea)
                                     • return false  (one-shot; re-armed on next post)
```

- `Gtk4.GLib.g_idle_add(f)` registers a Julia function called when there are no higher-priority GTK events pending; it is callable from any thread and is GLib's documented thread-safe scheduling primitive. This is the same idiom Gtk4.jl's own async examples use to marshal work from a `Threads.@spawn` block back onto the UI thread.
- When the window is **not** displayed (headless REPL export/animation — the entire v0.1 surface), there is no GLib loop to drain the queue. In that mode structural mutations apply **synchronously and directly**, exactly as they do in v0.1. The queue path is engaged only once `makieviews()` has opened a live window. `render_session(session)` for headless export is unchanged.

### Part B — incremental renderer operations

`_rebuild_from_session!`'s full-figure `empty!` observers are replaced (for the live path) by targeted operations that mutate only the changed node's Makie handle:

- `_add_plot_handle!(renderer, ax_node, plot)` — plot into the existing `Makie.Axis`/`Axis3` handle, register attribute observers, store the handle. No figure teardown.
- `_remove_plot_handle!(renderer, plot_id)` — `delete!` the Makie plot object from its axis, drop the stored handle and its observers.
- `_add_axis!` / `_remove_axis!` — add/remove one axis at a layout position without rebuilding sibling axes (this interacts with the deferred general `rows×cols` `LayoutSpec` placement noted in `renderer.jl`; see Consequences).
- Reorder = remove + re-add at the new position, or a layout-slot reassignment where Makie allows it.

The observer wiring changes from "on any structural change, rebuild everything" to "on a structural change, post the *specific* add/remove op to the queue." Attribute observers (the v0.1 in-place-mutation path that already works) are unchanged — they remain direct, because they are already thread-correct when fired from a main-thread widget callback and are the proven-working path.

## Hard constraints (all evidence-backed; each becomes a v0.2 requirement)

1. **Interactive thread is mandatory.** The `g_idle_add` drain only runs if the GLib loop has a thread to run on while the REPL is also live. Gtk4.jl requires Julia to start with an interactive thread pool (`--threads N,1`, or `JULIA_NUM_THREADS="N,1"`); without it the loop starves and the UI freezes during any REPL work, and on Julia 1.11 the REPL freezes outright. **v0.2 must (a) document this launch requirement and (b) add a startup check** — `makieviews()` should detect the absence of an interactive thread and refuse with an actionable message rather than deadlock. This interacts with the Julia 1.10 LTS + 1.12 compat range (ADR-001) and must be verified on both.
2. **`GtkMakieWidget` is a confirmed live blocker on exactly this operation.** Gtk4Makie documents its embeddable `GtkMakieWidget` as unstable, with an open upstream issue (JuliaGtk/Gtk4Makie.jl #14) specifically about *adding new plots to an existing widget* — the operation Bug F needs — and recommends the window-based `GTKScreen` path instead. **`makieviews()` uses precisely this widget path** (`src/FigureViews.jl`: `viewport_widget = Gtk4Makie.GtkMakieWidget(); push!(viewport_widget, makie_fig)`). So v0.2 inherits #14 as a direct blocker, and the embedding choice is **not** an open fork — it is a resolved fact that must change or be worked around. **v0.2's first spike must decide between:** (i) driving upstream #14 to resolution, (ii) switching the shell to a `GTKScreen`-in-grid arrangement (`grid(screen)` to host the tree/property panes alongside the GLMakie area), or (iii) the `GLMakie.Screen(; window=…, start_renderloop=false)` custom-window embedding route. This spike gates all GUI tasks and carries the milestone's highest risk. **Corroborating detail from the code:** the v0.1 demo only works because every `add_plot!` executes *before* `show(w)` — all mutation happens while the figure is still headless and the window opens last. Post-`show` structural mutation is unreached in v0.1, which is exactly why Bug F never fires in the shipped demo.
3. **Nothing in this stack is thread-safe by default.** GLMakie figures cannot be updated from a thread other than the render thread — not even through Observables. The queue exists precisely to funnel *every* structural mutation onto the single legal thread. Any code path that mutates a displayed figure off the main thread is a latent crash, so the queue must be the *only* structural-mutation entry point once a window is live (no direct `add_plot!`-to-renderer shortcut in GUI mode).

## Alternatives Considered

- **(a) `g_idle_add` per mutation, no explicit queue** — post each mutation as its own idle callback closure; skip the intermediate data structure. Rejected as the primary design but *acceptable as a v0.2 first cut*: it works for single edits, but a real queue gives ordering guarantees, lets the drain coalesce a burst of edits into one `queue_render`, and provides the natural seam for the undo/redo command stack ADR-019 anticipated. Start with per-mutation idle callbacks if it de-risks the milestone; converge on the queue.
- **(b) Keep the full-figure rebuild, just marshal it onto the main thread** — fix Defect 1 only. Rejected: every structural edit would re-render the whole figure and discard camera/interaction state on unrelated axes; does not scale past a few plots; the janky result is a worse first impression than v0.1's honest REPL API.
- **(c) Run the GLib loop on a separate thread and keep the REPL on the main thread** — invert which context owns main. Rejected: fights the entire Gtk4.jl/Gtk4Makie threading model (loop-on-interactive-thread is the supported configuration); unsupported territory with the same class of race conditions, just relocated.
- **(d) Poll the session tree on a timer and diff** — a `g_timeout_add` callback periodically diffs the tree and applies changes. Rejected: reintroduces the full-tree diff ADR-019 rejected for attribute edits; wastes frames when nothing changed; latency floor set by the timer interval; the queue is strictly better (event-driven, zero idle cost).
- **(e) Defer Bug F again / ship GUI without live structural editing** — a GUI where "Add Plot" requires closing and reopening the window. Rejected: this is the defining feature of a Veusz-style tool (SDD §1); without it the GUI offers little over the working REPL API.

## Consequences

- **Positive**: `makieviews()` can display a *user-built* session and accept live add/remove/reorder — the precondition for the entire v0.2 GUI surface (ADR-022's deferred list).
- **Positive**: Completes ADR-019's reasoning coherently — the command/queue seam it anticipated is now built, on the main thread, in compliance with the mutation rule it was protecting.
- **Positive**: Incremental ops preserve camera and interaction state on axes that didn't change; structural edits stop discarding unrelated view state.
- **Positive**: A single main-thread mutation entry point is a clean place to later hang undo/redo, transactional batching, and edit logging.
- **Negative / risk**: The `GtkMakieWidget` #14 dependency (constraint 2) is outside FigureViews' control. If upstream can't be driven and no embedding path works for live plot-add, v0.2's GUI scope is itself at risk — this is the milestone's highest-risk unknown and must be spiked first, before committing GUI tasks.
- **Negative**: The interactive-thread requirement (constraint 1) narrows how FigureViews may be launched and adds a startup check plus cross-version (1.10/1.12) verification. Documented as a launch prerequisite.
- **Negative**: Two code paths (headless-direct vs. live-queued) for structural mutation. Mitigation: a single `apply_structural!(session, op)` funnel that branches on "is a window live?" so callers never choose; only the funnel knows about the queue.
- **Negative**: Incremental `_add_axis!`/`_remove_axis!` must handle layout placement, which the v0.1 renderer sidesteps with its one-row-per-axis rule and deferred general `LayoutSpec`. General placement may need to land alongside, or the one-row rule be carried into v0.2 as an explicit interim constraint.

## Amendment to DESIGN.md

DESIGN.md §8 (renderer) and §9 (threading) are amended to specify the queue-drain mechanism, the headless-vs-live branch, and the incremental renderer operations. A threading-prerequisite note (interactive thread mandatory for live editing) is added to §9. Reference to ADR-024 added.

## References

- Gtk4.jl GLib reference — `g_idle_add` (callable from any thread; thread-safe scheduling): https://juliagtk.github.io/Gtk4.jl/dev/doc/GLib_reference/
- Gtk4.jl async UI howto (idle-callback marshalling pattern): https://juliagtk.github.io/Gtk4.jl/stable/howto/async/
- Gtk4.jl README (interactive-thread launch requirement, `--threads N,1`): https://github.com/JuliaGtk/Gtk4.jl
- Gtk4Makie.jl README (`GTKScreen` vs. unstable `GtkMakieWidget`; issue #14): https://github.com/JuliaGtk/Gtk4Makie.jl
- Working structural-mutation example (`empty!(ax); lines!(ax,…); Gtk4.queue_render`): Gtk4Makie/GtkMakie issue #5 thread
- GLMakie custom-window embedding (`GLMakie.Screen(; window=…, start_renderloop=false)`): https://docs.makie.org/dev/explanations/backends/glmakie
- `src/render/renderer.jl` (the full-rebuild observers this ADR replaces): project source, as of commit 3d4da4a (v0.1.0)
