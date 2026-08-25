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
**Status:** [ ] Pending
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
**Status:** [ ] Pending
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
**Status:** [ ] Pending
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
**Status:** [ ] Pending
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
**Status:** [ ] Pending
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