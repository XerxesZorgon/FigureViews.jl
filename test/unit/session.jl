using MakieViews: new_session, add_figure!, add_axis!, add_line_plot!
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
