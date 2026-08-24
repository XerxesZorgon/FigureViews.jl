# ADR-001 — Julia as the language and runtime, current stable (1.12) as the target

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: PLAN.md (compat pins), ADR-002 (UI stack)

## Context

MakieViews wraps Makie, which is a Julia package. Any host language other than Julia would either reimplement Makie (impossible in scope) or drive it via inter-process calls (defeats the "first-class Julia package" goal). The only real choice is which Julia version to target.

As of August 2026:
- **Julia 1.10.11** is the current LTS (long-term support) branch — March 2026 patch.
- **Julia 1.12.6** is the current stable release — April 2026.

All of Makie 0.24.13, GLMakie 0.13.13, CairoMakie 0.15.13, Gtk4.jl 0.7.12, Gtk4Makie.jl 0.3.9, CSV.jl 0.10.16, DataFrames.jl 1.8.2, HDF5.jl 0.18.0, and Scratch.jl 1.3.0 declare `julia = "1.10"` (or looser) as their lower bound, meaning they support 1.10 and above — including 1.12.

## Decision

- **Language**: Julia.
- **Target**: Julia 1.12 (current stable) as the primary development and CI target.
- **Compat bound**: `julia = "1.10"` in `Project.toml`, matching every direct dependency's lower bound and allowing LTS users to install v0.1 without pinning them to a specific patch.
- **CI matrix**: Julia 1.12 (primary) and Julia 1.10 (LTS validation) on all three OSes.

## Alternatives Considered

- **Julia 1.10 LTS as primary target**: safer install base, but loses precompilation and language-feature improvements that landed in 1.11–1.12. Rejected because we still gate on the LTS in CI, which is enough insurance.
- **Pin only to 1.12** (drop LTS support): would cut off users who have not moved off LTS. Rejected — v0.1 is meant to reach the widest audience.
- **Any non-Julia host language**: would put an IPC boundary between MakieViews and Makie, degrading interactivity and defeating the "first-class Julia package for all users" goal. Rejected.

## Consequences

- **Positive**: users on both LTS and current stable can install. Direct-dependency compat bounds line up. Precompilation improvements available to the majority of users.
- **Negative**: CI matrix doubles for Julia-version dimension.
- **Follow-up**: PLAN.md must pin the top-level `julia = "1.10"` compat range. TEST_PLAN.md must include the 1.10 × 1.12 matrix.

## References

- Julia release history: <https://en.wikipedia.org/wiki/Julia_(programming_language)>
- Gtk4Makie.jl `Project.toml` (compat: `julia = "1.10"`): <https://github.com/JuliaGtk/Gtk4Makie.jl>
