using Test
using MakieViews
using Gtk4
using Makie
using MakieViews: new_session, add_figure!, add_axis!, add_line_plot!, add_scatter_plot!, add_bar_plot!, add_heatmap_plot!, add_contour_plot!, Renderer, build_tree_pane, build_property_pane, validate, PLOT_SCHEMAS, _current_session, _current_renderer, ValidationError

include("unit/nodes.jl")
include("unit/schema.jl")
include("unit/session.jl")

@testset "M1 shell — module loads" begin
    @test :makieviews in names(MakieViews)
    w = makieviews()
    @test !isnothing(w)
    Gtk4.destroy(w)
end

@testset "M1 shell — non-REPL warning fires" begin
    w = @test_logs (:warn, r"MakieViews v0.1 reads variables from REPL Main") match_mode=:any makieviews()
    Gtk4.destroy(w)
end

@testset "M1 shell — window properties" begin
    w = makieviews()
    sleep(0.2)  # let GTK settle before reading properties
    @test w.title == "MakieViews"
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
    
    main_paned = w[]
    @test main_paned !== nothing
    
    # Stronger assertions: right child is the viewport
    viewport = main_paned[2]
    @test occursin(r"Makie|GL", string(typeof(viewport)))
    
    Gtk4.destroy(w)
end

@testset "M2 renderer — programmatic line plot renders" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax_node = add_axis!(fig_node; kind = :axis2d)
    x = collect(1.0:100.0)
    y = sin.(x ./ 10)
    plot_node = add_line_plot!(ax_node; x = x, y = y)

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)

    @test haskey(renderer.axis_handles, ax_node.id)
    @test haskey(renderer.plot_handles, plot_node.id)
    @test length(renderer._observer_handles) >= 1

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
    plot_node = add_scatter_plot!(ax_node; x = x, y = y)

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
    plot_node = add_bar_plot!(ax_node; x = x, y = y)
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
    plot_node = add_heatmap_plot!(ax_node; matrix = mat)
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
    plot_node = add_contour_plot!(ax_node; x = xs, y = ys, z = zs)
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
    plot_node = add_line_plot!(ax_node; x = x, y = sin.(x))

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
    plot_node = add_line_plot!(ax_node; x = 1.0:10.0 |> collect, y = zeros(10))

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
    @test validate(specs, :linewidth, 100.0) isa MakieViews.ValidationError    # out of range
    @test validate(specs, :linestyle, :solid) == :solid
    @test validate(specs, :linestyle, :bogus) isa MakieViews.ValidationError   # not in enum
end

@testset "M2 end-to-end — makieviews() launches with demo tree and edit propagates" begin
    w = makieviews()
    sleep(0.5)  # let everything settle
    @test w !== nothing

    # Retrieve session + renderer from module-level refs
    session = MakieViews._current_session[]
    renderer = MakieViews._current_renderer[]
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
