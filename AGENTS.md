## tasks.md is off-limits to git operations
`tasks.md` is owned by Claude Chat, not Antigravity. Its working-tree state is
authoritative and is often uncommitted between edits. Antigravity must NEVER run
`git checkout`, `git restore`, `git stash`, `git clean`, or `git add` on
`tasks.md`, and must never `git add -A` / `git commit -a` (which would sweep it
in). When committing a task, stage only that task's explicit source/test files by
name. If `tasks.md` shows as modified in `git status`, that is expected — leave it
exactly as-is. Never "clean up" or revert it before a commit.

## GTK dialog and g_idle_add rule
GTK dialog functions (`save_dialog`, `open_dialog`, `ask_dialog`) run a nested
GTK main loop internally. Calling them from inside `g_idle_add` creates a second
nested loop that deadlocks on Windows.

**Rule:** Dialogs must be called at the top level of a GSimpleAction handler,
never inside `g_idle_add`. Only non-UI work may be deferred:
- ✅ Defer with `g_idle_add`: `_do_save(...)`, `Gtk4.destroy(w)`, `_do_new(w)`
- ❌ Never defer: `save_dialog(...)`, `open_dialog(...)`, `ask_dialog(...)`

Example pattern for Save As:
```julia
Gtk4.GLib.add_action(action_map, "file_save_as", (_, _) -> begin
    save_dialog("Save session", w, filters) do path   # ← top level, not in g_idle_add
        isempty(path) && return
        Gtk4.GLib.g_idle_add() do                     # ← only the write is deferred
            _do_save(session, path)
            return false
        end
    end
end)
