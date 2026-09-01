# test/integration/live_structural_edit.jl
using Test
using FigureViews
using FigureViews: _context_add_axis!, _context_delete_axis!, _context_delete_plot!,
                   _add_plot_to_axis!, _current_renderer, _current_session
using Gtk4

# Only run when a display is available (xvfb on CI, real display locally).
_has_display = Sys.iswindows() || get(ENV, "DISPLAY", "") != ""
if !_has_display
    @info "No DISPLAY detected — skipping live_structural_edit smoke test (set DISPLAY or run under xvfb-run)"
else

@testset "M15 live structural editing" begin
    w = makieviews()
    sleep(0.5)   # let GLMakie initialize
    renderer = _current_renderer[]
    @test renderer !== nothing
    @test renderer.viewport_widget !== nothing  # live flag set

    session = _current_session[]
    fig_node = session.figures[][1]
    ax_node  = fig_node.axes[][1]

    # 3. Add a 3D axis via Task 099 callback:
    _context_add_axis!(session, fig_node, :axis3d)
    t0 = time()
    while length(renderer.axis_handles) < 2 && time() - t0 < 10.0
        sleep(0.1)
    end
    @test length(renderer.axis_handles) == 2

    # 4. Retrieve the new axis node:
    new_ax = fig_node.axes[][end]
    @test new_ax.kind == :axis3d

    # 5. Add an empty surface plot via Task 100 callback:
    new_plot = _add_plot_to_axis!(session, new_ax, :surface)
    t0 = time()
    while !haskey(renderer.plot_handles, new_plot.id) && time() - t0 < 10.0
        sleep(0.1)
    end
    @test haskey(renderer.plot_handles, new_plot.id)

    # 6. Delete the original axis's first plot via Task 099 callback:
    orig_plot = ax_node.plots[][1]
    _context_delete_plot!(session, orig_plot.id)
    t0 = time()
    while haskey(renderer.plot_handles, orig_plot.id) && time() - t0 < 10.0
        sleep(0.1)
    end
    @test !haskey(renderer.plot_handles, orig_plot.id)

    # 7. Verify destroy-signal safety (Task 101):
    Gtk4.destroy(w)
    sleep(0.3)
    @test _current_renderer[].viewport_widget === nothing
end

end  # DISPLAY check
