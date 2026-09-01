using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, DataRef, MainSource,
                   _context_add_axis!, _context_delete_axis!, _context_delete_plot!

@testset "tree_pane_context_menu" begin
    # a. Builds a session with one figure and one 2D axis.
    session = new_session()
    fig_node = add_figure!(session; title = "Test Fig")
    ax1 = add_axis!(fig_node; kind = :axis2d, title = "Axis 1")
    @test length(fig_node.axes[]) == 1

    # b. Calls _context_add_axis!(session, fig_node, :axis3d) directly (no GtkGesture required).
    new_ax = _context_add_axis!(session, fig_node, :axis3d)

    # c. Asserts the figure now has 2 axes and the second is :axis3d.
    @test length(fig_node.axes[]) == 2
    @test fig_node.axes[][2].kind == :axis3d
    @test fig_node.axes[][2].id == new_ax.id

    # d. Calls _context_delete_axis!(session, new_ax.id).
    _context_delete_axis!(session, new_ax.id)

    # e. Asserts the figure is back to 1 axis.
    @test length(fig_node.axes[]) == 1
    @test fig_node.axes[][1].id == ax1.id

    # Also test _context_delete_plot!
    _m = Module(:_TestPlot)
    Core.eval(_m, :(x = collect(1.0:5.0)))
    Core.eval(_m, :(y = collect(1.0:5.0)))
    _src = MainSource(_m)
    snap_x = ingest!(session, _src, "x")
    snap_y = ingest!(session, _src, "y")
    plot_node = add_plot!(ax1, :line, [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])
    @test length(ax1.plots[]) == 1

    _context_delete_plot!(session, plot_node.id)
    @test length(ax1.plots[]) == 0
end
