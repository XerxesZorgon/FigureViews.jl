# Session Log
**Updated:** 2026-08-27
**Active skill:** software-project (M10 done → M11 next)
**Last confirmed state:** M10 COMPLETE — Task 066 signed off, CI run #38 green on both cells. Bug E (Task 067) fixed and CI-green (commit 143cbf9). Bug F filed and deferred to v0.2. HEAD = 16c26c8.

## What happened this session
Finished milestone M10 (the pre-flight dataset check): host/GPU detection, memory-footprint and fallback frame-rate estimates, three downsampling algorithms, the accept/warn decision, and the REPL `add_plot_checked!` warning — all tested and green (CI #38). Wrote ADR-020 (ship the coarse fallback for v0.1; defer the real frame-rate measurement to M11). An errant `git checkout tasks.md` wiped the uncommitted tasks.md history for Tasks 034–060; it was rebuilt from the chat plus records, and AGENTS.md now forbids Antigravity from touching tasks.md with git — tasks.md is committed after every edit now. Two GUI bugs surfaced: Bug E (tree pane crashed when adding a node after launch) is fixed; Bug F (window hangs if you add/remove a plot or axis after it's already shown) is a deep renderer issue, deferred to v0.2.

## Decisions made (not yet in an ADR)
- **v0.1 ships REPL-driven**: build the session with `add_plot!` / `add_plot_checked!` / `save_session` / `export_figure`, then `makieviews()` to display. The clean Veusz-style interactive GUI is a **v0.2+** goal (John, 2026-08-27) — do not pull it into v0.1.
- **Bug F deferred to v0.2**, documented as a v0.1 limitation: build-then-display works, live attribute edits work, live add/remove of axes/plots hangs. Full diagnosis + fix direction in tasks.md.
- **README and SDD oversell v0.1**: they describe an interactive GUI (menus, variable picker, warning modal) that v0.1 did not build. Must be reconciled to the REPL-driven reality before tagging v0.1.0.

## Blocked on / open question
None blocking. Verification items carried into M11 QA (listed in PLAN.md M11): the FPS measurement pass on three OSes; the GPU-VRAM-reading branch on a real NVIDIA machine (dev box has no `nvidia-smi`, so only the "unknown VRAM" fallback has run); interactive-fps sanity through the embedded viewport.

## Next action
Start M11. **First task: the pre-tag docs reconciliation** — rewrite the README (Quickstart, "Large datasets", "click-to-build" tagline) and audit docs/SDD.md to describe the actual REPL-driven v0.1 workflow (the interactive GUI is v0.2). Then the rest of M11: Registrator.jl dry-run, LICENSE / README / semver check, and the manual full-suite run on Windows + macOS (the macOS live-test is the hard gate before tagging v0.1.0). Read first: README.md, docs/SDD.md, docs/PLAN.md (M11 section has the carryover list), and the tasks.md tail (Bug F entry + M10 tasks).
