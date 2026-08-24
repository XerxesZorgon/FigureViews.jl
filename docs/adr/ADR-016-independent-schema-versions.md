# ADR-016 — `preferences.toml` and `.mvz` carry independent `schema_version` fields

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ODQ-6 (closed by this ADR), DESIGN.md §6, ADR-004 (session format), ADR-005 (preferences storage)

## Context

Both `preferences.toml` and `.mvz` files carry a `schema_version` for forward/backward compatibility. Two designs:

1. **Shared version**: bump either file's format → bump both. Simpler policy; easier to reason about.
2. **Independent versions**: each file evolves on its own schedule. Preferences change more often (new styling defaults every minor MakieViews release), session format changes rarely (deep tree-model changes only).

## Decision

- `preferences.toml`'s `schema_version` and `.mvz`'s `schema_version` are **independent**.
- Each file's loader checks *only its own* schema version against its supported range.
- Preference-format changes do not bump `.mvz` schema and vice versa.
- Semver rules apply per file independently: a major bump in one is a breaking change for that file only.

## Alternatives Considered

- **Shared version**: creates false coupling — a new preference field would force a `.mvz` major bump, invalidating existing sessions. Rejected.
- **No schema versioning on preferences** (only `.mvz`): loses the "MakieViews v0.5 opens a v0.1 preferences.toml cleanly" story. Rejected.

## Consequences

- **Positive**: each file evolves at its own pace. Preferences can grow monthly without touching session files. Session-format changes remain deliberate and rare.
- **Positive**: the two loaders share a code pattern but no coupling, simplifying tests.
- **Negative**: two version numbers to reason about. Documented in DESIGN.md §3 and §6 with an at-a-glance compatibility table published in each MakieViews release notes.

## References

- ADR-004 (`.mvz` schema_version).
- ADR-005 (preferences storage).
