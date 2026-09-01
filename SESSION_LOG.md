# Session Log
**Updated:** 2026-08-31
**Active skill:** software-project (v0.2 execution — M14 Phase 1 complete + confirmed, entering Phase 2)
**Last confirmed state:** M14 Task 093 green and pushed (commit 680869f). Phase 1 CONFIRMED (full local suite green, CI run #68 green on Ubuntu 1.10+1.12, GUI launches clean). Ready to start Task 094.

## What happened this session
Renamed the package MakieViews → FigureViews (a registry reviewer flagged the old name as implying a link to the Makie project), closed the registry submission, and made all the reviewer's requested fixes — the package is deliberately not being re-registered until it's closer to done, so it stays off the public package index for now. Ran a science-council review of a big design question ("should the tool ever limit what Makie can draw?") which, backed by a measurement test, chose a new "generic node" design (written up as ADR-026): every plot is stored as plain data the tool doesn't have to hand-code per type. Built and confirmed Phase 1 of that design — the 7 existing plot types now use the generic model and survive a full save/reload with their data types intact.

## Decisions made (not yet in an ADR)
None. The load-bearing decision (the generic-node model, Option D) is fully recorded in ADR-026, with the phased build order and non-goals. The M14 re-scope is in tasks.md.

## Blocked on / open question
None. Phase 1 confirmed on all three checks (local tests, CI, manual GUI launch). No open questions.

## Next action
Start **Task 094 — the registry generator** (M14 Phase 2, the "dictionary" step). The task block is already written in tasks.md under Milestone M14. It promotes the introspection logic from the throwaway spike `spike/m14d_serializable_fraction.jl` into a committed generator (`tools/gen_registry.jl`) that asks Makie itself for each plot type's attributes and argument shapes, and emits registry entries as data for a broad list of plot types — validating its output for the 7 known types against the hand-written reference entries from Task 092. Types that can't be cleanly introspected (e.g. `arrows`, which the spike found is broken in Makie 0.24) get flagged `:needs_manual_review` rather than skipped or guessed.

To resume: say "resume FigureViews" and Claude will re-read this log, the antigravity skill, and ADR-026, then generate the Task 094 Antigravity instruction. Expect Task 094 to need a few iterations — Makie's introspection is fiddly, and that's normal, not failure.

## Recent commit trail (for reference)
- 083fe62 — Task 092 (generic node + registry structs, 7 types refactored)
- 680869f — Task 093 (generic-node .mvz round-trip, type fidelity + preserve-on-load)
- M13 chain: 1888c97, 5850d4b, 0fd156e, 1fcb3df, cd1aaae, b063b56
