# ADR-028 — Generative architecture: node graph as truth, code emitter, two-window model, mutable plot type

**Status**: Accepted  
**Date**: 2026-09-03  
**Deciders**: John Peach  
**Related**: ADR-026 (generic node model), ADR-027 (inline data), ADR-004 (`.mvz` format),
ADR-024/025 (renderer + embedding), PLAN-v0.2.md M17

## Context

During M17 development, the following design questions emerged and were resolved in a
single design session (2026-09-03). They are recorded here because they collectively
define the generative architecture that governs the editor, the planned grid window,
code export, and plot-type mutability. Prior ADRs (especially ADR-026) established the
node model; this ADR governs what is *done with* that model at the application layer.

The questions that drove this ADR:

1. **What is the primary creation flow?** Drag-to-add (data-first via drag/drop) or
   select-variables-then-choose-type, or type-first (Veusz style)?
2. **Can a plot's type be changed after creation?** Or is type fixed at creation time?
3. **Is the node graph or the emitted Makie code the source of truth?**
4. **How does the "store the code and regenerate" goal relate to the node model?**
5. **Should a second (grid/presentation) window be supported, and what are its rules?**
6. **How does matrix-role orientation ambiguity get resolved?**

## Decisions

### D1 — Creation flow: data-first, then type

The primary plot-creation flow is:

1. User selects one or more variables from the variable browser pane (ordered:
   1st selection → x role, 2nd → y role, 3rd → z role).
2. User chooses a plot type from the available types filtered by the selected
   variables' shapes and arity.
3. A plot node is created with the selected variables bound to roles in selection
   order; the plot renders immediately.

**Rationale.** Type-first (Veusz style) picks the type blind, before the data is
visible. Data-first picks the type after seeing what was selected, which is strictly
more informed. The creation flow is data-first, but type mutability (D2) means the
initial type choice is cheap to revise — so "wrong first choice" costs one click, not
an undo-and-redo. This dissolves the usual argument for type-first.

Drag-and-drop (Tasks 119–122) is **not the primary creation path** and is left in
place as a potential future accelerator. The variable browser's ordered selection is
the primary gesture.

**Matrix-role orientation.** When a matrix variable is bound to a role and its shape
does not uniquely determine orientation (e.g. a square N×N matrix with an x-vector of
length N — rows-vs-columns is ambiguous), the creation dialog presents a compact
orientation question. When alignment is unambiguous (matrix has N rows, x-vector has
N elements, other dimension differs), orientation is inferred silently. This replaces
the earlier "matrix column / slice DataRef" design that was considered and rejected as
unnecessary complexity.

### D2 — Plot type is a mutable node property

A plot's `type` (and `func`) field can be changed after creation without deleting and
recreating the node. The mechanism is:

1. `_remove_plot_handle!(renderer, plot_id)` — tears down the Makie handle and all
   observers (`off()` each, delete from `_plot_observers`, `plot_handles`, `_plot_axis`).
2. Mutate the node: set `plot.type`, `plot.func`, rebuild `plot.attrs` from the REGISTRY
   entry for the new type (preserving shared attribute values; taking REGISTRY defaults
   for new-type-only attrs; discarding old-type-only attrs).
3. `_add_plot_handle!(renderer, ax_node, plot)` — rebuilds the Makie handle and
   re-registers observers.

**Proven by spike** (`spike/type_mutability.jl`, 2026-09-03, headless CairoMakie):
`Plot` is a `mutable struct`; teardown returns the observer table to exactly the new
count with zero leaks; handle transitions from `Makie.Lines` to `Makie.Scatter`; node
`id` and `data_refs` are unchanged; export reflects the new type.

**Also proven by live-window spike** (`spike/live_type_swap.jl`, 2026-09-03,
GLMakie + Gtk4Makie, running window): the GLMakie viewport updated in-place from a
continuous line to scatter dots without closing, hanging, or blanking. Handle type
transitioned to `Makie.Scatter`, observer count returned to exactly 6, node id
unchanged, export 57 KB. No GL errors. The live-window gate is cleared.

**Type mutability is only valid within a role-compatible family.** `:line` → `:scatter`
is valid (both bind `:x`/`:y`). `:line` → `:hist` is not valid in-place (`:hist` binds
`:values`, not `:x`/`:y`); a cross-family type change requires re-binding roles and
is treated as a new plot creation, not an in-place mutation.

**UI surface.** A type selector control at the top of the plot's property pane exposes
this capability. "Change scatter to line after a first look" is one click on a dropdown,
not a rebuild. This is the primary motivation: cheap revision after seeing the data.

### D3 — Node graph is the source of truth; Makie code is emitted from it

The document model is the **node graph** (ADR-026). This is the source of truth for
editing, persistence, and rendering. The `.mvz` file serializes the node graph.

**Makie code is emitted *from* the node graph** — it is a derived, generated artifact,
not an editable primary. The emitter is a pure function:

```
emit_plot_code(plot::Plot)  →  String   # e.g. "lines!(ax, x, y; color=:blue)"
emit_axis_code(ax::Axis)    →  String   # e.g. "ax = Axis(fig[1,1]; title=\"Sine wave\")"
emit_figure_code(fig::Figure, session::Session) → String   # full runnable script
```

The node graph is the reason the property panel is tractable: `plot.attrs[:color]` is
an `Observable` a color-picker can bind to. Emitted code is text — there is nothing to
bind a slider to. If code were the primary truth, every property-panel edit would
require parsing Julia, mutating an AST, and regenerating the string on every interaction.
The node model makes editing O(1) field writes; code-as-primary makes it a compiler
problem. The node model is retained.

**The emitter is the bridge between the editable world and the generative/portable
world.** It enables:
- Code export: "give me the Julia that produces this figure."
- The grid (presentation) window: re-executes emitted code into grid cells.
- Reproducibility: store the emitted code alongside data and the figure regenerates
  exactly.

**Task 123** (`src/emit/emit_plot.jl`) is the first piece of the emitter chain. Axis-
and figure-level emission are subsequent tasks.

### D4 — Two-window model: editor and grid (presentation) window

Two windows are planned for a future milestone:

**Editor window** (current `makieviews()` window): the live editing surface. The node
graph is fully mutable here. The property panel, tree, variable browser, add-plot flow,
and type-change controls all live in this window. One figure per editor window at
launch; multiple editor windows is a future consideration.

**Grid (presentation) window**: a read-only composition surface. Each pane in the grid
re-executes the emitted Makie code for one stored figure into a grid cell
(`fig[i, j]`). The grid window has no property panel, no tree editing, no drag/drop.
It is read-only because it displays the *output* of stored code — editing would require
editing the code that belongs to another figure, which is the editor window's job.

**Why the read-only rule is principled, not arbitrary.** The grid window re-runs
emitted code; it does not hold a live node graph for those figures. Without the node
graph there is nothing to bind UI controls to. Read-only falls out of the architecture.

**Multi-panel single figures.** Multiple axes within one editor figure (e.g. main plot
+ residuals panel) remain supported for cases where panels genuinely belong to one
designed artifact — one `Figure`, shared layout, saved together, exported together.
The grid window is for composing *independent* figures, not for replacing the
within-figure multi-panel capability.

**Open prerequisite.** Whether Gtk4Makie supports two live embedded GL contexts in one
process has not been spiked. This is a hard gate before any grid-window task is written.
See consequences below.

### D5 — Drag/drop code (Tasks 119–122) is not removed

The drag/drop infrastructure (`_parse_var_drop_payload`, `_find_selected_axis`,
`recommend_plot_type`, `GtkDragSource`/`GtkDropTarget` wiring) is left in place.
It is superseded as the *primary* creation path but is not harmful and may be revisited
as an accelerator. No revert task is planned.

## Alternatives Considered

- **Type-first (Veusz style):** pick type before selecting data. Rejected because it
  forces the user to choose blind; data-first with cheap type mutation is strictly
  superior.
- **Code as primary truth:** store Julia source as the document. Rejected because a
  property panel cannot bind to syntax — editing becomes a compiler problem. See D3.
- **Auto-create on drop (Tier-1 recommender):** Task 122 implemented this but the
  manual gate showed it produces wrong defaults silently (`:hist` on a sine wave
  rescaled the axis unexpectedly). Superseded by the explicit selection + type-choice
  flow in D1.
- **Matrix-column / slice DataRef (new ADR for a slice grammar):** considered to support
  `M[:,3]`-style role binding. Rejected in favor of an orientation dialog at creation
  time, which covers the ambiguous cases without a new DataRef variant or grammar.
- **Removing multiple axes from the editor:** considered when the grid window was
  proposed, on the grounds that comparison belongs in the grid. Rejected because
  multi-panel figures (main + residuals) are a single designed artifact, not a
  comparison of independent figures.

## Consequences

- **Positive:** the property panel (and the type-change selector) is unambiguously
  grounded in the node graph. No architectural tension between "editing" and "code."
- **Positive:** code export and grid-window consumption are clean, bounded tasks —
  write the emitter, consume it in two places.
- **Positive:** type mutability is proven clean at the data/observer layer. "Change
  type after a look" is a first-class, cheap operation.
- **Positive:** matrix orientation ambiguity is resolved by a dialog ask rather than a
  new DataRef variant — simpler and consistent with the existing creation-dialog pattern.
- **Resolved:** the live-window type-swap path is verified clean (`spike/live_type_swap.jl`, 2026-09-03).
- **Negative / risk:** two live Gtk4Makie GL contexts in one process is unverified.
  Must be spiked before any grid-window task is written.
- **Neutral:** drag/drop code remains; it is inert if nothing initiates a drag. Future
  maintainers may wire it to the new creation flow or remove it.
- **Neutral:** the emitter (Task 123 onwards) is a new module (`src/emit/`) parallel to
  the renderer. Both read the node graph; neither modifies it.

## Pre-build spikes still required

| Spike | Gates |
|---|---|
| ~~Live GLMakie type-swap (window open, not headless)~~ | ~~Type-change UI task~~ — **cleared 2026-09-03** |
| Two live Gtk4Makie embedded contexts in one process | Any grid-window task |
