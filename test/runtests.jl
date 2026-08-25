using Test
using MakieViews
using Gtk4

include("unit/nodes.jl")
include("unit/schema.jl")

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
