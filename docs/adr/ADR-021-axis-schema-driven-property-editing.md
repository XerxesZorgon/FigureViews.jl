# ADR-021 — Axis schema-driven property editing (AXIS_SCHEMAS)

**Status**: Accepted (2026-08-25).
**Date**: 2026-08-25
**Deciders**: John Peach
**Related**: DESIGN.md §2.4, DESIGN.md §5, NFR-002

## Context

Through M3, the property panel only edited `Plot` nodes via `PLOT_SCHEMAS`. M4 introduces camera controls, which are an `Axis` property (`Axis.camera`), not a plot property. Editing them schema-driven requires a schema registry for axis attributes.

## Decision

Introduce `const AXIS_SCHEMAS = Dict{Symbol, Vector{AttrSpec}}()` parallel to `PLOT_SCHEMAS`, keyed by `Axis.kind` (`:axis3d`, later `:axis2d`). The property panel dispatches on the selected node's Julia type: `Plot` → `PLOT_SCHEMAS[plot.type]`, `Axis` → `AXIS_SCHEMAS[axis.kind]`. Reuse `AttrSpec` and `validate()` unchanged. Camera azimuth/elevation/zoom are modeled as three `:number` specs.

## Consequences

- First non-Plot node the property panel edits.
- Establishes the migration path for M2's hand-wired axis attributes (title/labels/limits) to become schema-driven in a later cleanup.
- No `.mvz` schema-version bump (camera already serialized per DESIGN §3.1).
- No change to `AttrSpec` or `validate`.

## Alternatives Considered

- (a) A dedicated non-schema camera sub-panel — rejected because it reintroduces per-type UI branching, the exact thing NFR-002 forbids.
- (b) Modeling camera as a pseudo-Plot — rejected as a semantic hack that would corrupt the tree model.
