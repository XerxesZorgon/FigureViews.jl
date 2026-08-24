# ADR-009 — Test strategy for a Gtk4 + GLMakie Julia app

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: TEST_PLAN.md (concrete matrix and jobs), ADR-002 (UI stack)

## Context

Two testing challenges are specific to this stack:

1. **Gtk4 on headless CI**: Gtk4 needs a display server. Standard GitHub-Actions Linux runners are headless.
2. **GLMakie in CI**: GLMakie needs an OpenGL context. Software rasterizers (Mesa's `llvmpipe`) work but are slow and can produce output that differs from real GPUs.

Prior art:
- **Gtk4.jl's own CI** uses `xvfb-run` on Linux to provide a virtual X display and runs its test suite there. It relies on the `x11-utils` and Xvfb packages installed via `apt`. Windows and macOS CI in the JuliaGtk org runs against the platform display without a virtual framebuffer.
- **Gtk4Makie.jl** inherits the same pattern; its CI is thin and largely delegates to smoke tests.
- **Makie.jl's own CI** for GLMakie uses `xvfb-run` on Linux and known-good driver setups. Reference-image tests are anchored on CairoMakie output, not GLMakie output, because GL rendering varies by driver.

## Decision

Four test layers, gated in CI on all three OSes:

1. **Unit tests** — pure-Julia logic (tree operations, schema derivation, TOML round-trip): no display required. Runs everywhere including headless without Xvfb.
2. **Integration tests (headless-safe)** — build a `Figure` programmatically via MakieViews' internal API, exercise the tree/property/data-snapshot code paths, export via CairoMakie. **No Gtk4 window is opened.** Runs everywhere.
3. **GUI smoke tests** — open a Gtk4 window, close it. On Linux, wrapped in `xvfb-run`. On Windows/macOS, runs against the CI runner's display (GitHub Actions provides one for both). Purpose: catch "the window doesn't open" regressions.
4. **Golden-image tests** — anchored on **CairoMakie** static export (not GLMakie framebuffer capture) because driver variation makes GL output unstable across runners. See TEST_PLAN.md §4.

Julia × OS matrix: Julia 1.10 (LTS) × Julia 1.12 (stable) × {Windows, macOS, Linux}. Six cells. `xvfb-run` wraps the Linux cells for layers 3 and 4.

## Alternatives Considered

- **GL framebuffer golden images**: rejected — driver-dependent output makes tests flaky. CairoMakie anchoring is upstream-standard.
- **All tests headless-safe (skip Gtk4)**: cheaper CI, but "the window doesn't open" would ship. Rejected — the smoke layer earns its keep.
- **Third-party GUI automation** (Xvfb + xdotool or SikuliX): overkill for v0.1; smoke tests are enough. Deferred.

## Consequences

- **Positive**: catches regressions at four distinct levels with appropriate cost per layer.
- **Positive**: CairoMakie anchoring aligns with upstream Makie's own visual-regression discipline.
- **Negative**: CI matrix is six cells; runtime cost is manageable but not free.
- **Negative**: GUI smoke tests on macOS runners can be flaky (documented Apple CI behavior). TEST_PLAN.md includes a retry policy for that specific cell.

## References

- Makie visual-regression discipline: <https://docs.makie.org/dev/changelog>
- xvfb-run pattern in Julia CI: standard across JuliaGtk and MakieOrg repositories.
