# ADR-018 — Reduce v0.1 CI matrix to Ubuntu-only

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ADR-009 (test strategy — amended in part by this ADR), ADR-002 (UI stack), PLAN.md, TEST_PLAN.md

## Context

ADR-009 specified a 6-cell CI matrix (Julia {1.10, 1.12} × OS {Ubuntu, Windows, macOS}) with Layer-3 GUI smoke tests running under `xvfb-run` on Linux and on the "CI runner's display" on Windows and macOS, on the assumption that GitHub Actions runners for those two OSes provide a usable OpenGL context. That assumption is factually wrong.

First push of the CI workflow (Task 012, commit `c7a901e`, 2026-08-24) produced:

- **Ubuntu Julia 1.10, 1.12**: green (2/2 as designed).
- **Windows Julia 1.10, 1.12**: red. GLMakie precompilation aborts with `GLFWError (API_UNAVAILABLE): WGL: The driver does not appear to support OpenGL`.
- **macOS Julia 1.10, 1.12**: red. GLMakie precompilation aborts with `GLFWError (FORMAT_UNAVAILABLE): NSGL: Failed to find a suitable pixel format`.

The failure is identical in shape on both OSes: GLMakie's `PrecompileTools` workload opens a real GL window to warm caches during `using GLMakie`, and GitHub Actions Windows and macOS hosted runners are headless VMs with no accessible OpenGL driver. This is not test failure — the package cannot even load into memory. The failure is not caused by our code, our workflow YAML, our test suite, or any pinned version.

Two pieces of empirical evidence confirm the failure is CI-environment-specific, not code-specific:

1. **The identical test suite passes on John's Windows 11 development machine.** Tasks 004, 006, 008, and 010 — 7 tests, all green — ran the same GLMakie code on real Windows hardware with a real GPU. The bytes that fail on GitHub's Windows runner succeed on his.
2. **Upstream Makie itself CI-tests GLMakie only on Ubuntu with `xvfb-run`.** The workflow at `MakieOrg/Makie.jl/.github/workflows/glmakie.yaml` runs a single OS. If the upstream Makie authors do not attempt Windows or macOS CI for GLMakie, FigureViews as a downstream Gtk4Makie + GLMakie consumer cannot reasonably succeed where they have not.

Also relevant to the reasoning: our current test suite (7 tests as of commit `a062cc1`) is entirely ADR-009's **Layer 3** (GUI smoke). Every test calls `makieviews()`, which opens a Gtk4 window and initializes GLMakie. ADR-009's Layers 1 (pure-Julia unit) and 2 (headless-safe integration via CairoMakie) are not yet exercised because M1's code is entirely "make a window appear" — no pure logic to unit-test, no CairoMakie fallback path in the source. Layers 1 and 2 will exist as testable code starting at M2 (tree model, schema-driven property panel) and M8 (CairoMakie static export).

## Decision

For v0.1 (M1 through M11), the CI matrix is **2 cells: `ubuntu-latest × {Julia 1.10, Julia 1.12}`**.

Windows and macOS are removed from the CI matrix. They remain fully supported target platforms — FigureViews is expected to install and run on both — but that support is:

- **Developer-machine-verified** by the maintainer on both a Windows 11 machine and a macOS machine available for pre-release manual checks.
- **User-reported** via GitHub issues for edge cases not caught by the developer-machine checks.

**Pre-release verification protocol (enforced at M11):** before any tagged v0.1.x release, the maintainer runs the full test suite manually on macOS in addition to Windows. If macOS access is unavailable at release time, the release notes explicitly say `macOS build not verified for this release; please report issues.`

**Restoration path (deferred to v0.2):** once M2 introduces the tree model and M8 introduces CairoMakie static export, Layers 1 and 2 will exist as code that runs without any GL context. At that point the CI matrix will be restored to 6 cells running Layers 1, 2, and 4 on all cells, with Layer 3 (GUI smoke) remaining Ubuntu-only under `xvfb`. This is not v0.1 work — it is v0.2 M(N) work, to be scheduled after v0.1 ships.

## Alternatives Considered

- **Mesa-software-OpenGL install on Windows via `pdmourao/mesa-dist-win` or similar third-party action.** Rejected: adds ongoing maintenance risk on a third-party action; Mesa-on-Windows for CI is not standard upstream practice; would still leave macOS unaddressed; best-case net effect is 4/6 green, not 6/6.
- **Wrap Windows/macOS jobs with `continue-on-error: true`.** Rejected: workflow badge would show green while 4 of 6 jobs actually fail. Dishonest to downstream users glancing at the badge; also makes real future regressions harder to spot.
- **Refactor tests into Layers 1/2 (headless-safe) and Layer 3 (GUI) immediately, before M2.** Rejected: no Layer 1 or Layer 2 code exists to test yet — M1's only code is "make a window appear." Would mean writing artificial pure-Julia tests for CI-coverage theater rather than for regression value.
- **Accept 2/6 green without any documentation update.** Rejected: leaves PLAN.md's M1 exit criterion formally unmet and creates future-reader confusion about intent vs. reality.

## Consequences

- **Positive**: CI matrix reflects what we can actually verify. Green badges mean green. Matches upstream Makie precedent.
- **Positive**: Faster CI runs (2 cells vs. 6) and lower Actions minutes consumption.
- **Positive**: Removes a source of transient noise (macOS runner GUI-smoke flake previously acknowledged in TEST_PLAN.md §2's retry policy — now moot).
- **Negative**: Windows and macOS regressions may reach users before they are caught by the maintainer. Mitigation: pre-release manual QA (M11 protocol), user issue reports.
- **Negative**: `.github/workflows/ci.yml` becomes less informative about intended long-term platform coverage. Mitigation: workflow file's top comment names ADR-018 as the source of the reduction and cross-references ADR-009's original 6-cell intent, so future maintainers understand why.

## Amendment to ADR-009

ADR-009 §Decision, layer 3, contained the phrase *"On Linux, wrapped in `xvfb-run`. On Windows/macOS, runs against the CI runner's display (GitHub Actions provides one for both)."* The second sentence is factually wrong for OpenGL — GitHub Actions Windows/macOS runners have desktop sessions but no accessible GL context. That sentence is amended in ADR-009 to point here. ADR-009's four-layer test structure remains authoritative; only its assumption about non-Linux runner GL availability is replaced.

## References

- Failing CI run (evidence): https://github.com/XerxesZorgon/FigureViews/actions/runs/32780549703
- Upstream Makie GLMakie CI (Ubuntu-only precedent): https://github.com/MakieOrg/Makie.jl/blob/master/.github/workflows/glmakie.yaml
- GLMakie README, "headless server" caveat: https://github.com/JuliaPlots/GLMakie.jl
