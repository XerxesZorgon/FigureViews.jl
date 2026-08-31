using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, ingest!, MainSource, DataRef, Plot,
                  Renderer, _init_attrs, _add_plot_handle!, _remove_plot_handle!,
                  _add_axis!, _remove_axis!
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

@testset "M13 incremental axis ops" begin
    # 1. Session with one figure, one 2D axis. Construct Renderer.
    s = new_session()
    fig_node = add_figure!(s)
    ax_node_2d = add_axis!(fig_node; kind = :axis2d)
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)

    @test length(renderer.axis_handles) == 1
    @test haskey(renderer.axis_handles, ax_node_2d.id)
    h_2d = renderer.axis_handles[ax_node_2d.id]

    # 2. _add_axis!(renderer, fig_node, ax_node_3d)
    # Disconnect structural full-rebuild observer so add_axis! does not trigger full rebuild
    for h in renderer._structural_observers
        off(h)
    end
    ax_node_3d = add_axis!(fig_node; kind = :axis3d)
    _add_axis!(renderer, fig_node, ax_node_3d)

    @test length(renderer.axis_handles) == 2
    @test renderer.axis_handles[ax_node_3d.id] isa Makie.Axis3

    # 3. Add a surface plot to the 3D axis via _add_plot_handle!
    m3d = Module(:_IncOps3DTest)
    Core.eval(m3d, :(xs = collect(LinRange(-1.0, 1.0, 10))))
    Core.eval(m3d, :(ys = collect(LinRange(-1.0, 1.0, 10))))
    Core.eval(m3d, :(zs = [x^2 + y^2 for x in LinRange(-1.0, 1.0, 10), y in LinRange(-1.0, 1.0, 10)]))
    src3d = MainSource(m3d)
    snap_xs = ingest!(s, src3d, "xs")
    snap_ys = ingest!(s, src3d, "ys")
    snap_zs = ingest!(s, src3d, "zs")

    surf_plot = Plot(string(uuid4()), :surface,
                     Observable([DataRef(:x, snap_xs, :main, "xs"),
                                 DataRef(:y, snap_ys, :main, "ys"),
                                 DataRef(:matrix, snap_zs, :main, "zs")]),
                     _init_attrs(:surface),
                     Observable{Union{Nothing,AnimBinding}}(nothing))
    _add_plot_handle!(renderer, ax_node_3d, surf_plot)
    @test length(renderer.plot_handles) == 1
    @test haskey(renderer.plot_handles, surf_plot.id)
    @test renderer._plot_axis[surf_plot.id] == ax_node_3d.id

    # 4. _remove_axis!(renderer, ax_node_3d.id)
    _remove_axis!(renderer, ax_node_3d.id)

    @test length(renderer.axis_handles) == 1
    @test !haskey(renderer.axis_handles, ax_node_3d.id)
    @test !haskey(renderer._axis_observers, ax_node_3d.id)
    @test !any(aid == ax_node_3d.id for aid in values(renderer._plot_axis))
    @test length(renderer.plot_handles) == 0
    @test renderer.axis_handles[ax_node_2d.id] === h_2d

    # 5. _remove_axis!(renderer, "nonexistent") is a no-op (no throw)
    @test_nowarn _remove_axis!(renderer, "nonexistent")
    @test length(renderer.axis_handles) == 1
end
