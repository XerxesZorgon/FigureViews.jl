# src/state/undo.jl

const UNDO_STACK_DEPTH = 20

"""
    UndoEntry

One reversible property-attr edit: the observable, its value before the edit,
and its value after. `label` is a human-readable description for future display.
"""
struct UndoEntry
    obs::Observable
    before::Any
    after::Any
    label::String
end

"""
    UndoStack

A bounded two-stack undo/redo manager. Capacity is fixed at construction.
Thread-safety: all mutations must happen on the GTK main thread (same
constraint as all Gtk4.jl widget operations).
"""
mutable struct UndoStack
    capacity::Int
    undo::Vector{UndoEntry}   # top of stack = last element
    redo::Vector{UndoEntry}   # top of stack = last element
end

UndoStack(capacity::Int = UNDO_STACK_DEPTH) = UndoStack(capacity, UndoEntry[], UndoEntry[])

can_undo(s::UndoStack) = !isempty(s.undo)
can_redo(s::UndoStack) = !isempty(s.redo)

"""
    push_edit!(stack, obs, before, after; label="")

Record a completed property edit. Clears the redo stack (new edit branches
history). Drops the oldest entry when capacity is exceeded.
"""
function push_edit!(stack::UndoStack, obs::Observable, before, after;
                    label::String = "")
    empty!(stack.redo)
    push!(stack.undo, UndoEntry(obs, before, after, label))
    if length(stack.undo) > stack.capacity
        popfirst!(stack.undo)
    end
    return stack
end

"""
    undo!(stack) -> Bool

Apply the top undo entry (set obs to `before`). Returns true if an entry
was available, false if the stack was empty.
"""
function undo!(stack::UndoStack)::Bool
    isempty(stack.undo) && return false
    entry = pop!(stack.undo)
    push!(stack.redo, entry)
    entry.obs[] = entry.before
    return true
end

"""
    redo!(stack) -> Bool

Re-apply the top redo entry (set obs to `after`). Returns true if an entry
was available, false if the stack was empty.
"""
function redo!(stack::UndoStack)::Bool
    isempty(stack.redo) && return false
    entry = pop!(stack.redo)
    push!(stack.undo, entry)
    entry.obs[] = entry.after
    return true
end
