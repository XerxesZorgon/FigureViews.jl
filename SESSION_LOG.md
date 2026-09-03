# Session Log
**Updated:** 2026-09-03
**Active skill:** software-project
**Last confirmed state:** Task 118, all bug fixes confirmed — green, manually verified

## What happened this session
Completed M17 Phase 1: Tasks 116 (tri-pane layout restructure), 117 (toolbar with
Document/Structure/History groups), and 118 (undo/redo stack + dirty flag). Fixed four
bugs found during manual smoke testing — GTK action handler arity errors, on_edit
wiring gap, File > New and Save As deadlocks caused by the save_dialog-inside-g_idle_add
pattern. All 13 smoke test items passed. AGENTS.md updated with the GTK dialog rule.

## Decisions made (not yet in an ADR)
- GTK dialog rule: `save_dialog`/`open_dialog`/`ask_dialog` must be called at the
  top level of an action handler, never inside `g_idle_add`. Only non-UI work
  (`_do_save`, `Gtk4.destroy`, `_do_new`) is deferred. Documented in AGENTS.md.
- `session.dirty` lives on `Session` struct (not in `_open_shell` closure); serializer
  skips it implicitly since `_session_to_dict` reads fields explicitly.
- Undo/redo stack is window-scoped (ephemeral, not persisted in .mvz). Depth = 20.
  Only property-attr edits are undoable (Option A); structural ops deferred.

## Blocked on / open question
None.

## Next action
Read `src/FigureViews.jl` (full `_open_shell`), `src/ui/variable_pane.jl`, and
`src/render/structural.jl` before drafting Task 119. Task 119 is the first task of
M17 Phase 2: drop-to-add infrastructure — making the variable browser pane a drag
source so variables can be dragged onto the canvas to create plots. The Science
Council design specifies a three-tier recommendation engine (deterministic ->
categorized browser -> AI), but Task 119 scope is only the drag source side: GTK4
drag-and-drop on the variable list, carrying a variable identifier as the drag
payload. The drop target (canvas) and recommendation engine come in later tasks.
Current task count: Tasks 116-118 done (3/13 M17 tasks). Next task number: 119.
Last commit: 73084d4.
