# MakieViews — tasks.md

Atomic execution list. One task per Antigravity instruction. Never advance
to Task N+1 until Task N is confirmed green with the acceptance criterion
listed on that task.

Task IDs are a global monotonic counter. `Milestone` is metadata.

---

## Milestone M1 — Shell

**Exit criterion:** `julia --project=. -e 'using MakieViews; w = makieviews(); sleep(1); Gtk4.destroy(w)'` opens a 1024×768 window titled "MakieViews" containing an empty Makie Axis rendered via GLMakie, closes cleanly, and returns exit code 0 on all six CI matrix cells (Julia 1.10 & 1.12 × Ubuntu, Windows, macOS).

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
**Status:** [ ] Pending
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

## Task 008: Implement Gtk4 window creation in makieviews()
**Status:** [ ] Pending
**Milestone:** M1
**Depends on:** 006 (007 is a merged placeholder)

### What to do
Modify `src/MakieViews.jl` so `makieviews()` creates a Gtk4 window titled `"MakieViews"` with default size `1024 × 768`, shows it, and returns the window handle so the caller (including tests) can inspect and destroy it. Do not run a nested blocking event loop — return the handle. Consult Gtk4.jl's current README and examples for the exact constructor and show functions; adjust to whatever the pinned Gtk4 v0.7.12 API provides. Preserve the ADR-011 warning from Task 006 at the top of the function.

### Files touched
- `src/MakieViews.jl` — modified: replace placeholder body with window construction

### Acceptance Criterion
`julia --project=. -e 'using MakieViews, Gtk4; w = makieviews(); sleep(0.2); @assert w !== nothing; Gtk4.destroy(w)' 2>&1` exits 0. On Linux, this may need `xvfb-run -a` prefix.

### On Failure
Report the exact error, including any Gtk4 initialization messages.

---

## Task 009: Extend test/runtests.jl to verify window title and size
**Status:** [ ] Pending
**Milestone:** M1
**Depends on:** 008

### What to do
Extend `test/runtests.jl` with a third `@testset "M1 shell — window properties" begin ... end` block that calls `makieviews()`, asserts the window's title equals `"MakieViews"`, asserts its default size is `(1024, 768)`, then destroys it. Use the Gtk4.jl accessor names that match the pinned v0.7.12 API — if `Gtk4.title(w)` and `Gtk4.default_size(w)` don't work, look up the current accessor names in Gtk4.jl's docs and use those.

### Files touched
- `test/runtests.jl` — modified: append third testset

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0. Total test count is at least 5, all passing. On Linux this may need `xvfb-run -a`.

### On Failure
Report the full `Pkg.test` output.

---

## Task 010: Embed an empty GLMakie Figure via Gtk4Makie
**Status:** [ ] Pending
**Milestone:** M1
**Depends on:** 009

### What to do
Modify `src/MakieViews.jl` so `makieviews()`, after creating the window, embeds a Gtk4Makie GLMakie widget as the window's child, containing an empty `Figure()` with a single empty `Axis`. Use whatever function Gtk4Makie.jl v0.3.9 currently exposes for this — check the package's README and `examples/` directory for the correct name (likely `GtkGLMakie` or similar; do not guess). The window should display a blank Cartesian axis with visible tick labels and axis lines. Return the window handle as before.

### Files touched
- `src/MakieViews.jl` — modified: add Figure/Axis embedding

### Acceptance Criterion
`julia --project=. -e 'using MakieViews, Gtk4; w = makieviews(); sleep(1.0); Gtk4.destroy(w)' 2>&1` exits 0 with no errors. Manual visual inspection: window shows a blank axis (verified during development; CI cannot verify this without image diffing, which is M11's concern).

### On Failure
Report the exact error, including any Gtk4Makie or GLMakie context initialization messages.

---

## Task 011: Extend test/runtests.jl to verify Figure is attached to window
**Status:** [ ] Pending
**Milestone:** M1
**Depends on:** 010

### What to do
Extend `test/runtests.jl` with a fourth `@testset "M1 shell — Figure attached" begin ... end` block that calls `makieviews()`, asserts the window has at least one child widget (the Gtk4Makie viewport), and — if Gtk4Makie exposes a way to retrieve the Makie Figure from its widget — asserts a Figure with one Axis is present. If the API doesn't expose this cleanly, restrict the assertion to child-widget presence and document why in an inline comment.

### Files touched
- `test/runtests.jl` — modified: append fourth testset

### Acceptance Criterion
`julia --project=. -e 'using Pkg; Pkg.test()'` exits 0. Total test count is at least 6, all passing. On Linux this may need `xvfb-run -a`.

### On Failure
Report the full `Pkg.test` output.

---

## Task 012: Create .github/workflows/ci.yml with 6-cell matrix
**Status:** [ ] Pending
**Milestone:** M1
**Depends on:** 011

### What to do
Create `.github/workflows/ci.yml` for GitHub Actions with a matrix over `julia-version: ["1.10", "1.12"]` and `os: [ubuntu-latest, windows-latest, macos-latest]`, per `docs/TEST_PLAN.md`. On each cell: check out the repo (`actions/checkout@v4`), set up Julia (`julia-actions/setup-julia@v2`), cache the depot (`julia-actions/cache@v2`), buildpkg (`julia-actions/julia-buildpkg@v1`), and run tests. On Ubuntu, prefix the test step with `xvfb-run -a` (install via `sudo apt-get install -y xvfb` in a prior step). On Windows and macOS, run tests directly. Trigger on `push` to any branch and `pull_request` to `main`.

### Files touched
- `.github/workflows/ci.yml` — new file

### Acceptance Criterion
Commit and push. All 6 matrix cells on the GitHub Actions run report success (green checkmark). No cells report failure or timeout.

### On Failure
Report the URL of the failed run and paste the failing job's log tail (last ~50 lines).

---

## M1 exit gate

When Tasks 001–012 are all `[x] Done` and all 6 CI cells are green, M1 is complete. Return to Claude Chat with "M1 complete" to extend `tasks.md` with M2 (Tree + first plot type).