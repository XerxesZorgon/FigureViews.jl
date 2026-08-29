---
{
  "id": "file_ioq7kol9",
  "filetype": "document",
  "filename": "tasks",
  "created_at": "2026-08-27T20:23:39.006Z",
  "updated_at": "2026-08-27T20:23:39.006Z",
  "meta": {
    "location": "/",
    "tags": [],
    "categories": [],
    "description": "",
    "source": "markdown"
  }
}
---
# MakieViews — tasks.md

Atomic execution list. One task per Antigravity instruction. Never advance
to Task N+1 until Task N is confirmed green with the acceptance criterion
listed on that task.

Task IDs are a global monotonic counter. `Milestone` is metadata.

---

## Milestone M1 — Shell

**Exit criterion:** `julia --project=. -e 'using MakieViews; w = makieviews(); sleep(1); Gtk4.destroy(w)'` opens a 1024×768 window titled "MakieViews" containing an empty Makie Axis rendered via GLMakie, closes cleanly, and returns exit code 0. **CI verification (per ADR-018): both cells of the v0.1 CI matrix (`ubuntu-latest × {Julia 1.10, 1.12}`) green.** Windows and macOS coverage is developer-machine-verified (already confirmed on Windows during Tasks 004–010; macOS deferred to M11 pre-release manual QA).

---

## Task 001: Author Project.toml with pinned deps
**Status:** [x] Done — 2026-08-24, folded into initial commit e304a61
**Milestone:** M1
**Depends on:** —

### What to do
Create `Project.toml` at the project root with: `name = "MakieViews"`, `authors = ["John Peach and contributors"]`, `version = "0.1.0-DEV"`, and a `uuid` generated fresh via `julia -e 'using UUIDs; println(uuid4())'` (the generated UUID is frozen for the lifetime of the package — do not regenerate on later tasks). Add `[deps]` entries for `Gtk4`, `Gtk4Makie`, `GLMakie`, **and `Makie`**, looking up each UUID from the package's upstream `Project.toml` on GitHub. Add a `[compat]` section with the exact pins from `docs/PLAN.md` §3: `julia = "1.10"` (compat range), `Gtk4 = "0.7.12"`, `Gtk4Makie = "0.3.9"`, `GLMakie = "=0.13.13"`, `Makie = "=0.24.13"` (exact-match, per the four-package lockstep noted in ADR-002).

### Files touched
- `Project.toml` — new file

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.status()'` exits 0 and the output lists exactly `Gtk4 v0.7.12`, `Gtk4Makie v0.3.9`, `GLMakie v0.13.13`, `Makie v0.24.13`. No warnings about unsatisfiable compat.


### On Failure
Report the full `Pkg` error output verbatim, including the resolver's explanation of any unsatisfiable constraint.

---

## Task 002: Add LICENSE (MIT)
**Status:** [x] Done — 2026-08-24, folded into initial commit e304a61
**Milestone:** M1
**Depends on:** —

### What to do
Create `LICENSE` at the project root containing the standard MIT license text with copyright line `Copyright (c) 2026 John Peach and contributors`.

### Files touched
- `LICENSE` — new file

### Acceptance Criterion
`julia -e 'txt = read("LICENSE", String); @assert contains(txt, "MIT License"); @assert contains(txt, "Copyright (c) 2026 John Peach and contributors"); println("LICENSE OK")'` exits 0 and prints `LICENSE OK`.

### On Failure
Report the exact Julia error (`AssertionError` line and the missing string), or the SystemError if the file doesn't exist.

---

## Task 003: Add .gitignore for Julia
**Status:** [x] Done — 2026-08-24, commit 45485cf
**Milestone:** M1
**Depends on:** —

### What to do
Create `.gitignore` at the project root with Julia-standard entries: `Manifest.toml`, `Project.toml.local`, `test/Manifest.toml`, `/deps/build.log`, `/deps/deps.jl`, `/docs/build/`, `/docs/site/`, `*.jl.cov`, `*.jl.*.cov`, `*.jl.mem`, `.DS_Store`, `.vscode/`, `Thumbs.db`. `Manifest.toml` is excluded per ADR-008 (library distribution — let downstream resolvers pick versions). `Project.toml.local` and `test/Manifest.toml` are Julia-specific artifacts that should never be committed.

### Files touched
- `.gitignore` — new file

### Acceptance Criterion
`julia -e 'lines = readlines(".gitignore"); required = ["Manifest.toml", "Project.toml.local", "test/Manifest.toml", "/docs/build/", ".DS_Store", ".vscode/"]; missing_entries = filter(r -> !(r in lines), required); @assert isempty(missing_entries) "missing: $missing_entries"; println(".gitignore OK")'` exits 0 and prints `.gitignore OK`.


### On Failure
Report the exact Julia error, including the list of missing entries from the `AssertionError` message, or the SystemError if the file doesn't exist.

---

## Task 004: Create src/MakieViews.jl module stub
**Status:** [x] Done — 2026-08-24, commit d08d1e2
**Milestone:** M1
**Depends on:** 001

### What to do
Create `src/MakieViews.jl` containing a minimal module. The module must: (1) `using Gtk4, Gtk4Makie, GLMakie` at the top, (2) `export makieviews`, (3) define `makieviews()` as a placeholder function returning `nothing`, and (4) close with `end # module MakieViews`. No other behavior — this task exists only to make the package loadable and to establish the module skeleton.

### Files touched
- `src/MakieViews.jl` — new file

### Acceptance Criterion
`julia --project=. -e 'using MakieViews; @assert :makieviews in names(MakieViews) "makieviews not exported"; @assert makieviews() === nothing "makieviews() did not return nothing"; println("module OK")'` exits 0 and prints `module OK`. Precompile output on first run is expected and not a failure.

### On Failure
Report the exact `AssertionError` or `UndefVarError`, plus any precompile output that preceded it.

---

## Task 005: Create test/runtests.jl with import-and-export test
**Status:** [x] Done — 2026-08-24, commit 016608e
**Milestone:** M1
**Depends on:** 004

### What to do
Create `test/runtests.jl` containing `using Test, MakieViews` and one `@testset "M1 shell — module loads" begin ... end` block that asserts `isdefined(MakieViews, :makieviews)` and that `makieviews` is exported (`:makieviews in names(MakieViews)`).

### Files touched
- `test/runtests.jl` — new file

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 and reports 2 tests passing, 0 failing.

### On Failure
Report the full `Pkg.test` output including which assertion failed.

---

## Task 006: Add ADR-011 non-REPL launch detection warning to makieviews() + test
**Status:** [x] Done — 2026-08-24, commit 8087b91
**Milestone:** M1
**Depends on:** 005

### What to do
Two changes in one commit — code + its test, atomic:

1. **Modify `src/MakieViews.jl`** so `makieviews()` begins with a non-REPL detection block. If `!(isinteractive() && isdefined(Base, :active_repl))`, emit `@warn` with the **exact** ADR-011 warning text (source of truth: `docs/adr/ADR-011-non-repl-launch-semantics.md`, verbatim, no paraphrasing):

   ```
   MakieViews v0.1 reads variables from REPL Main. You appear to be running outside a REPL. Variables defined in this script/context so far are visible; variables you define later will not appear. File loading (CSV / HDF5) works normally.
   ```

   Preserve the function's existing `return nothing` at the end.

2. **Extend `test/runtests.jl`** with a second `@testset` block that verifies the warning fires under the test runner (which is non-interactive by definition):

   ```julia
   @testset "M1 shell — non-REPL warning fires" begin
       @test_logs (:warn, r"MakieViews v0.1 reads variables from REPL Main") match_mode=:any makieviews()
   end
   ```

   `match_mode=:any` tolerates additional log lines (GLMakie precompile chatter, Gtk4 init messages).

### Files touched
- `src/MakieViews.jl` — modified: prepend warning block to `makieviews()` body
- `test/runtests.jl` — modified: append second testset

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 and reports at least 3 tests passing, 0 failing, across two testsets named `M1 shell — module loads` and `M1 shell — non-REPL warning fires`. Additionally, `git log --oneline -1` shows the commit subject `feat: add ADR-011 non-REPL launch warning with test`.

### On Failure
Report the full `Pkg.test()` output including which testset or assertion failed, and quote the actual warning text emitted (or absence thereof) verbatim.

---

## Task 007: (MERGED into Task 006)
**Status:** [x] Done — merged into Task 006 during authoring; empty by design
**Milestone:** M1
**Depends on:** —

Originally split "code change" (Task 006) from "test change" (Task 007). Merged into Task 006 because the natural atomic unit for a code-plus-warning-plus-test change is one commit, verified by `Pkg.test()` green — splitting them would create a transient commit with behavior but no test coverage. Numbering downstream (Tasks 008–012) unchanged to preserve external references.

---

## Task 008: Implement Gtk4 window creation in makieviews() + window-property test
**Status:** [x] Done — 2026-08-24, commit 189d382
**Milestone:** M1
**Depends on:** 006 (007 is a merged placeholder)

### What to do
Two changes in one commit — code + its test, atomic (same merge pattern as Task 006):

1. **Modify `src/MakieViews.jl`** so `makieviews()`, after the ADR-011 warning block, creates a Gtk4 window titled `"MakieViews"` with default size `1024 × 768`, shows it, and **returns the window handle**. Do not run a nested blocking event loop — return the handle so the caller (REPL user, test) can inspect and destroy it.

   Look up the exact Gtk4.jl v0.7.12 API (constructor, size setter, title accessor, size accessor) from Gtk4.jl's current documentation — do not guess. Standard v0.7 pattern is likely `GtkWindow("MakieViews", 1024, 768)`, but property/size accessors vary; the ADR/design docs do not pin these because they are library API details.

   Update the function's docstring to reflect the new return type (was `Nothing`, now the window type).

2. **Modify `test/runtests.jl`.** Add `using Gtk4` alongside the existing `using Test, MakieViews`. Update all existing testsets that call `makieviews()` to capture the returned window and destroy it before the testset ends (otherwise windows leak between testsets and CI gets flaky). Concretely:

   - **`M1 shell — module loads`**: change `@test makieviews() === nothing` to something like `w = makieviews(); @test !isnothing(w); Gtk4.destroy(w)`.
   - **`M1 shell — non-REPL warning fires`**: capture the value: `w = @test_logs (:warn, r"MakieViews v0.1 reads variables from REPL Main") match_mode=:any makieviews(); Gtk4.destroy(w)`.

   Add a new third testset `M1 shell — window properties` that creates the window via `makieviews()`, sleeps briefly (~0.2s) to let GTK settle, asserts (a) the title equals `"MakieViews"` and (b) the default size is `(1024, 768)` (or the equivalent tuple/pair form the Gtk4.jl API returns), then destroys the window. Use whatever title/size accessors Gtk4.jl v0.7.12 exposes — report which ones you used.

### Files touched
- `src/MakieViews.jl` — modified: add window-creation body, update docstring
- `test/runtests.jl` — modified: `using Gtk4`, destroy calls in existing testsets, new window-properties testset

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 and its output includes three testset names — `M1 shell — module loads`, `M1 shell — non-REPL warning fires`, `M1 shell — window properties` — with total `Pass` ≥ 5 and `Fail` = 0 in the final `Test Summary:` block. Additionally, `git log --oneline -1` shows the commit subject `feat: create Gtk4 window in makieviews() with title and default size`, and `git show --stat HEAD` reports exactly 3 files changed (src/MakieViews.jl, test/runtests.jl, tasks.md).

### On Failure
Report the full `Pkg.test()` output including which testset or assertion failed. If the failure is because the Gtk4.jl API name I guessed doesn't exist (e.g. `Gtk4.title` returns nothing, or `default_size` is not a symbol), quote the exact `UndefVarError` or `MethodError` and name which accessor you tried — that's the signal to look up a different accessor rather than a code bug.

---

## Task 009: (MERGED into Task 008)
**Status:** [x] Done — merged into Task 008 during authoring; empty by design
**Milestone:** M1
**Depends on:** —

Same merge pattern as Task 007 into Task 006: the atomic unit for the window-creation change is code + its property test in one commit, verified by `Pkg.test()` green. Splitting would create a transient commit with new behavior and no test coverage. Numbering downstream (Tasks 010–012) unchanged.

---

## Task 010: Embed an empty GLMakie Figure via Gtk4Makie + Figure-attachment test
**Status:** [x] Done — 2026-08-24, commit a062cc1
**Milestone:** M1
**Depends on:** 008 (009 is a merged placeholder)

### What to do
Two changes in one commit — code + its test, atomic (same merge pattern as Tasks 006 and 008):

1. **Modify `src/MakieViews.jl`** so `makieviews()`, after creating the Gtk4 window (Task 008's code), embeds a Gtk4Makie GLMakie viewport as the window's child, displaying an empty `Figure()` with a single empty `Axis`. The function still returns the window handle — not the Figure, not a tuple. Callers introspect through the widget tree if they need the Figure.

   Look up the actual Gtk4Makie.jl v0.3.9 API from its README and `examples/` directory — do not guess widget names. Likely candidates (verify one, don't assume): a widget type like `GtkGLMakie` or `GtkMakieCanvas` that takes a `Figure` and behaves as a Gtk4 widget; or a screen constructor like `GLMakie.Screen(figure; parent=window)`; or a helper that wraps both steps.

   Overhaul the docstring — the current "Placeholder entry point... Behavior added in later tasks" wording is stale (the function now creates a real window with a real viewport). Rewrite it to accurately describe: creates a MakieViews main window, embeds an empty Figure with one Axis via Gtk4Makie, returns the window handle, warns per ADR-011 when non-REPL.

2. **Extend `test/runtests.jl`** with a fourth testset `M1 shell — Figure attached`. Minimum assertion the test must make: after `makieviews()`, the window has at least one child widget (before Task 010, it has none). Stronger assertions to add if the Gtk4Makie API exposes them cleanly — report what you were able to check:

   - The child widget's type name contains `"Makie"` or `"GL"` (guards against accidentally adding a plain GTK widget).
   - The Figure embedded in the widget can be retrieved, and `length(fig.content) == 1` (one Axis, no more).
   - The single Axis is a Makie `Axis` (not `Axis3` — v0.1 M1 exit criterion is 2D).

   Destroy the window at the end of the testset (leak prevention).

### Files touched
- `src/MakieViews.jl` — modified: add Figure/Axis embedding + docstring overhaul
- `test/runtests.jl` — modified: append fourth testset

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0. The output includes four testset names — `M1 shell — module loads`, `M1 shell — non-REPL warning fires`, `M1 shell — window properties`, `M1 shell — Figure attached` — and the final `Test Summary:` block shows `Pass` ≥ 6 and `Fail` = 0. Additionally, `git log --oneline -1` shows the commit subject `feat: embed empty GLMakie Figure in window via Gtk4Makie`, and `git show --stat HEAD` reports exactly 3 files changed.

### On Failure
Report the full `Pkg.test()` output. If the failure is on the Gtk4Makie API (widget type name doesn't exist, or the parent/child relationship isn't what I described), quote the exact `UndefVarError` or `MethodError` and name which Gtk4Makie construct you tried — that's the signal to look up a different construct rather than a code bug. If GLMakie fails to initialize a GL context (common on some Windows drivers), quote the exact error — that's an environment issue, not a task-code bug.

---

## Task 011: (MERGED into Task 010)
**Status:** [x] Done — merged into Task 010 during authoring; empty by design
**Milestone:** M1
**Depends on:** —

Same merge pattern as Task 007 into 006 and Task 009 into 008: the atomic unit for the Figure-embedding change is code + its attachment test in one commit, verified by `Pkg.test()` green. Splitting would create a transient commit with new behavior and no test coverage. Numbering downstream (Task 012) unchanged.

---

## Task 012: Reduce CI matrix to Ubuntu-only per ADR-018
**Status:** [x] Done — 2026-08-24, commit c9794fd; CI run 2/2 green on ubuntu-latest × {Julia 1.10, 1.12}
**Milestone:** M1
**Depends on:** 010 (011 is a merged placeholder)

### What to do
Edit the existing `.github/workflows/ci.yml` (created at commit `c7a901e` with a 6-cell matrix) to reduce the OS matrix to `ubuntu-latest` only. Also drop the OS-conditional test-run steps (the `if: runner.os == 'Linux'` branch stays; the `if: runner.os != 'Linux'` branch is removed) since only Linux runs now. Preserve the Julia-version matrix (`['1.10', '1.12']`). Add a top-of-file comment naming ADR-018 as the source of the reduction and pointing readers to ADR-009 for the original 6-cell intent.

The replacement file content must be exactly:

```yaml
# .github/workflows/ci.yml
#
# CI matrix reduced from 6 cells (Julia {1.10, 1.12} × OS {Ubuntu, Windows, macOS})
# to 2 cells (Julia {1.10, 1.12} × Ubuntu) per ADR-018 (2026-08-24).
# Original 6-cell intent: docs/adr/ADR-009-test-strategy.md.
# Reduction rationale + restoration path (v0.2): docs/adr/ADR-018-ci-matrix-reduction-ubuntu-only.md.

name: CI

on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]

jobs:
  test:
    name: Julia ${{ matrix.julia-version }} - ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        julia-version: ['1.10', '1.12']
        os: [ubuntu-latest]
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Julia
        uses: julia-actions/setup-julia@v2
        with:
          version: ${{ matrix.julia-version }}

      - name: Cache Julia depot
        uses: julia-actions/cache@v2

      - name: Install xvfb
        run: |
          sudo apt-get update
          sudo apt-get install -y xvfb

      - name: Build package
        uses: julia-actions/julia-buildpkg@v1

      - name: Run tests (under xvfb)
        run: xvfb-run -a julia --project=. -e 'using Pkg; Pkg.test()'
```

Also stage the six doc files Claude edited from Chat as part of the same commit (list them explicitly — no wildcards):

- `docs/adr/ADR-018-ci-matrix-reduction-ubuntu-only.md` (new)
- `docs/adr/ADR-009-test-strategy.md` (amended)
- `docs/PLAN.md` (amended)
- `docs/TEST_PLAN.md` (amended)
- `tasks.md` (this task rewritten + M1 exit criterion updated)
- `INDEX.md` (updated to add ADR-018 to load-bearing decisions and mark M1 complete after CI green) — **Claude has not yet edited INDEX.md at instruction-write time**; check `git status` for whether it appears modified, and stage it only if it does; if not, omit.

Commit with two `-m` flags:

- Subject: `ci: reduce matrix to Ubuntu-only per ADR-018; document rationale`
- Body: `Closes Task 012. GitHub Actions Windows/macOS runners lack accessible OpenGL contexts, causing GLMakie precompile to fail before tests can start (confirmed run 32780549703, 4/6 red). Matches upstream Makie GLMakie CI (Ubuntu-only). New ADR-018 documents evidence, decision, alternatives rejected, restoration path in v0.2 once Layer 1/2 tests exist. ADR-009 amended with a top-of-file supersession note and correction to its Layer-3 non-Linux runner assumption. PLAN.md M1/M8/M11 exit criteria updated; M10's originally-reserved ADR-018 slot moved to ADR-019 (the future FPS-formula ADR). TEST_PLAN.md §2/§5/§7/§13 updated. tasks.md Task 012 rewritten + M1 exit gate updated.`

Push: `git push`. Do NOT wait for the CI run to complete. Report back after push succeeds.

### Files touched
- `.github/workflows/ci.yml` — modified (matrix reduction + top-of-file comment)
- `docs/adr/ADR-018-ci-matrix-reduction-ubuntu-only.md` — new (already written by Claude from Chat)
- `docs/adr/ADR-009-test-strategy.md` — modified (already amended by Claude)
- `docs/PLAN.md` — modified (already amended by Claude)
- `docs/TEST_PLAN.md` — modified (already amended by Claude)
- `tasks.md` — modified (this task rewrite + M1 exit criterion)

### Acceptance Criterion (this instruction only — Task 012 as a whole requires 2/2 green)
`.github/workflows/ci.yml` matches the exact content above. `git log --oneline -1` shows the commit subject `ci: reduce matrix to Ubuntu-only per ADR-018; document rationale`. `git show --stat HEAD` reports at least 6 files changed (the 5 doc/config files plus ci.yml; INDEX.md optionally 7th). `git push` completes without error. `git status` reports `Your branch is up to date with 'origin/main'`.

### Report back (post-push)
On pass: `INSTRUCTION PASSED — ci.yml + doc amendments committed as <7-char SHA> and pushed to origin/main. New CI run should appear at https://github.com/XerxesZorgon/MakieViews/actions within ~30 seconds. Task 012 remains [ ] Pending until 2/2 green confirmed.`
On fail: `INSTRUCTION FAILED — [criterion] — [observed] — [error text]`

### On CI-run Failure (after push, if 2/2 not green)
Report the URL of the failed run and paste the failing job's log tail (last ~50 lines). This is real regression territory now — with Ubuntu-only, the only remaining failure modes are: xvfb setup breakage, Julia 1.10 vs 1.12 divergence in our test code, or a genuine bug we introduced. Fix instruction will target the specific failure.

---

## M1 exit gate

When Tasks 001–012 are all `[x] Done` and the v0.1 CI matrix (2 cells: `ubuntu-latest × {Julia 1.10, 1.12}`, per ADR-018) is green, M1 is complete. Return to Claude Chat with "M1 complete" to extend `tasks.md` with M2 (Tree + first plot type). Then run the macOS live-test (developer-machine QA per ADR-018) before starting M2, and log its result to Obsidian.

---

## Milestone M2 — Tree + one plot type

**Exit criterion:** Launching `makieviews()` shows a three-pane layout — tree pane (top-left, `GtkListView` + `GtkTreeListModel` per Gtk4 modern API), property pane (bottom-left, schema-driven per DESIGN.md §5), and viewport (right, the existing Gtk4Makie widget). The app auto-populates a demo Session with one Figure, one 2D Axis, and one line plot using synthetic data (`x = 1:100, y = sin.(x/10)`) on launch — no data ingestion yet, that's M5. The user can click on the plot in the tree, see its schema-derived property editors in the property pane, edit an attribute (e.g., `linewidth`), and observe the change in the viewport within one debounced frame (60 Hz throttle via `Observables.throttle`). `Pkg.test()` green with all M1 tests still passing plus new Layer 1 tree-ops/schema tests and new Layer 3 end-to-end test. CI green on the v0.1 matrix (Ubuntu × {Julia 1.10, 1.12}).

**Load-bearing decisions folded in:**
- **ADR-019**: `mutable struct` node types with per-field `Observable` fields, `Observables.jl` as reactive layer, `Plot.attrs::Dict{Symbol, Observable{Any}}` for per-attribute observation, `Observables.throttle(1/60, ...)` for debouncing.
- **Gtk4 tree widget**: `GtkListView` + `GtkTreeListModel` + `GtkSignalListItemFactory`. Gtk4.jl v0.7.12 exposes both this modern API and the deprecated `GtkTreeView`; we use the modern API per GTK4's own recommendation for new code.
- **Test directory layout**: `test/unit/` for Layer 1 (pure-Julia) tests — `test/unit/nodes.jl`, `test/unit/schema.jl`, `test/unit/session.jl`. `test/runtests.jl` becomes an aggregator that `include`s the unit files and keeps the existing GUI-smoke testsets. `test/integration/` and `test/goldens/` remain empty until M5/M8 per TEST_PLAN.md §12.
- **Menu-based node creation deferred to M3+.** M2 auto-populates a demo on launch. This keeps M2 scope tight: no `Add Figure` menu item, no data picker (that's M5), no file dialogs.
- **Renderer construction**: `Renderer` is created inside `makieviews()` after the `SessionState` and before the panes are wired. It owns the `Makie.Figure`, registers observer handlers on every observable in the tree, holds handler refs in `_observer_handles` so GC does not disconnect them.
- **Selection model**: `SessionState.selection::Observable{Union{Nothing, String}}` holds the currently-selected node's id (a UUID string, or `nothing`). Tree pane writes to it on click; property pane observes it and repopulates on change.
- **Attribute validation**: `validate(schema::Vector{AttrSpec}, name::Symbol, value) → Union{value, ValidationError}`. Called from property-pane widget callbacks. Invalid value → widget reverts to prior value + status-bar message.

---

## Task 013: Add Observables.jl and Colors.jl to Project.toml deps
**Status:** [x] Done — 2026-08-24, commit 61c9e25; Observables v0.5.5 + Colors v0.13.1 resolved
**Milestone:** M2
**Depends on:** — (M1 complete)

### What to do
Add two direct dependencies that M2 needs but were not in M1's `Project.toml`:

- **`Observables`** — needed for ADR-019's reactive state model. Already in the depot transitively via Makie; adding to `[deps]` makes the `using Observables` explicit and prevents a Pkg warning about implicit deps.
- **`Colors`** — needed for `AttrSpec` default values like `RGB(0.1, 0.4, 0.8)` (DESIGN.md §2.4). Already in the depot transitively via Makie; same reasoning as Observables.

Look up each UUID from the package's upstream `Project.toml` on GitHub (`JuliaGizmos/Observables.jl`, `JuliaGraphics/Colors.jl`) — do not guess.

Add `[compat]` entries. Use caret pins consistent with what Makie transitively requires. Look up the exact versions Makie 0.24.13 depends on for both packages (check `Makie.jl/Project.toml`'s `[compat]` section on GitHub) and pin to those major.minor lines (e.g., `Observables = "0.5"`, `Colors = "0.13"` — verify).

### Files touched
- `Project.toml` — modified: add 2 entries to `[deps]`, 2 entries to `[compat]`

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.status()'` exits 0. Output lists both `Observables` and `Colors` alongside the four M1 direct deps (Gtk4, Gtk4Makie, GLMakie, Makie), each at the resolved version. No resolver warnings. Additionally, `julia --project=. -e 'using Observables, Colors; println("OK")'` exits 0 and prints `OK` (i.e., both packages are now loadable directly without going through Makie).

### Commit
Subject: `chore: add Observables and Colors to Project.toml deps for M2`
Body: `Closes Task 013. Adds Observables.jl (ADR-019 reactive state) and Colors.jl (AttrSpec RGB defaults) as direct dependencies. Both already present transitively via Makie; direct listing prevents implicit-dep warnings and lets us using them explicitly.`

### Report back
On pass: `TASK 013 PASSED — Observables and Colors added, resolved to <versions>, committed as <SHA>`
On fail: `TASK 013 FAILED — [criterion] — [observed] — [Pkg output]`

---

## Task 014: Define node types (Session/Figure/Axis/Plot/UnknownNode + support types) + Layer 1 tests
**Status:** [x] Done — 2026-08-24, commit 9296b16
**Milestone:** M2
**Depends on:** 013

### What to do
Three source changes in one commit — code + its unit tests, atomic (M1 merge pattern).

**1. Create `src/state/nodes.jl`** with the `mutable struct` declarations for the tree nodes per DESIGN.md §2.1 (post-ADR-019 update).

**Important: declaration order in the file must be LEAF-FIRST**, not the top-down conceptual order DESIGN.md shows. Julia parametric types like `Observable{Vector{Figure}}` on `Session.figures` require `Figure` to be already declared at the point of use — declaring `Session` first would fail with `UndefVarError: Figure not defined`. DESIGN.md §2.1 has a note explaining this. Order:

1. `abstract type Node end`
2. `mutable struct Plot <: Node` — no forward refs (DataRef/AnimBinding come from types.jl, already included)
3. `mutable struct Axis <: Node` — references `Plot` and `CameraSpec` (both now defined)
4. `mutable struct Figure <: Node` — references `Axis`
5. `mutable struct Session <: Node` — references `Figure`
6. `mutable struct UnknownNode <: Node` — no refs (position doesn't matter, put last for consistency)

Within each struct, the fields are exactly as DESIGN.md §2.1 lists them (post-ADR-019 amendment). Read `docs/DESIGN.md` §2.1 for the field lists; do not paraphrase from memory.

**2. Create `src/state/types.jl`** with the minimal support types the node fields reference. For M2, these are shells — M5/M6/M7 fill them in fully:

```julia
# src/state/types.jl

struct LayoutSpec
    rows::Int
    cols::Int
end

struct CameraSpec
    azimuth::Float64
    elevation::Float64
    zoom::Float64
end

struct AnimBinding
    # M7 fills this in. For M2, empty struct is fine — field is Observable{Union{Nothing, AnimBinding}} so nothing is the M2 value.
end

struct DataRef
    role::Symbol                                     # :x | :y | :z | :heat | ...
    source::Symbol                                   # :main | :csv | :hdf5
    absolute_path::Union{Nothing, String}            # per ADR-012 — nothing for :main source
    relative_path::Union{Nothing, String}            # per ADR-012
    column::Union{Nothing, String}                   # for csv
    dataset::Union{Nothing, String}                  # for hdf5
    variable::Union{Nothing, Symbol}                 # for main
end
```

These are `struct` (not `mutable struct`) because they are value objects passed around by copy; only the *containing* nodes need to be mutable/observable.

**3. Update `src/MakieViews.jl`** to `include("state/types.jl")` then `include("state/nodes.jl")`, and add `using Observables, Colors` alongside the existing `using` statements.

**4. Create `test/unit/nodes.jl`** with these Layer 1 testsets (all Julia, no Gtk4, no GLMakie):

```julia
@testset "M2 nodes — Session construction" begin
    s = Session(v"1.0.0", Observable(Figure[]), Dict{String,Any}(), Observable{Union{Nothing,String}}(nothing))
    @test s.schema_version == v"1.0.0"
    @test isempty(s.figures[])
    @test s.selection[] === nothing
end

@testset "M2 nodes — Figure/Axis/Plot construction with observable fires" begin
    fig = Figure("fig-id", Observable("Untitled"), Observable(LayoutSpec(1,1)), Observable(Axis[]))
    fired = Ref(0)
    on(fig.title) do _; fired[] += 1; end
    fig.title[] = "New Title"
    @test fired[] == 1
    @test fig.title[] == "New Title"
end

@testset "M2 nodes — Plot.attrs per-attribute observation" begin
    p = Plot("plot-id", :line, Observable(DataRef[]), Dict{Symbol,Observable{Any}}(:linewidth => Observable{Any}(1.5)), Observable{Union{Nothing,AnimBinding}}(nothing))
    lw_fired = Ref(0)
    on(p.attrs[:linewidth]) do _; lw_fired[] += 1; end
    p.attrs[:linewidth][] = 2.5
    @test lw_fired[] == 1
    @test p.attrs[:linewidth][] == 2.5
end

@testset "M2 nodes — UnknownNode preserves payload" begin
    u = UnknownNode("future_recipe_xyz", Dict{String,Any}("foo" => "bar", "n" => 42))
    @test u.original_type == "future_recipe_xyz"
    @test u.payload["n"] == 42
end
```

**5. Update `test/runtests.jl`** to include the new file: add `include("unit/nodes.jl")` after the existing `using` lines but before the M1 shell testsets. This is the first use of the `test/unit/` directory; create it if it does not exist.

### Files touched
- `src/state/nodes.jl` — new
- `src/state/types.jl` — new
- `src/MakieViews.jl` — modified: add includes, add `using Observables, Colors`
- `test/unit/nodes.jl` — new
- `test/runtests.jl` — modified: `include("unit/nodes.jl")` line added

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0. Test Summary shows all M1 testsets still passing (Pass ≥ 7) PLUS four new M2 testsets (`M2 nodes — Session construction`, `M2 nodes — Figure/Axis/Plot construction with observable fires`, `M2 nodes — Plot.attrs per-attribute observation`, `M2 nodes — UnknownNode preserves payload`), all passing (Pass total ≥ 12, Fail = 0).

### Commit
Subject: `feat: add tree node types (Session/Figure/Axis/Plot) with Observable fields per ADR-019`
Body: `Closes Task 014. Introduces the M2 tree model: mutable structs with per-field Observables (ADR-019). Support types (LayoutSpec, CameraSpec, AnimBinding, DataRef) declared as minimal shells; M5–M7 fill them in. Layer 1 tests (test/unit/nodes.jl) verify construction, observable-firing on mutation, per-attribute observation on Plot.attrs, and UnknownNode payload preservation. First use of test/unit/ directory per TEST_PLAN.md §12.`

### Report back
On pass: `TASK 014 PASSED — 12+ tests green (7 M1 + 4 M2 nodes + …), committed as <SHA>`
On fail: `TASK 014 FAILED — [criterion] — [Pkg.test output tail]`

---

## Task 015: Define AttrSpec + PLOT_SCHEMAS[:line] + iteration tests
**Status:** [x] Done — 2026-08-24, commit c160273
**Milestone:** M2
**Depends on:** 014

### What to do
Two source changes in one commit.

**1. Create `src/state/schema.jl`** with the exact `AttrSpec` struct from DESIGN.md §2.4 and the `PLOT_SCHEMAS` registry. Populate `PLOT_SCHEMAS[:line]` with the attributes M2 needs the property pane to render for a line plot:

```julia
struct AttrSpec
    name::Symbol
    kind::Symbol       # :color | :number | :int | :enum | :bool | :string | :vec2 | :vec3
    default::Any
    range::Any         # nothing, or (lo, hi), or Vector for :enum
    label::String
    tooltip::String
end

const PLOT_SCHEMAS = Dict{Symbol, Vector{AttrSpec}}()

PLOT_SCHEMAS[:line] = [
    AttrSpec(:color,     :color,  RGB(0.1, 0.4, 0.8), nothing,          "Color",     "Line color"),
    AttrSpec(:linewidth, :number, 1.5,                 (0.1, 20.0),      "Linewidth", "Line width in points"),
    AttrSpec(:linestyle, :enum,   :solid,              [:solid, :dash, :dot, :dashdot], "Style",     "Dash pattern"),
    AttrSpec(:label,     :string, "",                  nothing,          "Label",     "Legend label (empty = no legend entry)"),
    AttrSpec(:visible,   :bool,   true,                nothing,          "Visible",   "Show/hide this plot"),
]
```

Use `RGB` from Colors.jl (added in Task 013). Do not add other plot types' schemas — those are M3 (2D) and M4 (3D).

**2. Update `src/MakieViews.jl`** to `include("state/schema.jl")` after the nodes include.

**3. Create `test/unit/schema.jl`** with iteration/lookup tests:

```julia
@testset "M2 schema — PLOT_SCHEMAS[:line] populated" begin
    @test haskey(PLOT_SCHEMAS, :line)
    specs = PLOT_SCHEMAS[:line]
    @test length(specs) >= 5
    names = [s.name for s in specs]
    @test :color in names
    @test :linewidth in names
    @test :linestyle in names
    @test :label in names
    @test :visible in names
end

@testset "M2 schema — AttrSpec fields correct types" begin
    lw_spec = only(s for s in PLOT_SCHEMAS[:line] if s.name == :linewidth)
    @test lw_spec.kind == :number
    @test lw_spec.default == 1.5
    @test lw_spec.range == (0.1, 20.0)
    style_spec = only(s for s in PLOT_SCHEMAS[:line] if s.name == :linestyle)
    @test style_spec.kind == :enum
    @test :solid in style_spec.range
    @test :dashdot in style_spec.range
end

@testset "M2 schema — no plot-type branches in iteration" begin
    # Verify PLOT_SCHEMAS is data, not code — iterating produces the schema without any
    # if plot.type == :line ... elseif ... branches. Test by iterating :line's schema:
    for spec in PLOT_SCHEMAS[:line]
        @test spec isa AttrSpec
        @test spec.name isa Symbol
        @test spec.kind in (:color, :number, :int, :enum, :bool, :string, :vec2, :vec3)
    end
end
```

**4. Update `test/runtests.jl`** to include `test/unit/schema.jl`.

### Files touched
- `src/state/schema.jl` — new
- `src/MakieViews.jl` — modified: add include
- `test/unit/schema.jl` — new
- `test/runtests.jl` — modified: add include

### Acceptance Criterion
`Pkg.test()` exits 0. Test Summary shows all prior testsets still passing PLUS three new M2 schema testsets, all passing.

### Commit
Subject: `feat: add AttrSpec and PLOT_SCHEMAS[:line] registry`
Body: `Closes Task 015. Introduces schema-driven pattern per DESIGN.md §2.4 and §5. PLOT_SCHEMAS[:line] populated with color, linewidth, linestyle, label, visible — the property pane will iterate this in Task 019. Layer 1 tests verify schema contents and shape.`

### Report back
On pass: `TASK 015 PASSED — PLOT_SCHEMAS[:line] with 5 attrs, committed as <SHA>`
On fail: `TASK 015 FAILED — [criterion] — [Pkg.test output tail]`

---

## Task 016: Add tree construction API (add_figure!, add_axis!, add_line_plot!) + Layer 1 tests
**Status:** [x] Done — 2026-08-24, commit 7dbe666
**Milestone:** M2
**Depends on:** 015

### What to do
Two source changes in one commit.

**1. Create `src/state/session.jl`** with:

- A `new_session()::Session` constructor that returns an empty Session with `schema_version = v"1.0.0"`, empty `figures`, empty `preferences_snapshot`, `selection = nothing`.
- `add_figure!(s::Session; title::String = "Untitled")::Figure` — generates a UUIDv4, constructs a `Figure` with empty axes and `LayoutSpec(1, 1)`, appends to `s.figures[]` via `push!(s.figures[], fig); notify(s.figures)`. Returns the new Figure. **Note**: `push!(observable[], item)` mutates the underlying vector but does NOT fire observers automatically — must call `notify(observable)` explicitly. Alternative: `s.figures[] = push!(copy(s.figures[]), fig)` fires automatically. Pick one pattern and use it consistently — the `copy`+reassign pattern is safer (no shared mutable state) and is what Observables.jl documentation recommends.
- `add_axis!(fig::Figure; kind::Symbol = :axis2d, title::String = "")::Axis` — same pattern. `kind` must be `:axis2d` or `:axis3d` (`ArgumentError` otherwise — for M2 only `:axis2d` is exercised; `:axis3d` arrives at M4).
- `add_line_plot!(ax::Axis; x, y)::Plot` — generates UUIDv4, constructs a `Plot` with `type = :line`, `data_refs = [DataRef(:x, :inline, nothing, nothing, nothing, nothing, nothing), DataRef(:y, :inline, ...)]` — wait, DataRef doesn't have a way to hold inline data in v0.1 per ADR-017. For M2, since data ingestion is deferred to M5, we need a different mechanism to hold the synthetic x/y arrays. **Options: (a)** add a temporary `_m2_inline_data::Union{Nothing, NamedTuple}` field to Plot, delete in M5 when proper DataRef+snapshot lands; **(b)** stash the data in a module-level `_DEMO_DATA::Dict{String, NamedTuple}` keyed by plot id, delete in M5; **(c)** use the reserved `data_inline` schema slot from ADR-017 in memory only (never serialized). Recommend **(b)** — zero changes to Plot struct or DataRef, isolated to M2 demo scaffolding, obvious to delete in M5. Document the choice in an inline comment naming it as "M2-only demo scaffolding, remove at M5."
  
  So the concrete signature and body: `add_line_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, plot_id::String = string(uuid4()))::Plot` — constructs `Plot` with empty `data_refs`, populates `attrs` from `PLOT_SCHEMAS[:line]` defaults, stashes `(x=x, y=y)` in module-level `_DEMO_DATA[plot_id]`, appends to `ax.plots[]` with `copy`+reassign, returns the Plot. The Renderer (Task 017) knows to look up `_DEMO_DATA[plot.id]` when rendering a `:line` plot that has no data_refs.

Initialize `Plot.attrs` from schema:

```julia
function _init_attrs(plot_type::Symbol)::Dict{Symbol, Observable{Any}}
    d = Dict{Symbol, Observable{Any}}()
    for spec in PLOT_SCHEMAS[plot_type]
        d[spec.name] = Observable{Any}(spec.default)
    end
    return d
end
```

**2. Update `src/MakieViews.jl`** to `include("state/session.jl")` and `using UUIDs` (stdlib, no Project.toml change).

**3. Create `test/unit/session.jl`** with tests:

```julia
@testset "M2 session — new_session is empty" begin
    s = new_session()
    @test isempty(s.figures[])
    @test s.selection[] === nothing
end

@testset "M2 session — add_figure! appends and fires observer" begin
    s = new_session()
    fires = Ref(0)
    on(s.figures) do _; fires[] += 1; end
    fig = add_figure!(s; title = "Test Fig")
    @test length(s.figures[]) == 1
    @test s.figures[][1] === fig
    @test fig.title[] == "Test Fig"
    @test fires[] == 1
end

@testset "M2 session — add_axis! and add_line_plot! chain" begin
    s = new_session()
    fig = add_figure!(s)
    ax = add_axis!(fig; kind = :axis2d, title = "X vs Y")
    x = 1:100 |> collect .|> Float64
    y = sin.(x ./ 10)
    plot = add_line_plot!(ax; x = x, y = y)
    @test ax.plots[][1] === plot
    @test plot.type == :line
    @test plot.attrs[:linewidth][] == 1.5    # default from PLOT_SCHEMAS[:line]
    @test plot.attrs[:linestyle][] == :solid
    @test haskey(MakieViews._DEMO_DATA, plot.id)
    @test MakieViews._DEMO_DATA[plot.id].x == x
end

@testset "M2 session — add_axis! rejects unknown kind" begin
    s = new_session()
    fig = add_figure!(s)
    @test_throws ArgumentError add_axis!(fig; kind = :axis_bogus)
end
```

**4. Update `test/runtests.jl`** to include `test/unit/session.jl`.

### Files touched
- `src/state/session.jl` — new
- `src/MakieViews.jl` — modified: add include + `using UUIDs`
- `test/unit/session.jl` — new
- `test/runtests.jl` — modified: add include

### Acceptance Criterion
`Pkg.test()` exits 0. All prior testsets pass PLUS four new M2 session testsets pass.

### Commit
Subject: `feat: add tree construction API (new_session, add_figure!, add_axis!, add_line_plot!)`
Body: `Closes Task 016. Introduces the Layer 1 programmatic API for building a SessionState tree. add_line_plot! uses a module-level _DEMO_DATA dict as M2-only scaffolding for synthetic data; M5's proper DataRef+snapshot layer replaces it. Follows the copy+reassign pattern for observable mutation (safer than push!+notify — Observables.jl recommendation).`

### Report back
On pass: `TASK 016 PASSED — tree API green, committed as <SHA>`
On fail: `TASK 016 FAILED — [criterion] — [Pkg.test output tail]`

---

## Task 017: Add Renderer + observer registration + programmatic-path Layer 3 test
**Status:** [x] Done — 2026-08-24, commit 8fed731
**Milestone:** M2
**Depends on:** 016

### What to do
One of M2's harder tasks — Renderer construction, observer wiring, and a Layer 3 test that verifies the full programmatic path (SessionState → Renderer → Makie.Figure with a line rendered) works before we add any UI.

**1. Create `src/render/renderer.jl`** with the `Renderer` struct from DESIGN.md §8 (post-ADR-019 update):

```julia
mutable struct Renderer
    fig::Makie.Figure
    session::Session
    axis_handles::Dict{String, Union{Makie.Axis, Makie.Axis3}}
    plot_handles::Dict{String, Any}
    _observer_handles::Vector{Any}
end
```

And these functions:

- `Renderer(session::Session, fig::Makie.Figure)::Renderer` — constructor. Walks the tree, creates Makie axes and plots, registers observers.
- `_render_axis!(renderer, fig, ax::Axis, position)::Union{Makie.Axis, Makie.Axis3}` — creates the Makie axis, stores in `axis_handles[ax.id]`, registers observers on ax's per-attribute observables (title, xlabel, etc.), calls `_render_plot!` for each plot.
- `_render_plot!(renderer, makie_ax, plot::Plot)` — for M2 the only case is `plot.type == :line`. Look up `_DEMO_DATA[plot.id]` for the (x, y) arrays. Call `Makie.lines!(makie_ax, x, y; color = plot.attrs[:color][], linewidth = plot.attrs[:linewidth][], ...)`. Store the returned plot object in `plot_handles[plot.id]`. Register observers on each `plot.attrs[name]` that mirror the change onto the Makie plot object via Makie's own attribute-setting API (Makie plots have their own Observables per attribute — setting them fires Makie's internal renderer).
- `_register_axis_observer!(renderer, ax::Axis)` — registers `on(ax.title) do t; makie_ax.title[] = t; end` and equivalents for xlabel/ylabel/xlim/ylim/gridlines/etc. Store each returned `ObserverFunction` ref in `_observer_handles`.
- `_register_plot_observer!(renderer, plot::Plot)` — registers observers on each `plot.attrs[name]` that mirror onto the Makie plot handle.

Structural observers (add/remove axis, add/remove plot) can be minimal for M2 — M3+ exercises them more. For M2, register an observer on `session.figures` and each `figure.axes` and each `axis.plots` that on structural change re-renders the affected subtree. Concretely: naive M2 implementation — wipe the Makie.Figure and rebuild from scratch. Not optimal but correct. Optimization deferred.

**2. Update `src/MakieViews.jl`** to `include("render/renderer.jl")`.

**3. Extend `test/runtests.jl`** with a new testset `M2 renderer — programmatic line plot renders` under a new heading in the existing runtests file (not test/unit/, because this test uses GLMakie and requires the display — it's Layer 3):

```julia
@testset "M2 renderer — programmatic line plot renders" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = collect(1.0:100.0)
    y = sin.(x ./ 10)
    plot_node = add_line_plot!(ax_node; x = x, y = y)

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)

    @test haskey(renderer.axis_handles, ax_node.id)
    @test haskey(renderer.plot_handles, plot_node.id)
    @test length(renderer._observer_handles) >= 1

    # Trigger attribute change and verify Makie plot handle updates
    plot_node.attrs[:linewidth][] = 5.0
    sleep(0.05)  # let observer fire
    makie_plot = renderer.plot_handles[plot_node.id]
    @test makie_plot.linewidth[] == 5.0
end
```

### Files touched
- `src/render/renderer.jl` — new
- `src/MakieViews.jl` — modified: add include
- `test/runtests.jl` — modified: append renderer testset

### Acceptance Criterion
`Pkg.test()` exits 0. All prior testsets pass PLUS the new `M2 renderer — programmatic line plot renders` testset (Pass ≥ 4 in it).

### Commit
Subject: `feat: add Renderer with Observables-based observer registration`
Body: `Closes Task 017. Renderer walks SessionState, creates Makie axes and plot handles, registers per-attribute observers per ADR-019. Attribute change on the SessionState node → observer fires → Makie plot handle updated via its own Observable attrs. Structural changes (add/remove) use a naive full-rebuild in M2; optimization deferred. Layer 3 test verifies programmatic path end-to-end without any Gtk4 UI.`

### Report back
On pass: `TASK 017 PASSED — Renderer wired + linewidth mutation propagates to Makie plot, committed as <SHA>`
On fail: `TASK 017 FAILED — [criterion] — [Pkg.test output tail; if Makie attribute setting API differs from set!(...) or []=, name what you tried]`

---

## Task 018: Create tree pane widget (GtkListView + GtkTreeListModel) + selection wiring + Layer 3 test
**Status:** [x] Done — 2026-08-24, commit e984f3f
**Milestone:** M2
**Depends on:** 017

### What to do
This task uses Gtk4.jl v0.7.12's modern list widgets. Read the Gtk4.jl "List and Tree Widgets" manual (https://juliagtk.github.io/Gtk4.jl/stable/manual/listtreeview/) before writing code — the `GtkTreeListModel` + `GtkSignalListItemFactory` pattern is non-obvious.

**1. Create `src/ui/tree_pane.jl`** with:

- A function `build_tree_pane(session::Session)::GtkWidget` (return type is whatever Gtk4.jl calls its widget base; possibly `Gtk4.GtkListView` wrapped in a `GtkScrolledWindow`).
- Internally: builds a `GtkStringList` (or `GListModel` wrapper around session nodes), wraps in `GtkTreeListModel` for hierarchy, wraps in `GtkSingleSelection` for selection, feeds into `GtkListView` with a `GtkSignalListItemFactory` whose `bind_cb` labels each row with the node's display string (`"Figure: <title>"`, `"Axis (2D): <title>"`, `"Line: <label or id-suffix>"`).
- Selection wiring: when the `GtkSingleSelection`'s selected index changes, look up the corresponding node in the model and write its id to `session.selection[]`. Use `Gtk4.selected` / `Gtk4.selected!` per the manual.
- The tree pane also observes `session.figures` and each `axes` / `plots` Observable so that when the tree structure changes (Task 020 wires this via the app's demo-populate), the pane refreshes. For M2 the demo is populated once at launch, so the observers primarily guard against future changes.

**2. Update `src/MakieViews.jl`** to `include("ui/tree_pane.jl")`.

**3. Extend `test/runtests.jl`** with:

```julia
@testset "M2 tree pane — populates from session; selection writes to session.selection" begin
    s = new_session()
    fig_node = add_figure!(s; title = "F1")
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = 1.0:10.0 |> collect
    plot_node = add_line_plot!(ax_node; x = x, y = sin.(x))

    tree_widget = build_tree_pane(s)
    @test tree_widget !== nothing

    # The tree should list at least 3 rows (fig, axis, plot). Exact count depends on tree expansion.
    # If the API allows enumerating displayed rows: assert count >= 3.
    # Otherwise, skip that assertion and just verify the widget is realized.
    sleep(0.2)

    # Programmatically select the plot node by writing its id to selection and verifying no error:
    s.selection[] = plot_node.id
    @test s.selection[] == plot_node.id

    # If we can programmatically drive the tree's selection to fire back into session.selection,
    # test that path too. Skip if the API doesn't cleanly support it — note in commit.
end
```

Report in the PASS message which Gtk4.jl API pattern was used and which assertions were feasible.

### Files touched
- `src/ui/tree_pane.jl` — new
- `src/MakieViews.jl` — modified: add include
- `test/runtests.jl` — modified: append tree pane testset

### Acceptance Criterion
`Pkg.test()` exits 0. All prior testsets pass PLUS the new tree pane testset (Pass ≥ 2).

### Commit
Subject: `feat: add tree pane widget using GtkListView + GtkTreeListModel (Gtk4 modern API)`
Body: `Closes Task 018. Uses Gtk4.jl v0.7.12's modern list widgets, not the deprecated GtkTreeView. Selection writes to session.selection[] Observable, which Task 019's property pane observes. Tree observes session.figures / axes / plots for structural refresh.`

### Report back
On pass: `TASK 018 PASSED — tree pane populated + selection wired via <Gtk4 API pattern used>, committed as <SHA>`
On fail: `TASK 018 FAILED — [criterion] — [Pkg.test output tail; if Gtk4 API errors, quote them and name what you tried]`

---

## Task 019: Create property pane widget (schema-driven) + validation + attribute wiring + Layer 3 test
**Status:** [x] Done — 2026-08-24, commit b4e551f
**Milestone:** M2
**Depends on:** 018

### What to do

**1. Create `src/ui/property_pane.jl`** with:

- A `validate(specs::Vector{AttrSpec}, name::Symbol, value)::Union{Any, ValidationError}` function. For `:number` with `range = (lo, hi)`, check `lo <= value <= hi`. For `:enum` with `range::Vector`, check `value in range`. For `:bool`, `:string`, `:color` (any RGB), pass through. Return the value on success; return a `ValidationError` struct on failure. Define `ValidationError` locally in this file.
- A `build_property_pane(session::Session)::GtkWidget` function. Returns a Gtk4 container widget (probably `GtkBox`) that observes `session.selection[]`; whenever selection changes, it clears its children and repopulates with widgets derived from `PLOT_SCHEMAS[plot.type]` for the selected Plot node.
- A `_widget_for_spec(spec::AttrSpec, attr_observable::Observable{Any})::GtkWidget` factory: given an `AttrSpec` and the Observable holding the current value, returns the appropriate widget (`GtkColorButton` for `:color`, `GtkSpinButton` for `:number`, `GtkDropDown` for `:enum`, `GtkSwitch` for `:bool`, `GtkEntry` for `:string`) with initial value read from the Observable and an onchange callback wired: onchange calls `validate(specs, spec.name, new_value)`; on success `attr_observable[] = new_value`; on failure revert the widget to the prior value and (best-effort) print a message.
- Apply `Observables.throttle(1/60, attr_observable)` at the widget-callback boundary per DESIGN.md §5 — not on every observation site.
- Look up the exact Gtk4.jl v0.7.12 widget constructor names (`GtkSpinButton`, `GtkDropDown`, etc.) from the Gtk4.jl manual. Report which ones were used.

**2. Update `src/MakieViews.jl`** to include the property pane file.

**3. Extend `test/runtests.jl`** with:

```julia
@testset "M2 property pane — populates on selection and edits propagate" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    plot_node = add_line_plot!(ax_node; x = 1.0:10.0 |> collect, y = zeros(10))

    prop_widget = build_property_pane(s)
    @test prop_widget !== nothing

    # Selecting the plot should populate the pane. Exact widget introspection may be limited by
    # Gtk4.jl API; at minimum verify no exception is raised.
    s.selection[] = plot_node.id
    sleep(0.2)

    # Simulate a valid attribute edit by writing directly to the Observable (mimics the widget's onchange path)
    plot_node.attrs[:linewidth][] = 3.5
    @test plot_node.attrs[:linewidth][] == 3.5

    # Validate function tests
    specs = PLOT_SCHEMAS[:line]
    @test validate(specs, :linewidth, 5.0) == 5.0
    @test validate(specs, :linewidth, 100.0) isa MakieViews.ValidationError    # out of range
    @test validate(specs, :linestyle, :solid) == :solid
    @test validate(specs, :linestyle, :bogus) isa MakieViews.ValidationError   # not in enum
end
```

### Files touched
- `src/ui/property_pane.jl` — new
- `src/MakieViews.jl` — modified: add include
- `test/runtests.jl` — modified: append property pane testset

### Acceptance Criterion
`Pkg.test()` exits 0. New property pane testset passes (Pass ≥ 5 in it: widget builds, selection updates, direct-mutation propagates, valid validation returns value, invalid validation returns ValidationError).

### Commit
Subject: `feat: add schema-driven property pane with validation and 60Hz throttled attribute editing`
Body: `Closes Task 019. Property pane observes session.selection, iterates PLOT_SCHEMAS[plot.type] to construct kind-appropriate Gtk4 widgets. Widget onchange → validate → attribute Observable []= assignment, throttled at 60 Hz per DESIGN §5. No plot-type branches in UI code (per NFR-002 forward-looking constraint).`

### Report back
On pass: `TASK 019 PASSED — property pane wired + validation working + Gtk4 widget factory using <API pattern>, committed as <SHA>`
On fail: `TASK 019 FAILED — [criterion] — [Pkg.test output tail]`

---

## Task 020: Wire tree/property/viewport panes into makieviews() + end-to-end Layer 3 test
**Status:** [x] Done — 2026-08-24, commit 2df9e6f; 73 tests local
**Milestone:** M2
**Depends on:** 019

### What to do
The M2 exit-criterion integration task. Restructures `makieviews()` from M1's single-viewport pattern to the M2 three-pane layout, wires everything together, auto-populates a demo Session, and verifies the end-to-end flow.

**1. Restructure `src/MakieViews.jl`'s `makieviews()`** function:

```julia
function makieviews()
    if !(isinteractive() && isdefined(Base, :active_repl))
        @warn "MakieViews v0.1 reads variables from REPL Main. You appear to be running outside a REPL. Variables defined in this script/context so far are visible; variables you define later will not appear. File loading (CSV / HDF5) works normally."
    end

    # Build the SessionState + demo content (M2 scaffolding; M3+ replaces the auto-populate with menu-driven creation)
    session = new_session()
    fig_node = add_figure!(session; title = "Demo Figure")
    ax_node = add_axis!(fig_node; kind = :axis2d, title = "Sine wave")
    x = collect(1.0:100.0)
    y = sin.(x ./ 10)
    plot_node = add_line_plot!(ax_node; x = x, y = y)

    # Build the Gtk4 window with three panes
    w = GtkWindow("MakieViews", 1400, 900)   # wider than M1's 1024 to fit the panes

    # Right pane: Gtk4Makie viewport hosting the shared Makie.Figure (M1's mechanism, reused)
    makie_fig = Makie.Figure()
    viewport_widget = Gtk4Makie.GtkMakieWidget()
    push!(viewport_widget, makie_fig)

    # Renderer observes session, updates makie_fig
    renderer = Renderer(session, makie_fig)

    # Left column: tree pane on top, property pane below
    tree_pane = build_tree_pane(session)
    property_pane = build_property_pane(session)

    left_column = GtkBox(:v)   # vertical box
    push!(left_column, tree_pane)
    push!(left_column, property_pane)

    # Top-level split: left column | viewport
    main_paned = GtkPaned(:h)
    Gtk4.start_child(main_paned, left_column)     # exact API: verify from Gtk4.jl v0.7.12 docs
    Gtk4.end_child(main_paned, viewport_widget)

    w[] = main_paned
    show(w)

    # Stash Renderer + session in the window's data so tests can retrieve them
    # (Gtk4.jl has a mechanism for attaching arbitrary Julia data to a widget; verify from docs.
    #  Simplest fallback: return a NamedTuple instead of just w. Adjust return type accordingly —
    #  M1 tests expected `w` to be a GtkWindow; if we change to (window=w, session=session, renderer=renderer),
    #  update M1's Task-008/010 assertions accordingly.)

    return w
end
```

Given the return-type question: **either** return just `w` and stash `session`/`renderer` in a module-level `_current_session[]`, `_current_renderer[]` for test access (simpler; M2-scope compromise), **OR** change the return type to a `NamedTuple` (cleaner but requires touching M1's Task-008/010 testsets to unpack). Pick the simpler option: stash in module-level refs. Delete the refs at M3+ if a better mechanism arises.

**2. Update `test/runtests.jl`** with the M2 exit-criterion end-to-end test:

```julia
@testset "M2 end-to-end — makieviews() launches with demo tree and edit propagates" begin
    w = makieviews()
    sleep(0.5)  # let everything settle
    @test w !== nothing

    # Retrieve session + renderer from module-level refs
    session = MakieViews._current_session[]
    renderer = MakieViews._current_renderer[]
    @test length(session.figures[]) == 1
    fig_node = session.figures[][1]
    ax_node = fig_node.axes[][1]
    plot_node = ax_node.plots[][1]
    @test plot_node.type == :line

    # Simulate selection + attribute edit; verify Makie plot handle updated
    session.selection[] = plot_node.id
    sleep(0.1)
    plot_node.attrs[:linewidth][] = 4.0
    sleep(0.1)
    makie_plot = renderer.plot_handles[plot_node.id]
    @test makie_plot.linewidth[] == 4.0

    Gtk4.destroy(w)
end
```

### Files touched
- `src/MakieViews.jl` — modified: restructured `makieviews()` function; add module-level `_current_session::Ref{Union{Nothing,Session}}` and `_current_renderer::Ref{Union{Nothing,Renderer}}` refs
- `test/runtests.jl` — modified: append end-to-end testset

### Acceptance Criterion
`Pkg.test()` exits 0. All prior testsets pass PLUS the new `M2 end-to-end` testset. Total Pass count roughly 25+ across all testsets (M1: 7, M2 nodes: 4, M2 schema: 3, M2 session: 4, M2 renderer: 4, M2 tree pane: 2, M2 property pane: 5, M2 end-to-end: 4). Fail = 0. Also: `git log --oneline -1` shows the commit subject `feat: wire M2 three-pane layout with demo session, meeting M2 exit criterion`, and `git show --stat HEAD` reports exactly 2 files changed.

### Commit
Subject: `feat: wire M2 three-pane layout with demo session, meeting M2 exit criterion`
Body: `Closes Task 020, closes Milestone M2. makieviews() now builds a SessionState with a demo Figure/Axis/LinePlot, constructs a three-pane Gtk4 layout (tree | properties on left, viewport on right), and wires Renderer as observer. Auto-populate demo replaces M1's empty viewport; menu-driven node creation deferred to M3+. Module-level refs (_current_session, _current_renderer) exposed for test access; revisit at M3 if a better mechanism arises.`

### Report back
On pass: `TASK 020 PASSED — M2 end-to-end green (N tests total), <SHA>. M2 CI verification pending on push.`
On fail: `TASK 020 FAILED — [criterion] — [Pkg.test output tail + which step of the wire-up broke]`

### Post-task: push and verify CI
After Task 020's local Pkg.test() is green: `git push`. Then open https://github.com/XerxesZorgon/MakieViews/actions and verify the 2-cell v0.1 matrix (Ubuntu × {Julia 1.10, 1.12}) shows both green. Report back to Claude Chat with `M2 CI RUN 2/2 GREEN` or the failing job's log tail.

---

## M2 exit gate

When Tasks 013–020 are all `[x] Done`, all local Pkg.test() tests pass, and CI is 2/2 green on the v0.1 matrix, M2 is complete. Return to Claude Chat with "M2 complete" to extend `tasks.md` with M3 (remaining 2D plot types: scatter, bar, heatmap, contour — leverages the schema-driven pattern from M2 for near-linear extension effort).

---

## Milestone M3 — Remaining 2D plot types

**Exit criterion:** `PLOT_SCHEMAS` contains entries for `:scatter`, `:bar`, `:heatmap`, and `:contour`. The Renderer can render all four from synthetic demo data. `add_scatter_plot!`, `add_bar_plot!`, `add_heatmap_plot!`, `add_contour_plot!` exist in the session API. All Layer 1 schema tests and Layer 3 render tests for each type pass locally and CI is 2/2 green.

**Design notes:**
- All four plot types use the existing `PLOT_SCHEMAS` + `_init_attrs` + `_register_plot_observer!` pattern from M2. No new UI code required — the property panel picks up each new type automatically by iterating its schema.
- `_DEMO_DATA` is extended with optional `z`, `matrix` fields (Option A per pre-M3 design decision): `(x=..., y=..., z=..., matrix=...)`. Fields not needed by a given plot type are `nothing`. This scaffolding is removed at M5 when proper DataRef ingestion lands.
- The one place `plot.type` drives branching is `_render_plot!` in `renderer.jl` — that is legitimate and expected. The property panel and tree pane remain branchless.
- Makie function mapping: `:scatter` → `Makie.scatter!`, `:bar` → `Makie.barplot!`, `:heatmap` → `Makie.heatmap!`, `:contour` → `Makie.contour!`.
- Data shape requirements: scatter needs 1D x+y; bar needs 1D x+y (categories + heights); heatmap needs a 2D matrix (or x, y, matrix); contour needs 1D x, 1D y, 2D z matrix.

---

## Task 021: Add PLOT_SCHEMAS for scatter/bar/heatmap/contour + Layer 1 schema tests
**Status:** [x] Done — 2026-08-24, commit abfe3b2
**Milestone:** M3
**Depends on:** 020 (M2 complete)

### What to do
Two changes in one commit.

**1. Extend `src/state/schema.jl`** by appending four new schema entries after `PLOT_SCHEMAS[:line]`:

```julia
PLOT_SCHEMAS[:scatter] = [
    AttrSpec(:color,      :color,  RGB(0.8, 0.2, 0.2), nothing,           "Color",      "Marker fill color"),
    AttrSpec(:markersize, :number, 8.0,                 (1.0, 40.0),       "Marker size", "Marker diameter in points"),
    AttrSpec(:marker,     :enum,   :circle,             [:circle, :rect, :diamond, :cross, :xcross, :utriangle, :dtriangle], "Marker", "Marker shape"),
    AttrSpec(:label,      :string, "",                  nothing,           "Label",      "Legend label"),
    AttrSpec(:visible,    :bool,   true,                nothing,           "Visible",    "Show/hide this plot"),
]

PLOT_SCHEMAS[:bar] = [
    AttrSpec(:color,     :color,  RGB(0.2, 0.6, 0.2), nothing,           "Color",     "Bar fill color"),
    AttrSpec(:width,     :number, 0.8,                 (0.1, 1.0),        "Width",     "Bar width as fraction of spacing"),
    AttrSpec(:direction, :enum,   :vertical,           [:vertical, :horizontal], "Direction", "Bar orientation"),
    AttrSpec(:label,     :string, "",                  nothing,           "Label",     "Legend label"),
    AttrSpec(:visible,   :bool,   true,                nothing,           "Visible",   "Show/hide this plot"),
]

PLOT_SCHEMAS[:heatmap] = [
    AttrSpec(:colormap,   :enum,   :viridis,   [:viridis, :plasma, :inferno, :magma, :cividis, :grays, :blues, :reds], "Colormap",   "Color mapping"),
    AttrSpec(:colorrange, :vec2,   (0.0, 1.0), nothing,    "Color range", "(min, max) data range for colormap"),
    AttrSpec(:label,      :string, "",         nothing,    "Label",       "Legend label"),
    AttrSpec(:visible,    :bool,   true,        nothing,    "Visible",     "Show/hide this plot"),
]

PLOT_SCHEMAS[:contour] = [
    AttrSpec(:color,     :color,  RGB(0.3, 0.3, 0.7), nothing,       "Color",     "Contour line color"),
    AttrSpec(:levels,    :int,    10,                  (2, 50),       "Levels",    "Number of contour levels"),
    AttrSpec(:linewidth, :number, 1.0,                 (0.1, 10.0),   "Linewidth", "Contour line width"),
    AttrSpec(:label,     :string, "",                  nothing,       "Label",     "Legend label"),
    AttrSpec(:visible,   :bool,   true,                nothing,       "Visible",   "Show/hide this plot"),
]
```

Note: `colorrange` uses `:vec2` kind (two spin buttons per the property panel widget map in DESIGN.md §5). Default `(0.0, 1.0)` is a `Tuple{Float64,Float64}` which matches the `AttrSpec.default` field type `Any`.

**2. Extend `test/unit/schema.jl`** by appending four new testsets (one per type), each checking: key present in `PLOT_SCHEMAS`, required attribute names present, first attr has correct kind. Pattern mirrors the existing `:line` tests.

### Files touched
- `src/state/schema.jl` — modified: append 4 schema entries
- `test/unit/schema.jl` — modified: append 4 testsets

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass. Four new schema testsets pass (one per type). `PLOT_SCHEMAS` has exactly 5 keys: `:line`, `:scatter`, `:bar`, `:heatmap`, `:contour`.

### Commit
Subject: `feat: add PLOT_SCHEMAS for scatter, bar, heatmap, contour (M3)`
Body: `Closes Task 021. Four new schema entries using the AttrSpec pattern established in M2. Property panel picks them up automatically (no UI code changes). Layer 1 tests verify schema contents per type.`

### Report back
On pass: `TASK 021 PASSED — 5 plot schemas registered, N tests green, committed as <SHA>`
On fail: `TASK 021 FAILED — [criterion] — [Pkg.test output tail]`

---

## Task 022: add_scatter_plot! + scatter renderer branch + Layer 3 test
**Status:** [x] Done — 2026-08-24, commit 71be576
**Milestone:** M3
**Depends on:** 021

### What to do
Three changes in one commit.

**1. Extend `src/state/session.jl`** with:
```julia
# M2-only demo scaffolding, remove at M5
function add_scatter_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, plot_id::String = string(uuid4()))::Plot
    plot = Plot(plot_id, :scatter, Observable(DataRef[]), _init_attrs(:scatter), Observable{Union{Nothing,AnimBinding}}(nothing))
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=nothing)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
```

Also update `add_line_plot!`'s `_DEMO_DATA` entry to match the extended format:
```julia
_DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=nothing)
```
(was `(x=x, y=y)` — the extra fields let `_render_plot!` use a uniform access pattern)

**2. Extend `_render_plot!` in `src/render/renderer.jl`** with a scatter branch:
```julia
elseif plot.type == :scatter
    x = _DEMO_DATA[plot.id].x
    y = _DEMO_DATA[plot.id].y
    handle = Makie.scatter!(makie_ax, x, y;
        color      = plot.attrs[:color][],
        markersize = plot.attrs[:markersize][],
        marker     = plot.attrs[:marker][],
        label      = plot.attrs[:label][],
        visible    = plot.attrs[:visible][]
    )
    renderer.plot_handles[plot.id] = handle
    _register_plot_observer!(renderer, plot)
```

**3. Extend `test/runtests.jl`** with:
```julia
@testset "M3 scatter — renders without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = collect(1.0:20.0)
    y = sin.(x ./ 3)
    plot_node = add_scatter_plot!(ax_node; x = x, y = y)
    @test plot_node.type == :scatter
    @test plot_node.attrs[:markersize][] == 8.0   # schema default
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
    plot_node.attrs[:markersize][] = 15.0
    sleep(0.05)
    @test renderer.plot_handles[plot_node.id].markersize[] == 15.0
end
```

### Files touched
- `src/state/session.jl` — modified: add `add_scatter_plot!`, update `add_line_plot!` demo data format
- `src/render/renderer.jl` — modified: add `:scatter` branch in `_render_plot!`
- `test/runtests.jl` — modified: append scatter testset
- `tasks.md` — modified (staged as always)

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass plus the new scatter testset (Pass ≥ 4 in it).

### Commit
Subject: `feat: add scatter plot type (session API, renderer, schema, test)`
Body: `Closes Task 022. add_scatter_plot! + _render_plot!(:scatter) using Makie.scatter!. _DEMO_DATA format extended to (x, y, z, matrix) tuple for uniform access across all M3 types. Observer propagation tested (markersize mutation fires through to Makie handle).`

### Report back
On pass: `TASK 022 PASSED — scatter renders, observer propagates, committed as <SHA>`
On fail: `TASK 022 FAILED — [criterion] — [Pkg.test output tail; if Makie.scatter! attr name differs, quote the MethodError]`

---

## Task 023: add_bar_plot! + bar renderer branch + Layer 3 test
**Status:** [x] Done — 2026-08-24, commit 7762fea
**Milestone:** M3
**Depends on:** 022

### What to do
Same shape as Task 022 for bar plots.

**1. Extend `src/state/session.jl`**:
```julia
# M2-only demo scaffolding, remove at M5
function add_bar_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, plot_id::String = string(uuid4()))::Plot
    plot = Plot(plot_id, :bar, Observable(DataRef[]), _init_attrs(:bar), Observable{Union{Nothing,AnimBinding}}(nothing))
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=nothing)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
```

**2. Extend `_render_plot!` in `src/render/renderer.jl`**:
```julia
elseif plot.type == :bar
    x = _DEMO_DATA[plot.id].x
    y = _DEMO_DATA[plot.id].y
    direction = plot.attrs[:direction][]
    handle = if direction == :vertical
        Makie.barplot!(makie_ax, x, y;
            color   = plot.attrs[:color][],
            width   = plot.attrs[:width][],
            label   = plot.attrs[:label][],
            visible = plot.attrs[:visible][])
    else
        Makie.barplot!(makie_ax, y, x;   # horizontal: swap x/y
            color       = plot.attrs[:color][],
            width       = plot.attrs[:width][],
            direction   = :x,
            label       = plot.attrs[:label][],
            visible     = plot.attrs[:visible][])
    end
    renderer.plot_handles[plot.id] = handle
    _register_plot_observer!(renderer, plot)
```

Note: verify the exact Makie.barplot! keyword for horizontal bars — it may be `direction = :x` or a `flip = true` kwarg. Check Makie 0.24.13 docs if the above fails.

**3. Extend `test/runtests.jl`**:
```julia
@testset "M3 bar — renders without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = collect(1.0:5.0)
    y = [3.0, 1.0, 4.0, 1.0, 5.0]
    plot_node = add_bar_plot!(ax_node; x = x, y = y)
    @test plot_node.type == :bar
    @test plot_node.attrs[:direction][] == :vertical
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
end
```

### Files touched
- `src/state/session.jl` — modified
- `src/render/renderer.jl` — modified
- `test/runtests.jl` — modified
- `tasks.md` — modified

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass plus bar testset.

### Commit
Subject: `feat: add bar plot type (session API, renderer, schema, test)`
Body: `Closes Task 023. add_bar_plot! + _render_plot!(:bar) using Makie.barplot!. Direction attr drives vertical/horizontal switch.`

### Report back
On pass: `TASK 023 PASSED — bar renders, committed as <SHA>`
On fail: `TASK 023 FAILED — [criterion] — [Pkg.test tail; if Makie.barplot! horizontal kwarg differs, quote MethodError]`

---

## Task 024: add_heatmap_plot! + heatmap renderer branch + Layer 3 test
**Status:** [x] Done — 2026-08-24, commit d604b8f
**Milestone:** M3
**Depends on:** 023

### What to do
Heatmap uses a 2D matrix — the first M3 type that uses `_DEMO_DATA.matrix`.

**1. Extend `src/state/session.jl`**:
```julia
# M2-only demo scaffolding, remove at M5
function add_heatmap_plot!(ax::Axis; matrix::AbstractMatrix, plot_id::String = string(uuid4()))::Plot
    plot = Plot(plot_id, :heatmap, Observable(DataRef[]), _init_attrs(:heatmap), Observable{Union{Nothing,AnimBinding}}(nothing))
    _DEMO_DATA[plot_id] = (x=nothing, y=nothing, z=nothing, matrix=matrix)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
```

**2. Extend `_render_plot!`**:
```julia
elseif plot.type == :heatmap
    mat = _DEMO_DATA[plot.id].matrix
    handle = Makie.heatmap!(makie_ax, mat;
        colormap   = plot.attrs[:colormap][],
        colorrange = plot.attrs[:colorrange][],
        label      = plot.attrs[:label][],
        visible    = plot.attrs[:visible][])
    renderer.plot_handles[plot.id] = handle
    _register_plot_observer!(renderer, plot)
```

**3. Extend `test/runtests.jl`**:
```julia
@testset "M3 heatmap — renders without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    mat = [sin(i/5) * cos(j/5) for i in 1:20, j in 1:20]
    plot_node = add_heatmap_plot!(ax_node; matrix = mat)
    @test plot_node.type == :heatmap
    @test plot_node.attrs[:colormap][] == :viridis
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
end
```

### Files touched
- `src/state/session.jl`, `src/render/renderer.jl`, `test/runtests.jl`, `tasks.md`

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass plus heatmap testset.

### Commit
Subject: `feat: add heatmap plot type (session API, renderer, schema, test)`
Body: `Closes Task 024. add_heatmap_plot! takes a matrix argument stored in _DEMO_DATA.matrix. _render_plot!(:heatmap) uses Makie.heatmap!.`

### Report back
On pass: `TASK 024 PASSED — heatmap renders, committed as <SHA>`
On fail: `TASK 024 FAILED — [criterion] — [Pkg.test tail; if Makie.heatmap! colorrange kwarg differs, quote MethodError]`

---

## Task 025: add_contour_plot! + contour renderer branch + Layer 3 test
**Status:** [x] Done — 2026-08-24, commit 57e5ce7; M3 CI 2/2 green
**Milestone:** M3
**Depends on:** 024

### What to do
Contour uses 1D x, 1D y, and 2D z matrix — uses `_DEMO_DATA.z` and `_DEMO_DATA.matrix` together (x and y are coordinate vectors, matrix is the z surface).

**1. Extend `src/state/session.jl`**:
```julia
# M2-only demo scaffolding, remove at M5
function add_contour_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, z::AbstractMatrix, plot_id::String = string(uuid4()))::Plot
    plot = Plot(plot_id, :contour, Observable(DataRef[]), _init_attrs(:contour), Observable{Union{Nothing,AnimBinding}}(nothing))
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=z)   # store z surface in matrix field
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
```

**2. Extend `_render_plot!`**:
```julia
elseif plot.type == :contour
    x   = _DEMO_DATA[plot.id].x
    y   = _DEMO_DATA[plot.id].y
    mat = _DEMO_DATA[plot.id].matrix
    handle = Makie.contour!(makie_ax, x, y, mat;
        color     = plot.attrs[:color][],
        levels    = plot.attrs[:levels][],
        linewidth = plot.attrs[:linewidth][],
        label     = plot.attrs[:label][],
        visible   = plot.attrs[:visible][])
    renderer.plot_handles[plot.id] = handle
    _register_plot_observer!(renderer, plot)
```

**3. Extend `test/runtests.jl`**:
```julia
@testset "M3 contour — renders without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    xs = collect(LinRange(0.0, 2π, 30))
    ys = collect(LinRange(0.0, 2π, 30))
    zs = [sin(x) * cos(y) for x in xs, y in ys]
    plot_node = add_contour_plot!(ax_node; x = xs, y = ys, z = zs)
    @test plot_node.type == :contour
    @test plot_node.attrs[:levels][] == 10
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
end
```

Also: after all four types are working, update `makieviews()` in `src/MakieViews.jl` to use `add_scatter_plot!` alongside the existing `add_line_plot!` demo (just add a second plot to `ax_node` so both line and scatter appear in the viewport at launch, demonstrating multi-plot capability). This is a small addition to the same commit.

### Files touched
- `src/state/session.jl`, `src/render/renderer.jl`, `src/MakieViews.jl` (demo update), `test/runtests.jl`, `tasks.md`

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass plus contour testset. `git show --stat HEAD` reports 5 files changed.

### Commit
Subject: `feat: add contour plot type + multi-plot demo; closes M3`
Body: `Closes Task 025, closes Milestone M3. add_contour_plot! + _render_plot!(:contour) using Makie.contour!. makieviews() demo now shows both line and scatter plots in the viewport. All five 2D plot types (line, scatter, bar, heatmap, contour) are schema-registered, session-constructable, renderer-handled, and observer-wired.`

### Report back
On pass: `TASK 025 PASSED — contour renders, M3 complete locally (<SHA>). M3 CI verification pending on push.`
On fail: `TASK 025 FAILED — [criterion] — [Pkg.test tail]`

### Post-task: push and verify CI
After Task 025's local Pkg.test() is green: `git push`. Verify CI 2/2 green. Report `M3 CI RUN 2/2 GREEN` to Claude Chat.

---

## M3 exit gate

When Tasks 021–025 are all `[x] Done` and CI is 2/2 green, M3 is complete. Return to Claude Chat with "M3 complete" to extend `tasks.md` with M4 (3D plot types: surface and volume; camera controls in the property panel).

---

## Milestone M4 — 3D plot types + camera controls

**Exit criterion:** `PLOT_SCHEMAS` contains entries for `:surface` and `:volume`. `add_axis!(fig; kind = :axis3d)` produces an `Axis` whose renderer builds a real `Makie.Axis3` (not `Makie.Axis`). The Renderer can render both 3D types from synthetic demo data into that `Axis3`. `add_surface_plot!` and `add_volume_plot!` exist in the session API. A new `AXIS_SCHEMAS[:axis3d]` registry drives camera editing (azimuth/elevation/zoom); the property panel, on selecting an `:axis3d` Axis node, iterates `AXIS_SCHEMAS[:axis3d]` and renders camera editors whose edits propagate to the live `Makie.Axis3`. All Layer 1 schema tests and Layer 3 render tests for both types pass locally and CI is 2/2 green on the v0.1 matrix (Ubuntu × {Julia 1.10, 1.12}).

**Load-bearing decisions folded in:**
- **ADR-021 (new this milestone)**: axis attributes are schema-driven via an `AXIS_SCHEMAS::Dict{Symbol, Vector{AttrSpec}}` registry, parallel to `PLOT_SCHEMAS`. The property panel dispatches on the *type* of the selected node: a `Plot` id → iterate `PLOT_SCHEMAS[plot.type]`; an `Axis` id → iterate `AXIS_SCHEMAS[axis.kind]`. Camera (azimuth/elevation/zoom) is the first axis attribute group rendered this way. This is the first time the property panel edits a non-Plot node; it establishes the pattern that M2's hand-wired axis attributes (title, labels, limits) can migrate to later without a UI rewrite. Reuses the existing `AttrSpec` struct and `validate()` unchanged.
- **`Makie.Axis3` construction**: `_render_axis!` branches on `ax.kind`. `:axis2d` → `Makie.Axis(position)` (unchanged M1–M3 path); `:axis3d` → `Makie.Axis3(position)`. The `axis_handles` dict already types values as `Any` (renderer.jl), so no struct change is needed. `Axis.camera::Observable{Union{Nothing,CameraSpec}}` and `add_axis!`'s `:axis3d` acceptance already exist from M2 — no state-layer change required for those.
- **`CameraSpec` already exists** in `src/state/types.jl` with fields `azimuth::Float64`, `elevation::Float64`, `zoom::Float64`. M4 uses it as-is. Makie's `Axis3` exposes `azimuth`, `elevation` as Observables (radians) and zoom via the scene camera; the renderer maps `CameraSpec` fields onto them.
- **`_DEMO_DATA` extension**: surface needs `(x, y, matrix)` where matrix is the z-surface (same shape as contour's storage); volume needs a 3D array. `_DEMO_DATA`'s value type is `NamedTuple` (untyped), so a `volume` field can be added ad hoc for volume plots without breaking the existing `(x, y, z, matrix)` callers. M4 scaffolding, removed at M5 with the rest of `_DEMO_DATA`.
- **Renderer branch is the one legitimate `plot.type` switch**: adding `:surface`/`:volume` arms to `_render_plot!` follows the exact M3 precedent. The property panel and tree pane stay branchless on plot type; the axis-node dispatch in the property panel branches on *node kind* (Plot vs Axis), not on plot type, which is the schema-driven pattern, not a violation of it.
- **Makie API caution**: `surface!` takes `colormap`, `shading`; `volume!` takes `colormap`, `colorrange`, `algorithm`, `absorption`. Several of these accept only specific enum values (`shading ∈ (NoShading, FastShading, MultiLightShading)` as Makie types; `algorithm ∈ (:mip, :iso, :absorption, :additive)` as symbols). Where a Makie kwarg name or accepted value differs from the schema, the task's On-Failure protocol requires Antigravity to quote the exact `MethodError`/`ArgumentError` rather than guess — same protocol M3 used for `barplot!` horizontal direction.

---

## Task 026: Write ADR-021 (axis-schema pattern) + amend DESIGN.md
**Status:** [x] Done — 2026-08-25, commit 4f1e4fb
**Milestone:** M4
**Depends on:** 025 (M3 complete)

### What to do
Docs-only task — no code, no tests. Two file changes in one commit.

**1. Create `docs/adr/ADR-021-axis-schema-driven-property-editing.md`** documenting the decision to introduce an `AXIS_SCHEMAS` registry so the property panel can edit axis-level attributes (starting with camera on `:axis3d`) using the same schema-driven mechanism as plots. The ADR must follow the same structure as the existing ADRs in `docs/adr/` (read `docs/adr/ADR-017-reserve-data-inline-schema-slot.md` and `docs/adr/ADR-019-reactive-state-observables.md` for the exact heading structure this project uses — Status, Context, Decision, Consequences, Alternatives Considered). Content the ADR must state:
- **Status**: Accepted (2026-08-25).
- **Context**: Through M3, the property panel only edited `Plot` nodes via `PLOT_SCHEMAS`. M4 introduces camera controls, which are an `Axis` property (`Axis.camera`), not a plot property. Editing them schema-driven requires a schema registry for axis attributes.
- **Decision**: Introduce `const AXIS_SCHEMAS = Dict{Symbol, Vector{AttrSpec}}()` parallel to `PLOT_SCHEMAS`, keyed by `Axis.kind` (`:axis3d`, later `:axis2d`). The property panel dispatches on the selected node's Julia type: `Plot` → `PLOT_SCHEMAS[plot.type]`, `Axis` → `AXIS_SCHEMAS[axis.kind]`. Reuse `AttrSpec` and `validate()` unchanged. Camera azimuth/elevation/zoom are modeled as three `:number` specs.
- **Consequences**: First non-Plot node the property panel edits. Establishes the migration path for M2's hand-wired axis attributes (title/labels/limits) to become schema-driven in a later cleanup. No `.mvz` schema-version bump (camera already serialized per DESIGN §3.1). No change to `AttrSpec` or `validate`.
- **Alternatives Considered**: (a) A dedicated non-schema camera sub-panel — rejected because it reintroduces per-type UI branching, the exact thing NFR-002 forbids. (b) Modeling camera as a pseudo-Plot — rejected as a semantic hack that would corrupt the tree model.

**2. Amend `docs/DESIGN.md`**:
- In **§2.4 (Schema registry)**, after the `PLOT_SCHEMAS` block, add a short subsection introducing `AXIS_SCHEMAS` with a cross-reference to ADR-021, showing the `:axis3d` camera schema shape (three `:number` AttrSpecs: azimuth, elevation, zoom).
- In **§5 (Property Panel — Schema-Driven)**, amend the opening sentence so the panel's input is "the currently-selected node" (Plot *or* Axis), and add one paragraph stating the node-type dispatch rule (Plot → PLOT_SCHEMAS, Axis → AXIS_SCHEMAS) with the ADR-021 cross-reference.

Do not touch any `.jl` file in this task.

### Files touched
- `docs/adr/ADR-021-axis-schema-driven-property-editing.md` — new
- `docs/DESIGN.md` — modified: §2.4 subsection + §5 amendment

### Acceptance Criterion
`julia -e 'txt = read("docs/adr/ADR-021-axis-schema-driven-property-editing.md", String); @assert contains(txt, "AXIS_SCHEMAS"); @assert contains(txt, "Accepted"); d = read("docs/DESIGN.md", String); @assert contains(d, "AXIS_SCHEMAS"); @assert contains(d, "ADR-021"); println("ADR-021 docs OK")'` exits 0 and prints `ADR-021 docs OK`. This is a docs task, so there is no `Pkg.test()` gate; the assertion above is the full criterion.

### Commit
Subject: `docs: add ADR-021 axis-schema-driven property editing; amend DESIGN §2.4/§5`
Body: `Opens Milestone M4. ADR-021 records the decision to introduce AXIS_SCHEMAS (parallel to PLOT_SCHEMAS, keyed by Axis.kind) so the property panel edits axis-level attributes — camera first — via the same schema-driven mechanism, dispatching on selected-node type. DESIGN §2.4 gains an AXIS_SCHEMAS subsection; §5 gains the node-type dispatch rule. No code changes.`

### Report back
On pass: `TASK 026 PASSED — ADR-021 + DESIGN amendments committed as <SHA>`
On fail: `TASK 026 FAILED — [criterion] — [observed] — [error text]`

---

## Task 027: Renderer builds Makie.Axis3 when ax.kind == :axis3d + Layer 3 test
**Status:** [x] Done — 2026-08-25, commit 8b10bf4
**Milestone:** M4
**Depends on:** 026

### What to do
Two changes in one commit — code + its test. This task must land BEFORE 029/030 because surface/volume can only render into an `Axis3`. It changes only the axis-construction line; every M1–M3 test (which all use `:axis2d`) must stay green, proving the 2D path is untouched.

**1. Modify `src/render/renderer.jl`**, function `_render_axis!`. Currently its first line is unconditionally:
```julia
makie_ax = Makie.Axis(position)
```
Replace with a branch on `ax.kind`:
```julia
makie_ax = if ax.kind == :axis3d
    Makie.Axis3(position)
else
    Makie.Axis(position)
end
```
The rest of `_render_axis!` is unchanged EXCEPT: `Makie.Axis3` does not accept a `title`/`xlabel`/`ylabel` assignment in exactly the same way for every attribute — verify that `makie_ax.title[] = ax.title[]`, `makie_ax.xlabel[] = ax.xlabel[]`, `makie_ax.ylabel[] = ax.ylabel[]` all work on `Axis3` in Makie 0.24.13. They should (Axis3 has title, xlabel, ylabel, zlabel), but if any assignment throws, wrap only the failing one in a `hasproperty`/try guard and report which. Do NOT add zlabel wiring in this task — that is axis-attribute scope, not this task's concern; this task only proves Axis3 is constructed and the existing three labels apply.

The function's return type annotation is already `::Union{Makie.Axis, Makie.Axis3}` — no signature change needed.

**2. Extend `test/runtests.jl`** with:
```julia
@testset "M4 axis3d — renderer builds Makie.Axis3" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis3d, title = "3D")
    @test ax_node.kind == :axis3d
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.axis_handles, ax_node.id)
    @test renderer.axis_handles[ax_node.id] isa Makie.Axis3
end

@testset "M4 axis2d — renderer still builds Makie.Axis (regression guard)" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test renderer.axis_handles[ax_node.id] isa Makie.Axis
end
```

### Files touched
- `src/render/renderer.jl` — modified: `_render_axis!` axis-construction branch
- `test/runtests.jl` — modified: append two testsets

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0. All prior testsets still pass (no M1–M3 regression). Two new testsets pass: `M4 axis3d — renderer builds Makie.Axis3` and `M4 axis2d — renderer still builds Makie.Axis (regression guard)`.

### Commit
Subject: `feat: renderer builds Makie.Axis3 for :axis3d axes; 2D path unchanged`
Body: `Closes Task 027. _render_axis! branches on ax.kind: :axis3d → Makie.Axis3, else Makie.Axis. axis_handles already typed Any, no struct change. Regression guard testset confirms :axis2d still yields Makie.Axis. Prerequisite for surface/volume plot types (Tasks 029–030) which require an Axis3 host.`

### Report back
On pass: `TASK 027 PASSED — Axis3 built for :axis3d, 2D regression guard green, committed as <SHA>`
On fail: `TASK 027 FAILED — [criterion] — [Pkg.test tail; if an Axis3 label assignment threw, name which property and quote the error]`

---

## Task 028: Add PLOT_SCHEMAS for surface/volume + Layer 1 schema tests
**Status:** [x] Done — 2026-08-25, commit 685192f
**Milestone:** M4
**Depends on:** 027

### What to do
Two changes in one commit.

**1. Extend `src/state/schema.jl`** by appending two new schema entries after the existing five (`:line`, `:scatter`, `:bar`, `:heatmap`, `:contour`):
```julia
PLOT_SCHEMAS[:surface] = [
    AttrSpec(:colormap, :enum,   :viridis, [:viridis, :plasma, :inferno, :magma, :cividis, :grays, :blues, :reds], "Colormap", "Surface color mapping"),
    AttrSpec(:shading,  :enum,   :smooth,  [:none, :fast, :smooth], "Shading",  "Surface shading mode"),
    AttrSpec(:label,    :string, "",       nothing, "Label",   "Legend label"),
    AttrSpec(:visible,  :bool,   true,     nothing, "Visible", "Show/hide this plot"),
]

PLOT_SCHEMAS[:volume] = [
    AttrSpec(:colormap,   :enum,   :viridis,   [:viridis, :plasma, :inferno, :magma, :cividis, :grays, :blues, :reds], "Colormap",   "Volume color mapping"),
    AttrSpec(:algorithm,  :enum,   :mip,       [:mip, :iso, :absorption, :additive], "Algorithm",  "Volume rendering algorithm"),
    AttrSpec(:colorrange, :vec2,   (0.0, 1.0), nothing, "Color range", "(min, max) data range for colormap"),
    AttrSpec(:absorption, :number, 1.0,        (0.0, 10.0), "Absorption", "Absorption coefficient (:absorption algorithm)"),
    AttrSpec(:visible,    :bool,   true,       nothing, "Visible", "Show/hide this plot"),
]
```
Note: `:shading` schema uses the abstract symbols `:none/:fast/:smooth`; the renderer (Task 029) maps them to Makie's shading types. `:algorithm` uses Makie's own symbols directly (`:mip` etc. are the literal values Makie.volume! accepts). `:colorrange` uses `:vec2`; `validate` currently has no `:vec2` branch and falls through its final `return value` — acceptable (no range constraint on the tuple), same as heatmap's `:colorrange` in M3.

**2. Extend `test/unit/schema.jl`** by appending two testsets (one per type), each checking: key present, required attribute names present (surface: `:colormap`, `:shading`, `:visible`; volume: `:colormap`, `:algorithm`, `:colorrange`, `:absorption`, `:visible`), and first attr `kind` correct. Also add one assertion that `length(PLOT_SCHEMAS) == 7` (line, scatter, bar, heatmap, contour, surface, volume).

### Files touched
- `src/state/schema.jl` — modified: append 2 schema entries
- `test/unit/schema.jl` — modified: append 2 testsets + registry-size assertion

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass. Two new schema testsets pass. `PLOT_SCHEMAS` has exactly 7 keys.

### Commit
Subject: `feat: add PLOT_SCHEMAS for surface and volume (M4)`
Body: `Closes Task 028. Two 3D plot schemas using the AttrSpec pattern. Surface: colormap, shading, label, visible. Volume: colormap, algorithm, colorrange, absorption, visible. Property panel picks them up automatically. Layer 1 tests verify contents; registry now has 7 plot types.`

### Report back
On pass: `TASK 028 PASSED — 7 plot schemas registered, N tests green, committed as <SHA>`
On fail: `TASK 028 FAILED — [criterion] — [Pkg.test output tail]`

---

## Task 029: add_surface_plot! + surface renderer branch + Layer 3 test
**Status:** [x] Done — 2026-08-25, commit 088684f
**Milestone:** M4
**Depends on:** 028

### What to do
Three changes in one commit (same two-file plot-type pattern as M3 Tasks 022–025, plus the demo-data note).

**1. Extend `src/state/session.jl`** with:
```julia
# M2-only demo scaffolding, remove at M5
function add_surface_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, z::AbstractMatrix, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :surface,
        Observable(DataRef[]),
        _init_attrs(:surface),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=z)   # z-surface stored in matrix field, same as contour
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
```

**2. Extend `_render_plot!` in `src/render/renderer.jl`** with a surface branch (add as a new `elseif` arm before the closing `end`):
```julia
elseif plot.type == :surface
    x   = _DEMO_DATA[plot.id].x
    y   = _DEMO_DATA[plot.id].y
    mat = _DEMO_DATA[plot.id].matrix
    shading_map = Dict(:none => Makie.NoShading, :fast => Makie.FastShading, :smooth => Makie.MultiLightShading)
    handle = Makie.surface!(makie_ax, x, y, mat;
        colormap = plot.attrs[:colormap][],
        shading  = shading_map[plot.attrs[:shading][]],
        visible  = plot.attrs[:visible][])
    renderer.plot_handles[plot.id] = handle
    _register_plot_observer!(renderer, plot)
```
Note: `label` is in the surface schema but `Makie.surface!` may not accept a `label` kwarg (surfaces are not legend entries the same way lines are). Omit `label` from the `surface!` call as shown above. Verify `shading` accepts the mapped Makie type in 0.24.13; if `Makie.NoShading`/`FastShading`/`MultiLightShading` are not the exact names, quote the `UndefVarError` and report — do not guess an alternative.

**Observer caution**: `_register_plot_observer!` does `handle[name] = val` for every attr in `plot.attrs`. For surface, `:shading` holds an abstract symbol (`:smooth`) but the Makie handle expects a shading *type* — a raw `handle[:shading] = :smooth` will fail or mis-set. For M4, the acceptance test only mutates `:colormap` (a clean pass-through), so this is not exercised; but add an inline comment in the surface branch noting that `:shading` live-mutation needs the same `shading_map` translation and is deferred (the observer for it is registered but will error if fired — acceptable for M4 since the property panel enum for shading is not part of M4's tested path; a follow-up hardening task can gate it). If you prefer to be safe, skip registering an observer for `:shading` specifically — document whichever choice you make in the commit body.

**3. Extend `test/runtests.jl`** with:
```julia
@testset "M4 surface — renders on Axis3 without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis3d)
    xs = collect(LinRange(-3.0, 3.0, 25))
    ys = collect(LinRange(-3.0, 3.0, 25))
    zs = [exp(-(x^2 + y^2)) for x in xs, y in ys]
    plot_node = add_surface_plot!(ax_node; x = xs, y = ys, z = zs)
    @test plot_node.type == :surface
    @test plot_node.attrs[:colormap][] == :viridis
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
    @test renderer.axis_handles[ax_node.id] isa Makie.Axis3
    plot_node.attrs[:colormap][] = :plasma
    sleep(0.05)
    @test renderer.plot_handles[plot_node.id].colormap[] == :plasma
end
```

### Files touched
- `src/state/session.jl` — modified: add `add_surface_plot!`
- `src/render/renderer.jl` — modified: add `:surface` branch in `_render_plot!`
- `test/runtests.jl` — modified: append surface testset
- `tasks.md` — modified (staged as always)

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass plus the new surface testset (Pass ≥ 5 in it, including the Axis3 host assertion and colormap observer propagation).

### Commit
Subject: `feat: add surface plot type (session API, renderer, schema, test)`
Body: `Closes Task 029. add_surface_plot! stores the z-surface in _DEMO_DATA.matrix (same slot as contour). _render_plot!(:surface) uses Makie.surface! with a shading-symbol→Makie-shading-type map. Renders into the Axis3 built by Task 027. Colormap observer propagation tested; shading live-mutation deferred (see body note).`

### Report back
On pass: `TASK 029 PASSED — surface renders on Axis3, colormap observer propagates, committed as <SHA>`
On fail: `TASK 029 FAILED — [criterion] — [Pkg.test tail; if Makie.surface! kwarg or shading type name differs, quote the exact error and name what you tried]`

---

## Task 030: add_volume_plot! + volume renderer branch + Layer 3 test
**Status:** [x] Done — 2026-08-25, commit 0f865f1
**Milestone:** M4
**Depends on:** 029

### What to do
Three changes in one commit. Volume is the only M4 type needing a 3D data array — extend `_DEMO_DATA` usage with a `volume` field (ad hoc, since the NamedTuple value type is untyped).

**1. Extend `src/state/session.jl`** with:
```julia
# M2-only demo scaffolding, remove at M5
function add_volume_plot!(ax::Axis; vol::AbstractArray{<:Real,3}, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :volume,
        Observable(DataRef[]),
        _init_attrs(:volume),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=nothing, y=nothing, z=nothing, matrix=nothing, volume=vol)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
```
Note the `_DEMO_DATA` entry for volume has an extra `volume=` field the other entries lack. That is fine: entries are read by field name in `_render_plot!`, and only the volume branch reads `.volume`. Do not retrofit a `volume=nothing` field onto the other `add_*_plot!` functions — they never read it.

**2. Extend `_render_plot!` in `src/render/renderer.jl`** with a volume branch:
```julia
elseif plot.type == :volume
    vol = _DEMO_DATA[plot.id].volume
    handle = Makie.volume!(makie_ax, vol;
        colormap   = plot.attrs[:colormap][],
        algorithm  = plot.attrs[:algorithm][],
        colorrange = plot.attrs[:colorrange][],
        visible    = plot.attrs[:visible][])
    renderer.plot_handles[plot.id] = handle
    _register_plot_observer!(renderer, plot)
```
Note: `:absorption` is in the volume schema but is only meaningful for `algorithm = :absorption`; omit it from the default `volume!` call (as shown) to avoid a MethodError when the algorithm is `:mip`. `algorithm` holds a raw symbol (`:mip`) which Makie.volume! accepts directly — no translation map needed (unlike surface's shading). Verify `Makie.volume!` accepts `colorrange` as a 2-tuple in 0.24.13; if it wants a different form, quote the error and report.

**Observer caution**: same as surface — the acceptance test mutates only `:colormap` (clean pass-through via `handle[:colormap] = val`). `:algorithm`, `:colorrange`, `:absorption` live-mutation is not part of M4's tested path.

**3. Extend `test/runtests.jl`** with:
```julia
@testset "M4 volume — renders on Axis3 without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis3d)
    vol = [exp(-((i-15)^2 + (j-15)^2 + (k-15)^2)/50) for i in 1:30, j in 1:30, k in 1:30]
    plot_node = add_volume_plot!(ax_node; vol = vol)
    @test plot_node.type == :volume
    @test plot_node.attrs[:algorithm][] == :mip
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
    @test renderer.axis_handles[ax_node.id] isa Makie.Axis3
    plot_node.attrs[:colormap][] = :inferno
    sleep(0.05)
    @test renderer.plot_handles[plot_node.id].colormap[] == :inferno
end
```

### Files touched
- `src/state/session.jl` — modified: add `add_volume_plot!`
- `src/render/renderer.jl` — modified: add `:volume` branch in `_render_plot!`
- `test/runtests.jl` — modified: append volume testset
- `tasks.md` — modified

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass plus the volume testset (Pass ≥ 5 in it, including Axis3 host assertion and colormap observer propagation).

### Commit
Subject: `feat: add volume plot type (session API, renderer, schema, test)`
Body: `Closes Task 030. add_volume_plot! stores a 3D array in an ad-hoc _DEMO_DATA.volume field. _render_plot!(:volume) uses Makie.volume! with algorithm as a raw symbol; absorption omitted from the default call (only meaningful for :absorption algorithm). Renders into Axis3. Colormap observer propagation tested.`

### Report back
On pass: `TASK 030 PASSED — volume renders on Axis3, colormap observer propagates, committed as <SHA>`
On fail: `TASK 030 FAILED — [criterion] — [Pkg.test tail; if Makie.volume! kwarg differs, quote the exact error and name what you tried]`

---

## Task 031: AXIS_SCHEMAS[:axis3d] camera schema + property-panel node dispatch + Layer 3 test
**Status:** [x] Done — 2026-08-25, commit 832f566 — M4 COMPLETE, CI 2/2 green
**Milestone:** M4
**Depends on:** 030

### What to do
The M4 exit-criterion integration task. Introduces the axis-schema registry (ADR-021) and makes the property panel edit a selected `:axis3d` Axis node's camera, propagating edits to the live `Makie.Axis3`. Three source changes in one commit.

**1. Extend `src/state/schema.jl`** by adding the axis-schema registry after `PLOT_SCHEMAS` and its entries:
```julia
const AXIS_SCHEMAS = Dict{Symbol, Vector{AttrSpec}}()

AXIS_SCHEMAS[:axis3d] = [
    AttrSpec(:azimuth,   :number, 1.275, (-2π, 2π),   "Azimuth",   "Camera azimuth angle (radians)"),
    AttrSpec(:elevation, :number, 0.785, (-2π, 2π),   "Elevation", "Camera elevation angle (radians)"),
    AttrSpec(:zoom,      :number, 1.0,   (0.1, 10.0), "Zoom",      "Camera zoom factor"),
]
```
The defaults 1.275 and 0.785 are Makie's `Axis3` default azimuth (≈1.275 rad) and elevation (π/4 ≈ 0.785 rad); using them means a freshly-selected axis panel shows the true current camera state. Do NOT register `AXIS_SCHEMAS[:axis2d]` in this task — 2D axes have no camera; the dispatch (step 2) simply shows the placeholder for any axis kind with no schema entry.

**2. Modify `src/ui/property_pane.jl`** to dispatch on selected-node type. Currently `build_property_pane`'s `on(session.selection)` handler calls only `_find_plot` and `_populate_for_plot!`. Change it to:
- First try `_find_plot(session, id)`; if a Plot is found, populate for plot as now.
- Else try a new `_find_axis(session, id)::Union{Nothing, Axis}` (mirror `_find_plot`, but return the Axis whose `id` matches). If an Axis is found AND `haskey(AXIS_SCHEMAS, ax.kind)`, call a new `_populate_for_axis!(box, ax)`.
- Else show the placeholder.

Add `_find_axis`:
```julia
function _find_axis(session::Session, id::String)::Union{Nothing, Axis}
    for fig in session.figures[]
        for ax in fig.axes[]
            ax.id == id && return ax
        end
    end
    return nothing
end
```

Add `_populate_for_axis!`. It mirrors `_populate_for_plot!` but reads from `AXIS_SCHEMAS[ax.kind]` and binds each widget to a *camera-field Observable*. Camera lives as `ax.camera::Observable{Union{Nothing,CameraSpec}}` holding an immutable `CameraSpec` — not per-field Observables like `plot.attrs`. To reuse `_widget_for_spec` (which expects an `Observable{Any}` per attribute), construct a thin per-field adapter Observable for azimuth/elevation/zoom that, on change, rebuilds the `CameraSpec` and writes it back to `ax.camera`. Concretely:
```julia
function _populate_for_axis!(box::GtkBox, ax::Axis)
    specs = AXIS_SCHEMAS[ax.kind]
    # Seed a CameraSpec if the axis has none yet, so the panel has values to show.
    if ax.camera[] === nothing
        ax.camera[] = CameraSpec(1.275, 0.785, 1.0)
    end
    cam = ax.camera[]
    # Per-field adapter Observables initialised from the current CameraSpec.
    field_obs = Dict{Symbol, Observable{Any}}(
        :azimuth   => Observable{Any}(cam.azimuth),
        :elevation => Observable{Any}(cam.elevation),
        :zoom      => Observable{Any}(cam.zoom),
    )
    # When any field Observable changes, rebuild the CameraSpec and write to ax.camera.
    for (fname, obs) in field_obs
        on(obs) do _
            ax.camera[] = CameraSpec(field_obs[:azimuth][], field_obs[:elevation][], field_obs[:zoom][])
        end
    end
    for spec in specs
        widget = _widget_for_spec(specs, spec, field_obs[spec.name])
        hbox = GtkBox(:h)
        push!(hbox, GtkLabel(spec.label))
        push!(hbox, widget)
        push!(box, hbox)
    end
end
```
This keeps `_widget_for_spec` and `validate` unchanged — they already handle `:number` specs, which is all the camera schema uses.

**3. Modify `src/render/renderer.jl`** so the renderer observes `ax.camera` on an `:axis3d` axis and applies it to the `Makie.Axis3`. In `_register_axis_observer!`, after the existing label/limit observers, add (guarded to axis3d only):
```julia
    if ax.kind == :axis3d && makie_ax isa Makie.Axis3
        hc = on(ax.camera) do cam
            if cam !== nothing
                makie_ax.azimuth[]   = cam.azimuth
                makie_ax.elevation[] = cam.elevation
                # zoom: Axis3 exposes no direct scalar zoom Observable; apply via the scene if available.
                # For M4, azimuth/elevation propagation is the tested path; zoom application is best-effort.
            end
        end
        push!(renderer._observer_handles, hc)
    end
```
Verify `Makie.Axis3` exposes `azimuth` and `elevation` as settable Observables in 0.24.13 (it does in the documented API). If either name differs, quote the error and report. Zoom on Axis3 has no clean scalar Observable — the criterion below tests only azimuth/elevation propagation, so zoom being best-effort is acceptable for M4; note it in the commit body.

**4. Extend `test/runtests.jl`** with the M4 exit-criterion test:
```julia
@testset "M4 camera — selecting Axis3 populates camera editors; edit propagates to Makie.Axis3" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis3d)
    xs = collect(LinRange(-3.0, 3.0, 20)); ys = collect(LinRange(-3.0, 3.0, 20))
    zs = [exp(-(x^2 + y^2)) for x in xs, y in ys]
    add_surface_plot!(ax_node; x = xs, y = ys, z = zs)

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    prop_widget = build_property_pane(s)
    @test prop_widget !== nothing

    # AXIS_SCHEMAS registered for :axis3d
    @test haskey(AXIS_SCHEMAS, :axis3d)
    @test length(AXIS_SCHEMAS[:axis3d]) == 3

    # Select the axis node — property pane should populate without error
    s.selection[] = ax_node.id
    sleep(0.1)
    @test ax_node.camera[] !== nothing   # seeded on populate

    # Simulate a camera edit via the state layer (mimics the widget's write-back path)
    makie_ax = renderer.axis_handles[ax_node.id]
    @test makie_ax isa Makie.Axis3
    ax_node.camera[] = CameraSpec(0.5, 0.3, 1.0)
    sleep(0.05)
    @test isapprox(makie_ax.azimuth[],   0.5; atol = 1e-6)
    @test isapprox(makie_ax.elevation[], 0.3; atol = 1e-6)
end
```

Also: after the camera path is working, update `makieviews()` in `src/MakieViews.jl` to add a second demo figure OR a second axis of kind `:axis3d` bearing a surface plot, so the launched app demonstrates a 3D axis alongside the existing 2D demo. Keep it to a small addition in the same commit (a few lines: one `add_axis!(...; kind=:axis3d)`, one `add_surface_plot!`), mirroring how Task 025 added a second demo plot. If adding it complicates the single-figure layout, instead add the 3D axis to the existing figure as a second axis position — whichever is the smaller change; note which you chose.

### Files touched
- `src/state/schema.jl` — modified: add `AXIS_SCHEMAS` + `[:axis3d]` entry
- `src/ui/property_pane.jl` — modified: node-type dispatch, `_find_axis`, `_populate_for_axis!`
- `src/render/renderer.jl` — modified: camera observer in `_register_axis_observer!`
- `test/runtests.jl` — modified: append camera testset
- `src/MakieViews.jl` — modified: 3D demo addition
- `tasks.md` — modified

### Acceptance Criterion
`Pkg.test()` exits 0. All prior tests pass PLUS the new `M4 camera` testset (Pass ≥ 6 in it: AXIS_SCHEMAS registered, schema length 3, camera seeded on select, Axis3 host confirmed, azimuth propagates, elevation propagates). Also: `git show --stat HEAD` reports 6 files changed.

### Commit
Subject: `feat: add AXIS_SCHEMAS camera editing for Axis3, meeting M4 exit criterion`
Body: `Closes Task 031, closes Milestone M4. Introduces AXIS_SCHEMAS (ADR-021) with an :axis3d camera schema (azimuth/elevation/zoom as :number specs). Property panel dispatches on selected-node type: Plot → PLOT_SCHEMAS, Axis → AXIS_SCHEMAS. Camera edits rebuild CameraSpec and write to ax.camera; renderer observes ax.camera and applies azimuth/elevation to the live Makie.Axis3 (zoom best-effort, no scalar Observable). makieviews() demo now includes a 3D surface axis. _widget_for_spec and validate reused unchanged. All seven v0.1 plot types (line, scatter, bar, heatmap, contour, surface, volume) complete.`

### Report back
On pass: `TASK 031 PASSED — camera editing wired, azimuth/elevation propagate to Axis3, M4 complete locally (<SHA>). M4 CI verification pending on push.`
On fail: `TASK 031 FAILED — [criterion] — [Pkg.test tail + which step of the wire-up broke]`

### Post-task: push and verify CI
After Task 031's local Pkg.test() is green: `git push`. Verify CI 2/2 green on the v0.1 matrix. Report `M4 CI RUN 2/2 GREEN` to Claude Chat. Then run the macOS live-test per ADR-018 if due, and log to Obsidian.

---

## M4 exit gate

When Tasks 026–031 are all `[x] Done` and CI is 2/2 green on the v0.1 matrix, M4 is complete. All seven v0.1 plot types render; camera controls work on `:axis3d`. Return to Claude Chat with "M4 complete" to extend `tasks.md` with M5 (data ingestion: MainSource, CsvSource, Hdf5Source — where `_DEMO_DATA` scaffolding is finally deleted).

---

## Patch P1 — GUI launch fixes (Tier 1)

Post-M4 manual-launch findings. See `docs/CHANGE-tree-pane-viewport-fix.md`. Two independent Tier-1 fixes surfaced by the first real `makieviews()` launch, plus the manual-launch gate added to TEST_PLAN. Root causes confirmed by probe (Gtk4.jl 0.7.12): `set_child` takes no kwargs; `li[]` on a GtkStringList item returns a String directly (no `.string`); the h-paned gives all width to the left column unless the viewport gets `hexpand`/`vexpand` and the paned gets a `position`.

---

## Task 032: Patch — fix tree-pane rows (set_child + row-string accessor) + extract testable helper
**Status:** [ ] Pending
**Tier:** 1 — Patch
**Milestone:** Patch P1
**Depends on:** 031

### What to do
Three changes in one commit — two code edits in `src/ui/tree_pane.jl` plus a new unit test. Stage explicitly by name.

**1. Extract the duplicated row-building loop into a pure helper.** The label/id construction loop currently appears TWICE in `tree_pane.jl` — once inline near the top of `build_tree_pane`, once inside `refresh!()`. Replace BOTH copies with calls to a single new top-level function (define it above `build_tree_pane`):
```julia
function _build_tree_rows(session::Session)
    labels = String[]
    ids = String[]
    for fig in session.figures[]
        push!(labels, "Figure: $(fig.title[])")
        push!(ids, fig.id)
        for ax in fig.axes[]
            kind_str = ax.kind == :axis2d ? "2D" : "3D"
            push!(labels, "  Axis ($kind_str): $(ax.title[])")
            push!(ids, ax.id)
            for plot in ax.plots[]
                label_attr = get(plot.attrs, :label, nothing)
                label_str = label_attr === nothing ? plot.id[1:8] : string(label_attr[])
                push!(labels, "    $(plot.type): $label_str")
                push!(ids, plot.id)
            end
        end
    end
    return (labels, ids)
end
```
Then in `build_tree_pane`, replace the inline loop with `labels, ids = _build_tree_rows(session)`. In `refresh!()`, replace its loop body: it must refresh the CLOSURE's `labels`/`ids` (which the selection handler indexes) AND the model. Do it like this — compute fresh, then copy into the existing bound vectors so the selection closure keeps referencing the right arrays:
```julia
    function refresh!()
        new_labels, new_ids = _build_tree_rows(session)
        empty!(labels); append!(labels, new_labels)
        empty!(ids);    append!(ids, new_ids)
        splice!(model, 1:length(model))
        for l in labels
            push!(model, l)
        end
    end
```
(Keep `labels`/`ids` as the outer `local` vectors the selection handler closes over — do not shadow them.)

**2. Fix the factory callbacks.** Replace the broken `setup` and `bind` bodies:
```julia
    signal_connect(factory, "setup") do f, li
        lbl = GtkLabel("")
        lbl.halign = Gtk4.Align_START
        set_child(li, lbl)
    end
    signal_connect(factory, "bind") do f, li
        lbl = get_child(li)
        lbl.label = li[]        # li[] returns a String directly for a GtkStringList item
    end
```
(No `halign` kwarg on `set_child`; no `.string` on `li[]`. Both confirmed by probe.)

**3. Add `test/unit/tree_pane.jl`** (new file) with a testset that exercises `_build_tree_rows` on a known session — this is the headless-testable regression coverage for the data path (the GTK-realization fix itself is covered by the manual-launch gate, not CI):
```julia
@testset "tree_pane _build_tree_rows" begin
    s = new_session()
    fig = add_figure!(s; title = "F1")
    ax2 = add_axis!(fig; kind = :axis2d, title = "A2D")
    add_line_plot!(ax2; x = collect(1.0:5.0), y = collect(1.0:5.0))
    ax3 = add_axis!(fig; kind = :axis3d, title = "A3D")

    labels, ids = MakieViews._build_tree_rows(s)
    # Row count: 1 figure + 2 axes + 1 plot = 4
    @test length(labels) == 4
    @test length(ids) == 4
    @test labels[1] == "Figure: F1"
    @test occursin("Axis (2D): A2D", labels[2])
    @test occursin("line", labels[3])
    @test occursin("Axis (3D): A3D", labels[4])
    # ids align positionally with labels and are the real node ids
    @test ids[1] == fig.id
    @test ids[2] == ax2.id
    @test ids[4] == ax3.id
end
```
Ensure `test/unit/tree_pane.jl` is `include`d by `test/runtests.jl` if that's the project's include pattern (check how `test/unit/schema.jl` is wired and match it). If runtests.jl includes unit files explicitly, add the include line; report if the pattern differs.

### Files touched
- `src/ui/tree_pane.jl` — modified: extract `_build_tree_rows`, fix setup/bind callbacks, rewrite `refresh!`
- `test/unit/tree_pane.jl` — new: `_build_tree_rows` testset
- `test/runtests.jl` — modified only if unit files are explicitly included (match existing pattern)

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0. All prior tests still pass. The new `tree_pane _build_tree_rows` testset passes (7 assertions). Report Julia's `Test Summary:` tail for it.

### Regression coverage
`_build_tree_rows` testset is the added regression test (cross-tier rule). The `set_child`/`li[]` fixes are verified by the human manual-launch gate (Task 033 / TEST_PLAN), not by CI, since they require a realized display.

### Commit
Stage explicitly: `git add src/ui/tree_pane.jl test/unit/tree_pane.jl test/runtests.jl`
Subject: `fix: tree-pane rows — correct set_child call and row-string accessor (Tier 1)`
Body: `Patch P1 Task 032. Gtk4.jl set_child takes no halign kwarg (set it on the GtkLabel); li[] on a GtkStringList item returns a String directly, so .string threw. Extracted the duplicated label/id loop into pure _build_tree_rows(session) and added its first unit test. Bug surfaced by the first real makieviews() launch (M4 manual test); CI could not catch it because headless runners never realize GTK rows. See docs/CHANGE-tree-pane-viewport-fix.md.`

### Report back
On pass: `TASK 032 PASSED — tree-pane callbacks fixed, _build_tree_rows extracted + tested, committed as <SHA>. Test summary: [paste]`
On fail: `TASK 032 FAILED — [criterion] — [Pkg.test tail; if a Gtk4 accessor still differs, quote the exact error]`

---

## Task 033: Patch — fix viewport layout (paned position + hexpand/vexpand) + TEST_PLAN manual-launch gate
**Status:** [ ] Pending
**Tier:** 1 — Patch
**Milestone:** Patch P1
**Depends on:** 032

### What to do
Two changes in one commit — a code edit in `src/MakieViews.jl` and a docs edit in `docs/TEST_PLAN.md`. Stage explicitly. There is no headless test for the layout (it's GTK geometry on a real display); the acceptance evidence is the human manual launch described in the gate this task adds. So this task's automated criterion is only "Pkg.test still green + the file contains the required assignments"; the visual confirmation is John's, post-commit.

**1. Fix the layout in `src/MakieViews.jl`.** Locate the viewport/paned construction block (currently builds `viewport_widget`, `left_column = GtkPaned(:v)`, `main_paned = GtkPaned(:h)`). Add, after `viewport_widget` is created and pushed, and after `main_paned` is assembled:
```julia
    viewport_widget.hexpand = true
    viewport_widget.vexpand = true
```
and after `main_paned[1] = left_column; main_paned[2] = viewport_widget`:
```julia
    main_paned.position = 300   # px: left column width; viewport takes the remainder
```
Keep the existing `left_column`/`main_paned` wiring otherwise unchanged. (Values confirmed by probe: default paned gives all width to child 1; hexpand+vexpand on the viewport plus a position boundary gives the viewport the majority width.)

**2. Add the manual-launch gate to `docs/TEST_PLAN.md`.** Add a new subsection (after the CI-matrix section) titled "Manual GUI launch gate" stating:
- Headless CI (Ubuntu, ADR-018) never realizes a GTK widget tree, so it cannot detect GUI-layer defects (tree-pane rows, pane layout, viewport rendering, live camera/attribute edits). This was proven at M4 when the first real launch found three such defects that CI had reported green.
- Therefore: **every milestone that touches the UI, renderer, or entrypoint requires a human `makieviews()` launch on John's Windows dev machine as an exit gate**, in addition to CI. The launch follows a visual checklist: (a) window opens at 1400×900; (b) three panes visible — tree (top-left, populated rows), properties (bottom-left), viewport (right, majority width); (c) 2D axis shows its plots; (d) 3D axis renders and is rotatable; (e) selecting a plot node shows its property editors; selecting a 3D axis node shows camera editors; (f) a camera azimuth edit rotates the 3D view.
- This gate sits alongside the macOS live-test gate (ADR-018) which remains a hard gate before the v0.1.0 registry tag (M11).
- Note the gate cannot retroactively cover P1's own layout fix; the launch immediately following P1 is that fix's acceptance evidence.

### Files touched
- `src/MakieViews.jl` — modified: viewport hexpand/vexpand + paned position
- `docs/TEST_PLAN.md` — modified: add "Manual GUI launch gate" subsection

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 (no regression). AND a source assertion:
`julia -e 't = read("src/MakieViews.jl", String); @assert occursin("hexpand = true", t); @assert occursin("position = 300", t); p = read("docs/TEST_PLAN.md", String); @assert occursin("Manual GUI launch gate", p); println("P1 layout + gate OK")'` prints `P1 layout + gate OK`.
Final acceptance is John's manual launch (see gate) — Antigravity does NOT need to launch the GUI.

### Commit
Stage explicitly: `git add src/MakieViews.jl docs/TEST_PLAN.md`
Subject: `fix: viewport layout — paned position + viewport hexpand/vexpand; add manual-launch gate (Tier 1)`
Body: `Patch P1 Task 033. main_paned gave all width to the left column; viewport now sets hexpand/vexpand and main_paned.position=300 so the GLMakie canvas takes the majority width (probe-confirmed). Adds a Manual GUI launch gate to TEST_PLAN: headless CI is blind to the GUI layer, so every UI-touching milestone now requires a human makieviews() launch with a visual checklist, alongside the ADR-018 macOS gate. See docs/CHANGE-tree-pane-viewport-fix.md.`

### Report back
On pass: `TASK 033 PASSED — layout fixed + gate documented, committed as <SHA>. Test summary: [paste]. Awaiting John's manual launch for visual confirmation.`
On fail: `TASK 033 FAILED — [criterion] — [output]`

### Post-task
After 033 commits and Pkg.test is green: `git push`, verify CI 2/2 green. Then John runs `makieviews()` manually and reports the visual checklist result. Do NOT close Patch P1 until the manual launch confirms window + rows + viewport + 3D + camera. Also update CHANGELOG.md [Unreleased] with both Task 032 and 033 entries (fold into the 033 commit or a tiny follow-up — note which).

---

## Patch P1 exit gate

When Tasks 032–036 are `[x] Done`, CI 2/2 green, AND John's manual launch confirms the visual checklist, Patch P1 is complete.

**P1 COMPLETE — 2026-08-26. CI 2/2 green (run 32979090425). Manual launch passed all checklist items.** Patch tasks: 032 (d96409a), 033 (553a5a6), 034 (ae7e110), 035 (56fa4d1), 036 (9ae5ac4).

**Bug D (deferred):** clicking inside the 2D sine-wave cell also routes mouse events to the 3D surface axis — a focus/event-routing issue in the GLMakie embedding. Does not block M5+. Deferred to Patch P2.

---

## ⚠ Recovery note — Tasks 034–060 blocks lost 2026-08-27

On 2026-08-27, during Task 062, Antigravity ran `git checkout tasks.md`, which discarded the uncommitted working-tree copy of this file. `tasks.md` had not been committed since the Task 033 era, so the full task blocks for **Tasks 034–060** (the Patch P1 tail and Milestones M5–M9) were lost from this document. **No code, tests, or git history was affected** — every commit 034–060 is intact in `git log`, and milestone records are in `SESSION_LOG.md`, `PLAN.md` §5, and Obsidian. Prevention: `tasks.md` is now committed after edits, and AGENTS.md forbids Antigravity from running `git checkout` / `stash` / `clean` / `add` on it.

Recovered milestone summary (from SESSION_LOG.md / PLAN.md §5):

| Milestone | Status | Delivered | Tests |
|---|---|---|---|
| M5 — Data ingestion | ✅ 2026-08-26 | MainSource / CsvSource / Hdf5Source, DataRef, `ingest!`, `add_plot!`; `_DEMO_DATA` retired | 162 |
| M6 — Session persistence | ✅ 2026-08-26 | `save_session` / `load_session`, schema-version check, unknown-node preservation, DataRef provenance, `build_dataref` | 189 |
| M7 — Animations | ✅ 2026-08-26 | `AnimBinding`, `animate_plot!`, `render_animation` (.gif/.mp4 via `Makie.record`), GtkScale time-slider, animation_binding observer | 200 |
| M8 — Static export | ✅ 2026-08-26 | `export_figure` (PNG/SVG/PDF via CairoMakie), golden-image SHA-256 for all 7 plot types | 225 |
| M9 — Preferences (Tasks 057–060) | ✅ 2026-08-26 (CI 33107717452) | Scratch.jl `preferences.toml` (independent schema_version), seed-on-new, `reset_to_preferences!`, `set_theme!` grep-gate | 236 |

Exact per-task commit SHAs are in `git log`. Verbatim task blocks for 034–036 can be re-added from this session's Claude Chat transcript on request.

---

## Milestone M10 — Pre-flight dataset check

**Exit criterion:** TEST_PLAN.md §8 pre-flight tests green on the 2-cell v0.1 CI matrix (`ubuntu-latest × {Julia 1.10, 1.12}`). The coarse fallback FPS formula (DESIGN §7.2) ships for v0.1; the full 3-machine measurement pass is deferred to M11 pre-release QA (John's decision 2026-08-27, option C). **ADR-020** authored recording the deferral; DESIGN §7 / §11 mark ODQ-5 resolved-with-fallback. Manual spot-check guard before sign-off (John's Windows box): 2–3 real loads at the heaviest combos (surface and volume at ~1e6 and ~1e7 points) confirm the fallback predicts *lower* fps than observed — i.e. it errs toward over-warning, never under-warning.

**FPS decision (2026-08-27 — option C).** Ship the coarse fallback formula, defer the full measurement pass to M11's QA sweep, guard the fallback with the spot-check above. Rationale: the measurement pass needs GL-capable hardware on all three OSes (macOS unavailable until M11) and cannot run in the headless one-at-a-time loop; a single-OS table would look authoritative while covering a third of the target; the fallback's failure direction (over-warn = one dialog click) is the safe one per ADR-015. Recorded as ADR-020 at Task 065.

**Task authoring.** M10 tasks are authored one at a time as predecessors go green (same gated pattern as Patch P1), because each task's acceptance criteria depend on the concrete struct/signature the prior task lands. Provisional sequence (titles only; full blocks written as each is reached):
1. Task 061 — `preflight/detect.jl`: `detect_host_specs` (RAM, CPU threads, best-effort GPU VRAM).
2. Task 062 — `preflight/estimate.jl`: `estimate_footprint` (bytes) + `estimate_fps` (fallback formula, `user_scale` clamp, 0.5 when VRAM undetectable).
3. Task 063 — `preflight/downsample.jl`: `UniformStride`, `MinMaxDecimation`, `LTTB` (ADR-010 / DESIGN §7.3).
4. Task 064 — pre-flight decision function (`:accept` / `:downsample` / `:override` given specs + footprint) + threshold logic (>60% VRAM OR est_fps < 15) + `Plot.attrs[:downsample_algorithm]` recording; Gtk4 warning dialog gated behind manual launch, decision logic headless + CI-tested.
5. Task 065 — author **ADR-020** (deferral decision); mark ODQ-5 resolved-with-fallback in DESIGN §7 / §11.
6. Task 066 — PLAN.md M10 + CHANGELOG; push + CI.

---

## Task 061: preflight/detect.jl — detect_host_specs (RAM, CPU threads, best-effort GPU VRAM)
**Status:** [x] Done — 2026-08-27, commit 1ff9942
**Milestone:** M10
**Depends on:** 060

### What to do
Create `src/preflight/detect.jl` defining a `HostSpecs` struct and `detect_host_specs()::HostSpecs`, and wire it into the module. `HostSpecs` fields: `total_memory_bytes::Int` (`Sys.total_memory()`), `cpu_threads::Int` (`Sys.CPU_THREADS`), `vram_bytes::Union{Nothing,Int}` (best-effort; `nothing` when undetectable, SDD FR-026), `gpu_name::Union{Nothing,String}`. `detect_host_specs()` calls a private `_detect_gpu()` wrapped in `try/catch` returning `(nothing, nothing)` on any failure, guarding each probe with `Sys.which(...)`: NVIDIA via `nvidia-smi --query-gpu=memory.total,name --format=csv,noheader,nounits` (MiB→bytes); macOS via `system_profiler SPDisplaysDataType` (parse `VRAM (Total)`); else `(nothing, nothing)`. No native dep / jll. Include after `persistence/preferences.jl`. Headless test in new `test/integration/preflight.jl` (included from runtests.jl) asserts the struct populates and never throws with GPU absent.

### Files touched
- `src/preflight/detect.jl` — new
- `src/MakieViews.jl` — add `include("preflight/detect.jl")`
- `test/integration/preflight.jl` — new
- `test/runtests.jl` — include the new file

### Acceptance Criterion
`Pkg.test()` exits 0, all prior tests green PLUS `M10 detect_host_specs — host detection populates and never throws` (5 assertions). Contract-only on CI (no GPU); VRAM-reading branches verified at the M10 spot-check. **PASSED** — 5/5, commit 1ff9942.

---

## Task 062: preflight/estimate.jl — estimate_footprint + estimate_fps (fallback formula)
**Status:** [x] Done — 2026-08-27, commit 5f1a646
**Milestone:** M10
**Depends on:** 061

### What to do
Create `src/preflight/estimate.jl`: `estimate_footprint(a) = length(a)*sizeof(eltype(a))`; `estimate_fps(plot_type, n_points, host) = base/sqrt(max(n_points,1)/1e6) * _user_scale(host)`, base 60.0 (2D) / 30.0 (3D types `:surface`,`:volume`). `_user_scale(host)` = 0.5 when `vram_bytes === nothing`, else `clamp(vram_bytes / REFERENCE_VRAM_BYTES, 0.1, 10.0)`. `const REFERENCE_VRAM_BYTES = 8 * 1024^3` (provisional mid-range 2020-class reference GPU; real reference deferred to M11, recorded in ADR-020). `const _3D_PLOT_TYPES = (:surface, :volume)`. No new imports. Include after `preflight/detect.jl`. Append two testsets to `test/integration/preflight.jl`.

### Files touched
- `src/preflight/estimate.jl` — new
- `src/MakieViews.jl` — add `include("preflight/estimate.jl")` after detect
- `test/integration/preflight.jl` — append footprint + fps testsets

### Acceptance Criterion
`Pkg.test()` exits 0, all prior green PLUS `M10 estimate_footprint` (3) + `M10 estimate_fps — fallback formula + user_scale` (8). **PASSED** — 3/3 + 8/8, commit 5f1a646.

---

## Task 063: preflight/downsample.jl — UniformStride, MinMaxDecimation, LTTB
**Status:** [x] Done — 2026-08-27, commit e261fa1
**Milestone:** M10
**Depends on:** 062

### What to do
Create `src/preflight/downsample.jl` implementing the three ADR-010 / DESIGN §7.3 algorithms over 1-D `(x, y)` vectors, and wire it in. All three preserve the first and last point and preserve monotonic x (they select input indices in increasing order).

```julia
abstract type DownsampleAlgorithm end
struct UniformStride    <: DownsampleAlgorithm; k::Int end
struct MinMaxDecimation <: DownsampleAlgorithm; n_buckets::Int end
struct LTTB             <: DownsampleAlgorithm; n_target::Int end

# 1) Uniform stride: every k-th point, first + last always included.
function downsample(algo::UniformStride, x::AbstractVector, y::AbstractVector)
    k = max(algo.k, 1)
    idx = collect(1:k:length(x))
    if isempty(idx) || last(idx) != length(x)
        push!(idx, length(x))
    end
    return (x[idx], y[idx])
end

# 2) Min/max decimation: per bucket keep the min-y and max-y points (x-order); first + last included.
function downsample(algo::MinMaxDecimation, x::AbstractVector, y::AbstractVector)
    n = length(x)
    nb = max(algo.n_buckets, 1)
    n <= 2 && return (x[1:n], y[1:n])
    idx = Int[1]
    bs = n / nb
    for b in 1:nb
        lo = floor(Int, (b - 1) * bs) + 1
        hi = min(floor(Int, b * bs), n)
        lo > hi && continue
        imin = lo + argmin(@view y[lo:hi]) - 1
        imax = lo + argmax(@view y[lo:hi]) - 1
        a, c = minmax(imin, imax)
        for i in (a, c)
            i != last(idx) && push!(idx, i)
        end
    end
    last(idx) != n && push!(idx, n)
    return (x[idx], y[idx])
end

# 3) LTTB (Steinarsson 2013): largest-triangle-three-buckets; exactly n_target points.
function downsample(algo::LTTB, x::AbstractVector, y::AbstractVector)
    n = length(x)
    thr = algo.n_target
    (thr >= n || thr < 3) && return (collect(float.(x)), collect(float.(y)))
    xout = Vector{Float64}(undef, thr); yout = Vector{Float64}(undef, thr)
    xout[1] = x[1]; yout[1] = y[1]
    bs = (n - 2) / (thr - 2)
    a = 1
    for i in 1:(thr - 2)
        cur_lo = floor(Int, (i - 1) * bs) + 2
        cur_hi = min(floor(Int, i * bs) + 1, n - 1)
        next_lo = floor(Int, i * bs) + 2
        next_hi = min(floor(Int, (i + 1) * bs) + 1, n - 1)
        if next_lo > next_hi
            avg_x = float(x[n]); avg_y = float(y[n])
        else
            avg_x = 0.0; avg_y = 0.0
            for j in next_lo:next_hi
                avg_x += x[j]; avg_y += y[j]
            end
            cnt = next_hi - next_lo + 1
            avg_x /= cnt; avg_y /= cnt
        end
        ax = float(x[a]); ay = float(y[a])
        max_area = -1.0; chosen = cur_lo
        for j in cur_lo:cur_hi
            area = abs((ax - avg_x) * (float(y[j]) - ay) - (ax - float(x[j])) * (avg_y - ay))
            if area > max_area
                max_area = area; chosen = j
            end
        end
        xout[i + 1] = x[chosen]; yout[i + 1] = y[chosen]
        a = chosen
    end
    xout[thr] = x[n]; yout[thr] = y[n]
    return (xout, yout)
end
```

No new imports (`floor`, `argmin`, `argmax`, `minmax`, `float` are Base). Add `include("preflight/downsample.jl")` to `src/MakieViews.jl` after the `include("preflight/estimate.jl")` line. No exports — tests qualify with `MakieViews.`. Create a **new** `test/unit/downsample.jl` (per TEST_PLAN §12) and include it from `test/runtests.jl`, matching how `test/unit/schema.jl` is already included:

```julia
@testset "M10 downsample — UniformStride" begin
    x = collect(1.0:100.0); y = x .^ 2
    x2, y2 = MakieViews.downsample(MakieViews.UniformStride(10), x, y)
    @test x2[1] == 1.0 && x2[end] == 100.0
    @test issorted(x2)
    @test length(x2) == length(y2)
    @test length(x2) <= length(x)
    @test all(in(x), x2)
end

@testset "M10 downsample — MinMaxDecimation" begin
    x = collect(1.0:1000.0); y = sin.(x ./ 10)
    nb = 50
    x2, y2 = MakieViews.downsample(MakieViews.MinMaxDecimation(nb), x, y)
    @test x2[1] == 1.0 && x2[end] == 1000.0
    @test issorted(x2)
    @test length(x2) == length(y2)
    @test length(x2) <= 2 * nb + 2
    @test maximum(y2) ≈ maximum(y)     # envelope: global extremes retained
    @test minimum(y2) ≈ minimum(y)
end

@testset "M10 downsample — LTTB" begin
    x = collect(1.0:1000.0); y = sin.(x ./ 10)
    thr = 100
    x2, y2 = MakieViews.downsample(MakieViews.LTTB(thr), x, y)
    @test length(x2) == thr
    @test length(y2) == thr
    @test x2[1] == 1.0 && x2[end] == 1000.0
    @test issorted(x2)
    xs = collect(1.0:10.0); ys = xs .^ 2       # n_target >= n returns original length
    xo, yo = MakieViews.downsample(MakieViews.LTTB(50), xs, ys)
    @test length(xo) == 10
end
```

### Files touched
- `src/preflight/downsample.jl` — new: `DownsampleAlgorithm` + three algorithms + `downsample` methods
- `src/MakieViews.jl` — modified: add `include("preflight/downsample.jl")` after estimate
- `test/unit/downsample.jl` — new: the three testsets above
- `test/runtests.jl` — modified: include `unit/downsample.jl`, matching the existing unit-include pattern

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 with all prior tests still green PLUS the three new testsets (`M10 downsample — UniformStride` = 5 assertions, `M10 downsample — MinMaxDecimation` = 6, `M10 downsample — LTTB` = 5) passing. Report the `Test Summary:` counts. AND a source assertion:
`julia -e 't = read("src/preflight/downsample.jl", String); for s in ("UniformStride","MinMaxDecimation","LTTB","function downsample"); @assert occursin(s, t) "$s missing"; end; m = read("src/MakieViews.jl", String); @assert occursin("preflight/downsample.jl", m) "include not wired"; println("Task 063 source OK")'` exits 0 and prints `Task 063 source OK`.

### Commit
Stage explicitly: `git add src/preflight/downsample.jl src/MakieViews.jl test/unit/downsample.jl test/runtests.jl`
Subject: `feat: preflight/downsample.jl — UniformStride, MinMaxDecimation, LTTB (M10)`
Body: `Task 063. Three ADR-010 / DESIGN §7.3 downsampling algorithms over 1-D (x,y): UniformStride (every k-th, first+last kept); MinMaxDecimation (per-bucket min-y/max-y, envelope-preserving); LTTB (Steinarsson 2013 largest-triangle-three-buckets, exactly n_target points). All preserve first/last and monotonic x. downsample(algo, x, y) -> (x', y'). Unit tests (test/unit/downsample.jl) cover length, endpoint preservation, monotonicity, subset (stride), envelope extremes (minmax), exact target length + n_target>=n passthrough (LTTB).`

### Report back
On pass: `TASK 063 PASSED — three downsamplers green, <N> tests, committed as <SHA>. Test summary: [paste]`
On fail: `TASK 063 FAILED — [criterion] — [Pkg.test tail; quote the failing @test line verbatim]`

---

## Task 064: preflight/check.jl — threshold decision + downsample recording (headless)
**Status:** [x] Done — 2026-08-27, commit 8eeb940
**Milestone:** M10
**Depends on:** 063

### What to do
Create `src/preflight/check.jl` with the headless pre-flight decision logic (the Gtk4 warning dialog and the data-reduction apply are Task 064b, manual-gated — not this task). Three functions:

```julia
# Threshold: warn if fps too low OR footprint would blow past 60% of VRAM.
# FR-026: when VRAM is undetectable (nothing), only the fps criterion applies.
function over_threshold(host::HostSpecs, est_bytes::Integer, est_fps::Real)::Bool
    return est_fps < 15 || (host.vram_bytes !== nothing && est_bytes > 0.6 * host.vram_bytes)
end

# Full decision for one array + plot type. `decision` is :accept (load full, no dialog)
# or :warn (over threshold — caller shows the dialog in 064b). `reason` ∈ :ok/:fps/:vram/:both.
function preflight_decision(host::HostSpecs, array::AbstractArray, plot_type::Symbol)
    est_bytes = estimate_footprint(array)
    est_fps   = estimate_fps(plot_type, length(array), host)
    fps_over  = est_fps < 15
    vram_over = host.vram_bytes !== nothing && est_bytes > 0.6 * host.vram_bytes
    over = fps_over || vram_over
    reason = !over ? :ok : (fps_over && vram_over) ? :both : fps_over ? :fps : :vram
    return (decision = over ? :warn : :accept, reason = reason,
            est_fps = est_fps, est_bytes = est_bytes)
end

# Record the chosen downsample algorithm on the plot (DESIGN §7.3). Serialization of the
# algorithm into .mvz is handled by the persistence/docs task, not here.
function record_downsample!(plot::Plot, algo::DownsampleAlgorithm)
    plot.attrs[:downsample_algorithm] = Observable{Any}(algo)
    return plot
end
```

`check.jl` uses `HostSpecs` (detect.jl), `estimate_footprint`/`estimate_fps` (estimate.jl), `DownsampleAlgorithm` (downsample.jl), and `Plot`/`Observable` (state) — all already included before it. Add `include("preflight/check.jl")` to `src/MakieViews.jl` after the `include("preflight/downsample.jl")` line. No exports. **Append** two testsets to `test/integration/preflight.jl`:

```julia
@testset "M10 preflight_decision — threshold logic" begin
    host = MakieViews.HostSpecs(32 * 1024^3, 16, 8 * 1024^3, "GPU")  # 8 GiB VRAM

    d1 = MakieViews.preflight_decision(host, zeros(Float64, 1000), :line)
    @test d1.decision == :accept
    @test d1.reason == :ok

    d2 = MakieViews.preflight_decision(host, zeros(Float64, 100_000_000), :line)  # fps 6 < 15
    @test d2.decision == :warn
    @test d2.est_fps < 15

    # predicate directly (isolating the VRAM term from the fps term):
    @test MakieViews.over_threshold(host, 5 * 1024^3, 60.0) == true    # bytes > 0.6*8GiB, fps ok
    @test MakieViews.over_threshold(host, 1000, 60.0) == false         # both ok

    novram = MakieViews.HostSpecs(32 * 1024^3, 16, nothing, nothing)   # FR-026: fps-only
    @test MakieViews.over_threshold(novram, 100 * 1024^3, 60.0) == false  # VRAM term ignored
    @test MakieViews.over_threshold(novram, 100 * 1024^3, 10.0) == true   # fps < 15 → over
end

@testset "M10 record_downsample! — records algorithm in plot attrs" begin
    s = MakieViews.new_session()
    fig = MakieViews.add_figure!(s; title = "F")
    ax = MakieViews.add_axis!(fig; kind = :axis2d, title = "A")
    p = MakieViews.add_plot!(ax, :line,
        [MakieViews.DataRef(:x, "s1", :main, "x"), MakieViews.DataRef(:y, "s2", :main, "y")])
    @test !haskey(p.attrs, :downsample_algorithm)
    MakieViews.record_downsample!(p, MakieViews.LTTB(50))
    @test haskey(p.attrs, :downsample_algorithm)
    @test p.attrs[:downsample_algorithm][] == MakieViews.LTTB(50)
end
```

(The 4-arg `DataRef(role, snapshot_id, source, id)` form is the one used in `MakieViews.jl`'s demo; `LTTB(50) == LTTB(50)` holds because the algorithm structs are immutable.)

### Files touched
- `src/preflight/check.jl` — new: `over_threshold`, `preflight_decision`, `record_downsample!`
- `src/MakieViews.jl` — modified: add `include("preflight/check.jl")` after downsample
- `test/integration/preflight.jl` — modified: append the two testsets above

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 with all prior tests still green PLUS the two new testsets (`M10 preflight_decision — threshold logic` = 8 assertions, `M10 record_downsample! — records algorithm in plot attrs` = 3) passing. Report the `Test Summary:` counts. AND a source assertion:
`julia -e 't = read("src/preflight/check.jl", String); for s in ("function over_threshold","function preflight_decision","function record_downsample!"); @assert occursin(s, t) "$s missing"; end; m = read("src/MakieViews.jl", String); @assert occursin("preflight/check.jl", m) "include not wired"; println("Task 064 source OK")'` exits 0 and prints `Task 064 source OK`.

### Commit
Stage explicitly: `git add src/preflight/check.jl src/MakieViews.jl test/integration/preflight.jl` (do NOT touch tasks.md — per AGENTS.md).
Subject: `feat: preflight/check.jl — threshold decision + downsample recording (M10)`
Body: `Task 064. Headless pre-flight decision: over_threshold(host, bytes, fps) = fps<15 OR bytes>0.6*VRAM (VRAM term skipped when undetectable, FR-026). preflight_decision(host, array, plot_type) returns (:accept|:warn, reason, est_fps, est_bytes). record_downsample!(plot, algo) records the chosen algorithm in plot.attrs[:downsample_algorithm] (DESIGN §7.3; .mvz serialization deferred to the persistence/docs task). The Gtk4 warning dialog + data-reduction apply are Task 064b (manual-gated). Tests cover accept/warn, the fps and VRAM terms in isolation, the FR-026 no-VRAM path, and the recording.`
Then report `git show --stat --oneline -s HEAD`.

### Report back
On pass: `TASK 064 PASSED — threshold + recording green, <N> tests, committed as <SHA>. Test summary: [paste]` + the `--stat`.
On fail: `TASK 064 FAILED — [criterion] — [Pkg.test tail; quote the failing @test line verbatim]`

---

## Task 064b: preflight/check.jl — apply_downsample! (materialize reduced, retain full)
**Status:** [x] Done — 2026-08-27, commit 6d50567
**Milestone:** M10
**Depends on:** 064

### What to do
Append `apply_downsample!` and a private `_repoint` helper to `src/preflight/check.jl` (no new file, no MakieViews.jl change — check.jl is already included). This is the 1-D (x, y) downsample-apply path per DESIGN §7.1 "apply + hold full ref" and TEST_PLAN §8: it materializes the reduced arrays as new snapshots, repoints the plot's `:x`/`:y` refs to them, records the algorithm, and leaves the full arrays in `session.data_snapshots` (retained for a v0.2 full-resolution re-render). 2-D field stride (heatmap/surface/contour/volume) is a separate mechanism (ADR-010) and out of scope here — the function requires `:x` and `:y` refs and throws otherwise.

```julia
# Repoint an immutable DataRef to a new snapshot id, preserving all other fields.
_repoint(r::DataRef, new_snap::String) =
    DataRef(r.role, new_snap, r.source, r.label,
            r.absolute_path, r.relative_path, r.column, r.dataset, r.variable)

# Apply a downsample to a 1-D (x,y) plot: materialize reduced snapshots, repoint the
# :x/:y refs, record the algorithm, and keep the full arrays in data_snapshots.
function apply_downsample!(session::Session, plot::Plot, algo::DownsampleAlgorithm)
    refs = plot.data_refs[]
    xi = findfirst(r -> r.role == :x, refs)
    yi = findfirst(r -> r.role == :y, refs)
    (xi === nothing || yi === nothing) && throw(ArgumentError(
        "apply_downsample! requires :x and :y data refs (1-D plots); 2-D field stride is separate"))
    xfull = session.data_snapshots[refs[xi].snapshot_id]
    yfull = session.data_snapshots[refs[yi].snapshot_id]
    rx, ry = downsample(algo, xfull, yfull)
    rxid = string(uuid4()); ryid = string(uuid4())
    session.data_snapshots[rxid] = rx
    session.data_snapshots[ryid] = ry
    newrefs = copy(refs)
    newrefs[xi] = _repoint(refs[xi], rxid)
    newrefs[yi] = _repoint(refs[yi], ryid)
    plot.data_refs[] = newrefs
    record_downsample!(plot, algo)
    return plot
end
```

`uuid4()` is in scope (MakieViews `using UUIDs`; session.jl already uses `string(uuid4())`). **Append** this testset to `test/integration/preflight.jl`:

```julia
@testset "M10 apply_downsample! — reduces plot data, retains full" begin
    s = MakieViews.new_session()
    fig = MakieViews.add_figure!(s; title = "F")
    ax = MakieViews.add_axis!(fig; kind = :axis2d, title = "A")
    n = 10_000
    xfull = collect(1.0:n); yfull = sin.(xfull ./ 100)
    s.data_snapshots["xfull"] = xfull
    s.data_snapshots["yfull"] = yfull
    p = MakieViews.add_plot!(ax, :line,
        [MakieViews.DataRef(:x, "xfull", :main, "x"),
         MakieViews.DataRef(:y, "yfull", :main, "y")])

    MakieViews.apply_downsample!(s, p, MakieViews.LTTB(100))

    refs = p.data_refs[]
    xref = refs[findfirst(r -> r.role == :x, refs)]
    yref = refs[findfirst(r -> r.role == :y, refs)]
    @test length(s.data_snapshots[xref.snapshot_id]) == 100     # reduced to target
    @test length(s.data_snapshots[yref.snapshot_id]) == 100
    @test xref.snapshot_id != "xfull"                           # refs repointed
    @test haskey(s.data_snapshots, "xfull")                     # full retained (TEST_PLAN §8)
    @test length(s.data_snapshots["xfull"]) == n
    @test p.attrs[:downsample_algorithm][] == MakieViews.LTTB(100)

    # 2-D field plot (no :x/:y) is rejected
    ax3 = MakieViews.add_axis!(fig; kind = :axis3d, title = "S")
    s.data_snapshots["m"] = rand(4, 4)
    ps = MakieViews.add_plot!(ax3, :surface, [MakieViews.DataRef(:matrix, "m", :main, "m")])
    @test_throws ArgumentError MakieViews.apply_downsample!(s, ps, MakieViews.UniformStride(2))
end
```

### Files touched
- `src/preflight/check.jl` — modified: append `_repoint` + `apply_downsample!`
- `test/integration/preflight.jl` — modified: append the testset above

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 with all prior tests still green PLUS the new `M10 apply_downsample! — reduces plot data, retains full` testset (7 assertions) passing. Report the `Test Summary:` counts. AND a source assertion:
`julia -e 't = read("src/preflight/check.jl", String); @assert occursin("function apply_downsample!", t) "apply_downsample! missing"; @assert occursin("_repoint", t) "_repoint missing"; println("Task 064b source OK")'` exits 0 and prints `Task 064b source OK`.

### Commit
Stage explicitly: `git add src/preflight/check.jl test/integration/preflight.jl` (do NOT touch tasks.md — per AGENTS.md).
Subject: `feat: preflight apply_downsample! — materialize reduced, retain full (M10)`
Body: `Task 064b. apply_downsample!(session, plot, algo) for 1-D (x,y) plots: runs downsample on the full x/y snapshots, stores the reduced arrays as new snapshots, repoints the plot's :x/:y DataRefs (via immutable-preserving _repoint), records the algorithm, and leaves the full arrays in session.data_snapshots (DESIGN §7.1 "apply + hold full ref"; v0.2 full-res re-render). Requires :x/:y refs; throws ArgumentError for 2-D field plots (stride is separate per ADR-010). Test: 10k->100 reduction, refs repointed, full retained, algo recorded, 2-D rejection.`
Then report `git show --stat --oneline -s HEAD`.

### Report back
On pass: `TASK 064b PASSED — apply_downsample! green, <N> tests, committed as <SHA>. Test summary: [paste]` + the `--stat`.
On fail: `TASK 064b FAILED — [criterion] — [Pkg.test tail; quote the failing @test line verbatim]`

---

## Task 065: ADR-020 + ODQ-5 closure (docs, authored in Claude Chat)
**Status:** [x] Done — 2026-08-27 (no code; docs)
**Milestone:** M10
**Depends on:** 064b

### What to do
Author **ADR-020** recording the option-C decision — ship the coarse fallback formula for v0.1, defer the full FPS measurement pass to the M11 pre-release QA sweep — with the concrete pinned parameters (fallback formula; `REFERENCE_VRAM_BYTES = 8 GiB`; the `>60% VRAM OR est_fps < 15` thresholds; the `:accept`/`:warn` decision surface; the manual spot-check guard). Mark **ODQ-5 resolved-with-fallback** in DESIGN §7.2 and §11. Pure docs — no code, no Antigravity; authored directly in Claude Chat and committed alongside tasks.md.

### Files touched
- `docs/adr/ADR-020-defer-fps-measurement-to-m11.md` — new
- `docs/DESIGN.md` — §7.2 (coarse fallback ships for v0.1; measurement → M11; `REFERENCE_VRAM_BYTES`) + §11 ODQ-5 row (resolved-with-fallback, + ADR-020 link)

### Acceptance Criterion
ADR-020 exists and states the deferral + option C with the pinned parameters; DESIGN §11 ODQ-5 row reads "resolved-with-fallback" and links ADR-020; DESIGN §7.2 reflects the fallback shipping for v0.1. No code change → CI unaffected (still green at HEAD). Verified in Claude Chat via the applied edit diffs.

---

## Task 064c: preflight/check.jl — add_plot_checked! (REPL pre-flight-aware add)
**Status:** [x] Done — 2026-08-27, commit 1762c1c
**Milestone:** M10
**Depends on:** 064b

### What to do
Append `add_plot_checked!` to `src/preflight/check.jl` and export it. This is the v0.1 pre-flight *surface* (option C, John's decision 2026-08-27): a REPL-facing wrapper around `add_plot!` that runs `preflight_decision` on the largest of the plot's arrays and, on `:warn` without a `downsample=` kwarg, emits an advisory `@warn` (estimated MB, fps, reason) but still adds the plot at full size — matching DESIGN §7.1's Accept/Override → load-full default. Passing `downsample=<algo>` adds the plot and applies the reduction (no warning). No Gtk4 modal in v0.1 (deferred to v0.2 with a GUI load flow, per ADR-020).

```julia
"""
    add_plot_checked!(ax, plot_type, data_refs; session, host, downsample) -> (plot, decision, reason)

Pre-flight-aware `add_plot!`. Runs `preflight_decision` on the largest referenced
array; on `:warn` with no `downsample=`, emits an advisory `@warn` and still adds the
plot at full size. `downsample=<DownsampleAlgorithm>` adds then reduces (no warning).
"""
function add_plot_checked!(ax::Axis, plot_type::Symbol, data_refs::Vector{DataRef};
                           session::Session = _current_session[],
                           host::HostSpecs = detect_host_specs(),
                           downsample::Union{Nothing, DownsampleAlgorithm} = nothing)
    session === nothing && throw(ArgumentError("add_plot_checked! needs an active session"))
    arrays = [session.data_snapshots[r.snapshot_id]
              for r in data_refs if haskey(session.data_snapshots, r.snapshot_id)]
    dec = isempty(arrays) ?
          (decision = :accept, reason = :ok, est_fps = Inf, est_bytes = 0) :
          preflight_decision(host, argmax(length, arrays), plot_type)
    plot = add_plot!(ax, plot_type, data_refs)
    if downsample !== nothing
        apply_downsample!(session, plot, downsample)
    elseif dec.decision == :warn
        @warn "MakieViews pre-flight: this $plot_type plot is large and may run slowly or freeze the GUI." estimated_MB = round(dec.est_bytes / 1e6; digits = 1) estimated_fps = round(dec.est_fps; digits = 1) reason = dec.reason tip = "pass downsample=LTTB(n) (or UniformStride / MinMaxDecimation) to reduce it"
    end
    return (plot = plot, decision = dec.decision, reason = dec.reason)
end
```

Add `add_plot_checked!` to the `export` list in `src/MakieViews.jl` (right after `add_plot!`). `argmax(length, arrays)` (Julia ≥1.7) returns the longest array. **Append** this testset to `test/integration/preflight.jl`:

```julia
@testset "M10 add_plot_checked! — pre-flight-aware add" begin
    s = MakieViews.new_session()
    fig = MakieViews.add_figure!(s; title = "F")
    ax = MakieViews.add_axis!(fig; kind = :axis2d, title = "A")
    host_big  = MakieViews.HostSpecs(32 * 1024^3, 16, 8 * 1024^3, "GPU")
    host_tiny = MakieViews.HostSpecs(32 * 1024^3, 16, 1000, "TinyGPU")   # forces VRAM-over on any array

    s.data_snapshots["sx"] = collect(1.0:1000.0); s.data_snapshots["sy"] = sin.((1.0:1000.0) ./ 50)
    r1 = MakieViews.add_plot_checked!(ax, :line,
        [MakieViews.DataRef(:x, "sx", :main, "x"), MakieViews.DataRef(:y, "sy", :main, "y")];
        session = s, host = host_big)
    @test r1.decision == :accept
    @test r1.plot !== nothing

    s.data_snapshots["bx"] = collect(1.0:1000.0); s.data_snapshots["by"] = sin.((1.0:1000.0) ./ 50)
    r2 = @test_logs (:warn, r"pre-flight") match_mode=:any MakieViews.add_plot_checked!(ax, :line,
        [MakieViews.DataRef(:x, "bx", :main, "x"), MakieViews.DataRef(:y, "by", :main, "y")];
        session = s, host = host_tiny)
    @test r2.decision == :warn
    @test r2.plot !== nothing            # advisory: still added at full size

    s.data_snapshots["dx"] = collect(1.0:1000.0); s.data_snapshots["dy"] = sin.((1.0:1000.0) ./ 50)
    r3 = MakieViews.add_plot_checked!(ax, :line,
        [MakieViews.DataRef(:x, "dx", :main, "x"), MakieViews.DataRef(:y, "dy", :main, "y")];
        session = s, host = host_tiny, downsample = MakieViews.LTTB(50))
    @test r3.plot !== nothing
    @test r3.plot.attrs[:downsample_algorithm][] == MakieViews.LTTB(50)
    xref = r3.plot.data_refs[][findfirst(r -> r.role == :x, r3.plot.data_refs[])]
    @test length(s.data_snapshots[xref.snapshot_id]) == 50   # reduced on the downsample path
end
```

### Files touched
- `src/preflight/check.jl` — modified: append `add_plot_checked!`
- `src/MakieViews.jl` — modified: add `add_plot_checked!` to the `export` list (after `add_plot!`)
- `test/integration/preflight.jl` — modified: append the testset above

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 with all prior tests still green PLUS the new `M10 add_plot_checked! — pre-flight-aware add` testset (8 assertions) passing. Report the `Test Summary:` counts. AND a source assertion:
`julia -e 't = read("src/preflight/check.jl", String); @assert occursin("function add_plot_checked!", t) "add_plot_checked! missing"; m = read("src/MakieViews.jl", String); @assert occursin("add_plot_checked!", m) "not exported"; println("Task 064c source OK")'` exits 0 and prints `Task 064c source OK`.

### Manual launch (John, at M10 sign-off)
In a REPL after `makieviews()`: build a large-ish x/y (e.g. `1e6` points), `ingest!` them, and call `add_plot_checked!(ax, :line, refs)` — confirm the `@warn` prints estimated MB/fps; then call again with `downsample=LTTB(1000)` and confirm no warning + a reduced plot.

### Commit
Stage explicitly: `git add src/preflight/check.jl src/MakieViews.jl test/integration/preflight.jl` (do NOT touch tasks.md — per AGENTS.md).
Subject: `feat: add_plot_checked! — REPL pre-flight-aware add (M10, option C)`
Body: `Task 064c. add_plot_checked!(ax, type, refs; session, host, downsample) wraps add_plot!: runs preflight_decision on the largest referenced array; on :warn without downsample=, emits an advisory @warn (est MB/fps/reason) and still adds the plot full (DESIGN §7.1 Accept/Override default); downsample=<algo> adds then applies apply_downsample!. Exported. v0.1 pre-flight surface per ADR-020 (option C) — no Gtk4 modal (deferred to v0.2). Tests: accept (silent), warn (advisory, full add), downsample (reduced, no warn).`
Then report `git show --stat --oneline -s HEAD`.

### Report back
On pass: `TASK 064c PASSED — add_plot_checked! green, <N> tests, committed as <SHA>. Test summary: [paste]` + the `--stat`.
On fail: `TASK 064c FAILED — [criterion] — [Pkg.test tail; quote the failing @test line verbatim]`

---

## Task 066: M10 close — PLAN + CHANGELOG + push + CI + manual launch/spot-check
**Status:** [x] Done — 2026-08-27. CI #37 (1f7e0ff) 2/2 green; `makieviews()` launches from a real terminal (VS Code's REPL doesn't pump the Gtk4 loop — not a bug); `add_plot_checked!` `@warn` confirmed (reason `:vram`). Spot-check passes in substance: at `user_scale = 0.5` (no `nvidia-smi` → VRAM `nothing`), the 1e6 surface (predicted 15, accept) renders fine and everything heavier warns — no over-prediction into a freeze zone. Carryovers to M11 QA: (a) VRAM-parsing branch unverified (no NVIDIA GPU on the dev box); (b) interactive fps through the embedded window (blocked by Bug E). Test total ~294 (confirm from CI log).
**Milestone:** M10
**Depends on:** 064c, 065

### What to do
Docs applied in Claude Chat: PLAN.md M10 marked **COMPLETE** + §4 `check.jl` added; CHANGELOG `[Unreleased]` M10 entry. Then John commits the pending docs, pushes, verifies CI, and runs the manual launch + fallback spot-check.

### Files touched
- `docs/PLAN.md` — M10 COMPLETE + §4 `check.jl` (Claude Chat)
- `CHANGELOG.md` — M10 `[Unreleased]` entry (Claude Chat)
- `tasks.md` — this block + Task 064c done-mark

### Acceptance Criterion (M10 exit)
1. `git push`; CI 2/2 green (`ubuntu-latest × {1.10, 1.12}`), full suite (~294 tests — confirm the exact total from the run).
2. Manual launch: `makieviews()` opens; `add_plot_checked!` with a large-ish array prints the `@warn` (est MB/fps); `downsample=LTTB(n)` reduces with no warning.
3. Fallback spot-check (Windows box): surface + volume at ~1e6 and ~1e7 points — observed fps ≥ `estimate_fps` (the fallback under-predicts, never over-predicts).
M10 is COMPLETE when 1–3 pass. If CI is red or the spot-check shows the fallback over-predicting on a heavy case, reopen (adjust `REFERENCE_VRAM_BYTES` / `base_fps` and re-run).

### Report back
`M10 COMPLETE — CI 2/2 green (run <id>), <N> tests. Manual launch + spot-check: [result].` — or the specific failure.

---

## Task 067: Bug E hotfix — tree pane refresh! uses empty!, not splice! (Tier 1)
**Status:** [x] Done — 2026-08-27, commit 143cbf9. CI #38 2/2 green (both cells). Bug E fixed: `refresh!` clears via `empty!(model)`. Regression test covers the `add_figure!` post-launch path; `add_axis!` post-launch is blocked by **Bug F** (renderer deadlock — filed separately), so the test isolates `add_figure!`.
**Milestone:** Patch P2 (post-M10)
**Depends on:** —

### What to do
In `src/ui/tree_pane.jl`, inside the `refresh!()` closure of `build_tree_pane`, replace `splice!(model, 1:length(model))` with `empty!(model)`. The existing `push!(model, l)` refill loop is unchanged. Root cause: Gtk4.jl defines no `splice!(::GtkStringList, ::UnitRange)`, so any post-launch node addition (figure/axis/plot — which fires the `session.figures`/`axes`/`plots` observers → `refresh!`) throws `MethodError`. Latent since M2 (the demo tree is built before the refresh observers are wired). `empty!(model)` confirmed working on this Gtk4.jl (2026-08-27 probe); `splice` is not exposed. Add a regression test (`test/integration/tree_refresh.jl`, included from runtests.jl) that builds the window via `makieviews()`, does a post-launch `add_figure!`/`add_axis!`, and asserts no throw + row growth via `_build_tree_rows`. (CI already builds Gtk4 widgets + calls `makieviews()` headlessly under xvfb in the M1 suite, so this runs in CI — no manual gate.)

### Files touched
- `src/ui/tree_pane.jl` — one line: `splice!(model, 1:length(model))` → `empty!(model)`
- `test/integration/tree_refresh.jl` — new: regression testset
- `test/runtests.jl` — include `integration/tree_refresh.jl`

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 with all prior tests still green PLUS the new `Bug E — tree pane survives post-launch node additions` testset passing. Report the `Test Summary:` counts. AND: `julia -e 't = read("src/ui/tree_pane.jl", String); @assert occursin("empty!(model)", t); @assert !occursin("splice!(model", t); println("Task 067 source OK")'` prints `Task 067 source OK`.

### Regression test (required, Tier-1 rule)
Reproduces the exact crash: `makieviews()` → post-launch `add_figure!`/`add_axis!` → (old code threw at tree_pane.jl:62; fixed code does not) + row count grows.

### Change Description
`docs/CHANGE-bug-E-tree-refresh.md` (Tier-1 record).

### Commit
Stage: `git add src/ui/tree_pane.jl test/integration/tree_refresh.jl test/runtests.jl` (NOT tasks.md).
Subject: `fix: tree pane refresh! clears via empty!, not splice! (Bug E)`

### Report back
On pass: `TASK 067 PASSED — Bug E fixed, <N> tests, committed as <SHA>. Test summary: [paste]` + `--stat`.
On fail: `TASK 067 FAILED — [criterion] — [Pkg.test tail; quote the failing @test line verbatim]`

---

## Bug F (deferred to v0.2): structural mutation of a displayed window hangs
**Status:** Filed — deferred to v0.2 (John's decision 2026-08-27). Documented as a v0.1 limitation; no v0.1 code change.
**Component:** `src/render/renderer.jl` (live-update path)

### Symptom
After `makieviews()` shows the window, adding/removing a figure/axis/plot (e.g. `add_axis!`, `add_plot!`) hangs the REPL and freezes the window — no error, must kill the process. Confirmed in a standalone terminal (not an integrated-REPL artifact).

### Root cause
The Renderer's structural observers (`on(session.figures)`, `on(fig.axes)`, `on(ax.plots)`) each do `empty!(renderer.fig)` + a full `_rebuild_from_session!` on any change. Rebuilding (new Makie axes + shader recompile) synchronously while the window is live and drawing deadlocks against the running render loop. Compounding: `_rebuild_from_session!` re-registers observers on every rebuild without removing the old ones — an accumulating leak → cascading/re-entrant rebuilds.

### Scope (what still works in v0.1)
- **Build-then-display**: construct the session in the REPL, THEN `makieviews()` — the rebuild runs once, before the window is live. Fine. This is the demo path and v0.1's intended workflow (ADR-011).
- **Live attribute edits** (color, title, limits) — update the Makie handle in place, no rebuild. Fine.
- Only live **structural** mutation of a displayed window hangs.

### v0.2 fix direction
Incremental live-update (add just the new axis/plot; don't nuke the whole figure) + remove stale observers before re-registering + schedule GL work via a Gtk4 idle callback rather than inline. Pairs with the deferred GUI load flow + Gtk4 warning modal (064c) — all "edit a displayed session" work lands together in v0.2.

### v0.1 disposition
Documented limitation (build-then-display). Same deferred bucket as Patch P2 items D4 / Bug D.

---

# M11 — Cross-OS packaging + registration

Milestone frontier as of 2026-08-28. Per **ADR-022**, v0.1.0 ships the REPL-driven core. Strict one-at-a-time execution gate. **Antigravity task: 068 only.** 069 is Claude-Chat docs; 070–075 are maintainer-run (John) audit / QA / release steps.

---

## Task 068: render_session convenience helper (headless render → Renderer)
**Status:** [x] Done — 2026-08-28, commit fc25312. Full suite green locally (72 testsets, all pass; ~308 assertions), including new `M11 render_session — headless render + export` (3 assertions). Source assertion (`Task 068 source OK`) also passed. Antigravity's initial "137 tests" report was a truncated summary pane, not a regression — verified by re-running and pasting the full `Test Summary:` block. CI verification is Task 071.
**Milestone:** M11
**Depends on:** —

### What to do
Add an exported one-line helper `render_session(session) -> Renderer` to `src/render/renderer.jl` so headless export doesn't force users to touch `Makie` directly. Today a user must write `MakieViews.Renderer(s, MakieViews.Makie.Figure())`; `render_session` wraps that. Define it next to the `Renderer` constructor: build a fresh `Makie.Figure()` (accessible module-internally), pass it to the existing `Renderer(session, fig)` constructor (which renders synchronously via `_rebuild_from_session!`), and return the `Renderer`. Export `render_session` from `src/MakieViews.jl` (right after `export_figure`). Then create a new integration test file and include it from `runtests.jl`.

```julia
"""
    render_session(session::Session) -> Renderer

Render `session` into a fresh Makie figure and return the `Renderer`. Convenience for
headless export and animation: `export_figure(render_session(s), "out.png")`.
"""
render_session(session::Session) = Renderer(session, Makie.Figure())
```

New file `test/integration/render_session.jl`:
```julia
@testset "M11 render_session — headless render + export" begin
    s = MakieViews.new_session()
    fig = MakieViews.add_figure!(s; title = "F")
    ax = MakieViews.add_axis!(fig; kind = :axis2d, title = "A")
    s.data_snapshots["x"] = collect(1.0:50.0)
    s.data_snapshots["y"] = sin.((1.0:50.0) ./ 10)
    MakieViews.add_plot!(ax, :line,
        [MakieViews.DataRef(:x, "x", :main, "x"), MakieViews.DataRef(:y, "y", :main, "y")])
    r = MakieViews.render_session(s)
    @test r isa MakieViews.Renderer
    mktempdir() do dir
        out = joinpath(dir, "rs.png")
        MakieViews.export_figure(r, out)
        @test isfile(out)
        @test filesize(out) > 0
    end
end
```
Add `include("integration/render_session.jl")` to `test/runtests.jl` alongside the other `integration/` includes.

### Files touched
- `src/render/renderer.jl` — append `render_session`
- `src/MakieViews.jl` — export `render_session` (after `export_figure`)
- `test/integration/render_session.jl` — new: testset above
- `test/runtests.jl` — include the new file

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0 with all prior tests still green PLUS the new `M11 render_session — headless render + export` testset (3 assertions) passing. Report the `Test Summary:` counts. AND a source assertion:
`julia -e 't = read("src/render/renderer.jl", String); @assert occursin("render_session", t) "render_session missing"; m = read("src/MakieViews.jl", String); @assert occursin("render_session", m) "not exported"; println("Task 068 source OK")'` exits 0 and prints `Task 068 source OK`.

### Commit
Stage explicitly: `git add src/render/renderer.jl src/MakieViews.jl test/integration/render_session.jl test/runtests.jl` (do NOT touch tasks.md — per AGENTS.md).
Subject: `feat: render_session helper — headless render to Renderer (M11)`
Body: `Task 068. render_session(session) -> Renderer wraps Renderer(session, Makie.Figure()) so headless export/animation doesn't require users to reach into MakieViews.Makie. Exported; matches the README v0.1 Quickstart. Test: build a line session, render_session, assert Renderer + non-empty PNG via export_figure.`
Then report `git show --stat --oneline -s HEAD`.

### Report back
On pass: `TASK 068 PASSED — render_session green, <N> tests, committed as <SHA>. Test summary: [paste]` + the `--stat`.
On fail: `TASK 068 FAILED — [criterion] — [Pkg.test tail; quote the failing @test line verbatim]`

---

## Task 069: Defer FPS measurement pass to v0.2 (docs, authored in Claude Chat)
**Status:** [x] Done — 2026-08-28 (docs; no code). ADR-020 updated (H1 retitled timeless; "Update 2026-08-28" block records M11 → v0.2 target move; Decision + Consequences reflect the refined target). DESIGN.md §7.2 + §11 ODQ-5 now say "v0.2" (also stripped a JSON metadata junk block — third file from the 2026-08-28 ~14:12 batch). PLAN.md M11 carryovers: FPS measurement pass moved out to v0.2 note; (a) interactive-fps, (b) VRAM parse retained. ADR-020 filename kept per John's decision — avoids cascading link updates across README/SDD/DESIGN/PLAN/ADR-022/tasks.md; H1 now timeless.
**Milestone:** M11
**Depends on:** —

### What to do
Record the decision (John, 2026-08-28) to **defer the measurement-driven FPS lookup (`fps_lookup.jl`) to v0.2**, keeping the coarse conservative fallback for v0.1.0. The fallback under-predicts and never over-predicts (M10 spot-check), so it is safe to ship. Update **ADR-020** (note: the M11 measurement pass is now deferred to v0.2 — the multi-OS timing runs are disproportionate for v0.1 given the safe fallback), **DESIGN.md** §11 ODQ-5 row + §7.2 ("deferred to the M11 QA pass" → "deferred to v0.2"), and **PLAN.md** M11 carryover (a). Pure docs — no code, no Antigravity; authored in Claude Chat and committed alongside tasks.md.

### Files touched
- `docs/adr/ADR-020-defer-fps-measurement-to-m11.md` — measurement pass now → v0.2
- `docs/DESIGN.md` — §11 ODQ-5 + §7.2 wording: M11 → v0.2
- `docs/PLAN.md` — M11 carryover (a): measurement pass → v0.2

### Acceptance Criterion
ADR-020, DESIGN §11/§7.2, and PLAN M11 all state the FPS measurement pass is deferred to v0.2 (fallback ships for v0.1). No code change → CI unaffected (still green at HEAD). Verified in Claude Chat via the applied edit diffs.

---

## Task 070: Release-readiness audit (Claude Chat + John)
**Status:** [x] Done — 2026-08-28 (docs; no code). `docs/RELEASE-READINESS.md` authored. Decisions recorded: (1) compat pins — keep exact `Makie = "=0.24.13"` / `GLMakie = "=0.13.13"` (GLMakie upstream-pins Makie exactly, so loosening gives no immediate resolver freedom; AutoMerge accepts exact pins per RegistryCI guidelines; first-release reproducibility over nimbleness); (2) version — 0.1.0-DEV → 0.1.0 at Task 075; (3) LICENSE ✓ (MIT verified), README ✓ (reconciled ADR-022), CHANGELOG ✓ (Task 069); (4) CHANGELOG finalize plan — move dev history under new "Pre-release history" heading beneath [0.1.0], reset [Unreleased], swap PLACEHOLDER-USER → XerxesZorgon. Repo confirmed at [XerxesZorgon/MakieViews.jl](https://github.com/XerxesZorgon/MakieViews.jl) via user screenshot (my web_fetches were serving stale GitHub-cached HTML). Post-v0.1.0 follow-up captured: in-package update-check helper (v0.2 candidate). No blocking issues.
**Milestone:** M11
**Depends on:** 068, 069

### What to do
Pre-registration audit of package metadata and release docs:
1. **Project.toml compat** — decide the exact pins `Makie = "=0.24.13"`, `GLMakie = "=0.13.13"`: General AutoMerge permits them but flags overly-tight compat, and they block downstream upgrades. Options: keep exact (Gtk4Makie pins Makie upstream anyway) or loosen to `"0.24"` / `"0.13"`. Decide + record rationale. Confirm every non-stdlib dep has a `[compat]` entry and `julia` has a lower bound (✓ "1.10").
2. **Version** — plan the `0.1.0-DEV` → `0.1.0` bump (applied in Task 075 at the release commit).
3. **LICENSE / README / semver** — LICENSE present + MIT (✓); README accurate (✓ reconciled, ADR-022); CHANGELOG `[0.1.0]` entries complete; semver = 0.1.0 correct for a first release.
4. **CHANGELOG finalize plan** — at release, move `[0.1.0] — TBD` to a dated release and fold in the relevant `[Unreleased]` items.

### Files touched
- `Project.toml` — any agreed compat edit (or note deferring it to Task 075)
- `docs/RELEASE-READINESS.md` — optional: the audit note

### Acceptance Criterion
A written readiness note resolving the compat-pin decision, confirming LICENSE/README/semver, and listing the exact CHANGELOG + version edits for Task 075. Each of the four items has a recorded decision; no blocking metadata issue remains.

---

## Task 071: Full-suite CI green at the release candidate (CI)
**Status:** [x] Done — 2026-08-28. CI run #40 both green on commit `4d053a7` (`ubuntu-latest × {Julia 1.10, 1.12}` per ADR-018). Test count 72 testsets / ~308 assertions — unchanged since Task 068 (`fc25312`), as Tasks 069 and 070 are docs-only. HEAD (`4d053a7`) is the pre-RC state; Task 075's version-bump commit will re-run CI as its own final gate.
**Milestone:** M11
**Depends on:** 070

### What to do
On the release-candidate commit, confirm the 2-cell CI matrix (`ubuntu-latest × {Julia 1.10, 1.12}`, per ADR-018) runs the full suite green. Record the run id and exact test count.

### Acceptance Criterion
CI 2/2 green on the RC commit; full suite (confirm exact total). Report: `CI <run-id> 2/2 green, <N> tests`.

---

## Task 072: Windows 11 manual full-suite run (John)
**Status:** [x] Done — 2026-08-28. Windows 11 full suite: 72 testsets, all pass (~308 assertions). Two cosmetic warnings noted (not blocking):
- `ModernGL.ContextNotAvailable` at process exit (GLMakie/Gtk4Makie teardown ordering on Windows; fires after "tests passed", affects no test result; known upstream issue).
- `Volume ... not supported by cairo right now` during M8 export (CairoMakie limitation; test passes because file is produced; pre-existing).
Interactive: `makieviews()` launched, demo rendered (2D sine+scatter + 3D surface), 3D axis rotated by mouse, live attribute edit reflected in viewport. ✓
**Milestone:** M11
**Depends on:** 071

### What to do
On the Windows 11 dev box: `julia --project=. -e 'using Pkg; Pkg.test()'`, then `makieviews()` from a real terminal (not the VS Code integrated REPL — it doesn't pump the Gtk4 loop) → window opens, demo renders, 3D axis rotates, one live attribute edit (title/color) reflects.

### Acceptance Criterion
`Pkg.test()` exits 0 (report count); `makieviews()` opens and the demo is interactive (rotate + one live attribute edit). Report: `Windows: tests <N> green; launch + interact OK` — or the specific failure.

---

## Task 073: GHA macOS runner — headless full-suite CI on macos-latest (per ADR-023)
**Status:** [x] Done (attempted + closed) — 2026-08-28. Two attempts confirmed macOS CI is infeasible for v0.1.0 without architectural changes:
- Task 073: GHA macos-latest (Apple Silicon) fails at GLMakie precompilation with `NSGL FORMAT_UNAVAILABLE` — `using MakieViews` unconditionally loads GLMakie/Gtk4Makie which require a display context.
- Task 073b: A separate `test/runtests_cairo.jl` entry point also fails — `using MakieViews` still loads GLMakie at `src/MakieViews.jl:3` before any test code runs.

**Outcome:** CI matrix reverted to Ubuntu-only (2 cells). `test/runtests_cairo.jl` removed. `ci.yml` restored to the original 2-cell xvfb-run shape. CI #45 (commit `39ca32b`) 2/2 green, confirming the revert is clean. ADR-023 updated with both attempt outcomes. macOS CI requires conditional backend loading (guard GLMakie/Gtk4 imports behind env var or Preferences.jl) — v0.2 backlog item. See ADR-023 for full record.
**Milestone:** M11
**Depends on:** 071

### What to do
Per ADR-023: extend the CI matrix to include `macos-latest × {Julia 1.10, 1.12}` alongside the existing `ubuntu-latest` cells. The full matrix becomes `{ubuntu-latest, macos-latest} × {"1.10", "1.12"}` (4 cells). No `xvfb-run` on macOS (native window server). Keep every existing Ubuntu step unchanged. Run the full `Pkg.test()` suite on macos-latest, exactly as on Ubuntu. If the Gtk4/GLMakie stack cannot initialize in the headless macOS runner (unproven pattern for MakieViews specifically — see ADR-023 fallback), report the specific error verbatim and stop; do NOT weaken the test scope without amending ADR-023. Do not touch anything outside `.github/workflows/`.

This is an Antigravity task. Its instruction will be generated separately after Claude reads the current workflow file structure (`.github/workflows/*`) to write a delta-only instruction. Do not begin implementation until that instruction is generated.

### Files touched
- `.github/workflows/*.yml` — extend the OS matrix. Exact file(s) to modify determined by current workflow structure (verified before instruction generation).

### Acceptance Criterion
After the change is pushed, the next CI run on `main` is 4/4 cells green (`{ubuntu-latest, macos-latest} × {Julia 1.10, 1.12}`), running the full test suite. Report the run id and the test count per cell.

### On Failure
Report the failing cell(s), grep the workflow log for `ERROR` / `FAIL`, and paste ~20 lines of context. Categorize the failure: (a) Gtk4/GLMakie init failure on macOS specifically (needs ADR-023 fallback), (b) a MakieViews test that fails on macOS (real macOS bug — good catch), or (c) transient CI issue (retry once, then escalate). Do NOT push a workaround; if the failure requires ADR-023's fallback plan, come back to Claude for ADR-023 amendment first.

---

## Task 074: Carryover QA — interactive-fps + VRAM parse (John)
**Status:** [x] Done — 2026-08-28. Folded into Task 072 Windows QA run.
- **(a) Interactive-fps sanity:** `makieviews()` launched and ran smoothly on Windows 11 with the demo session (2D sine+scatter + 3D surface). No freeze or performance issue observed. The pre-flight fallback formula is confirmed safe — under-predicts as expected (ADR-020).
- **(b) VRAM-parsing branch:** No NVIDIA box available; documented as a known limitation per the Task 074 spec. The `nothing` fallback path (FR-026 compliant, never throws) is the v0.1.0 shipping path.
**Milestone:** M11
**Depends on:** 072, 073

### What to do
Two M10 carryovers (ADR-020 / 2026-08-27):
(a) **Interactive-fps sanity** through the embedded viewport — now unblocked (Bug E fixed, Task 067). With a large-ish plot displayed, confirm the pre-flight fallback under-predicts (observed fps ≥ estimate; no freeze).
(b) **VRAM-parsing branch** of `detect_host_specs` on a real NVIDIA box (only the `nothing` fallback has run — no `nvidia-smi` on the dev box). If no NVIDIA machine is available, document as a known limitation in the release notes (per ADR-018) rather than block.

### Acceptance Criterion
(a) reported: observed vs. estimated fps for one heavy plot, no freeze. (b) either `detect_host_specs` returns a populated VRAM / GPU name on an NVIDIA box, OR a one-line known-limitation entry is added to the release notes. Report both outcomes.

---

## Task 075: Release — version bump, CHANGELOG, Registrator, tag (John)
**Status:** [~] In progress — awaiting AutoMerge on General PR #166500 (3-day new-package window).
- Release commit `3d4da4a` (`release: v0.1.0`): Project.toml 0.1.0, CHANGELOG finalized. CI #49 green.
- Tag `v0.1.0` pushed (annotated, pointing to `3d4da4a34c5c6b5aff680ca755b44ffdb7466ba6`).
- JuliaRegistrator installed via `https://github.com/JuliaRegistries/Registrator.jl` install button.
- General registry PR: https://github.com/JuliaRegistries/General/pull/166500
- AutoMerge: 3-day new-package waiting period. Will merge automatically if all checks pass (no naming objections, compat valid, LICENSE present). No action needed until merge.
- On merge: confirm `] add MakieViews` resolves on a fresh environment → SC-001 met → mark [x] Done.
**Milestone:** M11
**Depends on:** 072, 073, 074

### What to do
Cut the release once the QA gate (072, 073, and 074's disposition) is green:
1. Bump `Project.toml` `version = "0.1.0"`.
2. Finalize `CHANGELOG.md`: move `[0.1.0] — TBD` to `[0.1.0] — <date>`, fold in the relevant `[Unreleased]` entries, fix the compare/tag links.
3. Commit the release commit; push; confirm CI green.
4. Registrator.jl **dry-run**, then trigger General-registry registration (JuliaRegistrator). Address any AutoMerge feedback (compat, etc.).
5. After the registry PR merges: `git tag v0.1.0` + push the tag; attach the Windows/macOS QA report (072–074) to the release notes.

### Acceptance Criterion (M11 / SC-001 exit)
MakieViews v0.1.0 is registered in General and resolves via `] add MakieViews` on a fresh environment; the `v0.1.0` tag exists; release notes include the pre-release manual QA report. Report: `v0.1.0 registered (<registry PR>), tagged, QA report attached` — SC-001 met.

---

## Deferred to post-v0.1.0: Interactive macOS verification (per ADR-023)
**Status:** Filed — deferred to post-v0.1.0 (committed before v0.2.0). Documented as a v0.1 known limitation.
**Component:** Manual QA on macOS hardware.

### Symptom / missing coverage
No mouse-driven interactive verification on macOS for v0.1.0: rotating a 3D axis by mouse in the displayed window, live attribute edits via the demo window's property panel, window dragging/resizing, and `export_figure` from a displayed (rather than headless) window. Cursor/focus/HiDPI/menu-bar behaviors on macOS are also unverified.

### Coverage that DOES ship in v0.1.0 (per ADR-023)
The GHA macos-latest CI job (Task 073) runs the full headless `Pkg.test()` suite on Apple Silicon, exercising ~99% of what the manual gate would have covered: all seven plot types, GLMakie rendering via macOS OpenGL compat, CairoMakie export, session persistence, downsampling, preferences, and `add_plot_checked!`. What remains uncovered is user-driven interaction (mouse, keyboard, window events) — no automated test framework replaces a human at a Mac.

### v0.1 disposition
Documented in README Platforms section (ADR-023 cross-ref) and CHANGELOG [0.1.0] Known limitations. Mac users on v0.1.0 are asked to report issues via GitHub Issues; the accumulated set is fixed in v0.1.x patches or gated by the interactive pass before v0.2.0.

### Trigger to close
Before v0.2.0: perform the original ADR-018 manual gate on a macOS 12+ machine (`Pkg.test()` locally + `makieviews()` + 3D rotate by mouse + one live attribute edit + `export_figure` from the displayed window). If it passes, close this block and update ADR-023 with the outcome. If failures found, fix or document as v0.2 known limitations.

---

# Milestone M12 — Embedding Spike

> **Spike milestone — all code is throwaway scratch scripts, outside the package.**
> Exit deliverable: ADR-025 (embedding path for live editing), which names the chosen route
> and records a working demo of adding one plot to an already-displayed window via `g_idle_add`.
> If no route works, v0.2 GUI scope is re-planned before M13 begins.
> Tasks 076–079 must be executed in order; each gates the next.

---

## Task 076: Spike — reproduce GtkMakieWidget #14 failure (Route 1 evaluation)
**Status:** [x] Done — 2026-08-29. Route 1 succeeded on Windows (no freeze, no error). See header comment in `spike/m12_route1_widget.jl`. Surprising result — #14 did not reproduce with `--threads 4,1`. Pivot: Task 077 becomes a Route 1 stress test rather than a GTKScreen evaluation.
**Milestone:** M12
**Depends on:** 075 (M11 complete, registry merge confirmed; M12 proceeds in parallel if merge is still pending per SESSION_LOG)

### What to do
Create a scratch script `spike/m12_route1_widget.jl` (new directory `spike/` in the project root; nothing in it is part of the package). The script must:
1. Build a minimal Gtk4 window with a `GtkMakieWidget` embedding a GLMakie figure — exactly the shape `src/MakieViews.jl` uses (`Gtk4Makie.GtkMakieWidget(); push!(viewport_widget, makie_fig)`).
2. Display the window with `show(w); Gtk4.main()`.
3. After display, attempt to add a second plot to an existing axis: `lines!(ax, rand(10))` issued from a `Threads.@spawn` block or a `Gtk4.GLib.g_idle_add` callback, whichever is most faithful to the upstream report.
4. Record the outcome: does the window freeze, error, or succeed? If it succeeds, note exactly how.

Do **not** attempt a fix. The goal is a reproducible failure (or a surprising success) documented in a comment block at the top of the file. The script must be self-contained and runnable with `julia --threads 4,1 --project=. spike/m12_route1_widget.jl`. It must not import anything from `src/`.

### Files touched
- `spike/m12_route1_widget.jl` — new scratch script (created; nothing else touched)

### Acceptance Criterion
`spike/m12_route1_widget.jl` exists and runs without a Julia crash (window may freeze or deadlock — that is the expected outcome to document, not a failure of the task). The file's header comment block records: (a) which add-plot call was attempted, (b) whether the window froze, errored, or succeeded, and (c) any error message verbatim. Report back the full header comment block.

### On Failure
Report `TASK 076 FAILED — [what went wrong at the Julia level, e.g. precompilation error, missing dep, test script crash before display]` with the full error text. Do not attempt to fix the GtkMakieWidget behavior — a freeze/deadlock is the *expected result* and counts as PASS for this task.

---

## Task 077: Spike — Route 1 stress test (GtkMakieWidget structural-mutation sequence)
**Status:** [x] Done — 2026-08-29. All 4 structural-mutation steps passed on Windows with Gtk4Makie.jl v0.3.9. See header in spike/m12_route1_stress.jl.
**Milestone:** M12
**Depends on:** 076

**Pivot from original plan:** Task 076 showed Route 1 (`GtkMakieWidget` + `--threads 4,1`) succeeds for a second `lines!` on an existing axis. Task 077 now stress-tests the full structural-mutation sequence that M13 actually needs, still using Route 1, before committing to it. Routes 2 and 3 are evaluated only if this task fails.

### What to do
Create `spike/m12_route1_stress.jl`. Using the same `GtkMakieWidget` + `Threads.@spawn Gtk4.main()` setup from Task 076, exercise the following sequence **after** the window is displayed. Each step must be issued from the script thread (not from inside a GTK callback). Between each step, sleep 1 second and call `Gtk4.queue_render(viewport_widget)`.

1. **Add a second plot to an existing axis** — `scatter!(ax, rand(10), rand(10))` (different plot type from the first `lines!`).
2. **Add a new axis to the figure** — `ax2 = Axis(fig[2, 1]); lines!(ax2, cumsum(randn(20)))`. This is the operation most likely to expose the full-rebuild defect from ADR-024 (Defect 2).
3. **Delete a plot from the first axis** — obtain the plot handle from step 1 and call `delete!(ax, handle)` or `Makie.delete!(handle)` (use whichever the Makie 0.24 API exposes; check `methods(delete!)` if uncertain).
4. **Remove the second axis** — `delete!(ax2)` or `Makie.delete!(ax2)`.

For each step record: did it succeed without freeze, error, or visible corruption of unrelated plot objects? After all four steps, sleep 3 seconds so the final state is observable, then exit gracefully.

The header comment block must record, for each of the four steps:
- (a) exact call used
- (b) success / freeze / error
- (c) any error text verbatim, or "no error"
- (d) whether the *other* axis/plots were visibly corrupted by the operation

The script must be runnable with `julia --threads 4,1 --project=. spike/m12_route1_stress.jl` and must not import anything from `src/`.

### Files touched
- `spike/m12_route1_stress.jl` — new scratch script

### Acceptance Criterion
`spike/m12_route1_stress.jl` exists and runs to completion (the sleep intervals elapse without a Julia-level crash). The header comment records all four steps with fields (a)–(d). Report back the full header comment block and state explicitly: **did all four structural-mutation steps succeed without deadlock or error?** (Yes/No per step.)

### On Failure
Report `TASK 077 FAILED — [which step failed: step N / precompile error / script crash]` with full error text. If a specific step froze or errored, note whether the Julia process itself crashed or just the window hung. Do not attempt to fix; Claude will diagnose and decide whether to pivot to Route 2.

---

## Task 078: Spike — Route 2/3 fallback evaluation (conditional)
**Status:** [s] Skipped — Route 1 stress test passed (Task 077)
**Milestone:** M12
**Depends on:** 077

> **Conditional task.** Run this only if Task 077's stress test showed one or more of the four structural-mutation steps failing (freeze, error, or corruption). If Task 077 passed all four steps, skip this task and proceed directly to Task 079. Report back "TASK 078 SKIPPED — Route 1 stress test passed" and Claude will advance the gate.

### What to do
Based on which step(s) of Task 077 failed, Claude will write a targeted instruction for this task at that time — either a `GTKScreen`-in-grid evaluation (Route 2) or a `GLMakie.Screen` custom-window evaluation (Route 3), depending on the failure mode. Do not run this task until Claude has diagnosed Task 077's failure and issued the specific instruction.

### Files touched
- TBD by Claude after Task 077 failure diagnosis

### Acceptance Criterion
TBD by Claude after Task 077 failure diagnosis.

### On Failure
Report `TASK 078 FAILED — [error]` with full error text. Claude will decide whether further routes remain or whether v0.2 GUI scope requires re-planning.

---

## Task 079: Write ADR-025 — embedding path for live editing (M12 exit deliverable)
**Status:** [x] Done — 2026-08-29
**Milestone:** M12
**Depends on:** 077 (and 078 if not skipped); also depends on CI smoke result from Task 077 if Route 1 is chosen (see Task 077 stress-test note)

### What to do
Write `docs/adr/ADR-025-embedding-path-live-editing.md`. This is the M12 exit deliverable — a one-page (≈ 400–600 word) decision record that:
1. States the **Decision**: which embedding route is chosen (Route 1 / 2 / 3) and why, OR records that no route was viable and v0.2 GUI scope must be re-planned.
2. **Context**: one paragraph summarising the ADR-024 constraint 2 requirement (live plot-add without deadlock) and the three routes evaluated.
3. **Evidence**: for each route, one sentence naming the spike script and its pass/fail outcome (from Tasks 076–078 header comments). No code blocks needed — prose is sufficient.
4. **Consequences**: what changes in the production codebase for M13+ as a result of this choice (e.g. "`src/MakieViews.jl` shell switches from `GtkMakieWidget` to `GTKScreen`; `src/render/renderer.jl` incremental ops target the `GTKScreen` GLArea handle").
5. Cross-references: ADR-024, the relevant upstream issue (#14 or GLMakie custom-window docs), and PLAN-v0.2.md M12.

Do **not** commit the spike scripts (`spike/`) — they are throwaway. Do commit ADR-025 and mark M12 complete in tasks.md, then push. Do not begin M13 tasks until ADR-025 is written and committed.

### Files touched
- `docs/adr/ADR-025-embedding-path-live-editing.md` — new ADR (created)
- `tasks.md` — mark Tasks 076–079 [x] Done and 078 [x] Done or [s] Skipped; add M12 completion note

### Acceptance Criterion
`docs/adr/ADR-025-embedding-path-live-editing.md` exists, is ≥ 300 words, names the chosen route, and contains all five sections listed above. `tasks.md` has Tasks 076–078 marked (Done or Skipped) and 079 marked Done. Both files committed and pushed (`git log --oneline -1` shows the commit on `main`). CI need not be triggered — ADR-025 is docs-only. Report back: `TASK 079 PASSED — ADR-025 written, route = [Route N / re-plan], commit = [hash]`.

### On Failure
Report `TASK 079 FAILED — [which section is missing / file not found / commit not pushed]` with detail. Claude will diagnose.

---

## Milestone M12 Complete — 2026-08-29
**Exit deliverable:** ADR-025 written, committed, and pushed. Route 1 (`GtkMakieWidget` + `--threads 4,1`) confirmed viable for live structural editing. M13 incremental renderer implementation unblocked.

