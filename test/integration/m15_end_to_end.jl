# test/integration/m15_end_to_end.jl
using Test
using FigureViews
using FigureViews: _context_add_axis!, _confirm_add_plot, _do_new, _do_save, _do_load,
                   _current_renderer, _current_session, add_figure!, MainSource
using Gtk4

module _E2EFixture
    x = collect(1.0:20.0)
    y = sin.(collect(1.0:20.0))
end

_has_display = Sys.iswindows() || get(ENV, "DISPLAY", "") != ""
if !_has_display
    @info "No DISPLAY detected — skipping m15_end_to_end test"
else

@testset "M15 end-to-end" begin

    # 1. Open the demo session
    w = makieviews()
    sleep(0.5)
    renderer = _current_renderer[]
    @test renderer !== nothing

    # 2. Discard and start fresh
    w2 = _do_new(w)
    session = _current_session[]
    renderer = _current_renderer[]
    @test isempty(session.figures[])

    # 3. Add a figure and 2D axis
    fig_node = add_figure!(session; title = "E2E Figure")
    _context_add_axis!(session, fig_node, :axis2d)
    ax_node = fig_node.axes[][1]
    @test ax_node.kind == :axis2d

    # 4. Add a line plot via the pure dialog function
    plot = _confirm_add_plot(session, ax_node, :line,
               Dict(:x_vector => "x", :y_vector => "y");
               source = MainSource(_E2EFixture))
    t0 = time()
    while !haskey(renderer.plot_handles, plot.id) && time() - t0 < 10.0
        sleep(0.1)
    end
    @test haskey(renderer.plot_handles, plot.id)

    # 5. Save the session
    tmp_path = joinpath(mktempdir(), "e2e_test.mvz")
    _do_save(session, tmp_path)
    @test isfile(tmp_path)
    @test session.file_path[] == tmp_path

    # 6. Start fresh again
    w3 = _do_new(w2)
    session2 = _current_session[]
    @test isempty(session2.figures[])

    # 7. Load the saved session
    loaded = _do_load(tmp_path)
    @test length(loaded.figures[]) == 1
    @test length(loaded.figures[][1].axes[]) == 1
    @test length(loaded.figures[][1].axes[][1].plots[]) == 1

    # 8. Teardown
    Gtk4.destroy(w3)
    sleep(0.3)
end

end  # _has_display
