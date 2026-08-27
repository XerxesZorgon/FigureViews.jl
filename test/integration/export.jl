using Test, MakieViews, Makie, CairoMakie
using MakieViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, DataRef,
                  MainSource, Renderer, export_figure

function _make_export_session(plot_type::Symbol)
    s   = new_session()
    fig = add_figure!(s)
    kind = plot_type in (:surface, :volume) ? :axis3d : :axis2d
    ax  = add_axis!(fig; kind=kind)
    m   = Module(Symbol(:_Exp_, plot_type))
    refs = DataRef[]
    for (role, dim) in _roles_for(plot_type)
        arr = _demo_array(dim)
        Core.eval(m, :($(role) = $arr))
        src  = MainSource(m)
        snap = Base.invokelatest(ingest!, s, src, string(role))
        push!(refs, DataRef(role, snap, :main, string(role)))
    end
    add_plot!(ax, plot_type, refs)
    return s
end

function _roles_for(t)
    t == :line    && return [(:x,(10,)), (:y,(10,))]
    t == :scatter && return [(:x,(10,)), (:y,(10,))]
    t == :bar     && return [(:x,(5,)),  (:y,(5,))]
    t == :heatmap && return [(:matrix,(8,8))]
    t == :contour && return [(:x,(8,)), (:y,(8,)), (:matrix,(8,8))]
    t == :surface && return [(:x,(8,)), (:y,(8,)), (:matrix,(8,8))]
    t == :volume  && return [(:volume,(4,4,4))]
end

_demo_array(dim) = rand(dim...)

@testset "M8 export_figure — PNG produced for each plot type" begin
    for ptype in [:line, :scatter, :bar, :heatmap, :contour, :surface, :volume]
        s         = _make_export_session(ptype)
        makie_fig = Makie.Figure()
        renderer  = Renderer(s, makie_fig)
        tmp       = tempname() * ".png"
        export_figure(renderer, tmp)
        @test isfile(tmp)
        @test filesize(tmp) > 0
        rm(tmp)
    end
end

@testset "M8 export_figure — SVG produced" begin
    s         = _make_export_session(:line)
    makie_fig = Makie.Figure()
    renderer  = Renderer(s, makie_fig)
    tmp       = tempname() * ".svg"
    export_figure(renderer, tmp)
    @test isfile(tmp)
    @test filesize(tmp) > 0
    content = read(tmp, String)
    @test startswith(lstrip(content), "<")   # SVG is XML
    rm(tmp)
end

@testset "M8 export_figure — unsupported format errors" begin
    s         = _make_export_session(:line)
    makie_fig = Makie.Figure()
    renderer  = Renderer(s, makie_fig)
    @test_throws Exception export_figure(renderer, "out.xyz")
end
