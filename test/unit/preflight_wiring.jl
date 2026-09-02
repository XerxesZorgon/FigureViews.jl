# test/unit/preflight_wiring.jl
using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, add_plot!,
                   _apply_preflight_choice, _confirm_add_plot, _window_is_live,
                   DataRef, LTTB, MainSource

module _WarnFixture
    x = zeros(Float32, 20_000_000)
    y = zeros(Float32, 20_000_000)
end

@testset "preflight_wiring" begin
    # a. Builds a session with one figure and one :axis2d. Adds a plot directly via add_plot!(ax, :line, DataRef[]).
    # Captures length(ax.plots[]) — should be 1.
    s = new_session()
    fig = add_figure!(s; title = "Fig 1")
    ax = add_axis!(fig; kind = :axis2d, title = "Ax 1")
    p1 = add_plot!(ax, :line, DataRef[])
    @test length(ax.plots[]) == 1

    # b. Calls _apply_preflight_choice(session, plot, :accept, nothing). Asserts plot is unchanged.
    p_ret = _apply_preflight_choice(s, p1, :accept, nothing)
    @test p_ret === p1
    @test p1.id == p_ret.id
    @test p1.data_refs[] == p_ret.data_refs[]

    # c. Calls _apply_preflight_choice(session, plot, :override, nothing).
    # Uses @test_logs (:info, r"override accepted") to assert the info message fires. Asserts plot is unchanged.
    @test_logs (:info, r"override accepted") begin
        _apply_preflight_choice(s, p1, :override, nothing)
    end
    @test length(ax.plots[]) == 1

    # d. Calls _apply_preflight_choice(session, plot, :downsample, nothing).
    # Uses @test_logs (:info, r"downsample cancelled") to assert the cancellation message fires. Asserts plot is unchanged.
    @test_logs (:info, r"downsample cancelled") begin
        _apply_preflight_choice(s, p1, :downsample, nothing)
    end
    @test length(ax.plots[]) == 1

    # e. Tests headless path — _current_renderer[] = nothing — then calls _confirm_add_plot with a fixture module
    # that has x and y vectors. Uses @test_logs (:warn, r"pre-flight"i) to confirm the existing @warn in
    # add_plot_checked! fires when the dataset is large enough to trigger it.
    FigureViews._current_renderer[] = nothing
    @test _window_is_live(FigureViews._current_renderer[]) == false

    @test_logs (:warn, r"pre-flight"i) begin
        _confirm_add_plot(s, ax, :line, Dict(:x_vector => "x", :y_vector => "y"); source = MainSource(_WarnFixture))
    end

    # f. Asserts _apply_preflight_choice(session, plot, :downsample, LTTB(5)) — with a plot that has :x and :y refs
    # with valid snapshots in session.data_snapshots — sets plot.attrs[:downsample_algorithm][] to a LTTB instance.
    # Note: apply_downsample! currently looks for refs with role == :x and role == :y (legacy convention).
    # This test constructs the plot with DataRef(:x, snap_x, ...) and DataRef(:y, snap_y, ...) refs directly,
    # referencing the TODO in add_plot_dialog.jl.
    snap_x = "snap_x_$(time_ns())"
    snap_y = "snap_y_$(time_ns())"
    s.data_snapshots[snap_x] = Float64[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
    s.data_snapshots[snap_y] = Float64[1.0, 4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0, 81.0, 100.0]
    legacy_refs = [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")]
    p_down = add_plot!(ax, :line, legacy_refs)
    _apply_preflight_choice(s, p_down, :downsample, LTTB(5))
    @test haskey(p_down.attrs, :downsample_algorithm)
    @test p_down.attrs[:downsample_algorithm][] isa LTTB
end
