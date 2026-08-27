using Test, MakieViews

@testset "M10 downsample — UniformStride" begin
    x = collect(1.0:100.0); y = x .^ 2
    x2, y2 = MakieViews.downsample(MakieViews.UniformStride(10), x, y)
    @test x2[1] == 1.0 && x2[end] == 100.0
    @test issorted(x2)
    @test length(x2) == length(y2)
    @test length(x2) <= length(x)
    @test all(in(x), x2)
end

@testset "M10 downsample — MinMaxDecimation" begin
    x = collect(1.0:1000.0); y = sin.(x ./ 10)
    nb = 50
    x2, y2 = MakieViews.downsample(MakieViews.MinMaxDecimation(nb), x, y)
    @test x2[1] == 1.0 && x2[end] == 1000.0
    @test issorted(x2)
    @test length(x2) == length(y2)
    @test length(x2) <= 2 * nb + 2
    @test maximum(y2) ≈ maximum(y)     # envelope: global extremes retained
    @test minimum(y2) ≈ minimum(y)
end

@testset "M10 downsample — LTTB" begin
    x = collect(1.0:1000.0); y = sin.(x ./ 10)
    thr = 100
    x2, y2 = MakieViews.downsample(MakieViews.LTTB(thr), x, y)
    @test length(x2) == thr
    @test length(y2) == thr
    @test x2[1] == 1.0 && x2[end] == 1000.0
    @test issorted(x2)
    xs = collect(1.0:10.0); ys = xs .^ 2       # n_target >= n returns original length
    xo, yo = MakieViews.downsample(MakieViews.LTTB(50), xs, ys)
    @test length(xo) == 10
end
