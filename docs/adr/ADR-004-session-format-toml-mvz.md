# ADR-004 — `.mvz` session files: TOML with a top-level `schema_version`

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: SDD §7 (Forward-Looking Constraint), DESIGN.md §3

## Context

Session files hold the tree (Session → Figure → Axis → Plot) plus enough state to reproduce the figure. Requirements:
- Human-readable and diffable in Git.
- Forward- and backward-compatible: FigureViews v0.2 must open a v0.1 file, and v0.1 must fail cleanly (not corrupt) on a v0.2 file.
- Small enough to email; no binary bulk unless data is inlined (v0.1 stores references, not raw arrays).
- Parseable by Julia's stdlib.

## Decision

- Format: **TOML** (Tom's Obvious Minimal Language), Julia stdlib `TOML` module.
- Extension: **`.mvz`** — distinct from generic `.toml` so OS file associations can route to FigureViews.
- **Top-level `schema_version = "1.0"`** field, semver.
- **Forward compatibility**: FigureViews v0.1 refuses to load a file whose `schema_version` major is higher than the loader's.
- **Backward compatibility**: on load, FigureViews preserves unknown node types as opaque tables, renders them as placeholder tree entries, and round-trips them on save. (See SDD Forward-Looking Constraint and DESIGN.md §3.)

## Alternatives Considered

- **JSON**: less human-readable, no comments, awkward for a config-like file. Rejected.
- **BSON / JLD2**: opaque, not diffable in Git, no schema evolution story. Rejected.
- **YAML**: parses to something more permissive than we want; Julia support less canonical than TOML stdlib. Rejected.
- **Custom binary**: reinvents versioning and tooling; loses the "email me your session" affordance. Rejected.

## Consequences

- **Positive**: `.mvz` is Git-diffable; users can edit in a text editor for minor tweaks; version handling is explicit.
- **Positive**: `TOML` stdlib means no extra dependency.
- **Negative**: TOML has no native array-of-heterogeneous-typed-tables in a single scope — the tree must be encoded as a list of tables with an explicit `type` tag per node (see DESIGN.md §3).
- **Negative**: large numeric arrays would bloat a TOML file. v0.1 stores only *references* to source data (`source: "csv"`, `path: "…"` + `columns: [...]`), not the arrays themselves. If a user wants a self-contained bundle, that's a v0.2 feature.

## References

- Julia TOML stdlib: <https://docs.julialang.org/en/v1/stdlib/TOML/>
