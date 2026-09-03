# Session Log
**Updated:** 2026-09-02
**Active skill:** software-project
**Last confirmed state:** M18 design complete — ready for task specs

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

### Science Council Meeting — FigureViews GUI Layout
- 2 rounds completed. Full transcript in Obsidian: `60_Daily/science-sessions/Science Council Meeting FigureViews-GUI-Layout.md`
- Council converged on: tri-pane layout (variable browser left, canvas center, property inspector right), drop-to-add gesture with graceful escalation recommendation engine, one-way code emission (Recipe Drawer), transform boundary enforced visually on canvas.
- Key lesson from Gemini: MATLAB's bi-directional code generation failed catastrophically — one-way emission only (deliberate non-goal).
- Key finding from Perplexity: scientists default to bar/scatter due to tool friction, not preference — recommender must actively surface distribution-revealing alternatives.

### M18 Design — Confirmed decisions
All confirmed by John. Ready for task specs.

**Layout — tri-pane + toolbar:**
```
Window
  menubar                (existing)
  toolbar                (NEW — icon+label, grouped)
  ─────────────────────────────────────────────────
  variable browser │ canvas (viewport) │ property inspector
  (left, ~280px)   │ (center, fills)   │ (right, ~280px)
  ─────────────────┤                   ├──────────────────
  derived variable │                   │ recipe drawer
  drawer (foldable)│                   │ (foldable)
```

**Toolbar groups:**
- Document: New, Open, Save, Export
- Structure: Add Figure, Add 2D Axis, Add 3D Axis, Delete Selected, Move Up, Move Down
- History: Undo, Redo (~20-step shallow stack)
- Context-sensitive: structure buttons grey when no valid target selected

**Plot creation — drop-to-add with graceful escalation:**
- Tier 1 (deterministic, instant): rule-based shortlist by data shape. 2×1D numeric → lines/scatter/band. 1D numeric → hist/density/boxplot. 2D matrix → heatmap/contour/surface.
- Tier 2 (deterministic, expandable): "show more" → categorized browser by visual question ("show relationship," "show distribution," "show field," "show uncertainty"). Plain-language labels, static thumbnails, Makie name on hover only.
- Tier 3 (AI, on-demand): "Ask FigureViews" button → sends to configurable provider (Claude/OpenAI/Gemini/OpenRouter). Skills.md system prompt. Adaptive sampling (see below).

**AI assistant:**
- Provider: pluggable via preferences (endpoint URL + API key via Scratch.jl). OpenRouter supported.
- Data sampling: opt-in, two levels:
  - Metadata only: names, shapes, eltypes, min/max/mean/std
  - Sampled data (opt-in default): adaptive subsample — 1D vectors: 200-point uniform subsample + summary stats (full if ≤500 pts); 2D matrix: downsampled to max 20×20 + marginals; 3D array: 10×10 first-slice sample + per-slice stats; hard cap 10,000 values total per call.
  - Full data: explicit per-call user override with warning if large.
- System prompt: Skills.md — provider-agnostic, encodes Makie inventory, data-shape rules, session context injected at call time.
- Output: same ranked list format as Tiers 1 and 2 — plain-language label, thumbnail, one-click add.

**Thumbnails:**
- Static, fetched from Makie docs at first launch (`https://docs.makie.org/stable/reference/plots/<plottype>/`), cached via Scratch.jl.
- Fallback: colored rectangle with plot type name if offline.
- Source image confirmed: Makie website example images (e.g., the `lines` zig-zag pattern).

**Transform boundary:**
- Axis transforms: hover gear icon on axis in canvas. "log" badge on axis label. "Axis Transform Active" chip in status bar.
- Data transforms: Derived Variable drawer (foldable, below variable browser). Julia expression input, named output, "D" badge. Explicit drag-to-canvas. REPL never mutated silently.

**Recipe Drawer:**
- One-way code emission only (bi-directionality is deliberate non-goal).
- Collapsible right panel. Minimal idiomatic Makie code, non-default attrs only.
- "Copy Script" and "Insert to REPL" buttons.

**Undo/Redo:**
- Shallow ~20-step command stack.
- Covers: structural ops (add/delete/reorder axis and plot) and property changes.
- Does not cover: REPL variable assignments, Derived Variable expressions.

**Move Up/Down:**
- Reorders plots within their parent axis (z-order/draw order).
- Moving plots between axes is out of scope for M18.

## Decisions made (not yet in an ADR)
- `open_dialog`/`save_dialog` used for File > Open/Save As (async path deferred).
- `ask_dialog(no_text="Cancel", yes_text="Discard")` used for File > New confirmation.
- `GtkMessageDialog(msg, [(label, id)...], flags, type, parent)` constructor used for pre-flight modal.
- GtkNotebook tab strip (Option A) chosen for variable + snapshot panes.
- AoG noted as future candidate for tabular/DataFrame plotting — needs ADR before any code.
- AI provider abstraction needs ADR-028 before any M18 code.

## Blocked on / open question
None.

## Next action
Start M18 task specs in a fresh session. Sequence:
- Phase 1 (Tasks 116–117): layout restructure + toolbar handlers
- Phase 2 (Task 118): undo/redo command stack
- Phase 3 (Tasks 119–122): ADR-028 + drop-to-add + recommendation tiers 1/2/3
- Phase 4 (Tasks 123–124): Derived Variable drawer + Recipe Drawer
- Phase 5 (Task 125): M18 integration test + Windows manual verification

Read PLAN-v0.2.md and the current `_open_shell` in `src/FigureViews.jl` before writing Phase 1 specs.
