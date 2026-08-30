# ADR-007 — v0.1 data ingestion: REPL `Main`, CSV, HDF5 only

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: SDD FR-001..FR-004, DESIGN.md §4

## Context

Scientific data lives in many formats: CSV, HDF5, Parquet, Arrow, JSON, SQLite, custom binaries. Every ingestion path adds surface area — dependency, tests, error handling, UI affordance. v0.1 should cover the workflows most users need on first launch and leave the rest for later.

## Decision

v0.1 supports three ingestion sources:

1. **Julia REPL `Main` variables** — enumerated when FigureViews is launched as `makieviews()` from the REPL, filtered to array-like plottable types (`AbstractVector`, `AbstractMatrix`, `AbstractArray{<:Real, 3}`, `DataFrame`).
2. **CSV files** via `CSV.jl` 0.10.x + `DataFrames.jl` 1.8.x.
3. **HDF5 files** via `HDF5.jl` 0.18.x.

Data snapshots are taken by copy at ingest time (SDD FR-004) so later mutations in `Main` do not silently affect plots.

## Alternatives Considered

Deferred to a later version:

- **Parquet** (via `Parquet2.jl`): valuable for analytics workflows but adds a compression stack. Deferred.
- **Arrow** (via `Arrow.jl`): similar reasoning; deferred.
- **JSON** (via `JSON3.jl`): often used for schema-less blobs; picker UX for nested JSON is nontrivial and deserves its own design pass. Deferred.
- **SQLite** (via `SQLite.jl`): would need a query builder or query editor — a project of its own. Deferred.
- **Direct URL / network** (fetch a CSV from HTTP): security/UI implications; deferred.

## Consequences

- **Positive**: v0.1 covers the two dominant scientific-data formats (CSV, HDF5) plus the "I already have it in my REPL" path that Julia users expect.
- **Positive**: three ingestion paths keep the ingestion layer testable.
- **Negative**: users with Parquet/Arrow/JSON/SQLite data must convert externally for v0.1. README.md documents this and the intended v0.2+ additions.
- **Follow-up**: the ingestion layer is written behind a small abstraction (`DataSource` — DESIGN.md §4) so adding formats later is additive rather than intrusive.

## References

- CSV.jl 0.10.16, DataFrames.jl 1.8.2, HDF5.jl 0.18.0.
