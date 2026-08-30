# ADR-012 — Data-source paths: store both absolute and relative-to-mvz; try relative first

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ODQ-2 (closed by this ADR), DESIGN.md §3.2 and §4, ADR-004

## Context

`.mvz` files reference data (CSV, HDF5) by path, not by inlined array (ADR-004, DESIGN.md §3.2). Two failure modes are common:

1. **User emails a folder** containing `analysis.mvz` and `data/q3.csv` to a colleague. Absolute paths fail on the colleague's machine.
2. **User keeps sessions on a workstation** and reopens `analysis.mvz` months later. Relative paths fail if they opened FigureViews from a different working directory.

Two-path storage handles both: absolute for the workstation case, relative-to-`.mvz` for the portable case.

## Decision

- Every `DataRef` in `.mvz` stores **both** `absolute_path` and `relative_path` (relative to the `.mvz` file's directory).
- On load, the loader tries paths in this precedence:
  1. **`relative_path`** resolved against the `.mvz` file's directory.
  2. **`absolute_path`** as stored.
  3. If both fail, open a "file not found" dialog with (a) the two paths tried, (b) a Browse button, (c) a "Skip this plot" option.
- Content-hash verification of a matched file is **deferred to v0.2+**. v0.1 trusts filename matches.

TOML shape for a `DataRef`:

```toml
[[figure.axis.plot.data_refs]]
role = "z"
source = "csv"
absolute_path = "C:\\Users\\johnx\\Documents\\research\\q3\\runs\\q3.csv"
relative_path = "runs/q3.csv"
column = "P"
```

## Alternatives Considered

- **Absolute only**: portable failure mode (email a folder → colleague can't open). Rejected.
- **Relative only**: workstation failure mode (open from a different `cwd`). Rejected.
- **Content hash + fuzzy search**: robust but complex and slow on large datasets; scanning a directory tree for a matching hash is a v0.2+ investment. Deferred.
- **Prompt the user on every load**: dialog fatigue. Rejected.

## Consequences

- **Positive**: portable-folder use case works without user action. Workstation use case works. Both surfaces of failure produce a clear dialog, never a silent skip.
- **Positive**: the two-path scheme is a tiny schema addition and stays backward-compatible with v0.2 hash-based verification (hash becomes an additional optional field).
- **Negative**: `.mvz` files are marginally larger — negligible for the sub-KB per-DataRef entries typical of scientific sessions.
- **Negative**: if the user reorganizes their folder tree (e.g., splits data into subfolders after saving), the relative path can point at the wrong file. The load-time "file not found" dialog catches missing files; a *wrong* file with a valid name at the right relative path would still load. Documented in README; content-hash in v0.2 is the fix.

## References

- DESIGN.md §3.2, §4.
- ADR-004 (session format).
