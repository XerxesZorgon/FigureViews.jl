# RELEASE-READINESS.md — MakieViews v0.1.0

**Status**: Metadata audit clear; ready for the M11 release execution once macOS/Windows QA (Tasks 072–074) is green.
**Date**: 2026-08-28
**Companion**: [ADR-022](adr/ADR-022-v0-1-ships-repl-driven.md) (v0.1.0 scope); [ADR-020](adr/ADR-020-defer-fps-measurement-to-m11.md) updated 2026-08-28 (FPS measurement pass → v0.2); [ADR-023](adr/ADR-023-defer-interactive-macos-to-post-v0-1.md) (macOS verification split: headless CI + deferred interactive)
**Repository**: [XerxesZorgon/MakieViews.jl](https://github.com/XerxesZorgon/MakieViews.jl) (public)

## Summary

Four decisions recorded (compat, version bump, LICENSE/README/semver, CHANGELOG finalize). **No blocking issues.** Task 075 has a scripted edit list to apply at the release commit.

---

## 1. Compat pins — keep exact on Makie/GLMakie

**Decision (2026-08-28):** keep `Makie = "=0.24.13"` and `GLMakie = "=0.13.13"` for v0.1.0.

**Verified facts:**
- Julia General AutoMerge accepts exact pins ([RegistryCI guidelines](https://juliaregistries.github.io/RegistryCI.jl/stable/guidelines/)): `"=X.Y.Z"` satisfies the "upper-bounded + finite breaking releases" criterion. No "overly-tight" flag exists in the checked criteria.
- Makie 0.24.13 is the current latest release (July 7, 2026); the 0.24 line has been stable ~11 months with 13 patches. A v0.25.0 reference-images tag exists but no v0.25 release yet.
- GLMakie 0.13.13 upstream-pins `Makie = "=0.24.13"`. CairoMakie 0.15.13 also upstream-pins Makie exactly. Loosening MakieViews' Makie compat therefore gives no immediate resolver freedom — the constraint is enforced upstream regardless.

**Rationale (first release, solo maintainer):**
- Reproducibility over nimbleness: users of v0.1.0 get exactly the Makie + GLMakie pair the M10 spot-check calibrated on.
- Deliberate retag over silent drift: when Makie 0.24.14 + GLMakie 0.13.14 ship (together, by upstream construction), MakieViews retags 0.1.1 after a quick sanity check. Clear signal: "this matched pair is what we tested."

**Trade-off accepted:**
- Users cannot receive Makie 0.24.14 in a MakieViews environment until MakieViews 0.1.1 is tagged. Trigger is a manual maintainer step per Makie patch cycle (historically ~monthly). The mitigation is the follow-up in §Post-v0.1.0 (in-package update-check helper).

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

## 5. macOS verification (per ADR-023)

**Decision (2026-08-28):** split macOS verification into two parts.

**Part A — Headless CI on GHA `macos-latest`:** new job added via Task 073, running the full `Pkg.test()` suite on `macos-latest × {Julia 1.10, 1.12}` (real macOS on Apple Silicon). Exercises ~99% of the test coverage the original ADR-018 manual gate would have hit: all seven plot types, GLMakie rendering via macOS OpenGL compat layer, CairoMakie export, session persistence, downsampling, preferences, and `add_plot_checked!`. Gates every release the same way Ubuntu CI does.

**Part B — Interactive/live-launch verification deferred to post-v0.1.0** (no fixed version tag; committed before v0.2.0). Mouse-driven 3D rotation, live attribute edits, window dragging, and `export_figure` from a displayed (rather than headless) window need a human at a Mac; no CI substitutes for that.

**Verified facts:**
- GLMakie's own docs state "GLMakie's CI has no GPU" and point to a working GHA workflow — GHA runners can initialize GLMakie without dedicated hardware via Apple's OpenGL compatibility layer.
- Gtk4Makie's README states it runs on Windows, macOS, and Linux. Its behavior in a headless macOS CI environment specifically is unproven for MakieViews — the fallback per ADR-023 kicks in if init fails.
- `macos-latest` GHA runners are free for public repos within reasonable limits; XerxesZorgon/MakieViews.jl is public.

**Rationale:** no Mac hardware currently available to John; GHA macos-latest is a ~30-line addition that meaningfully de-risks the release for Mac users. The residual risk (cursor/focus/HiDPI/menu-bar behaviors visible only to a live user) is acknowledged rather than papered over.

**Fallback plan:** if the headless macOS runner can't initialize the Gtk4/GLMakie stack, Task 073 falls back to a narrower macOS job that runs Layers 1, 2, and 4 but skips Layer 3 GUI smoke (per ADR-023). ADR-023 will be updated with the actual outcome once Task 073 completes.

**Amends ADR-018:** CI matrix goes from Ubuntu-only (2 cells) to `{ubuntu-latest, macos-latest} × {Julia 1.10, 1.12}` (4 cells). Windows manual gate (Task 072) remains.

**Alternatives rejected** (full list in ADR-023): defer macOS entirely (leaves Mac users as beta testers), cloud Mac rental for the interactive test (paid, disproportionate), browser-based macOS "simulators" like macos-web.app (JavaScript UI recreations, cannot run Julia), local KVM/QEMU emulation (EULA violation, no GPU passthrough).

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
- [Unreleased]: https://github.com/PLACEHOLDER-USER/MakieViews.jl/compare/v0.1.0...HEAD
- [0.1.0]: https://github.com/PLACEHOLDER-USER/MakieViews.jl/releases/tag/v0.1.0
+ [Unreleased]: https://github.com/XerxesZorgon/MakieViews.jl/compare/v0.1.0...HEAD
+ [0.1.0]: https://github.com/XerxesZorgon/MakieViews.jl/releases/tag/v0.1.0
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

- **In-package update-check helper (v0.2 candidate).** Idea captured 2026-08-28: add `MakieViews.check_updates()` or similar that queries the General registry for a newer MakieViews version and prints a one-line "an update is available (0.1.X); run `] up MakieViews`" hint at REPL startup (or on demand). Motivation: the exact-pin decision above puts responsibility on the user to run `] up` after MakieViews retags a compat refresh; a lightweight in-package check makes that discoverable. Not blocking v0.1.0.
- **FPS measurement pass** — three-OS reference table → `src/preflight/fps_lookup.jl`: v0.2 per ADR-020 updated 2026-08-28.
- **Interactive macOS verification** — mouse-driven 3D rotation, live attribute editing, window dragging, `export_figure` from a displayed window: deferred to post-v0.1.0 per ADR-023 (committed before v0.2.0). Headless macOS CI (Task 073, `macos-latest × {Julia 1.10, 1.12}`) covers ~99% of what the manual gate would have exercised.
- **`.mvz` data round-trip** (full save/reload including arrays via the reserved `data_inline` slot): v0.2 per ADR-017.
- **Interactive Veusz-style GUI** (variable picker, Add Plot menu, property panel as primary flow, load flow, live structural editing — pairs with Bug F): v0.2+ per ADR-022.
