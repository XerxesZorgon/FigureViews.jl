# ADR-003 — CairoMakie for PNG/SVG/PDF static export

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ADR-002 (UI stack), DESIGN.md §5

## Context

Users export figures for papers, slides, and reports. Two paths exist inside Makie:

1. **Rasterize from GLMakie**: capture the GL framebuffer to PNG.
2. **Render again via CairoMakie**: run Makie's Cairo backend on the same figure and export PNG/SVG/PDF.

Vector formats (SVG, PDF) are non-negotiable for scientific publication. GLMakie's framebuffer is inherently raster; a vector export via GL would be a project of its own.

## Decision

Use **CairoMakie 0.15.x** for PNG, SVG, and PDF export. Interactive viewport stays on GLMakie (ADR-002). The two backends operate on the same underlying `Figure` object.

## Alternatives Considered

- **Rasterize from GLMakie only**: no SVG/PDF path; unacceptable for scientific export. Rejected.
- **Third-party post-processing** (e.g., convert PNG→PDF externally): degrades vector quality; adds a system dependency. Rejected.

## Consequences

- **Positive**: publication-quality vector export using Makie's own Cairo backend. Same `Figure` used for both interactive and static output — no duplicate figure state.
- **Negative**: CairoMakie must be a direct dependency, adding to install footprint and precompile time.
- **Negative**: some Makie plot primitives render differently under Cairo than under GL (documented Makie behavior; the two backends are close but not pixel-identical). Golden-image tests (TEST_PLAN.md §4) are anchored on CairoMakie output, since that is what the user takes away.

## References

- CairoMakie 0.15.13 `Project.toml`: pins `Makie = "=0.24.13"` — the version lock is intentional upstream.
