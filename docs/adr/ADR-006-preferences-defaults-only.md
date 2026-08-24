# ADR-006 — Preferences are defaults-only; existing figures are not restyled on load

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ADR-005 (storage), SDD FR-020..FR-022, DESIGN.md §6

## Context

Preferences let a user pick a default look. But there are two ways to apply them:

1. **Live theme override** (via Makie's `set_theme!`): every figure — new or loaded — renders with current preferences. Users don't have to re-apply styling per figure.
2. **Defaults only**: preferences seed new figures. A loaded figure keeps its saved styling. Users get an explicit "Reset selection to preferences" action to apply on demand.

Option 1 breaks the "the plot I saved is the plot I get back" contract: opening `paper_figure.mvz` after changing your preferred palette silently gives you a different figure. This is exactly the surprise that erodes trust in any tool that stores styling.

## Decision

- **Defaults-only**. Preferences seed new figures at creation time. Existing figures load with their saved styling untouched.
- Provide a **"Reset selection to preferences"** GUI action that walks selected tree nodes and applies current preferences to them explicitly, at user request.
- **Do not call `set_theme!`** at any point in the runtime — the app must not carry a global theme override that surprises the user on figure load.

## Alternatives Considered

- **Live theme override via `set_theme!`**: convenient for users who want their look to follow every figure, but breaks save/reload fidelity (SC-004). The user's escape hatch — "Reset selection to preferences" — recovers the same behavior on demand without the surprise. Rejected as default.
- **Ask on load** ("Apply current preferences?"): dialog fatigue; users pick the same answer forever and would prefer the app to just do the safe thing. Rejected.

## Consequences

- **Positive**: the "what I saved is what I get back" contract holds. Save/reload fidelity is testable (see TEST_PLAN.md §3 round-trip test).
- **Positive**: preferences are still useful — every new figure picks them up.
- **Negative**: users who change preferences and want them applied to existing figures must click "Reset selection to preferences." This is a discoverability cost, mitigated by naming and by including it in the getting-started walkthrough (README.md §Quickstart).

## References

- SDD §5 FR-021, FR-022.
