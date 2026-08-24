using Test
using MakieViews

@testset "M1 shell — module loads" begin
    @test :makieviews in names(MakieViews)
    @test makieviews() === nothing
end
