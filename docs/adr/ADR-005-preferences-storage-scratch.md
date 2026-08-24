# ADR-005 — Per-user preferences via Scratch.jl-managed TOML

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ADR-006 (preferences behavior), DESIGN.md §6

## Context

MakieViews needs a per-user, cross-platform place to store runtime preferences: font family/size, line width, marker types, color palette, grid defaults. It must:
- Survive package reinstalls (users hate re-configuring on `] update`).
- Be per-user, not per-project.
- Work on Windows, macOS, and Linux without hand-rolled path logic.

## Decision

Use **`Scratch.jl` v1.3.x** to obtain a per-user scratch directory scoped to MakieViews, and write preferences as `preferences.toml` inside it.

Location resolves via Julia's standard cross-platform directories (e.g., `~/.julia/scratchspaces/<uuid>/MakieViews/` under the hood — implementation detail; we do not depend on the exact path).

## Alternatives Considered

- **`Preferences.jl`**: designed for *compile-time* package preferences (things `Base.@load_preference` reads during precompilation). Not intended for user-driven runtime settings that change often. Would trigger recompiles for benign styling tweaks. Rejected.
- **Hand-rolled config paths** (e.g., `$HOME/.config/makieviews/` on Linux, `%APPDATA%\MakieViews\` on Windows, `~/Library/Application Support/MakieViews/` on macOS): reinvents cross-platform user-config-directory logic, which is exactly what Scratch.jl solves. Rejected.
- **Store in the `.mvz` session file only**: ties preferences to a session; loses "my defaults follow me across projects." Rejected.

## Consequences

- **Positive**: cross-platform path handling handled by Scratch.jl; survives reinstalls; no compile-time coupling.
- **Positive**: preferences are a plain TOML file the user can edit in a text editor or delete to reset.
- **Negative**: scratch spaces are keyed by package UUID; if the UUID ever changes, existing preferences are orphaned. Migration path documented in DESIGN.md §6.

## References

- Scratch.jl 1.3.0: <https://github.com/JuliaPackaging/Scratch.jl>
