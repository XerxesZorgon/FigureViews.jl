using Test, FigureViews, Makie, CairoMakie
using FigureViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, DataRef,
                  MainSource, Renderer, export_figure

function _make_export_session(plot_type::Symbol; deterministic::Bool=false)
    s   = new_session()
    fig = add_figure!(s)
    kind = plot_type in (:surface, :volume) ? :axis3d : :axis2d
    ax  = add_axis!(fig; kind=kind)
    m   = Module(Symbol(:_Exp_, plot_type))
    refs = DataRef[]
    for (role, dim) in _roles_for(plot_type)
        arr = if !deterministic
            _demo_array(dim)
        elseif plot_type in (:line, :scatter)
            role == :x ? collect(1.0:Float64(dim[1])) : sin.(collect(1.0:Float64(dim[1])))
        elseif plot_type == :bar
            collect(1.0:Float64(dim[1]))
        elseif plot_type == :heatmap
            [Float64(i+j) for i in 1:dim[1], j in 1:dim[2]]
        elseif plot_type in (:contour, :surface)
            if role == :x
                collect(LinRange(0.0, 1.0, dim[1]))
            elseif role == :y
                collect(LinRange(0.0, 1.0, dim[1]))
            else
                [sin(xi)*cos(yi) for xi in LinRange(0.0, 1.0, dim[1]), yi in LinRange(0.0, 1.0, dim[2])]
            end
        elseif plot_type == :volume
            [Float64(i+j+k) for i in 1:dim[1], j in 1:dim[2], k in 1:dim[3]]
        end
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

if get(ENV, "FIGUREVIEWS_GOLDEN", "0") == "1"
    @testset "M8 golden-image hashes — all 7 plot types stable" begin
        using SHA, TOML
        hashes_file = joinpath(@__DIR__, "..", "goldens", "hashes.toml")
        ref_hashes  = TOML.parsefile(hashes_file)["golden_sha256"]

        for ptype in [:line, :scatter, :bar, :heatmap, :contour, :surface, :volume]
            s         = _make_export_session(ptype; deterministic=true)
            makie_fig = Makie.Figure()
            renderer  = Renderer(s, makie_fig)
            tmp       = tempname() * ".png"
            export_figure(renderer, tmp)
            got_hash  = bytes2hex(sha256(read(tmp)))
            rm(tmp)
            ref_hash  = get(ref_hashes, string(ptype), "")
            @test got_hash == ref_hash
        end
    end
else
    @info "Skipping golden-image testset (set FIGUREVIEWS_GOLDEN=1 to enable)"
end
