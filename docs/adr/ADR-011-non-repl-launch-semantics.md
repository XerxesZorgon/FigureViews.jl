# ADR-011 — Non-REPL launch: REPL-only for v0.1, with detection and warning

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ODQ-1 (closed by this ADR), DESIGN.md §4.3, SDD FR-001

## Context

`makieviews()` is designed to be called from a Julia REPL, where `Main` is the interactive module and holds the user's variables. In other launch contexts, `Main` means something different:

- Script run via `julia script.jl`: `Main` is the *script's* top-level scope. Variables defined in the script are visible; anything the user defines later goes nowhere.
- IDE-integrated REPL (VS Code Julia extension, Pluto, Jupyter): behavior varies by IDE. VS Code's Julia extension routes user input to `Main` similarly to a REPL, but the guarantee is not language-level.
- `Base.include`, embedded runtimes, distributed workers: further variants.

A silent behavior difference between contexts is exactly the confusion trap the SDD's forward-looking constraints exist to avoid.

## Decision

- **v0.1 supports REPL launch as the tested happy path.**
- At `makieviews()` entry, FigureViews detects whether it is running in an interactive REPL by inspecting `isinteractive()` and `Base.active_repl` availability.
- On non-REPL launches, FigureViews **does not error** — it opens normally and emits a one-line warning explaining the semantic difference:

  > `FigureViews v0.1 reads variables from REPL Main. You appear to be running outside a REPL. Variables defined in this script/context so far are visible; variables you define later will not appear. File loading (CSV / HDF5) works normally.`

- A `source_module=` keyword argument to `makieviews()` is **explicitly deferred to v0.2** and not accepted in v0.1. (Silently accepting it now would create a documentation-lag risk.)

## Alternatives Considered

- **REPL-only with a hard error on non-REPL launch**: prevents confusion by refusing to run. Rejected: users on IDE-integrated REPLs where `isinteractive()` returns true but the harness is subtly different (Pluto, some Jupyter kernels) would be locked out of a working workflow.
- **No detection, launch silently, document REPL requirement in README only**: users won't read the README before trying; silent misbehavior would be the first impression.
- **Accept `source_module=` in v0.1**: solves the IDE-and-embedded case now, but adds a parameter that must be tested against every configuration we can't yet enumerate. Better to defer to v0.2 once the REPL path is stable.

## Consequences

- **Positive**: happy-path launch is fully supported and tested. Alternative launches work with a self-explanatory warning — users are not surprised.
- **Positive**: the warning is one line, easy to grep for in the source, and easy to update as v0.2 lands the `source_module=` fix.
- **Negative**: detection heuristic (`isinteractive() && isdefined(Base, :active_repl)`) has known false-positives in embedded contexts. Documented in README troubleshooting; users can pass a v0.2 flag then.
- **Follow-up for v0.2**: add `source_module=` kwarg; deprecate warning when `source_module=` is passed; expand launch-mode coverage in TEST_PLAN.md.

## References

- Julia `isinteractive` / `Base.active_repl`: <https://docs.julialang.org/en/v1/base/base/#Base.isinteractive>
- DESIGN.md §4.3 (Main-namespace enumeration).
