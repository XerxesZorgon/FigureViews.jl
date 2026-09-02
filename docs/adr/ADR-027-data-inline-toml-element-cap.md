# ADR-027 — Inline array data in `.mvz` TOML with a 100,000-element cap; binary sidecar deferred

**Status**: Accepted  
**Date**: 2026-09-02  
**Deciders**: John Peach  
**Related**: ADR-017 (reserved `data_inline` slot), ADR-004 (session format), DESIGN.md §3

## Context

v0.1 `.mvz` files store data by reference only — snapshot ids are written but the actual arrays are not. A reloaded session renders plots as unresolved placeholders because `session.data_snapshots` is empty after load. M16 implements the `data_inline` slot ADR-017 reserved so a saved session reopens with its data intact (SDD SC-004).

The key design question is how to store arrays in a TOML file:

- TOML has no binary type. Arrays must be stored as lists of numbers (text).
- A 1,000-element float vector becomes ~8 KB of text — tolerable.
- A 1,000,000-element vector becomes ~8 MB of text — slow and impractical.
- The project's demo surface plot is 900 elements. Typical scientific plots in FigureViews fit comfortably below 100,000 elements.

## Decision

For M16 (v0.2), session array data is stored **inline in the `.mvz` TOML file** as flat lists of Float64 values. The following rules apply:

1. **Element cap**: any snapshot with more than **100,000 elements** is refused at save time with a clear error message directing the user to keep large data in CSV or HDF5 files and load via the existing file-source machinery.
2. **No binary sidecar**: no second file is written alongside the `.mvz`. A saved session is always a single file.
3. **Orphan drops**: snapshots not referenced by any plot in the session are silently dropped on save. Only data that is actually plotted is stored.
4. **De-duplication**: if two `DataRef`s in the same plot share a snapshot id, the array is written only once.
5. **Schema version**: bumped from `"1.0"` to `"1.1"` (minor bump). The v0.1 loader already emits a warning for same-major newer-minor files and continues loading; v0.1 `.mvz` files (no `data_inline`) load unchanged under the v1.1 loader.

The on-disk format per snapshot under `[figure.axis.plot.data_inline]`:
```toml
[figure.axis.plot.data_inline.SNAPSHOT_ID]
eltype = "Float64"
shape  = [100]
data   = [0.1, 0.2, ...]
```

## Alternatives Considered

- **Binary sidecar (HDF5 or raw bytes alongside the `.mvz`)**: compact and fast for large arrays, but a saved session becomes two files — awkward for the user and complicates file-dialog save/open flows. Deferred indefinitely; the project already has HDF5.jl for large-data loading.
- **HDF5 embedded in the `.mvz`**: would require either renaming `.mvz` to a zip container or a non-standard TOML extension. Rejected — adds complexity for no benefit at current dataset sizes.
- **No inline data / REPL-only forever**: leaves SC-004 permanently open and breaks the "save → share → reopen" use case entirely. Rejected.

## Consequences

- **Positive**: SDD SC-004 is closed. A saved session is a single portable file that reopens with all data intact.
- **Positive**: the 100,000-element cap is generous for typical scientific plots and gives a clear, actionable error for the rare case that exceeds it.
- **Negative**: users with large datasets (>100k elements) cannot save inline and must use CSV/HDF5 file sources instead. This is documented in the error message.
- **Negative**: TOML float-list representation is ~8× larger than binary for float64 data. Acceptable at the cap size (~800 KB text maximum per snapshot).
- **Neutral**: binary sidecar remains a valid future option if user demand grows; nothing in this ADR precludes it.
