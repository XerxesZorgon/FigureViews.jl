# ADR-023 — Defer interactive macOS verification to post-v0.1.0; add headless macOS CI runner

**Status**: Accepted (2026-08-28).
**Date**: 2026-08-28
**Deciders**: John Peach
**Related**: [ADR-018](ADR-018-ci-matrix-reduction-ubuntu-only.md) (refines: amends the CI matrix and keeps the Windows manual gate; splits the macOS gate into headless-CI + deferred-interactive), [ADR-022](ADR-022-v0-1-ships-repl-driven.md) (v0.1.0 scope), PLAN.md M11, tasks.md Task 073.

## Context

ADR-018 established Ubuntu-only CI (Julia 1.10 + 1.12) with Windows and macOS manual verification before release, naming the macOS live-test the hard gate before tagging v0.1.0. That was correct at project start when multi-OS CI setup felt heavy.

By the M11 pre-release audit (2026-08-28), two things are true that weren't at M0:

1. No Mac hardware is available to John; the manual live-test as originally specified can't be performed on v0.1.0's timeline.
2. A GitHub Actions macos-latest runner is a ~30-line workflow addition — no longer a scope decision, just a task. GHA provides real macOS on Apple Silicon (M-series), free for public repos.

A skeptic's counter deserves an honest answer: Windows + Linux CI catches most bugs, but a class of macOS-only failure surfaces exists in this stack that neither covers:

- **GLMakie on macOS** uses Apple's OpenGL compatibility layer (Apple deprecated OpenGL in 2018). GLMakie's issue tracker has macOS-specific tickets that don't reproduce on Linux/Windows.
- **Gtk4Makie's macOS embedding** — the shared-figure architecture (GLMakie window embedded in a Gtk4 container, DESIGN §1) is exactly the kind of thing that breaks under macOS' window-server model. Gtk4Makie's README says it works on macOS but not that it works in a headless CI environment.
- **File paths** — FigureViews is developed on Windows and CI is Linux; APFS case-sensitivity and macOS-specific path handling are unreached.
- **Metal-based VRAM detection** in `detect_host_specs` on macOS is unreached by both the Windows dev box and Ubuntu CI.

## Decision

**Split the macOS verification into two parts:**

1. **Headless test suite on GHA macos-latest**: add a new CI job (Task 073, replacing the original manual Task 073) that runs the full `Pkg.test()` suite on `macos-latest × {Julia 1.10, 1.12}`. This exercises package load, all seven plot types, GLMakie rendering via macOS OpenGL compat, CairoMakie export, session persistence, downsampling, preferences, and `add_plot_checked!`. It gates every release the same way the Ubuntu CI does.

2. **Interactive/live-launch verification is deferred** to post-v0.1.0, no fixed version tag. The manual gate as originally specified in ADR-018 (open `makieviews()`, rotate 3D axis, edit an attribute live, export from a displayed window) requires a real Mac and a human at the keyboard — neither available on v0.1.0's timeline. Committed before v0.2.0, because the Veusz-style GUI work already needs macOS validation.

ADR-018's Ubuntu-only CI matrix is amended: the matrix becomes `{ubuntu-latest, macos-latest} × {Julia 1.10, 1.12}` (four cells). If the GHA macos-latest job cannot initialize the Gtk4/GLMakie stack in a headless runner (unproven pattern for FigureViews specifically), the fallback is a narrower macOS job that skips Layer 3 GUI smoke tests but keeps Layers 1, 2, and 4 (unit / integration / golden-image export). ADR-023 will be updated with the actual outcome once Task 073 completes.

> **Update 2026-08-28 — Task 073b outcome (CairoMakie-only entry point attempt).** `using FigureViews` unconditionally loads `GLMakie` and `Gtk4Makie` at `src/FigureViews.jl:3`. Even a separate `test/runtests_cairo.jl` that includes only pure-data testsets fails immediately at `using FigureViews` with the same `NSGL: Failed to find a suitable pixel format` error. There is no way to load FigureViews on a headless macOS GHA runner without architectural changes.
>
> **Final outcome — macOS CI dropped for v0.1.0 (Option 2).** The CI matrix reverts to Ubuntu-only (2 cells). macOS CI requires conditional backend loading (guard `GLMakie`/`Gtk4`/`Gtk4Makie` imports behind `ENV["MAKIEVIEWS_BACKEND"]` or `Preferences.jl`) — this is a v0.2 backlog item, pairing naturally with the GUI/headless split that v0.2 needs anyway. `test/runtests_cairo.jl` is removed (it cannot run without `using FigureViews`). `ci.yml` reverts to the 2-cell Ubuntu-only matrix with the xvfb-run step restored.
>
> **What this means for v0.1.0:** Ubuntu CI (2 cells, 72 testsets, ~308 assertions) is the only automated test coverage. Windows is validated manually (Task 072). macOS is untested for v0.1.0 — both headless and interactive. README and CHANGELOG reflect this accurately.

## Consequences

- **v0.1.0 has no macOS CI coverage** (see Updates 2026-08-28 above). Ubuntu CI (2 cells, 72 testsets) remains the automated gate. macOS is untested for v0.1.0 — both headless and interactive. Enabling macOS CI requires conditional backend loading (v0.2 backlog).
- **v0.1.0 acknowledges what it does not cover**: rotating a 3D axis by mouse, live attribute edits, window dragging — not verified on macOS for v0.1.0. README and CHANGELOG note this explicitly.
- **Risk accepted**: a Mac user's first live/interactive session may hit an issue the headless suite didn't catch (probably minor: cursor handling, focus, HiDPI scaling, menu-bar quirks). Mitigation: release notes suggest reporting issues; the interactive verification pass before v0.2.0 catches the accumulated set.
- **Latency**: CI runs go from ~10 min (Ubuntu ×2) to ~25 min (+ macOS ×2). macOS runners boot slower but tests run in similar wall-clock time.
- **Cost**: free for public repos within GHA limits. XerxesZorgon/FigureViews.jl is public.
- **This refines but does not overturn ADR-018.** The Ubuntu-only decision was correct for M0–M10; adding macOS to CI reduces what must be manual. The Windows manual gate (Task 072) remains.

## Alternatives Considered

- **(a) Defer macOS entirely** (initially proposed 2026-08-28) — rejected once GHA macos-latest was weighed as a real option: leaving Mac users to discover bugs post-release is a worse trade than adding a ~30-line workflow that catches them in CI.
- **(b) Add GHA runner only, defer nothing** — rejected: the interactive/live-launch gate needs a human at a Mac; no tooling replaces that.
- **(c) Cloud Mac rental (MacStadium, AWS EC2 mac1/2)** — rejected for v0.1.0: paid, additional complexity, one-time gate not worth the operational overhead. Reconsidered for v0.2.0 if ongoing Mac verification becomes recurring.
- **(d) macos-web.app or browser-based "macOS simulators"** — rejected: JavaScript UI recreations, not real emulators. Cannot run Julia; cannot initialize OpenGL. Would test nothing.
- **(e) Local KVM/QEMU macOS emulation** — rejected: violates Apple's EULA, no GPU passthrough means LLVMpipe software rendering (unusably slow for GLMakie), operationally fragile.
