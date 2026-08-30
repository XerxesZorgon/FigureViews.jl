using FigureViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, MainSource, DataRef
using Observables: on

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

@testset "M2 session — add_axis! and add_plot! chain" begin
    s = new_session()
    fig = add_figure!(s)
    ax = add_axis!(fig; kind = :axis2d, title = "X vs Y")
    x = 1:100 |> collect .|> Float64
    y = sin.(x ./ 10)
    _m = Module(:_T)
    Core.eval(_m, :(x = $x))
    Core.eval(_m, :(y = $y))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "x")
    snap_y = ingest!(s, _src, "y")
    plot = add_plot!(ax, :line,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])
    @test ax.plots[][1] === plot
    @test plot.type == :line
    @test plot.attrs[:linewidth][] == 1.5    # default from PLOT_SCHEMAS[:line]
    @test plot.attrs[:linestyle][] == :solid
    @test haskey(s.data_snapshots, snap_x)
    @test s.data_snapshots[snap_x] == x
end

@testset "M2 session — add_axis! rejects unknown kind" begin
    s = new_session()
    fig = add_figure!(s)
    @test_throws ArgumentError add_axis!(fig; kind = :axis_bogus)
end
