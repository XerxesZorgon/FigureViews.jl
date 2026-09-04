# test/unit/emit_plot.jl
using Test
using FigureViews
using FigureViews: Plot, DataRef, AnimBinding, emit_plot_code, _emit_value
using Observables: Observable

@testset "emit_plot_code" begin
    # 1. A :lines plot with x,y refs (labels "x","y") and attrs color=:blue, linewidth=1.5
    plot1 = Plot("p1", :lines,
        Observable([DataRef(:x, "s1", :main, "x"), DataRef(:y, "s2", :main, "y")]),
        Dict{Symbol, Observable{Any}}(:color => Observable{Any}(:blue), :linewidth => Observable{Any}(1.5)),
        Observable{Union{Nothing, AnimBinding}}(nothing))
    @test emit_plot_code(plot1) == "lines!(ax, x, y; color=:blue, linewidth=1.5)"

    # 2. A :scatter plot with x,y refs and attr markersize=8.0
    plot2 = Plot("p2", :scatter,
        Observable([DataRef(:x, "s1", :main, "x"), DataRef(:y, "s2", :main, "y")]),
        Dict{Symbol, Observable{Any}}(:markersize => Observable{Any}(8.0)),
        Observable{Union{Nothing, AnimBinding}}(nothing))
    @test emit_plot_code(plot2) == "scatter!(ax, x, y; markersize=8.0)"

    # 3. A :heatmap plot with one :matrix ref (label "M") and NO attrs
    plot3 = Plot("p3", :heatmap,
        Observable([DataRef(:matrix, "s3", :main, "M")]),
        Dict{Symbol, Observable{Any}}(),
        Observable{Union{Nothing, AnimBinding}}(nothing))
    @test emit_plot_code(plot3) == "heatmap!(ax, M)"

    # 4. _emit_value(:blue) == ":blue"
    @test _emit_value(:blue) == ":blue"

    # 5. _emit_value("hello") == "\"hello\""
    @test _emit_value("hello") == "\"hello\""

    # 6. _emit_value(true) == "true"
    @test _emit_value(true) == "true"

    # 7. emit_plot_code(plot; axis_var="myax") uses myax not ax in the output
    @test startswith(emit_plot_code(plot1; axis_var = "myax"), "lines!(myax, ")
end
