@testset "M11 render_session — headless render + export" begin
    s = MakieViews.new_session()
    fig = MakieViews.add_figure!(s; title = "F")
    ax = MakieViews.add_axis!(fig; kind = :axis2d, title = "A")
    s.data_snapshots["x"] = collect(1.0:50.0)
    s.data_snapshots["y"] = sin.((1.0:50.0) ./ 10)
    MakieViews.add_plot!(ax, :line,
        [MakieViews.DataRef(:x, "x", :main, "x"), MakieViews.DataRef(:y, "y", :main, "y")])
    r = MakieViews.render_session(s)
    @test r isa MakieViews.Renderer
    mktempdir() do dir
        out = joinpath(dir, "rs.png")
        MakieViews.export_figure(r, out)
        @test isfile(out)
        @test filesize(out) > 0
    end
end
