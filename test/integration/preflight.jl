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
