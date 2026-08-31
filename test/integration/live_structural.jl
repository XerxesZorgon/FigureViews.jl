# test/integration/live_structural.jl
using Test
using FigureViews
using FigureViews: _current_renderer, apply_structural!, AddPlotOp, RemovePlotOp,
                   AddAxisOp, RemoveAxisOp, new_session, add_figure!, add_axis!,
                   add_plot!, ingest!, DataRef, MainSource
using Gtk4

# Only run when a display is available (xvfb on CI, real display locally).
_has_display = Sys.iswindows() || get(ENV, "DISPLAY", "") != ""
if !_has_display
    @info "No DISPLAY detected — skipping live_structural smoke test (set DISPLAY or run under xvfb-run)"
else

@testset "M13 live structural editing smoke test" begin
    w = makieviews()
    sleep(0.5)   # let GLMakie initialize
    renderer = _current_renderer[]
    @test renderer !== nothing
    @test renderer.viewport_widget !== nothing  # live flag set

    session = FigureViews._current_session[]
    fig_node = session.figures[][1]
    ax_node  = fig_node.axes[][1]

    # --- Add a plot post-display via apply_structural! ---
    _m = Module(:_LiveTest)
    src = MainSource(_m)
    Core.eval(_m, :(x = collect(1.0:20.0)))
    Core.eval(_m, :(y = sin.(collect(1.0:20.0))))
    snap_x = ingest!(session, src, "x")
    snap_y = ingest!(session, src, "y")
    new_plot = add_plot!(ax_node, :scatter,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])

    op = AddPlotOp(ax_node, new_plot)
    apply_structural!(renderer, op)

    # Poll for the drain to fire (up to 3 seconds).
    t0 = time()
    while !haskey(renderer.plot_handles, new_plot.id) && time() - t0 < 3.0
        sleep(0.1)
    end
    @test haskey(renderer.plot_handles, new_plot.id)

    # --- Remove the plot ---
    apply_structural!(renderer, RemovePlotOp(new_plot.id))
    t0 = time()
    while haskey(renderer.plot_handles, new_plot.id) && time() - t0 < 3.0
        sleep(0.1)
    end
    @test !haskey(renderer.plot_handles, new_plot.id)

    # --- Add an axis post-display ---
    new_ax = add_axis!(fig_node; kind=:axis2d, title="Live axis")
    apply_structural!(renderer, AddAxisOp(fig_node, new_ax))
    t0 = time()
    while !haskey(renderer.axis_handles, new_ax.id) && time() - t0 < 3.0
        sleep(0.1)
    end
    @test haskey(renderer.axis_handles, new_ax.id)

    # --- Attribute edit still works (v0.1 path unchanged) ---
    orig_ax = renderer.axis_handles[ax_node.id]
    ax_node.title[] = "Live title edit"
    sleep(0.1)
    @test orig_ax.title[] == "Live title edit"

    Gtk4.destroy(w)
end

end  # DISPLAY check
