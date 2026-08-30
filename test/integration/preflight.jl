using Test
using FigureViews

@testset "M10 detect_host_specs — host detection populates and never throws" begin
    hs = FigureViews.detect_host_specs()
    @test hs isa FigureViews.HostSpecs
    @test hs.total_memory_bytes > 0
    @test hs.cpu_threads >= 1
    @test hs.vram_bytes === nothing || hs.vram_bytes > 0
    @test hs.gpu_name === nothing || hs.gpu_name isa String
end

@testset "M10 estimate_footprint — bytes = length × sizeof(eltype)" begin
    @test FigureViews.estimate_footprint(zeros(Float64, 1000)) == 8000
    @test FigureViews.estimate_footprint(zeros(Int32, 100, 100)) == 40000
    @test FigureViews.estimate_footprint(rand(UInt8, 256)) == 256
end

@testset "M10 estimate_fps — fallback formula + user_scale" begin
    ref = FigureViews.HostSpecs(16 * 1024^3, 8, 8 * 1024^3, "Ref GPU")     # user_scale = 1.0
    @test FigureViews.estimate_fps(:line,    1_000_000, ref) ≈ 60.0
    @test FigureViews.estimate_fps(:surface, 1_000_000, ref) ≈ 30.0
    @test FigureViews.estimate_fps(:line,    4_000_000, ref) ≈ 30.0        # 60/sqrt(4)
    @test FigureViews.estimate_fps(:volume,  4_000_000, ref) ≈ 15.0        # 30/sqrt(4)

    novram = FigureViews.HostSpecs(16 * 1024^3, 8, nothing, nothing)       # user_scale = 0.5
    @test FigureViews.estimate_fps(:line, 1_000_000, novram) ≈ 30.0

    big = FigureViews.HostSpecs(16 * 1024^3, 8, 100 * 1024^3, "Big")       # ratio 12.5 → clamp 10.0
    @test FigureViews.estimate_fps(:line, 1_000_000, big) ≈ 600.0
    small = FigureViews.HostSpecs(16 * 1024^3, 8, 100 * 1024^2, "Small")   # 100 MiB → clamp 0.1
    @test FigureViews.estimate_fps(:line, 1_000_000, small) ≈ 6.0

    @test isfinite(FigureViews.estimate_fps(:line, 0, ref))               # n≤0 guarded
end

@testset "M10 preflight_decision — threshold logic" begin
    host = FigureViews.HostSpecs(32 * 1024^3, 16, 8 * 1024^3, "GPU")  # 8 GiB VRAM

    d1 = FigureViews.preflight_decision(host, zeros(Float64, 1000), :line)
    @test d1.decision == :accept
    @test d1.reason == :ok

    d2 = FigureViews.preflight_decision(host, zeros(Float64, 100_000_000), :line)  # fps 6 < 15
    @test d2.decision == :warn
    @test d2.est_fps < 15

    # predicate directly (isolating the VRAM term from the fps term):
    @test FigureViews.over_threshold(host, 5 * 1024^3, 60.0) == true    # bytes > 0.6*8GiB, fps ok
    @test FigureViews.over_threshold(host, 1000, 60.0) == false         # both ok

    novram = FigureViews.HostSpecs(32 * 1024^3, 16, nothing, nothing)   # FR-026: fps-only
    @test FigureViews.over_threshold(novram, 100 * 1024^3, 60.0) == false  # VRAM term ignored
    @test FigureViews.over_threshold(novram, 100 * 1024^3, 10.0) == true   # fps < 15 → over
end

@testset "M10 record_downsample! — records algorithm in plot attrs" begin
    s = FigureViews.new_session()
    fig = FigureViews.add_figure!(s; title = "F")
    ax = FigureViews.add_axis!(fig; kind = :axis2d, title = "A")
    p = FigureViews.add_plot!(ax, :line,
        [FigureViews.DataRef(:x, "s1", :main, "x"), FigureViews.DataRef(:y, "s2", :main, "y")])
    @test !haskey(p.attrs, :downsample_algorithm)
    FigureViews.record_downsample!(p, FigureViews.LTTB(50))
    @test haskey(p.attrs, :downsample_algorithm)
    @test p.attrs[:downsample_algorithm][] == FigureViews.LTTB(50)
end

@testset "M10 apply_downsample! — reduces plot data, retains full" begin
    s = FigureViews.new_session()
    fig = FigureViews.add_figure!(s; title = "F")
    ax = FigureViews.add_axis!(fig; kind = :axis2d, title = "A")
    n = 10_000
    xfull = collect(1.0:n); yfull = sin.(xfull ./ 100)
    s.data_snapshots["xfull"] = xfull
    s.data_snapshots["yfull"] = yfull
    p = FigureViews.add_plot!(ax, :line,
        [FigureViews.DataRef(:x, "xfull", :main, "x"),
         FigureViews.DataRef(:y, "yfull", :main, "y")])

    FigureViews.apply_downsample!(s, p, FigureViews.LTTB(100))

    refs = p.data_refs[]
    xref = refs[findfirst(r -> r.role == :x, refs)]
    yref = refs[findfirst(r -> r.role == :y, refs)]
    @test length(s.data_snapshots[xref.snapshot_id]) == 100     # reduced to target
    @test length(s.data_snapshots[yref.snapshot_id]) == 100
    @test xref.snapshot_id != "xfull"                           # refs repointed
    @test haskey(s.data_snapshots, "xfull")                     # full retained (TEST_PLAN §8)
    @test length(s.data_snapshots["xfull"]) == n
    @test p.attrs[:downsample_algorithm][] == FigureViews.LTTB(100)

    # 2-D field plot (no :x/:y) is rejected
    ax3 = FigureViews.add_axis!(fig; kind = :axis3d, title = "S")
    s.data_snapshots["m"] = rand(4, 4)
    ps = FigureViews.add_plot!(ax3, :surface, [FigureViews.DataRef(:matrix, "m", :main, "m")])
    @test_throws ArgumentError FigureViews.apply_downsample!(s, ps, FigureViews.UniformStride(2))
end

@testset "M10 add_plot_checked! — pre-flight-aware add" begin
    s = FigureViews.new_session()
    fig = FigureViews.add_figure!(s; title = "F")
    ax = FigureViews.add_axis!(fig; kind = :axis2d, title = "A")
    host_big  = FigureViews.HostSpecs(32 * 1024^3, 16, 8 * 1024^3, "GPU")
    host_tiny = FigureViews.HostSpecs(32 * 1024^3, 16, 1000, "TinyGPU")   # forces VRAM-over on any array

    s.data_snapshots["sx"] = collect(1.0:1000.0); s.data_snapshots["sy"] = sin.((1.0:1000.0) ./ 50)
    r1 = FigureViews.add_plot_checked!(ax, :line,
        [FigureViews.DataRef(:x, "sx", :main, "x"), FigureViews.DataRef(:y, "sy", :main, "y")];
        session = s, host = host_big)
    @test r1.decision == :accept
    @test r1.plot !== nothing

    s.data_snapshots["bx"] = collect(1.0:1000.0); s.data_snapshots["by"] = sin.((1.0:1000.0) ./ 50)
    r2 = @test_logs (:warn, r"pre-flight") match_mode=:any FigureViews.add_plot_checked!(ax, :line,
        [FigureViews.DataRef(:x, "bx", :main, "x"), FigureViews.DataRef(:y, "by", :main, "y")];
        session = s, host = host_tiny)
    @test r2.decision == :warn
    @test r2.plot !== nothing            # advisory: still added at full size

    s.data_snapshots["dx"] = collect(1.0:1000.0); s.data_snapshots["dy"] = sin.((1.0:1000.0) ./ 50)
    r3 = FigureViews.add_plot_checked!(ax, :line,
        [FigureViews.DataRef(:x, "dx", :main, "x"), FigureViews.DataRef(:y, "dy", :main, "y")];
        session = s, host = host_tiny, downsample = FigureViews.LTTB(50))
    @test r3.plot !== nothing
    @test r3.plot.attrs[:downsample_algorithm][] == FigureViews.LTTB(50)
    xref = r3.plot.data_refs[][findfirst(r -> r.role == :x, r3.plot.data_refs[])]
    @test length(s.data_snapshots[xref.snapshot_id]) == 50   # reduced on the downsample path
end
