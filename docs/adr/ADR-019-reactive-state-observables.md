# ADR-019 — Reactive state model: `Observables.jl` + mutable structs with per-field `Observable` fields

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: DESIGN.md §5 (property panel value flow), DESIGN.md §8 (renderer), DESIGN.md §9 (threading), ADR-002 (UI stack), ADR-009 (test strategy — Layer 1 tests are enabled by the pure-Julia mutability model this ADR pins), PLAN.md M2+ (this decision affects all reactive code through M10)

## Context

DESIGN.md §5 describes the property-panel value flow as *"widget change → callback writes to `plot.attrs[name]` → observer re-renders the plot on the shared `Makie.Figure`"* and §8 mentions Makie's "Observable pipeline" without pinning the mechanism for FigureViews' own tree state. The choice of reactive mechanism is load-bearing: every M2+ code path that mutates a `Session`, `Figure`, `Axis`, or `Plot` node — property-panel edits, add/delete tree operations, data-source snapshot updates, preferences-reset actions, animation binding changes, pre-flight downsampling application — flows through it. Pinning it after M2 has begun would mean rework.

Three realistic options were considered in the M2 pre-design pass (2026-08-24 chat session):

1. **`Observables.jl`** — the reactive library Makie itself uses internally. `Observable{T}` wraps a value; `on(observable) do new_val ... end` registers callbacks; `observable[] = new_val` fires all callbacks synchronously.
2. **Hand-rolled callback lists** — each mutable field carries a `_listeners::Vector{Function}`; setter functions notify listeners; no external reactive library.
3. **`Channel{Event}` + reader task** — mutations post events to a channel; a reader task processes them; enables logging, undo/redo, transactional batching by construction.

## Decision

FigureViews' tree state uses **`Observables.jl`** as its reactive layer, with node types declared as **`mutable struct`** and per-field `Observable` wrapping.

Concretely, the node type shapes DESIGN.md §2.1 declares as `struct` become:

```julia
mutable struct Session
    schema_version::VersionNumber
    figures::Observable{Vector{Figure}}
    preferences_snapshot::Dict{String,Any}
    selection::Observable{Union{Nothing, String}}    # id of currently-selected node
end

mutable struct Figure
    id::String
    title::Observable{String}
    layout::Observable{LayoutSpec}
    axes::Observable{Vector{Axis}}
end

mutable struct Axis
    id::String
    kind::Symbol                                     # :axis2d | :axis3d — immutable after creation
    title::Observable{String}
    xlabel::Observable{String}
    ylabel::Observable{String}
    zlabel::Observable{String}
    xlim::Observable{Union{Nothing, Tuple{Float64,Float64}}}
    ylim::Observable{Union{Nothing, Tuple{Float64,Float64}}}
    xscale::Observable{Symbol}
    yscale::Observable{Symbol}
    gridlines::Observable{Bool}
    legend::Observable{Bool}
    tickformat::Observable{Union{Nothing, String}}
    camera::Observable{Union{Nothing, CameraSpec}}
    plots::Observable{Vector{Plot}}
end

mutable struct Plot
    id::String
    type::Symbol                                     # :line | :scatter | ... — immutable after creation
    data_refs::Observable{Vector{DataRef}}
    attrs::Dict{Symbol, Observable{Any}}             # one Observable per attribute; keys match PLOT_SCHEMAS[type]
    animation_binding::Observable{Union{Nothing, AnimBinding}}
end
```

Two shape rules the above encodes:

- **`id` and `type` (or `kind`) fields are plain (non-Observable) and immutable after node creation.** They identify the node; changing them would mean creating a different node.
- **Everything mutable is an `Observable`.** No mixed plain-mutable-plus-Observable fields — a reader should never have to remember which fields fire and which do not.

`Plot.attrs` is a `Dict{Symbol, Observable{Any}}` rather than `Observable{Dict{Symbol, Any}}` because the property panel observes individual attributes (change linewidth → one observer fires) rather than the whole attrs dict at once (change linewidth → every observer of the dict fires, then diffs to find what changed).

The property-panel value flow (DESIGN.md §5) becomes:

```
widget onchange → validate(schema, :linewidth, new_value) → plot.attrs[:linewidth][] = new_value
                                                            └─→ Renderer's `on(plot.attrs[:linewidth]) do v ... end`
                                                                fires; renderer updates the Makie plot handle.
```

Debouncing at 60 Hz (DESIGN.md §5) is a `throttle(1/60, observable)` wrapper from Observables.jl applied at the widget-callback boundary, not at every observation site.

`Observables.jl` becomes a direct entry in `[deps]` of `Project.toml`, added in the first M2 task. It is already transitively present via Makie, so no resolver constraint change results.

## Alternatives Considered

- **Hand-rolled callback lists (Option 2).** Rejected: reinvents Observables.jl with per-node boilerplate; loses "well-tested, mature exception-isolation semantics" that Observables provides for free; unfamiliar to Makie users reading FigureViews source. The only real gain would be zero external reactive library, which is moot because Observables.jl is already in our depot via Makie.
- **`Channel{Event}` + reader task (Option 3).** Rejected: adds a task, which fights Gtk4's main-thread-only mutation rule (DESIGN §9); introduces race conditions between main-thread widget callbacks and reader-thread event processing; overengineered for v0.1 use cases; the async debugging cost is not justified when undo/redo (its main future benefit) is v0.2 deferred anyway. If M9's preferences work or a later milestone genuinely requires event batching, a command pattern on top of Observables.jl (mutation-through-a-single-function that also appends to an undo stack) satisfies it without a channel.
- **Immutable structs + top-level `Observable{SessionState}` with tree replacement (Redux-style).** Rejected as an alternative to per-field mutability: every attribute change (dragging a color picker at 60 Hz) would trigger a full-tree diff to identify what changed; performance concern for figures with many plots; alien to Julia GUI-state idiom; the undo/redo affordance it would provide is v0.2 work, not v0.1.

## Consequences

- **Positive**: FigureViews' source reads like an extension of Makie rather than a foreign object grafted on. Any Makie user is fluent in the `x[]`, `on(x) do v ... end` pattern.
- **Positive**: Layer 1 unit tests (per ADR-009 and TEST_PLAN.md §6) can drive the tree entirely through the reactive layer without any Gtk4 or GLMakie code, satisfying the "SessionState is a pure Julia object graph — no Gtk4 or GLMakie references" invariant declared in DESIGN.md §1.
- **Positive**: Debouncing (60 Hz per DESIGN §5) is a one-line `throttle` from Observables.jl.
- **Positive**: The Renderer (DESIGN §8) becomes a simple observer registration hub — no polling, no diffing.
- **Negative**: `mutable struct` disables Julia's `==` value equality by default; equality now compares object identity. Any code that needs value equality on a node writes an explicit equality function (or the round-trip test at TEST_PLAN §3 compares serialized TOML forms, not Julia structs — which is what it already does).
- **Negative**: Ties FigureViews' state model to `Observables.jl`'s API. Historically stable; if it breaks in a future release, migration effort is proportional to node type count (small in v0.1).
- **Negative**: Every mutation site must remember to `[] =` rather than `=`. Mitigation: convention documented in DESIGN.md §5 and §8; enforced by code review.

## Amendment to DESIGN.md

Sections §5 (property panel) and §8 (renderer) are amended to specify this decision. The struct field declarations in §2.1 are updated to reflect the `mutable struct` shape with `Observable` fields shown above. Reference to ADR-019 added.

## References

- Observables.jl: https://github.com/JuliaGizmos/Observables.jl
- Makie's use of Observables (idiomatic pattern FigureViews mirrors): https://docs.makie.org/dev/explanations/observables
- M2 pre-design chat session (this decision): 2026-08-24
