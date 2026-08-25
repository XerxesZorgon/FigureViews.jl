# TEST_PLAN.md — MakieViews v0.1

**Status**: Draft
**Date**: 2026-08-24
**Companion documents**: SDD.md, DESIGN.md, ADR-009 (test strategy), **ADR-018 (CI matrix reduction for v0.1)**, PLAN.md
**Template basis**: Custom (Spec Kit's checklist-template.md is too shallow for a full test plan; this document is written from first principles against SDD success criteria and ADR-009).

---

## 1. Scope & Traceability

Every test in this plan traces to a Functional Requirement (FR-*), Success Criterion (SC-*), or Non-Functional Requirement (NFR-*) from the SDD.

| Test suite | Traces to |
|---|---|
| Unit tests | FR-001..026 individually; NFR-001, NFR-002 |
| Integration (headless) | SC-003, SC-004, SC-005, SC-007 |
| GUI smoke | SC-001, SC-002 |
| Golden-image (CairoMakie) | SC-004, SC-005 |
| Cross-OS install | SC-001, SC-002, NFR-003, NFR-004 |
| Session round-trip | SC-004, FR-015..018 |
| Pre-flight | SC-006, FR-023..026 |
| Preferences behavior | SC-007, FR-020..022 |
| Startup time | NFR-005 |

---

## 2. Layers & CI Matrix (per ADR-009, amended by ADR-018)

Four layers, four costs:

| Layer | What runs | Where | Time/cell |
|---|---|---|---|
| 1. Unit | Pure Julia: tree ops, schema, TOML round-trip | Everywhere; no display | <1 min |
| 2. Integration (headless-safe) | Programmatic figure builds, CairoMakie export, no Gtk4 window | Everywhere (no Xvfb needed) | 2–5 min |
| 3. GUI smoke | Open Gtk4 window, close it | **v0.1: Linux only, under `xvfb-run` (per ADR-018).** Original ADR-009 intent was all three OSes; Windows/macOS runners on GitHub Actions lack accessible GL contexts and cannot even load GLMakie. | 1–3 min |
| 4. Golden-image | CairoMakie export vs. stored PNG hashes | Same as layer 2 | 2–5 min |

**v0.1 CI matrix (per ADR-018):** `{Julia 1.10, Julia 1.12} × {ubuntu-latest}` = **2 cells**. Windows and macOS are removed from CI for v0.1; support on those platforms is developer-machine-verified and covered by the M11 pre-release manual QA protocol.

**v0.2+ restoration path (per ADR-018):** once M2 lands the tree model and M8 lands CairoMakie static export, Layers 1, 2, and 4 will exist as code that runs without GL. At that point the CI matrix will be extended to `{Julia 1.10, Julia 1.12} × {ubuntu-latest, windows-latest, macos-latest}` = 6 cells, running Layers 1, 2, and 4 on all cells and Layer 3 (GUI smoke) on Linux only. That extension is v0.2 work, not v0.1.

Layer 3 on Linux is wrapped in `xvfb-run -a -s "-screen 0 1920x1080x24" julia --project=. -e '...smoke...'`.

---

## 3. Session Round-Trip Test (backing SC-004, FR-015..018)

The single most important test in v0.1. Property-style:

```julia
@testset "mvz round-trip: build → save → load → export produces same PNG hash" begin
    for scenario in ROUND_TRIP_SCENARIOS  # one per plot type × axis kind
        state1 = build_session_programmatically(scenario)   # no Gtk4 involved
        png1_hash = png_hash_via_cairomakie(state1)

        tmp = tempname() * ".mvz"
        save_mvz(state1, tmp)

        state2 = load_mvz(tmp)
        png2_hash = png_hash_via_cairomakie(state2)

        @test png1_hash == png2_hash
    end
end
```

`png_hash_via_cairomakie` renders the figure to a PNG in a tempdir, hashes the file bytes with SHA-256. Two identical trees produce byte-identical PNGs under CairoMakie (deterministic renderer). Fonts are pinned in the test setup (one bundled TTF) so cross-OS rendering is stable — else font substitution flakes tests.

Additional round-trip cases:
- **Unknown-node preservation**: hand-craft an `.mvz` containing `type = "future_recipe"`, load in v0.1, save, load again, assert the sub-table is byte-equal to the original after TOML normalization.
- **`schema_version` refusal**: hand-craft `.mvz` with `schema_version = "2.0"`, assert loader raises with the expected message.

---

## 4. Golden-Image Tests for Seven Plot Types (backing SC-005)

One canonical dataset per plot type, one canonical set of styling. Rendered via CairoMakie only (never GLMakie — ADR-009).

| Plot type | Dataset | Golden PNG |
|---|---|---|
| line     | `y = sin.(0:0.1:2π)` | `test/goldens/line_sin.png` |
| scatter  | Anscombe I | `test/goldens/scatter_anscombe1.png` |
| bar      | `[1,3,2,5,4]` labelled `A..E` | `test/goldens/bar_letters.png` |
| heatmap  | `[i+j for i=1:20, j=1:20]` | `test/goldens/heatmap_ramp.png` |
| contour  | `peaks(30)` reimpl | `test/goldens/contour_peaks.png` |
| surface  | `peaks(50)` | `test/goldens/surface_peaks.png` |
| volume   | Gaussian blob 32³ | `test/goldens/volume_gaussian.png` |

Pass criterion: SHA-256 of the produced PNG equals the stored golden's SHA-256 recorded in `test/goldens/hashes.toml`. Regeneration is a manual `just regenerate-goldens` step, reviewed in a PR — never on CI.

Fonts pinned; Cairo version pinned via `Cairo_jll` (transitive of CairoMakie); Julia bit-for-bit deterministic renderer expected within a Julia patch version. If a Julia patch changes floating-point ordering enough to break byte-hash equality, we downgrade to Structural Similarity Index (SSIM ≥ 0.995) on the stored reference and note the change in `CHANGELOG.md`.

---

## 5. Cross-OS Install Test (backing SC-001, NFR-004)

**v0.1 CI (per ADR-018): Linux only.** Runs on both Julia versions in the 2-cell matrix, on a fresh runner (no cached Julia depot):

```yaml
- run: julia -e 'using Pkg; Pkg.add("MakieViews")'
- run: xvfb-run -a julia -e 'using MakieViews; open_and_close_blank()'
```

**Windows and macOS cross-OS install (v0.1): maintainer manual QA before each release.** Same commands, without `xvfb-run`:

```
julia -e 'using Pkg; Pkg.add("MakieViews")'
julia -e 'using MakieViews; open_and_close_blank()'
```

Maintainer records pass/fail per platform in the release-notes QA report per ADR-018 protocol.

`open_and_close_blank()` is a MakieViews test helper that constructs the main window, verifies it is realized, and closes it. Exit code 0 = pass.

For the pre-registered branch (before we hit the General registry), the install step is `Pkg.add(url="https://github.com/XerxesZorgon/MakieViews.jl#main")`. After registration, it becomes `Pkg.add("MakieViews")` — same script, different target.

---

## 6. Headless-Safe Integration Tests (layer 2)

- **Tree operations**: add/delete/reorder nodes; assert the tree observer receives one event per operation with the correct payload.
- **Schema-driven property panel** (headless surrogate): iterate every attribute in `PLOT_SCHEMAS[type]` for each of the seven plot types; set each to a valid value; assert the Makie plot object reflects it after re-render.
- **Data ingestion**:
  - CSV: canned files under `test/data/csv/` including edge cases (mixed types → column greyed; trailing empty rows).
  - HDF5: canned files under `test/data/hdf5/` including nested groups and both float/int datasets.
  - `Main`: a synthetic module used as a `Main` stand-in for tests (`MainSource(source_module=TestMain)`).
- **Static export**: PNG/SVG/PDF each written and opened to assert non-empty valid content (SVG well-formed via `EzXML.jl`, PDF header `%PDF-` check, PNG via IHDR chunk).
- **Animation MP4 export**: three-frame animation via CairoMakie backend + `FFMPEG_jll`; assert output is a valid MP4 (moov atom present) and duration matches `frames / fps`.

---

## 7. GUI Smoke Tests (layer 3)

**v0.1: Linux only in CI (per ADR-018).** Runs on both Julia versions with Xvfb:

```julia
using MakieViews
w = MakieViews._internal_open_window()
@assert Gtk4.is_realized(w)
sleep(0.5)
close(w)
```

Purpose: fail fast if Gtk4 or Gtk4Makie is broken on Linux under xvfb. Windows and macOS coverage of the equivalent smoke check is via maintainer pre-release manual QA per ADR-018 protocol. Detailed interaction testing is out of scope for v0.1 CI — see §11.

---

## 8. Pre-Flight Dataset Check (backing SC-006, FR-023..026)

- **Small dataset**: below threshold → no warning, loads directly. Assert no dialog opened.
- **Large synthetic dataset** (100M-point vector): above threshold → warning shown. Test triggers by mocking `Sys.total_memory()` and VRAM to small values; assert dialog with expected fields.
- **User picks LTTB (10M → 100k)**: assert resulting plot has exactly 100k points; assert `plot.attrs[:downsample_algorithm]` records `LTTB(100_000)`; assert data-snapshot reference to full 10M is retained in `SessionState.data_snapshots`.
- **VRAM undetected**: mock the VRAM probe to raise; assert fallback message and no block.

Pre-flight tests live in layer 2 (headless-safe) — the dialog is a plain observable event, tested at the state-machine level, not the widget level.

---

## 9. Preferences Behavior (backing SC-007, FR-020..022)

- **Seed new**: write `preferences.toml { default_linewidth = 3 }`; create a new line plot programmatically; assert `plot.attrs[:linewidth] == 3`.
- **Load-does-not-override**: save an `.mvz` with `linewidth = 1`; overwrite `preferences.toml` to `default_linewidth = 5`; load the `.mvz`; assert `plot.attrs[:linewidth] == 1`.
- **Reset action**: with same setup as above, call `MakieViews.reset_to_preferences!(plot)`; assert `plot.attrs[:linewidth] == 5`.
- **Never calls `set_theme!`**: use `Test.@test_throws` style with a shim on `Makie.set_theme!` that throws; run full test suite; assert no test triggered it (backing ADR-006 "MUST NOT call `set_theme!`").
- **Preferences schema-version handling**: hand-craft a `preferences.toml` with a future minor version and an unknown field; assert the unknown field survives one round-trip through save.

---

## 10. Startup Time (backing NFR-005)

Excluded from CI gating (too noisy on shared runners), but tracked as a nightly benchmark on a dedicated self-hosted runner:

- Cold: `] add MakieViews` → `using MakieViews` → `makieviews()` → first frame. Target ≤10 s after precompilation on a 2020-class laptop equivalent.
- Warm: `using MakieViews` → `makieviews()` → first frame. Target ≤3 s.

Nightly failure emails; PR-time only if the M11 acceptance run flags it.

---

## 11. Explicitly Out of Scope for v0.1 CI

- Detailed GUI interaction tests (clicking specific menu items, dragging tree items). Deferred; will require a GUI automation tool.
- GPU-driver-specific rendering conformance. Golden images anchor on CairoMakie precisely to avoid this.
- Memory-leak profiling across long sessions. Manual only for v0.1.

---

## 12. Test Data Layout

```
test/
├── runtests.jl                 # entry point; runs all layers except goldens if $HEADLESS=1
├── unit/
│   ├── tree_ops.jl
│   ├── schema.jl
│   ├── toml_roundtrip.jl
│   └── downsample.jl
├── integration/
│   ├── data_sources.jl
│   ├── property_panel.jl
│   ├── export.jl
│   └── preflight.jl
├── gui_smoke/
│   └── open_close.jl           # gated on $DISPLAY (Linux) or platform (Win/mac)
├── goldens/
│   ├── hashes.toml
│   ├── line_sin.png
│   ├── scatter_anscombe1.png
│   ├── bar_letters.png
│   ├── heatmap_ramp.png
│   ├── contour_peaks.png
│   ├── surface_peaks.png
│   └── volume_gaussian.png
└── data/
    ├── csv/
    │   ├── clean_2col.csv
    │   ├── mixed_types.csv
    │   └── trailing_empty.csv
    └── hdf5/
        ├── flat.h5
        └── nested_groups.h5
```

---

## 13. Acceptance Criteria for Merging to `main`

- All layers 1–4 green on the 2-cell v0.1 CI matrix (`ubuntu-latest × {Julia 1.10, 1.12}`, Linux with Xvfb, per ADR-018).
- Golden-image hashes present and unchanged (or a regeneration PR reviewed).
- No `set_theme!` call anywhere in `src/` (grep gate in CI).
- No hard-coded plot-type branch in property-panel UI code (grep gate: `if.*plot\.type ==` forbidden in `src/ui/`).
- **For M11 (release-gating) only:** maintainer pre-release manual QA on Windows and macOS complete, results in release notes per ADR-018.
