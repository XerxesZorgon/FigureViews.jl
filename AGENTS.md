## tasks.md is off-limits to git operations
`tasks.md` is owned by Claude Chat, not Antigravity. Its working-tree state is
authoritative and is often uncommitted between edits. Antigravity must NEVER run
`git checkout`, `git restore`, `git stash`, `git clean`, or `git add` on
`tasks.md`, and must never `git add -A` / `git commit -a` (which would sweep it
in). When committing a task, stage only that task's explicit source/test files by
name. If `tasks.md` shows as modified in `git status`, that is expected — leave it
exactly as-is. Never "clean up" or revert it before a commit.
