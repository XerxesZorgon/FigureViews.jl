# Session Log
**Updated:** 2026-09-02
**Active skill:** software-project
**Last confirmed state:** CI patch complete (commit 05e5466) — green

## What happened this session

### M15 — Live GUI editing + entry surface (Tasks 099–111, all green)
- Phase 1: tree context menu (add/delete axes/plots), property-pane Add-plot button, `makieviews(session)` method, destroy-signal safety, Layer-3 live-edit CI test.
- Phase 2: variable picker pane (`selected_variable` observable), data/snapshots pane (GtkNotebook tab strip), Add-Plot dialog with positional-shape role wiring (`SHAPE_TO_VAR_KIND`, `AXIS_KIND_FOR_TYPE`).
- Phase 3: menubar scaffold (File + Plot menus), Open/Save/Save As handlers (`open_dialog`/`save_dialog` fallback — async GAsyncReadyCallback deferred), File > New with `ask_dialog` confirmation (M18 TODO for dirty-flag).
- Phase 4: pre-flight modal (`GtkMessageDialog` button-list constructor), downsample dialog, modal wired into Add-Plot flow.
- Phase 5: M15 end-to-end integration test (CI 2/2) + Windows manual verification (11/11 ✓).
- Patch: left-column label clipping fixed (`outer_paned.width_request = 320`, hscrollbar AUTOMATIC on tree + variable panes).
- SDD SC-002/SC-003/SC-005/SC-006 met through GUI.

### M16 — `.mvz` data round-trip (Tasks 112–115, all green)
- ADR-027: inline TOML storage, 100,000-element cap, binary sidecar deferred indefinitely.
- Schema version bumped 1.0 → 1.1.
- `data_inline` written per plot (de-duplicated by snapshot id, orphans dropped, >100k refuses with clear error).
- `_load_data_inline` + `_parse_eltype` restore arrays into `session.data_snapshots` on load.
- Round-trip pixel hashes matched (CairoMakie before/after export identical). SC-004 closed.
- CI patch: added `julia-actions/julia-processcoverage@v1` step; Codecov upload now green.

## Decisions made (not yet in an ADR)
- `open_dialog`/`save_dialog` used for File > Open/Save As (not async `GAsyncReadyCallback` path — deferred).
- `ask_dialog(no_text="Cancel", yes_text="Discard")` used for File > New confirmation.
- `GtkMessageDialog(msg, [(label, id)...], flags, type, parent)` constructor used for pre-flight modal.
- GtkNotebook tab strip (Option A) chosen for variable + snapshot panes (four stacked panes too cramped).
- AoG (AlgebraOfGraphics) noted as a future candidate for tabular/DataFrame plotting — no milestone assigned yet; needs ADR before any code.

## Blocked on / open question
None.

## Next action
M17 planning: macOS CI gate (ADR-018 hard gate before any future version tag) + conditional backend loading (ADR-023 backlog item). Read PLAN-v0.2.md M17 section before writing task specs. M18 (toolbar — the primary UX — unsaved-changes tracking, FPS pass) follows M17.
