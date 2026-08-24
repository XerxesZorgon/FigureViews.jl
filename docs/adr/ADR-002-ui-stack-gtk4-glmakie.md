# ADR-002 — Gtk4.jl + Gtk4Makie.jl desktop shell, GLMakie viewport

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ADR-003 (static export), ADR-009 (test strategy), DESIGN.md §1

## Context

MakieViews needs:
- A native desktop shell — window, menus, docked panels (tree, properties), file dialogs.
- An embedded viewport that runs Makie's interactive backend, keeping full 3D and animation.
- Reasonable cross-platform coverage: Windows, macOS, Linux.

The Julia GUI ecosystem is thin. The realistic candidates in August 2026:

| Option | Shell | Viewport | Assessment |
|---|---|---|---|
| **Gtk4.jl + Gtk4Makie.jl + GLMakie** | Gtk4 | GLMakie via Gtk4Makie glue | Only combination with a first-class, actively used embed of GLMakie into a native shell; docs state Windows/macOS/Linux support |
| QML.jl + Makie | QML/Qt | via Qt widget | QML.jl 2026 maintenance status not independently verified; risk of stalled binding |
| Bonito + WGLMakie | Browser (Bonito web UI) | WGLMakie in a browser tab | WGLMakie weaker on 3D and animation; "opens in browser" wrong feel for a desktop app |
| Pure Makie widgets | Makie's own layout | GLMakie | No tree, no docking, no file dialogs — reinvent shell primitives |
| Electron / Blink.jl | Chromium | WGLMakie | Chromium overhead unjustified for the target audience |
| CImGui.jl + ImGuiMakieBackend.jl | Dear ImGui | ImGuiMakieBackend | Developer-tool aesthetic wrong for scientists; `ImGuiMakieBackend.jl` has low activity |

## Decision

- **Shell**: `Gtk4.jl` v0.7.x — the current active Gtk4 binding under JuliaGtk.
- **Embed glue**: `Gtk4Makie.jl` v0.3.x — the only supported embed of GLMakie into Gtk4.
- **Interactive viewport backend**: **GLMakie**.
- Static export lives on a different backend (see ADR-003).

## Alternatives Considered

Enumerated in the table above. Rejected reasons in short:

- **QML.jl**: 2026 maintenance signal not verified — going with an actively developed binding matters more than QML/Qt polish.
- **Bonito + WGLMakie**: browser-shaped shell wrong for a desktop app; WGLMakie weaker on 3D/animation which are v0.1 requirements.
- **Pure Makie widgets**: no shell primitives — we would spend v0.1 reinventing menus and dialogs.
- **Electron / Blink.jl**: bundling Chromium is disproportionate.
- **CImGui.jl + ImGuiMakieBackend.jl**: aesthetic mismatch; `ImGuiMakieBackend.jl` inactive.

## Consequences

- **Positive**: native desktop feel on all three OSes; GLMakie's full 3D/animation retained; a single well-scoped upstream binding for Makie embedding.
- **Negative — stability risk**: Gtk4Makie.jl's README explicitly warns it "unavoidably relies on Makie internals and is likely to break from time to time when upgrading Makie." This means we pin Makie and Gtk4Makie together and bump them in lockstep (see PLAN.md pinned versions and TEST_PLAN.md upgrade-check job).
- **Negative — Linux Wayland/NVidia quirks**: the Gtk4Makie README notes issues with NVidia hardware on Linux and Wayland configuration. TEST_PLAN.md must include an X11 fallback documentation note and a Wayland-specific troubleshooting entry in README.md.
- **Negative — Julia GUI headless CI**: Gtk4 + GLMakie in CI requires xvfb (X virtual framebuffer) on Linux; Windows/macOS need a real display or a virtual one — see ADR-009.

## References

- Gtk4.jl (0.7.12): <https://github.com/JuliaGtk/Gtk4.jl>
- Gtk4Makie.jl (0.3.9): <https://github.com/JuliaGtk/Gtk4Makie.jl>
- GLMakie (0.13.13): <https://github.com/JuliaPlots/GLMakie.jl>
