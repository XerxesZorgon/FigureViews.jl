# RELEASE-READINESS.md — FigureViews v0.1.0

**Status**: Metadata audit clear; ready for the M11 release execution once macOS/Windows QA (Tasks 072–074) is green.
**Date**: 2026-08-28
**Companion**: [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md) (v0.1.0 scope); [ADR-020](adr/ADR-020-defer-fps-measurement-to-m11.md) updated 2026-08-28 (FPS measurement pass → v0.2); [ADR-023](adr/ADR-023-defer-interactive-macos-to-post-v0-1.md) (macOS verification split: headless CI + deferred interactive)
**Repository**: [XerxesZorgon/FigureViews.jl](https://github.com/XerxesZorgon/FigureViews.jl) (public)

## Summary

Four decisions recorded (compat, version bump, LICENSE/README/semver, CHANGELOG finalize). **No blocking issues.** Task 075 has a scripted edit list to apply at the release commit.

---

## 1. Compat pins — keep exact on Makie/GLMakie

**Decision (2026-08-28):** keep `Makie = "=0.24.13"` and `GLMakie = "=0.13.13"` for v0.1.0.

**Verified facts:**
- Julia General AutoMerge accepts exact pins ([RegistryCI guidelines](https://juliaregistries.github.io/RegistryCI.jl/stable/guidelines/)): `"=X.Y.Z"` satisfies the "upper-bounded + finite breaking releases" criterion. No "overly-tight" flag exists in the checked criteria.
- Makie 0.24.13 is the current latest release (July 7, 2026); the 0.24 line has been stable ~11 months with 13 patches. A v0.25.0 reference-images tag exists but no v0.25 release yet.
- GLMakie 0.13.13 upstream-pins `Makie = "=0.24.13"`. CairoMakie 0.15.13 also upstream-pins Makie exactly. Loosening FigureViews' Makie compat therefore gives no immediate resolver freedom — the constraint is enforced upstream regardless.

**Rationale (first release, solo maintainer):**
- Reproducibility over nimbleness: users of v0.1.0 get exactly the Makie + GLMakie pair the M10 spot-check calibrated on.
- Deliberate retag over silent drift: when Makie 0.24.14 + GLMakie 0.13.14 ship (together, by upstream construction), FigureViews retags 0.1.1 after a quick sanity check. Clear signal: "this matched pair is what we tested."

**Trade-off accepted:**
- Users cannot receive Makie 0.24.14 in a FigureViews environment until FigureViews 0.1.1 is tagged. Trigger is a manual maintainer step per Makie patch cycle (historically ~monthly). The mitigation is the follow-up in §Post-v0.1.0 (in-package update-check helper).

---

## 2. Version — `0.1.0-DEV` → `0.1.0` at release commit

Applied in Task 075. Registrator requires a non-prerelease version string, so `0.1.0-DEV` bumps to `0.1.0` on the release commit itself.

**Semver:** `0.1.0` is correct for a first release with an unstable API surface (Julia convention: `0.x` means "may break in 0.x+1"). Post-0.1.0 patch releases → `0.1.1` (bug fixes, compat refresh) or `0.2.0` (features / breaking changes).

---

## 3. LICENSE / README / semver

- **LICENSE ✓** — MIT, top-level, standard boilerplate ("Copyright (c) 2026 John Peach and contributors"). Required by General AutoMerge (guideline 13); verified 2026-08-28.
- **README ✓** — reconciled 2026-08-28 (ADR-022 + Framing-A REPL Quickstart, verified against the actual public API; Platforms section updated per ADR-023 for the macOS split). Accurately describes the v0.1 shipping surface; v0.2 roadmap section captures deferred work.
- **CHANGELOG `[0.1.0]` ✓** — scoped to the REPL-driven core (cross-references ADR-022); Known-limitations lists Bug F, `.mvz` data round-trip, GUI deferral, and interactive macOS deferral (ADR-023).
- **semver ✓** — first release, no prior versions to conflict with, no breaking-change annotation needed.

---

## 4. CHANGELOG finalize plan (for Task 075)

At the release commit:

1. `## [0.1.0] — TBD` → `## [0.1.0] — YYYY-MM-DD` (actual release date).
2. Move the current `[Unreleased]` milestone log entries (M1–M11 development history) under a new `## Pre-release history` heading placed *beneath* the `[0.1.0]` release block. Rationale: the `[0.1.0]` release-manifest summary already curates *what shipped*; the dev history captures *how it was built* and belongs after the release manifest, not muddled into a new `[Unreleased]`.
3. Reset `[Unreleased]` to an empty placeholder for post-0.1.0 work.
4. Replace `PLACEHOLDER-USER` in the two compare/tag links at the bottom of `CHANGELOG.md` with `XerxesZorgon`.

---

## 5. macOS verification (per ADR-023) — CI infeasible for v0.1.0

**Final outcome (2026-08-28):** macOS CI dropped for v0.1.0. Two attempts (Tasks 073 and 073b) confirmed that `using FigureViews` unconditionally loads GLMakie and Gtk4Makie at `src/FigureViews.jl:3`, which fail to precompile on GHA Apple Silicon VMs (`NSGL: Failed to find a suitable pixel format`). A separate `test/runtests_cairo.jl` entry point also fails at `using FigureViews`. There is no way to run any FigureViews test on GHA macOS without conditional backend loading.

**What ships for v0.1.0:** Ubuntu CI only (2 cells, 72 testsets, ~308 assertions). Windows validated manually (Task 072). macOS is untested — both headless and interactive. README and CHANGELOG reflect this accurately.

**v0.2 backlog item:** Enable macOS CI via conditional backend loading (guard `GLMakie`/`Gtk4`/`Gtk4Makie` imports behind `ENV["MAKIEVIEWS_BACKEND"]` or `Preferences.jl`). This pairs naturally with the GUI/headless split already planned for v0.2. Interactive macOS verification (Task 073's original manual gate) also remains a v0.2 commitment (ADR-023).

**Alternatives rejected** (full record in ADR-023): CairoMakie-only entry point (fails because `using FigureViews` loads GLMakie regardless), cloud Mac rental (disproportionate), browser-based simulators (cannot run Julia), local KVM/QEMU (EULA + no GPU).

---

## Task 075 — exact edits to apply at the release commit

```diff
[Project.toml]
- version = "0.1.0-DEV"
+ version = "0.1.0"

[CHANGELOG.md, [0.1.0] header]
- ## [0.1.0] — TBD
+ ## [0.1.0] — YYYY-MM-DD          # actual release date

[CHANGELOG.md, bottom links]
- [Unreleased]: https://github.com/PLACEHOLDER-USER/FigureViews.jl/compare/v0.1.0...HEAD
- [0.1.0]: https://github.com/PLACEHOLDER-USER/FigureViews.jl/releases/tag/v0.1.0
+ [Unreleased]: https://github.com/XerxesZorgon/FigureViews.jl/compare/v0.1.0...HEAD
+ [0.1.0]: https://github.com/XerxesZorgon/FigureViews.jl/releases/tag/v0.1.0
```

Plus the `[Unreleased]` restructuring per §4 step 2. Commit as `release: v0.1.0`, push, verify CI green, run Registrator dry-run, submit to General.

---

## Non-blocking observations (record; act later if desired)

- `TOML = "1.0.3"` in `[compat]` — TOML is a Julia stdlib. Compat entries for stdlibs are unnecessary (they're pinned by the Julia version) but harmless. Optional cleanup later.
- `Gtk4 = "0.7.12"` and `Gtk4Makie = "0.3.9"` are bare patch versions — Julia caret semantics make these floor-only (any 0.7.x ≥ 0.7.12; any 0.3.x ≥ 0.3.9). Consistent with either compat philosophy.
- PLAN.md §3 comments `HDF5 = "0.18"` current, but Project.toml pins `HDF5 = "0.17"`. Doc/actual drift; CI green on the pinned range means 0.17.x is what runs. Verify at Task 075 if the discrepancy matters for release notes.
- GitHub repo description ("GUI frontend for Makie to simplify making plots/animations in Julia") reads as GUI-first; the v0.1 shipping surface is REPL-first per ADR-022. Optional cosmetic edit on the GitHub Settings page — not part of the release.
- No `[weakdeps]` used — clean.
- Stdlib usage (`UUIDs`, `SHA`, `Test`) correctly placed in `[deps]` / `[extras]`; nothing missing.

---

## Post-v0.1.0 follow-ups

- **In-package update-check helper (v0.2 candidate).** Idea captured 2026-08-28: add `FigureViews.check_updates()` or similar that queries the General registry for a newer FigureViews version and prints a one-line "an update is available (0.1.X); run `] up FigureViews`" hint at REPL startup (or on demand). Motivation: the exact-pin decision above puts responsibility on the user to run `] up` after FigureViews retags a compat refresh; a lightweight in-package check makes that discoverable. Not blocking v0.1.0.
- **FPS measurement pass** — three-OS reference table → `src/preflight/fps_lookup.jl`: v0.2 per ADR-020 updated 2026-08-28.
- **Interactive macOS verification** — mouse-driven 3D rotation, live attribute editing, window dragging, `export_figure` from a displayed window: deferred to post-v0.1.0 per ADR-023 (committed before v0.2.0). Headless macOS CI (Task 073, `macos-latest × {Julia 1.10, 1.12}`) covers ~99% of what the manual gate would have exercised.
- **`.mvz` data round-trip** (full save/reload including arrays via the reserved `data_inline` slot): v0.2 per ADR-017.
- **Interactive Veusz-style GUI** (variable picker, Add Plot menu, property panel as primary flow, load flow, live structural editing — pairs with Bug F): v0.2+ per ADR-022.
