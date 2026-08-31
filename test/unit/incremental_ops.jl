using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, ingest!, MainSource, DataRef, Plot,
                  Renderer, _init_attrs, _add_plot_handle!, _remove_plot_handle!
using Observables
using UUIDs
using Makie

@testset "M13 incremental plot ops — _add_plot_handle! and _remove_plot_handle!" begin
    # 1. Session with one figure, one 2D axis, one line plot; construct Renderer
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)

    m = Module(:_IncOpsTest)
    Core.eval(m, :(x1 = collect(1.0:10.0)))
    Core.eval(m, :(y1 = sin.(collect(1.0:10.0))))
    Core.eval(m, :(x2 = collect(1.0:10.0)))
    Core.eval(m, :(y2 = cos.(collect(1.0:10.0))))

    src = MainSource(m)
    snap_x1 = ingest!(s, src, "x1")
    snap_y1 = ingest!(s, src, "y1")
    snap_x2 = ingest!(s, src, "x2")
    snap_y2 = ingest!(s, src, "y2")

    plot1 = Plot(string(uuid4()), :line,
                 Observable([DataRef(:x, snap_x1, :main, "x1"), DataRef(:y, snap_y1, :main, "y1")]),
                 _init_attrs(:line),
                 Observable{Union{Nothing,AnimBinding}}(nothing))
    ax_node.plots[] = [plot1]

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)

    @test length(renderer.plot_handles) == 1
    @test haskey(renderer.plot_handles, plot1.id)
    line_handle = renderer.plot_handles[plot1.id]

    # 2. _add_plot_handle! a scatter plot to the same axis
    plot2 = Plot(string(uuid4()), :scatter,
                 Observable([DataRef(:x, snap_x2, :main, "x2"), DataRef(:y, snap_y2, :main, "y2")]),
                 _init_attrs(:scatter),
                 Observable{Union{Nothing,AnimBinding}}(nothing))
    _add_plot_handle!(renderer, ax_node, plot2)

    @test length(renderer.plot_handles) == 2
    @test haskey(renderer.plot_handles, plot2.id)
    @test haskey(renderer._plot_observers, plot2.id)

    # 3. _remove_plot_handle! the scatter's id
    _remove_plot_handle!(renderer, plot2.id)

    @test length(renderer.plot_handles) == 1
    @test !haskey(renderer.plot_handles, plot2.id)
    @test !haskey(renderer._plot_observers, plot2.id)
    @test renderer.plot_handles[plot1.id] === line_handle

    # 4. _remove_plot_handle! on "nonexistent" is a no-op (no throw)
    @test_nowarn _remove_plot_handle!(renderer, "nonexistent")
    @test length(renderer.plot_handles) == 1
end
