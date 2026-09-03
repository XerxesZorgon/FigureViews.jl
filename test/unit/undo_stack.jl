using Test
using FigureViews
using FigureViews: UndoStack, UndoEntry, push_edit!, undo!, redo!, can_undo, can_redo, new_session
using Observables

@testset "UndoStack — basic push, undo, redo" begin
    stack = UndoStack()
    @test !can_undo(stack)
    @test !can_redo(stack)

    obs = Observable(10)
    push_edit!(stack, obs, 10, 20; label = "test_edit")
    @test can_undo(stack)
    @test !can_redo(stack)
    @test length(stack.undo) == 1

    # Apply undo
    res = undo!(stack)
    @test res == true
    @test obs[] == 10
    @test can_redo(stack)
    @test !can_undo(stack)

    # Apply redo
    res_redo = redo!(stack)
    @test res_redo == true
    @test obs[] == 20
    @test can_undo(stack)
    @test !can_redo(stack)
end

@testset "UndoStack — empty stack undo/redo returns false" begin
    stack = UndoStack()
    @test undo!(stack) == false
    @test redo!(stack) == false
end

@testset "UndoStack — capacity bounds (20 entries max)" begin
    stack = UndoStack(20)
    obs = Observable(0)
    for i in 1:21
        push_edit!(stack, obs, i - 1, i; label = "edit_$i")
    end
    @test length(stack.undo) == 20
    # Oldest entry (0 -> 1) was dropped; oldest remaining is (1 -> 2)
    @test stack.undo[1].before == 1
    @test stack.undo[1].after == 2
    @test stack.undo[end].before == 20
    @test stack.undo[end].after == 21
end

@testset "UndoStack — push after undo clears redo stack" begin
    stack = UndoStack()
    obs = Observable("A")
    push_edit!(stack, obs, "A", "B")
    push_edit!(stack, obs, "B", "C")
    @test length(stack.undo) == 2

    undo!(stack) # restores to "B"
    @test obs[] == "B"
    @test can_redo(stack)

    # New edit branches history and clears redo
    push_edit!(stack, obs, "B", "D")
    @test !can_redo(stack)
    @test length(stack.undo) == 2
    @test stack.undo[end].after == "D"
end

@testset "Session — dirty flag default" begin
    s = new_session()
    @test s.dirty isa Observable{Bool}
    @test s.dirty[] == false
end
