using Test, MakieViews
using MakieViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, DataRef, MainSource,
                  reset_to_preferences!, load_preferences, save_preferences, preferences_path
using Colors

@testset "M9 preferences — load returns defaults when absent" begin
    p = load_preferences()
    @test haskey(p, "schema_version")
    @test haskey(p, "default_linewidth")
    @test p["default_linewidth"] isa Real
end

@testset "M9 preferences — seed plot attrs from prefs" begin
    prefs = Dict{String,Any}("default_linewidth" => 4.0, "palette" => ["#ff0000", "#00ff00"])
    s = new_session(); fig = add_figure!(s); ax = add_axis!(fig; kind=:axis2d)
    m = Module(:_P1); Core.eval(m, :(x=collect(1.0:5.0))); Core.eval(m, :(y=collect(1.0:5.0)))
    src = MainSource(m); sx = ingest!(s, src, "x"); sy = ingest!(s, src, "y")
    plot = add_plot!(ax, :line, [DataRef(:x,sx,:main,"x"), DataRef(:y,sy,:main,"y")]; prefs=prefs)
    @test plot.attrs[:linewidth][] == 4.0
    @test plot.attrs[:color][] == parse(Colors.RGB, "#ff0000")
end

@testset "M9 preferences — palette cycles across plots in an axis" begin
    prefs = Dict{String,Any}("palette" => ["#ff0000", "#00ff00"])
    s = new_session(); fig = add_figure!(s); ax = add_axis!(fig; kind=:axis2d)
    m = Module(:_P2); Core.eval(m, :(x=collect(1.0:5.0))); Core.eval(m, :(y=collect(1.0:5.0)))
    src = MainSource(m); sx = ingest!(s, src, "x"); sy = ingest!(s, src, "y")
    p1 = add_plot!(ax, :line, [DataRef(:x,sx,:main,"x"), DataRef(:y,sy,:main,"y")]; prefs=prefs)
    p2 = add_plot!(ax, :line, [DataRef(:x,sx,:main,"x"), DataRef(:y,sy,:main,"y")]; prefs=prefs)
    @test p1.attrs[:color][] == parse(Colors.RGB, "#ff0000")   # palette[1]
    @test p2.attrs[:color][] == parse(Colors.RGB, "#00ff00")   # palette[2]
end

@testset "M9 preferences — reset_to_preferences! overwrites attrs" begin
    prefs = Dict{String,Any}("default_linewidth" => 4.0)
    s = new_session(); fig = add_figure!(s); ax = add_axis!(fig; kind=:axis2d)
    m = Module(:_P3); Core.eval(m, :(x=collect(1.0:5.0))); Core.eval(m, :(y=collect(1.0:5.0)))
    src = MainSource(m); sx = ingest!(s, src, "x"); sy = ingest!(s, src, "y")
    plot = add_plot!(ax, :line, [DataRef(:x,sx,:main,"x"), DataRef(:y,sy,:main,"y")])  # spec defaults
    plot.attrs[:linewidth][] = 99.0
    reset_to_preferences!(plot, prefs)
    @test plot.attrs[:linewidth][] == 4.0
    @test plot.attrs[:linestyle][] == :solid   # attr not in prefs → spec default
end

@testset "M9 preferences — missing pref field falls back to spec default" begin
    prefs = Dict{String,Any}()
    s = new_session(); fig = add_figure!(s); ax = add_axis!(fig; kind=:axis2d)
    m = Module(:_P4); Core.eval(m, :(x=collect(1.0:5.0))); Core.eval(m, :(y=collect(1.0:5.0)))
    src = MainSource(m); sx = ingest!(s, src, "x"); sy = ingest!(s, src, "y")
    plot = add_plot!(ax, :line, [DataRef(:x,sx,:main,"x"), DataRef(:y,sy,:main,"y")]; prefs=prefs)
    @test plot.attrs[:linewidth][] == 1.5
end

@testset "M9 ADR-006 gate — set_theme! never called in src/" begin
    src_dir = joinpath(@__DIR__, "..", "..", "src")
    offenders = String[]
    for (root, _dirs, files) in walkdir(src_dir)
        for f in files
            endswith(f, ".jl") || continue
            content = read(joinpath(root, f), String)
            if occursin("set_theme!(", content)
                push!(offenders, joinpath(root, f))
            end
        end
    end
    @test isempty(offenders)
end
