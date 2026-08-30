# ADR-010 — Downsampling algorithms offered by the pre-flight check

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: SDD FR-023..FR-026, DESIGN.md §7 (pre-flight state machine)

## Context

When a dataset is too large for smooth interactive display, FigureViews offers to downsample before rendering. The choice of algorithms matters:
- Different plot types need different algorithms.
- The algorithm changes the visual character of the plot; users must know which one is running.

## Decision

v0.1 offers three algorithms, chosen per plot type by the GUI:

1. **Uniform stride** — take every k-th point. Cheap, unbiased for regularly-sampled data, but drops peaks. Applicable to any 1-D or 2-D array.
2. **Min/max decimation** — bucket the data into N buckets, keep both the min and the max of each bucket. Preserves envelope. Applicable to line and scatter plots on ordered X.
3. **LTTB** (Largest-Triangle-Three-Buckets, Steinarsson 2013) — for line plots, an algorithm that preserves visual shape by picking the point in each bucket that forms the largest triangle with the previous and next buckets' representatives.

For 2-D field data (heatmap, contour, surface), the property panel exposes a stride slider only (algorithm 1). LTTB and min/max are 1-D-line algorithms.

## Alternatives Considered

- **Adaptive sampling** (recursively subdivide where variation is high): produces the best-quality reduction but is complex to implement and hard to make predictable for users. Deferred.
- **Douglas–Peucker** (line-simplification): changes visual character in ways that surprise users of scientific plots (removes points that lie near a straight line even when those points are meaningful measurements). Rejected for v0.1.
- **No downsampling — just warn**: leaves the user to figure it out. Rejected because the SDD requires an offered fix, not just a warning.

## Consequences

- **Positive**: three algorithms cover the common cases; LTTB is well-known in the exploratory-plotting community.
- **Positive**: the downsampled plot preserves a reference to the full dataset (DESIGN.md §7), so a "render at full resolution" action is a v0.2 add without data loss in v0.1 files.
- **Negative**: users may want an algorithm we don't ship (adaptive, Douglas–Peucker, custom). v0.2 can add more; the downsampling API is a simple `(data, target_n) -> data′` interface (DESIGN.md §7) that admits new entries.

## References

- Steinarsson, S. (2013). *Downsampling Time Series for Visual Representation.* MSc thesis, University of Iceland — LTTB source.
