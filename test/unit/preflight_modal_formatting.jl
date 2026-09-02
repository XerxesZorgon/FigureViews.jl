# test/unit/preflight_modal_formatting.jl
using Test
using FigureViews
using FigureViews: _format_preflight_body

@testset "preflight_modal_formatting" begin
    # a. reason=:fps
    body_fps = _format_preflight_body((decision = :warn, reason = :fps, est_fps = 8.3, est_bytes = 1_500_000))
    @test occursin("1.5", body_fps)
    @test occursin("8.3", body_fps)
    @test occursin("frame rate", body_fps)

    # b. reason=:vram
    body_vram = _format_preflight_body((decision = :warn, reason = :vram, est_fps = 8.3, est_bytes = 1_500_000))
    @test occursin("VRAM", body_vram)
    @test !occursin("frame rate", body_vram)

    # c. reason=:both
    body_both = _format_preflight_body((decision = :warn, reason = :both, est_fps = 8.3, est_bytes = 1_500_000))
    @test occursin("frame rate", body_both)
    @test occursin("VRAM", body_both)
end
