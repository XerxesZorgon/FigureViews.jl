using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, Session, makieviews, _open_shell

@testset "makieviews_session_method" begin
    # a. Constructs an empty Session (no figures) via new_session(); asserts construction succeeds (no error).
    s_empty = new_session()
    @test s_empty isa Session
    @test isempty(s_empty.figures[])

    # b. Constructs a session with one figure and one axis via add_figure! / add_axis!; asserts construction succeeds.
    s_populated = new_session()
    fig = add_figure!(s_populated; title = "Test Figure")
    ax = add_axis!(fig; kind = :axis2d, title = "Test Axis")
    @test length(s_populated.figures[]) == 1
    @test length(fig.axes[]) == 1

    # c. Asserts length(methods(makieviews)) >= 2 — both the zero-arg and one-arg (Session) methods exist.
    m = methods(makieviews)
    @test length(m) >= 2
    @test hasmethod(makieviews, Tuple{})
    @test hasmethod(makieviews, Tuple{Session})

    # Assert _open_shell is exported / defined
    @test isdefined(FigureViews, :_open_shell)
end
