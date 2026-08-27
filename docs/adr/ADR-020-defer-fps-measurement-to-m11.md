# ADR-020 — Defer the FPS measurement pass to M11; ship the coarse fallback for v0.1

**Status**: Accepted (2026-08-27).
**Date**: 2026-08-27
**Deciders**: John Peach
**Related**: [ADR-015](ADR-015-preflight-fps-formula-conservative.md) (refines its timing), [ADR-010](ADR-010-downsampling-algorithms.md), [ADR-018](ADR-018-ci-matrix-reduction-ubuntu-only.md), DESIGN.md §7, ODQ-5

## Context

ADR-015 specified the pre-flight FPS estimate as a measurement-driven lookup table (`fps_ref`), to be populated **during M10** by a measurement pass on three reference machines (one per OS) across the seven v0.1 plot types and point counts 10³..10⁸, with a coarse fallback formula holding "until M10 lands the measured table."

At M10 kickoff that measurement pass proved impossible to run inside the project's execution model:

- CI is Ubuntu-only and headless (ADR-018); it cannot load GLMakie (no OpenGL context), so it cannot measure real frame rates.
- The one-task-at-a-time Antigravity loop has no GL-capable, multi-OS hardware.
- macOS is not available until the M11 pre-release QA pass — its live-test is already a hard gate there (ADR-018 / PLAN M11).

Measuring on only the available Windows box would yield a single-OS table that *looks* authoritative while covering one GPU of three — arguably worse than a clearly-labelled formula, because it invites false confidence.

## Decision

**Ship the coarse fallback formula for v0.1; defer the full measurement pass to the M11 pre-release QA sweep** (which already forces a human onto all three OSes). ODQ-5 is **resolved-with-fallback**.

Concrete v0.1 pre-flight parameters (previously only sketched in ADR-015 / §7.2):

```
estimated_fps (2D) = 60 / sqrt(n_points / 1e6)
estimated_fps (3D) = 30 / sqrt(n_points / 1e6)      # 3D plot types = :surface, :volume
estimated_fps      = base_fps * user_scale
user_scale         = clamp(vram_bytes / REFERENCE_VRAM_BYTES, 0.1, 10.0)
                     # user_scale = 0.5 when VRAM is undetectable (conservative, FR-026)
REFERENCE_VRAM_BYTES = 8 * 1024^3                    # provisional mid-range 2020-class GPU
```

- **Threshold**: warn when `est_fps < 15` OR `est_bytes > 0.6 * vram_bytes`. When VRAM is undetectable, only the fps term applies (FR-026).
- **Decision surface**: the headless `preflight_decision` returns `:accept` (under threshold — load full, no dialog) or `:warn` (over threshold). The `:warn` case raises the Gtk4 dialog, which resolves the user's Accept / Downsample / Override; that dialog is manual-gated (verified at launch, not CI).
- **`REFERENCE_VRAM_BYTES = 8 GiB` is provisional**: typical 2020-class laptop dGPUs (4–6 GB) score just under 1.0 (mildly conservative); modern desktop cards (12–24 GB) score above. The measurement pass later replaces the `base_fps` term with `fps_ref[plot_type][ceil(log10(n_points))]` and sets a real reference.

**Guard before the v0.1 tag**: a manual spot-check on the Windows reference box takes 2–3 real loads at the heaviest combos (surface and volume at ~1e6 and ~1e7 points) and confirms the fallback predicts *lower* fps than observed — i.e. it errs toward over-warning, never under-warning. This de-risks the only dangerous failure direction without building the full table.

This **refines ADR-015**: its formula and conservative-bias rationale stand unchanged; only the *timing* of the measured table moves from M10 to M11.

## Consequences

- v0.1 pre-flight warnings are calibrated by formula, not measurement — occasionally imprecise, but biased toward the safe direction (over-warn = one dialog click; the app never silently freezes on a case the formula flagged).
- The measurement pass folds into the M11 QA sweep at no extra hardware cost (M11 already touches Windows + macOS + Linux).
- `src/preflight/fps_lookup.jl` is **not** created in v0.1; the fallback lives in `src/preflight/estimate.jl`.
- `REFERENCE_VRAM_BYTES` is a documented provisional constant; changing it later touches no file format or public API.

## Alternatives Considered

- **(a) Full measurement pass in M10** — rejected: cannot run headless / multi-OS in this loop; a Windows-only table would be misleadingly partial and would block M10 on manual, un-automatable work.
- **(b) Fallback with no guard** — rejected: the formula is unvalidated, and an optimistic error on a heavy 3D case (the freeze-the-GUI failure) is exactly what the feature exists to prevent. The spot-check closes that gap cheaply.
- **(c) Drop the pre-flight check for v0.1** — rejected: SDD FR-024/FR-026 require it; the freeze-on-huge-dataset first impression is the specific harm v0.1 must avoid.
