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
**Status:** [ ] Pending
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