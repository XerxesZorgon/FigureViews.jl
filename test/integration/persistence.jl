using Test, MakieViews
using MakieViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, DataRef, MainSource,
                  save_session, load_session, UnknownNode
using Colors
import TOML

function _make_line_session()
    s = new_session()
    fig = add_figure!(s; title="Persist")
    ax  = add_axis!(fig; kind=:axis2d, title="A1")
    m = Module(:_PT)
    Core.eval(m, :(x = collect(1.0:10.0)))
    Core.eval(m, :(y = sin.(collect(1.0:10.0))))
    src = MainSource(m)
    snap_x = Base.invokelatest(ingest!, s, src, "x")
    snap_y = Base.invokelatest(ingest!, s, src, "y")
    add_plot!(ax, :line,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])
    return s
end

@testset "M6 save/load — round-trip preserves tree structure" begin
    s   = _make_line_session()
    tmp = tempname() * ".mvz"
    save_session(s, tmp)
    s2  = load_session(tmp)
    rm(tmp)
    @test length(s2.figures[]) == 1
    @test s2.figures[][1].title[] == "Persist"
    ax2 = s2.figures[][1].axes[][1]
    @test ax2.title[] == "A1"
    @test ax2.kind   == :axis2d
    @test length(ax2.plots[]) == 1
    plot2 = ax2.plots[][1]
    @test plot2.type == :line
    @test plot2.attrs[:linewidth][] ≈ 1.5
end

@testset "M6 save/load — round-trip for all 7 plot types" begin
    for (ptype, roles, dims) in [
            (:line,    [:x, :y],           [(10,), (10,)]),
            (:scatter, [:x, :y],           [(10,), (10,)]),
            (:bar,     [:x, :y],           [(5,),  (5,)]),
            (:heatmap, [:matrix],          [(6, 6)]),
            (:contour, [:x, :y, :matrix],  [(8,),  (8,),  (8, 8)]),
            (:surface, [:x, :y, :matrix],  [(8,),  (8,),  (8, 8)]),
            (:volume,  [:volume],          [(5, 5, 5)]),
        ]
        s    = new_session()
        fig  = add_figure!(s)
        kind = ptype in (:surface, :volume) ? :axis3d : :axis2d
        ax   = add_axis!(fig; kind=kind)
        m    = Module(Symbol(:_PT_, ptype))
        refs = DataRef[]
        for (role, dim) in zip(roles, dims)
            arr = rand(dim...)
            Core.eval(m, :($(role) = $arr))
            src  = MainSource(m)
            snap = Base.invokelatest(ingest!, s, src, string(role))
            push!(refs, DataRef(role, snap, :main, string(role)))
        end
        add_plot!(ax, ptype, refs)
        tmp = tempname() * ".mvz"
        save_session(s, tmp)
        s2  = load_session(tmp)
        rm(tmp)
        plot2 = s2.figures[][1].axes[][1].plots[][1]
        @test plot2.type == ptype
    end
end

@testset "M6 save/load — camera state preserved" begin
    s   = new_session()
    fig = add_figure!(s)
    ax  = add_axis!(fig; kind=:axis3d)
    ax.camera[] = CameraSpec(1.23, 0.45, 2.0)
    tmp = tempname() * ".mvz"
    save_session(s, tmp)
    s2  = load_session(tmp)
    rm(tmp)
    cam = s2.figures[][1].axes[][1].camera[]
    @test cam !== nothing
    @test isapprox(cam.azimuth,   1.23; atol=1e-6)
    @test isapprox(cam.elevation, 0.45; atol=1e-6)
    @test isapprox(cam.zoom,      2.0;  atol=1e-6)
end

@testset "M6 save/load — color attr survives hex round-trip" begin
    s    = _make_line_session()
    ax   = s.figures[][1].axes[][1]
    plot = ax.plots[][1]
    plot.attrs[:color][] = Colors.RGB(1.0, 0.0, 0.5)
    tmp  = tempname() * ".mvz"
    save_session(s, tmp)
    s2   = load_session(tmp)
    rm(tmp)
    c2   = s2.figures[][1].axes[][1].plots[][1].attrs[:color][]
    @test c2 isa Colors.RGB
    @test isapprox(Float64(c2.r), 1.0; atol=0.01)
    @test isapprox(Float64(c2.g), 0.0; atol=0.01)
    @test isapprox(Float64(c2.b), 0.5; atol=0.01)
end

@testset "M6 save/load — unknown node type preserved" begin
    s   = _make_line_session()
    tmp = tempname() * ".mvz"
    save_session(s, tmp)
    # Inject an unknown plot type by string replacement
    content = read(tmp, String)
    content = replace(content, "\"line\"" => "\"custom_recipe_xyz\"")
    write(tmp, content)
    s2  = load_session(tmp)
    rm(tmp)
    node = s2.figures[][1].axes[][1].plots[][1]
    @test node isa MakieViews.UnknownNode
    @test node.original_type == "custom_recipe_xyz"
    # Re-save and confirm the type string survives
    tmp2     = tempname() * ".mvz"
    save_session(s2, tmp2)
    content2 = read(tmp2, String)
    rm(tmp2)
    @test occursin("custom_recipe_xyz", content2)
end

@testset "M6 error paths — major version mismatch errors" begin
    s   = _make_line_session()
    tmp = tempname() * ".mvz"
    save_session(s, tmp)
    content = replace(read(tmp, String),
                      "schema_version = \"1.0\"" => "schema_version = \"9.0\"")
    write(tmp, content)
    @test_throws Exception load_session(tmp)
    rm(tmp)
end

@testset "M6 error paths — data_inline rejected" begin
    # Build a raw dict that includes data_inline and write it via TOML directly
    # (string-appending invalid TOML is unreliable; inject via dict instead)
    s   = _make_line_session()
    tmp = tempname() * ".mvz"
    save_session(s, tmp)
    raw = open(tmp) do io TOML.parse(io) end
    # Insert data_inline into the first plot of the first axis of the first figure
    raw["figure"][1]["axis"][1]["plot"][1]["data_inline"] = Dict("foo" => 1)
    open(tmp, "w") do io TOML.print(io, raw) end
    @test_throws Exception load_session(tmp)
    rm(tmp)
end
