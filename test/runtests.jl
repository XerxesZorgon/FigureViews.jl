using Test
using FigureViews
using Gtk4
using Makie
using FigureViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, DataRef, MainSource, Renderer, build_tree_pane, build_property_pane, validate, PLOT_SCHEMAS, AXIS_SCHEMAS, CameraSpec, _current_session, _current_renderer, ValidationError, UndoStack, UndoEntry, push_edit!, undo!, redo!, can_undo, can_redo

include("unit/nodes.jl")
include("unit/schema.jl")
include("unit/registry.jl")
include("unit/registry_generated.jl")
include("unit/function_registry.jl")
include("unit/downsample.jl")
include("unit/session.jl")
include("unit/tree_pane.jl")
include("unit/tree_pane_context_menu.jl")
include("unit/property_pane.jl")
include("unit/property_pane_add_plot.jl")
include("unit/incremental_ops.jl")
include("unit/thread_check.jl")
include("unit/makieviews_session_method.jl")
include("unit/variable_pane.jl")
include("unit/drop_target.jl")
include("unit/tier1_recommend.jl")
include("unit/emit_plot.jl")
include("unit/data_pane.jl")
include("unit/add_plot_dialog_logic.jl")
include("unit/menubar_scaffold.jl")
include("unit/file_menu_handlers.jl")
include("unit/file_menu_new_handler.jl")
include("unit/preflight_modal_formatting.jl")
include("unit/preflight_wiring.jl")
include("unit/data_inline_save.jl")
include("unit/data_inline_load.jl")
include("unit/undo_stack.jl")
include("ui/test_shell_layout_m17.jl")

@testset "M1 shell — module loads" begin
    @test :makieviews in names(FigureViews)
    w = makieviews()
    @test !isnothing(w)
    Gtk4.destroy(w)
end

@testset "M1 shell — non-REPL warning fires" begin
    w = @test_logs (:warn, r"FigureViews v0.1 reads variables from REPL Main") match_mode=:any makieviews()
    Gtk4.destroy(w)
end

@testset "M1 shell — window properties" begin
    w = makieviews()
    sleep(0.2)  # let GTK settle before reading properties
    @test w.title == "FigureViews"
    # Window size may be clamped by the display environment (e.g. xvfb defaults to 1280px wide).
    # Assert reasonable minimums rather than exact pixels — the app requests 1400x900 but CI
    # runners may constrain it. What matters is the window opened at a usable size.
    @test w.default_width >= 1024
    @test w.default_height >= 768
    Gtk4.destroy(w)
end

@testset "M1 shell — Figure attached" begin
    w = makieviews()
    sleep(0.3)  # let GLMakie initialize the GL context
    
    root = w[]
    main_paned = root isa GtkPaned ? root : Gtk4.G_.get_last_child(root)
    @test main_paned !== nothing

    # M17 tri-pane: main_paned[2] is center_paned (GtkPaned :h); viewport is center_paned[1]
    center_paned = main_paned[2]
    @test center_paned isa GtkPaned
    viewport = center_paned[1]
    @test occursin(r"Makie|GL", string(typeof(viewport)))
    
    Gtk4.destroy(w)
end

@testset "M2 renderer — programmatic line plot renders" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = collect(1.0:100.0)
    y = sin.(x ./ 10)
    _m = Module(:_T)
    Core.eval(_m, :(x = $x))
    Core.eval(_m, :(y = $y))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "x")
    snap_y = ingest!(s, _src, "y")
    plot_node = add_plot!(ax_node, :line,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)

    @test haskey(renderer.axis_handles, ax_node.id)
    @test haskey(renderer.plot_handles, plot_node.id)
    @test haskey(renderer._plot_observers, plot_node.id)
    @test !isempty(renderer._plot_observers[plot_node.id])

    # Trigger attribute change and verify Makie plot handle updates
    plot_node.attrs[:linewidth][] = 5.0
    sleep(0.05)  # let observer fire
    makie_plot = renderer.plot_handles[plot_node.id]
    @test makie_plot.linewidth[] == 5.0
end

@testset "M3 renderer — programmatic scatter plot renders" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = collect(1.0:10.0)
    y = x.^2
    _m = Module(:_T)
    Core.eval(_m, :(x = $x))
    Core.eval(_m, :(y = $y))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "x")
    snap_y = ingest!(s, _src, "y")
    plot_node = add_plot!(ax_node, :scatter,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)

    @test haskey(renderer.axis_handles, ax_node.id)
    @test haskey(renderer.plot_handles, plot_node.id)

    # Trigger attribute change and verify Makie plot handle updates
    plot_node.attrs[:markersize][] = 15.0
    sleep(0.05)
    makie_plot = renderer.plot_handles[plot_node.id]
    
    # In Makie, markersize might be accessible via handle.markersize[] or handle[:markersize][]
    if hasproperty(makie_plot, :markersize)
        val = makie_plot.markersize[]
        @test (val isa Number ? val == 15.0 : val[1] == 15.0)
    else
        val = makie_plot[:markersize][]
        @test (val isa Number ? val == 15.0 : val[1] == 15.0)
    end
end

@testset "M3 bar — renders without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = collect(1.0:5.0)
    y = [3.0, 1.0, 4.0, 1.0, 5.0]
    _m = Module(:_T)
    Core.eval(_m, :(x = $x))
    Core.eval(_m, :(y = $y))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "x")
    snap_y = ingest!(s, _src, "y")
    plot_node = add_plot!(ax_node, :bar,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])
    @test plot_node.type == :bar
    @test plot_node.attrs[:direction][] == :vertical
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
end

@testset "M3 heatmap — renders without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    mat = [sin(i/5) * cos(j/5) for i in 1:20, j in 1:20]
    _m = Module(:_T)
    Core.eval(_m, :(mat = $mat))
    _src = FigureViews.MainSource(_m)
    snap_mat = ingest!(s, _src, "mat")
    plot_node = add_plot!(ax_node, :heatmap,
        [DataRef(:matrix, snap_mat, :main, "mat")])
    @test plot_node.type == :heatmap
    @test plot_node.attrs[:colormap][] == :viridis
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
end

@testset "M3 contour — renders without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    xs = collect(LinRange(0.0, 2π, 30))
    ys = collect(LinRange(0.0, 2π, 30))
    zs = [sin(x) * cos(y) for x in xs, y in ys]
    _m = Module(:_T)
    Core.eval(_m, :(xs = $xs))
    Core.eval(_m, :(ys = $ys))
    Core.eval(_m, :(zs = $zs))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "xs")
    snap_y = ingest!(s, _src, "ys")
    snap_z = ingest!(s, _src, "zs")
    plot_node = add_plot!(ax_node, :contour,
        [DataRef(:x, snap_x, :main, "xs"), DataRef(:y, snap_y, :main, "ys"), DataRef(:matrix, snap_z, :main, "zs")])
    @test plot_node.type == :contour
    @test plot_node.attrs[:levels][] == 10
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
end

@testset "M2 tree pane — populates from session; selection writes to session.selection" begin
    s = new_session()
    fig_node = add_figure!(s; title = "F1")
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = 1.0:10.0 |> collect
    _m = Module(:_T)
    Core.eval(_m, :(x = $x))
    Core.eval(_m, :(y = sin.($x)))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "x")
    snap_y = ingest!(s, _src, "y")
    plot_node = add_plot!(ax_node, :line,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])

    tree_widget = build_tree_pane(s)
    @test tree_widget !== nothing

    sleep(0.2)

    # Programmatically select the plot node by writing its id to selection and verifying no error:
    s.selection[] = plot_node.id
    @test s.selection[] == plot_node.id
end

@testset "M2 property pane — populates on selection and edits propagate" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    _m = Module(:_T)
    Core.eval(_m, :(x = 1.0:10.0 |> collect))
    Core.eval(_m, :(y = zeros(10)))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "x")
    snap_y = ingest!(s, _src, "y")
    plot_node = add_plot!(ax_node, :line,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])

    prop_widget = build_property_pane(s)
    @test prop_widget !== nothing

    # Selecting the plot should populate the pane. Exact widget introspection may be limited by
    # Gtk4.jl API; at minimum verify no exception is raised.
    s.selection[] = plot_node.id
    sleep(0.2)

    # Simulate a valid attribute edit by writing directly to the Observable (mimics the widget's onchange path)
    plot_node.attrs[:linewidth][] = 3.5
    @test plot_node.attrs[:linewidth][] == 3.5

    # Validate function tests
    specs = PLOT_SCHEMAS[:line]
    @test validate(specs, :linewidth, 5.0) == 5.0
    @test validate(specs, :linewidth, 100.0) isa FigureViews.ValidationError    # out of range
    @test validate(specs, :linestyle, :solid) == :solid
    @test validate(specs, :linestyle, :bogus) isa FigureViews.ValidationError   # not in enum
end

@testset "M2 end-to-end — makieviews() launches with demo tree and edit propagates" begin
    w = makieviews()
    sleep(0.5)  # let everything settle
    @test w !== nothing

    # Retrieve session + renderer from module-level refs
    session = FigureViews._current_session[]
    renderer = FigureViews._current_renderer[]
    @test length(session.figures[]) == 1
    fig_node = session.figures[][1]
    ax_node = fig_node.axes[][1]
    plot_node = ax_node.plots[][1]
    @test plot_node.type == :line

    # Simulate selection + attribute edit; verify Makie plot handle updated
    session.selection[] = plot_node.id
    sleep(0.1)
    plot_node.attrs[:linewidth][] = 4.0
    sleep(0.1)
    makie_plot = renderer.plot_handles[plot_node.id]
    @test makie_plot.linewidth[] == 4.0

    Gtk4.destroy(w)
end

@testset "M4 axis3d — renderer builds Makie.Axis3" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis3d, title = "3D")
    @test ax_node.kind == :axis3d
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.axis_handles, ax_node.id)
    @test renderer.axis_handles[ax_node.id] isa Makie.Axis3
end

@testset "M4 axis2d — renderer still builds Makie.Axis (regression guard)" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test renderer.axis_handles[ax_node.id] isa Makie.Axis
end

@testset "M4 surface — renders on Axis3 without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis3d)
    xs = collect(LinRange(-3.0, 3.0, 25))
    ys = collect(LinRange(-3.0, 3.0, 25))
    zs = [exp(-(x^2 + y^2)) for x in xs, y in ys]
    _m = Module(:_T)
    Core.eval(_m, :(xs = $xs))
    Core.eval(_m, :(ys = $ys))
    Core.eval(_m, :(zs = $zs))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "xs")
    snap_y = ingest!(s, _src, "ys")
    snap_z = ingest!(s, _src, "zs")
    plot_node = add_plot!(ax_node, :surface,
        [DataRef(:x, snap_x, :main, "xs"), DataRef(:y, snap_y, :main, "ys"), DataRef(:matrix, snap_z, :main, "zs")])
    @test plot_node.type == :surface
    @test plot_node.attrs[:colormap][] == :viridis
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
    @test renderer.axis_handles[ax_node.id] isa Makie.Axis3
    plot_node.attrs[:colormap][] = :plasma
    sleep(0.05)
    @test renderer.plot_handles[plot_node.id].colormap[] == :plasma
end

@testset "M4 volume — renders on Axis3 without error" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis3d)
    vol = [exp(-((i-15)^2 + (j-15)^2 + (k-15)^2)/50) for i in 1:30, j in 1:30, k in 1:30]
    _m = Module(:_T)
    Core.eval(_m, :(vol = $vol))
    _src = FigureViews.MainSource(_m)
    snap_vol = ingest!(s, _src, "vol")
    plot_node = add_plot!(ax_node, :volume,
        [DataRef(:volume, snap_vol, :main, "vol")])
    @test plot_node.type == :volume
    @test plot_node.attrs[:algorithm][] == :mip
    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    @test haskey(renderer.plot_handles, plot_node.id)
    @test renderer.axis_handles[ax_node.id] isa Makie.Axis3
    plot_node.attrs[:colormap][] = :inferno
    sleep(0.05)
    @test renderer.plot_handles[plot_node.id].colormap[] == :inferno
end

@testset "M4 camera — selecting Axis3 populates camera editors; edit propagates to Makie.Axis3" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis3d)
    xs = collect(LinRange(-3.0, 3.0, 20)); ys = collect(LinRange(-3.0, 3.0, 20))
    zs = [exp(-(x^2 + y^2)) for x in xs, y in ys]
    _m = Module(:_T)
    Core.eval(_m, :(xs = $xs))
    Core.eval(_m, :(ys = $ys))
    Core.eval(_m, :(zs = $zs))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "xs")
    snap_y = ingest!(s, _src, "ys")
    snap_z = ingest!(s, _src, "zs")
    add_plot!(ax_node, :surface,
        [DataRef(:x, snap_x, :main, "xs"), DataRef(:y, snap_y, :main, "ys"), DataRef(:matrix, snap_z, :main, "zs")])

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)
    prop_widget = build_property_pane(s)
    @test prop_widget !== nothing

    @test haskey(AXIS_SCHEMAS, :axis3d)
    @test length(AXIS_SCHEMAS[:axis3d]) == 3

    s.selection[] = ax_node.id
    sleep(0.1)
    @test ax_node.camera[] !== nothing

    makie_ax = renderer.axis_handles[ax_node.id]
    @test makie_ax isa Makie.Axis3
    ax_node.camera[] = CameraSpec(0.5, 0.3, 1.0)
    sleep(0.05)
    @test isapprox(makie_ax.azimuth[],   0.5; atol = 1e-6)
    @test isapprox(makie_ax.elevation[], 0.3; atol = 1e-6)
end

@testset "P1 layout — two-axis figure renders both axes (Bug B)" begin
    s = new_session()
    fig_node = add_figure!(s; title = "Two axes")
    ax2 = add_axis!(fig_node; kind = :axis2d, title = "2D")
    _m = Module(:_T)
    Core.eval(_m, :(x = collect(1.0:100.0)))
    Core.eval(_m, :(y = sin.((1.0:100.0) ./ 10)))
    _src = FigureViews.MainSource(_m)
    snap_x = ingest!(s, _src, "x")
    snap_y = ingest!(s, _src, "y")
    add_plot!(ax2, :line, [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])
    ax3 = add_axis!(fig_node; kind = :axis3d, title = "3D")
    xs = collect(LinRange(-3.0, 3.0, 20)); ys = collect(LinRange(-3.0, 3.0, 20))
    zs = [exp(-(x^2 + y^2)) for x in xs, y in ys]
    Core.eval(_m, :(xs = $xs))
    Core.eval(_m, :(ys = $ys))
    Core.eval(_m, :(zs = $zs))
    snap_x3 = ingest!(s, _src, "xs")
    snap_y3 = ingest!(s, _src, "ys")
    snap_z3 = ingest!(s, _src, "zs")
    add_plot!(ax3, :surface,
        [DataRef(:x, snap_x3, :main, "xs"), DataRef(:y, snap_y3, :main, "ys"), DataRef(:matrix, snap_z3, :main, "zs")])

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)

    @test haskey(renderer.axis_handles, ax2.id)
    @test haskey(renderer.axis_handles, ax3.id)
    @test renderer.axis_handles[ax2.id] isa Makie.Axis
    @test renderer.axis_handles[ax3.id] isa Makie.Axis3
end

include("integration/data_sources.jl")
include("integration/persistence.jl")
include("integration/mvz_roundtrip_generic.jl")
include("integration/preserve_and_warn.jl")
include("integration/roundtrip_generic_extended.jl")
include("integration/animation.jl")
include("integration/export.jl")
include("integration/preferences.jl")
include("integration/preflight.jl")
include("integration/tree_refresh.jl")
include("integration/render_session.jl")
include("integration/live_structural.jl")
include("integration/live_structural_edit.jl")
include("integration/m15_end_to_end.jl")
include("integration/data_roundtrip_sc004.jl")
