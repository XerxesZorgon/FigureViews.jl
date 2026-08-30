# ADR-008 — Distribute via Julia's General registry (`] add FigureViews`)

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: SDD SC-001, NFR-004, PLAN.md M11

## Context

Distribution options for a Julia-language desktop app:

1. **General registry** — `Pkg.add("FigureViews")`; Julia-native, canonical for Julia packages.
2. **Standalone bundled binary** via `PackageCompiler.jl` — a one-file installer with Julia embedded.
3. **Private / third-party registry** — controlled distribution.

## Decision

Register FigureViews in Julia's **General registry** as v0.1.0. Users install with:

```julia
] add FigureViews
```

## Alternatives Considered

- **Standalone bundled binary (PackageCompiler)**: attractive for non-Julia-user reach, but three costs make it wrong for v0.1: (a) build overhead for three OSes delays the first release, (b) users lose the ability to `] update` alongside the rest of their Julia environment, (c) our primary audience is *Julia users*, who prefer `] add`. Considered again for v0.2+ if we reach for a non-Julia audience.
- **Private registry**: blocks the "first-class Julia package for all users" goal in the SDD. Rejected.

## Consequences

- **Positive**: canonical Julia install flow; users' existing Julia workflow, IDE integrations, and CI already know how to add General-registry packages.
- **Positive**: dependency resolution handled by `Pkg.jl` — we do not ship or manage Makie/Gtk4 binaries ourselves; the JLL packages (`GTK4_jll`, `Glib_jll`, etc.) already listed as transitive deps of `Gtk4.jl` handle native binaries per OS.
- **Negative — registry submission process**: v0.1.0 must satisfy General-registry submission requirements (LICENSE, README, tests that pass in CI, semver-compliant version, no name conflict). PLAN.md M11 covers this checklist.
- **Negative — first install time**: adding FigureViews pulls Makie, GLMakie, CairoMakie, Gtk4.jl, Gtk4Makie.jl, CSV.jl, DataFrames.jl, HDF5.jl transitively. First precompilation is slow. Mitigated by Julia 1.12's precompilation improvements; README.md should set expectations.

## References

- Julia General registry: <https://github.com/JuliaRegistries/General>
- Registrator.jl (submission tooling): <https://github.com/JuliaRegistries/Registrator.jl>
