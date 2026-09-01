# test/unit/menubar_scaffold.jl
using Test
using FigureViews

@testset "menubar_scaffold" begin
    src = read(joinpath(pkgdir(FigureViews), "src", "ui", "tree_pane.jl"), String)
    @test !occursin("Add plot\u2026", src)   # temporary item removed
end
