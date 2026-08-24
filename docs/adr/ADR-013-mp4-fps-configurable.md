# ADR-013 — MP4 / GIF export: user-configurable fps, default 30

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ODQ-3 (closed by this ADR), SDD FR-014, DESIGN.md §5 (per-plot attributes not affected)

## Context

Animation export requires a frames-per-second (fps) choice. Two options:

1. Fixed default with no UI (simplest; least flexible).
2. User-configurable with a sensible default (standard export dialog convention).

Standard scientific animation runs 24–60 fps. 30 is the common default for MP4 and matches many projector refresh rates.

## Decision

- Export dialog exposes a **fps spinner** (integer, range 1–60, default **30**).
- Applies to both MP4 and GIF export.
- The fps value is **not** stored in the `.mvz` file — it is an export-time choice, not a session property. Re-opening the session does not re-preload a specific fps.

## Alternatives Considered

- **Fixed 30 fps, no UI**: works for 95% of cases but forces users needing 24 (cinematic) or 60 (smooth motion) to modify export code externally. Rejected — the extra UI is trivial.
- **Store fps in `.mvz`**: overloads session state with export preferences; the same session might be exported at different fps for different venues. Rejected.

## Consequences

- **Positive**: covers standard scientific export needs without cluttering session state.
- **Negative**: none material.

## References

- SDD FR-014.
- DESIGN.md §5 (property panel) — fps is *export-dialog* UI, not per-plot property panel.
