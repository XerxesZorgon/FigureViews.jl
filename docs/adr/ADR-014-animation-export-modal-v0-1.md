# ADR-014 — Animation export blocks with a modal in v0.1; background export deferred to v0.2

**Status**: Accepted
**Date**: 2026-08-24
**Deciders**: John Peach
**Related**: ODQ-4 (closed by this ADR), DESIGN.md §9 (threading), ADR-013 (fps)

## Context

Rendering an MP4 iterates frames through Makie, writes each via CairoMakie, encodes via FFMPEG. For a 10k-frame animation at 30 fps that is minutes of work — long enough that "the GUI froze" is the user's first thought.

Two directions:

1. **Modal**: an "Exporting animation…" dialog with progress bar and cancel. The rest of the GUI is unresponsive until the export completes or is cancelled. Simple, safe.
2. **Background export**: the exporting figure is snapshotted; export runs on a worker task; the user can continue editing other figures or the tree meanwhile. The exporting figure's own edit controls are disabled to avoid confusion; other figures stay live.

Background export sounds better and *is* better UX. The obstacle is that GLMakie's OpenGL context is main-thread only, and Gtk4's event loop is main-thread only. A background task cannot render GL frames itself; it must marshal each frame's render call back to the main thread. Doing this correctly, with progress reporting and cancellation and without deadlock, is a real engineering project.

## Decision

- **v0.1 uses a modal.** "Exporting animation…" dialog with progress bar (`current_frame / total_frames`) and Cancel. The GUI is unresponsive during export.
- The export operates on a **snapshot of the figure taken at export-start**. Subsequent edits (once the modal clears) do not affect the file being written.
- **Background export is a named v0.2 project**, tracked in `CHANGELOG.md` under `[Unreleased]` future intent.

## Alternatives Considered

- **Background export in v0.1**: better UX, but adds weeks to M7 (Animations) for cross-platform correctness. Rejected for v0.1.
- **No progress bar; just freeze**: the user cannot tell whether the app has hung. Rejected.
- **Time-boxed modal that yields periodically**: partial-solution complexity approaches full background export. Rejected.

## Consequences

- **Positive**: v0.1 ships a correct, testable animation export on schedule.
- **Positive**: the snapshot-at-start rule (no live-state race) is simple and matches user intuition.
- **Negative**: long exports freeze the GUI. Documented in the export dialog itself ("This may take several minutes for long animations. GUI will resume when done.") and in README.
- **Negative — Cancel semantics**: cancelling mid-export leaves a partial file. v0.1 deletes the partial file on cancel and reports "Export cancelled; no file written." Documented in the export code.
- **Follow-up (v0.2)**: implement background export with per-figure edit-lock. TEST_PLAN.md v0.2 must add a concurrency test.

## References

- DESIGN.md §9.
