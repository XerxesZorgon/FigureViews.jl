using Test
using MakieViews
using Gtk4
using Makie
using MakieViews: new_session, add_figure!, add_axis!, add_line_plot!, Renderer

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
