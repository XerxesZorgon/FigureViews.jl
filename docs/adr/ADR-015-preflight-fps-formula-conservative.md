# ADR-015 — Pre-flight FPS estimate: measurement-driven lookup with conservative bias

**Status**: Accepted (formula pending M10 measurement pass)
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ODQ-5 (closed by this ADR), SDD FR-023..026, DESIGN.md §7, ADR-010

## Context

The pre-flight dataset check estimates whether an incoming dataset can render at ≥15 fps sustained over 2 s (SDD FR-024). It needs a formula:

```
estimated_fps = f(n_points, plot_type, gpu_class, driver_hint, plot_type_cost)
```

No first-principles closed form exists; scatter plots are not proportional to line plots are not proportional to volume rendering, and driver stacks (Metal / DirectX / OpenGL on Linux + Wayland or X11 + NVIDIA or Mesa) each have their own performance shape.

Two design principles apply:

1. **Conservative bias**. False positive ("this will be slow" when it wouldn't have been) costs the user one dialog click. False negative ("this will be fast" when it freezes for 90 seconds) costs the user trust. Bias the estimate toward *predicting slow*.
2. **Measurement-driven, not first-principles**. Publish a lookup table.

## Decision

- v0.1 M10 executes a **measurement pass** on three reference machines (one per OS) covering the seven v0.1 plot types × a grid of point counts (`10³, 10⁴, 10⁵, 10⁶, 10⁷, 10⁸`). The result is a lookup `fps_ref[plot_type][log10_n_points]`.
- The lookup lives in `src/preflight/fps_lookup.jl` as a `const` `Dict` and is versioned with the package.
- Per-user scaling factor: `user_scale = clamp( user_gpu_score / reference_gpu_score, 0.1, 10.0 )` where `gpu_score` derives from detected VRAM and, if available, a driver-family label. If undetectable, `user_scale = 0.5` (**conservative bias**: assume half the reference GPU's speed).
- `estimated_fps = fps_ref[plot_type][ceil(log10(n_points))] * user_scale`.
- Warning threshold: `estimated_fps < 15` OR `estimated_bytes > 0.6 * detected_vram_bytes` (SDD FR-024). If VRAM is undetectable, only the fps criterion applies (SDD FR-026).
- On M10 completion, DESIGN.md §7.2 is updated with the specific formula and constants. Until M10 ships, MakieViews falls back to a coarser heuristic (`estimated_fps = 60 / (n_points / 1e6)^0.5` for 2-D plot types; halve for 3-D) with the same conservative-bias scaling.

## Alternatives Considered

- **First-principles model (bytes / bandwidth)**: fails because rendering cost is dominated by GL pipeline factors that don't map cleanly to bytes. Rejected.
- **Online learning from the user's own runs**: appealing but v0.2+ scope; requires telemetry, storage, and a UX story around "why did this get slower?" Deferred.
- **No estimate, only bytes**: fps-based warnings catch the actual problem users hit (jittery frame rate) — bytes-only would over-warn on cheap 100M-point heatmaps and under-warn on 1M-point volume renders. Rejected.

## Consequences

- **Positive**: the estimate is grounded in measurements on real hardware, not guessed at.
- **Positive**: conservative bias means the first-impression failure mode is "the app was cautious," not "the app hung."
- **Negative**: the lookup ages — driver updates and new GPU generations shift the reference. `fps_lookup.jl` needs a refresh policy; v0.2 CHANGELOG entry noted.
- **Negative — bootstrapping**: v0.1's fallback heuristic (used until M10 measurement lands) is a rough approximation. Users on the pre-M10 builds may see occasional wrong warnings. Documented in CHANGELOG for the pre-release period.

## References

- DESIGN.md §7 (state machine and detection).
- ADR-010 (downsampling algorithms — the offered remedies when the warning fires).
