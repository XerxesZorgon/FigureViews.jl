# ADR-017 — Reserve `[[figure.axis.plot.data_inline]]` in v0.1 schema; v0.1 loader rejects with a specific message

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ODQ-7 (closed by this ADR), ADR-004 (session format), DESIGN.md §3

## Context

v0.1 `.mvz` files store data by reference, not by value (ADR-004, DESIGN.md §3.2). v0.2+ may add self-contained sessions — inlining data arrays so a single `.mvz` file is a complete portable artifact.

If v0.1 does not reserve the schema slot for inline data now, v0.2's addition becomes a schema bump. If v0.1 reserves the slot and *rejects* it on load with a specific message, v0.2's addition is a minor version bump — the schema was already prepared.

## Decision

- v0.1 **reserves** the sub-table name `data_inline` under `[[figure.axis.plot]]` in the documented schema. It is not written by v0.1 save code.
- v0.1's loader **refuses** to open any `.mvz` file whose `[[figure.axis.plot]]` entries include a `data_inline` sub-table, with a **specific error message** (not a generic parse failure):

  > `"This .mvz contains inline data (data_inline), which requires MakieViews v0.2 or later. Loading aborted."`

- The error is caught at file-load time and surfaced via a Gtk4 message dialog naming the file path and the message above.
- v0.2 will define `data_inline`'s TOML schema and enable both read and write.

## Alternatives Considered

- **Do not reserve the slot; add it in v0.2 as a schema change**: forces a `.mvz` schema-version major bump when v0.2 lands. Rejected.
- **Reserve the slot and try to read it in v0.1** (best-effort): v0.1 has no code path to render from inline arrays; partial success would be silent breakage. Rejected.
- **Generic "unknown field" behavior**: users would see a generic parse error and blame their file. Rejected — a named field deserves a named error.

## Consequences

- **Positive**: v0.2 can add inline data without bumping the major schema version. Existing v0.1 sessions are unaffected.
- **Positive**: v0.1 users who try a v0.2-generated inline-data file get a clear, actionable error message.
- **Negative — small documentation obligation**: `DESIGN.md` §3 must call out the reserved slot even though v0.1 doesn't use it. Done.

## References

- ADR-004.
- DESIGN.md §3.
