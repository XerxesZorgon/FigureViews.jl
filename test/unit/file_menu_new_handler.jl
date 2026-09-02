# test/unit/file_menu_new_handler.jl
using Test
using FigureViews
using FigureViews: new_session, add_figure!, _current_session, _do_new, makieviews

@testset "file_menu_new_handler" begin
    # a. Constructs a session with one figure via add_figure!. Sets _current_session[] = session.
    session = new_session()
    add_figure!(session; title = "Existing Figure")
    _current_session[] = session
    @test length(_current_session[].figures[]) == 1

    # b. Calls _do_new() (no window argument — old_window = nothing).
    # Asserts _current_session[] is a fresh session with isempty(_current_session[].figures[]).
    w_new = _do_new()
    @test isempty(_current_session[].figures[])
    if w_new !== nothing
        try
            Gtk4.destroy(w_new)
        catch
        end
    end

    # c. Asserts length(methods(makieviews)) >= 2 — both entry points still exist.
    @test length(methods(makieviews)) >= 2

    # d. Greps src/FigureViews.jl for the string "M18".
    src = read(joinpath(pkgdir(FigureViews), "src", "FigureViews.jl"), String)
    @test occursin("M18", src)
end
