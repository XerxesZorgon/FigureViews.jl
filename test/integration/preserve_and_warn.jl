# test/integration/preserve_and_warn.jl
# M14 Task 097: Preserve-and-warn on load + degraded-render placeholder

using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, add_plot!, ingest!,
                  DataRef, MainSource, save_session, load_session, render_session
import CairoMakie
import Makie

@testset "preserve_and_warn" begin
    # 1. Load subtest
    s = new_session()
    fig = add_figure!(s; title = "TestFig")
    ax = add_axis!(fig; kind = :axis2d, title = "TestAx")
    _m = Module(:_T_pw)
    Core.eval(_m, :(x = collect(1.0:5.0)))
    Core.eval(_m, :(y = collect(1.0:5.0)))
    _src = MainSource(_m)
    sx = ingest!(s, _src, "x")
    sy = ingest!(s, _src, "y")
    add_plot!(ax, :scatter, [DataRef(:x, sx, :main, "x"), DataRef(:y, sy, :main, "y")])

    tmp1 = tempname() * ".mvz"
    save_session(s, tmp1)

    content = read(tmp1, String)
    content_modified = replace(content, "func = \"scatter\"" => "func = \"unknown_plot_xyzzy\"")
    content_modified = replace(content_modified, "type = \"scatter\"" => "type = \"unknown_plot_xyzzy\"")

    tmp2 = tempname() * ".mvz"
    write(tmp2, content_modified)

    loaded = @test_logs (:warn, r"unknown plot type") load_session(tmp2)
    rm(tmp1, force = true)
    rm(tmp2, force = true)

    plots = loaded.figures[][1].axes[][1].plots[]
    @test length(plots) == 1
    loaded_plot = plots[1]
    @test loaded_plot isa FigureViews.Plot
    @test loaded_plot.func == :unknown_plot_xyzzy
    @test loaded_plot.meta.status == :unresolved

    # 2. Render subtest
    CairoMakie.activate!()
    renderer = nothing
    @test_nowarn begin
        renderer = render_session(loaded)
    end
    @test renderer isa FigureViews.Renderer
    @test haskey(renderer.plot_handles, loaded_plot.id)
    handle = renderer.plot_handles[loaded_plot.id]
    @test handle isa Makie.Text
end
