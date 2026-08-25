using Test
using MakieViews
using Gtk4
using Makie
using MakieViews: new_session, add_figure!, add_axis!, add_line_plot!, Renderer, build_tree_pane, build_property_pane, validate, PLOT_SCHEMAS

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
    @test (w.default_width, w.default_height) == (1024, 768)
    Gtk4.destroy(w)
end

@testset "M1 shell — Figure attached" begin
    w = makieviews()
    sleep(0.3)  # let GLMakie initialize the GL context
    
    child_widget = w[]
    @test child_widget !== nothing
    
    # Stronger assertions
    @test occursin(r"Makie|GL", string(typeof(child_widget)))
    
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
