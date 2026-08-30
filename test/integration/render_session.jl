@testset "M11 render_session — headless render + export" begin
    s = FigureViews.new_session()
    fig = FigureViews.add_figure!(s; title = "F")
    ax = FigureViews.add_axis!(fig; kind = :axis2d, title = "A")
    s.data_snapshots["x"] = collect(1.0:50.0)
    s.data_snapshots["y"] = sin.((1.0:50.0) ./ 10)
    FigureViews.add_plot!(ax, :line,
        [FigureViews.DataRef(:x, "x", :main, "x"), FigureViews.DataRef(:y, "y", :main, "y")])
    r = FigureViews.render_session(s)
    @test r isa FigureViews.Renderer
    mktempdir() do dir
        out = joinpath(dir, "rs.png")
        FigureViews.export_figure(r, out)
        @test isfile(out)
        @test filesize(out) > 0
    end
end
