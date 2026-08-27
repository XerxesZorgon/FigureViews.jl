using Test
using MakieViews

@testset "M10 detect_host_specs — host detection populates and never throws" begin
    hs = MakieViews.detect_host_specs()
    @test hs isa MakieViews.HostSpecs
    @test hs.total_memory_bytes > 0
    @test hs.cpu_threads >= 1
    @test hs.vram_bytes === nothing || hs.vram_bytes > 0
    @test hs.gpu_name === nothing || hs.gpu_name isa String
end

@testset "M10 estimate_footprint — bytes = length × sizeof(eltype)" begin
    @test MakieViews.estimate_footprint(zeros(Float64, 1000)) == 8000
    @test MakieViews.estimate_footprint(zeros(Int32, 100, 100)) == 40000
    @test MakieViews.estimate_footprint(rand(UInt8, 256)) == 256
end

@testset "M10 estimate_fps — fallback formula + user_scale" begin
    ref = MakieViews.HostSpecs(16 * 1024^3, 8, 8 * 1024^3, "Ref GPU")     # user_scale = 1.0
    @test MakieViews.estimate_fps(:line,    1_000_000, ref) ≈ 60.0
    @test MakieViews.estimate_fps(:surface, 1_000_000, ref) ≈ 30.0
    @test MakieViews.estimate_fps(:line,    4_000_000, ref) ≈ 30.0        # 60/sqrt(4)
    @test MakieViews.estimate_fps(:volume,  4_000_000, ref) ≈ 15.0        # 30/sqrt(4)

    novram = MakieViews.HostSpecs(16 * 1024^3, 8, nothing, nothing)       # user_scale = 0.5
    @test MakieViews.estimate_fps(:line, 1_000_000, novram) ≈ 30.0

    big = MakieViews.HostSpecs(16 * 1024^3, 8, 100 * 1024^3, "Big")       # ratio 12.5 → clamp 10.0
    @test MakieViews.estimate_fps(:line, 1_000_000, big) ≈ 600.0
    small = MakieViews.HostSpecs(16 * 1024^3, 8, 100 * 1024^2, "Small")   # 100 MiB → clamp 0.1
    @test MakieViews.estimate_fps(:line, 1_000_000, small) ≈ 6.0

    @test isfinite(MakieViews.estimate_fps(:line, 0, ref))               # n≤0 guarded
end
