using Test, FigureViews, Makie
using FigureViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, DataRef,
                  MainSource, animate_plot!, Renderer, render_animation, save_session, load_session

function _make_anim_session()
    s   = new_session()
    fig = add_figure!(s)
    ax  = add_axis!(fig; kind=:axis2d)
    m   = Module(:_Anim)
    vol = [Float64(i + j + t) for i in 1:8, j in 1:8, t in 1:5]
    Core.eval(m, :(vol = $vol))
    src      = MainSource(m)
    snap_vol = Base.invokelatest(ingest!, s, src, "vol")
    mat0     = vol[:, :, 1]
    m2       = Module(:_Anim2); Core.eval(m2, :(mat = $mat0))
    src2     = MainSource(m2)
    snap_mat = Base.invokelatest(ingest!, s, src2, "mat")
    plot_node = add_plot!(ax, :heatmap, [DataRef(:matrix, snap_mat, :main, "mat")])
    animate_plot!(s, plot_node, snap_vol, 5; fps=10)
    return s, plot_node
end

@testset "M7 AnimBinding — animate_plot! sets binding correctly" begin
    s, plot_node = _make_anim_session()
    b = plot_node.animation_binding[]
    @test b isa FigureViews.AnimBinding
    @test b.frame_count == 5
    @test b.fps == 10
    @test b.current_frame == 1
    @test haskey(s.data_snapshots, b.snapshot_id)
    @test ndims(s.data_snapshots[b.snapshot_id]) == 3
end

@testset "M7 AnimBinding — save/load round-trip" begin
    s, plot_node = _make_anim_session()
    tmp = tempname() * ".mvz"
    save_session(s, tmp)
    s2  = load_session(tmp)
    rm(tmp)
    b2  = s2.figures[][1].axes[][1].plots[][1].animation_binding[]
    @test b2 isa FigureViews.AnimBinding
    @test b2.frame_count == 5
    @test b2.fps == 10
end

@testset "M7 render_animation — exports GIF of non-zero size" begin
    s, plot_node = _make_anim_session()
    makie_fig    = Makie.Figure()
    renderer     = Renderer(s, makie_fig)
    tmp          = tempname() * ".gif"
    render_animation(s, renderer, plot_node, tmp; fps=5)
    @test isfile(tmp)
    @test filesize(tmp) > 0
    rm(tmp)
end
