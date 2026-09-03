# test/unit/tier1_recommend.jl
using Test
using FigureViews
using FigureViews: recommend_plot_type, recommend_from_var, DataVar

@testset "recommend_plot_type" begin
    @test recommend_plot_type(:vector, 1, :axis2d) == :lines
    @test recommend_plot_type(:matrix, 2, :axis2d) == :heatmap
    @test recommend_plot_type(:matrix, 2, :axis3d) == :surface
    @test recommend_plot_type(:matrix, 3, :axis3d) == :volume
    @test recommend_plot_type(:vector, 1, :axis3d) === nothing
    @test recommend_plot_type(:unsupported, 1, :axis2d) === nothing
    @test recommend_plot_type(:matrix, 1, :axis2d) === nothing
end
