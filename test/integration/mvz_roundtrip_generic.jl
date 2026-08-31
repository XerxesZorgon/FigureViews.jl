# test/integration/mvz_roundtrip_generic.jl
# M14 Task 093: Round-trip the generic node through .mvz save/load for the 7 types

using Test, FigureViews
using FigureViews: new_session, add_figure!, add_axis!, add_plot!, DataRef,
                  save_session, load_session, Renderer, REGISTRY,
                  TypedValue, typed_value, decode_typed_value
using Colors
import Makie
import TOML

function _make_session_with_plot(ptype::Symbol, non_default_attrs::Dict{Symbol, Any})
    s = new_session()
    fig = add_figure!(s; title="GenericRoundTrip_$(ptype)")
    kind = ptype in (:surface, :volume) ? :axis3d : :axis2d
    ax = add_axis!(fig; kind=kind, title="Axis_$(ptype)")

    refs = DataRef[]
    if ptype in (:line, :scatter, :bar)
        n = ptype == :bar ? 5 : 10
        s.data_snapshots["$(ptype)_x"] = collect(1.0:Float64(n))
        s.data_snapshots["$(ptype)_y"] = ptype == :bar ? [2.0, 4.0, 1.0, 5.0, 3.0] : sin.(1.0:Float64(n))
        push!(refs, DataRef(:x, "$(ptype)_x", :main, "x"))
        push!(refs, DataRef(:y, "$(ptype)_y", :main, "y"))
    elseif ptype == :heatmap
        s.data_snapshots["heatmap_m"] = rand(6, 6)
        push!(refs, DataRef(:matrix, "heatmap_m", :main, "matrix"))
    elseif ptype in (:contour, :surface)
        s.data_snapshots["$(ptype)_x"] = collect(1.0:8.0)
        s.data_snapshots["$(ptype)_y"] = collect(1.0:8.0)
        s.data_snapshots["$(ptype)_m"] = rand(8, 8)
        push!(refs, DataRef(:x, "$(ptype)_x", :main, "x"))
        push!(refs, DataRef(:y, "$(ptype)_y", :main, "y"))
        push!(refs, DataRef(:matrix, "$(ptype)_m", :main, "matrix"))
    elseif ptype == :volume
        s.data_snapshots["volume_v"] = rand(5, 5, 5)
        push!(refs, DataRef(:volume, "volume_v", :main, "volume"))
    end

    add_plot!(ax, ptype, refs)
    orig_plot = ax.plots[][1]
    for (k, v) in non_default_attrs
        orig_plot.attrs[k][] = v
    end

    return s, orig_plot
end

@testset "M14 generic .mvz round-trip — 7 plot types value & type preservation" begin
    test_configs = [
        (:line, Dict{Symbol, Any}(
            :color => Colors.RGB(1.0, 0.0, 0.5),
            :linewidth => 3.5,
            :linestyle => :dash
        )),
        (:scatter, Dict{Symbol, Any}(
            :color => Colors.RGB(0.2, 0.7, 0.4),
            :markersize => 18.0,
            :marker => :rect
        )),
        (:bar, Dict{Symbol, Any}(
            :color => Colors.RGB(0.9, 0.4, 0.1),
            :direction => :x
        )),
        (:heatmap, Dict{Symbol, Any}(
            :colormap => :plasma,
            :colorrange => (0.2, 0.8)
        )),
        (:contour, Dict{Symbol, Any}(
            :color => Colors.RGB(0.8, 0.2, 0.5),
            :linewidth => 2.5,
            :levels => 7
        )),
        (:surface, Dict{Symbol, Any}(
            :colormap => :magma,
            :shading => :multi
        )),
        (:volume, Dict{Symbol, Any}(
            :colormap => :blues,
            :algorithm => :iso,
            :absorption => 2.5
        )),
    ]

    for (ptype, non_defaults) in test_configs
        @testset "Round-trip :$(ptype)" begin
            s, orig_plot = _make_session_with_plot(ptype, non_defaults)
            tmp = joinpath(mktempdir(), "roundtrip_$(ptype).mvz")
            save_session(s, tmp)
            @test isfile(tmp)

            s2 = load_session(tmp)
            # Rehydrate in-memory snapshots for headless rendering
            s2.data_snapshots = copy(s.data_snapshots)

            @test length(s2.figures[]) == 1
            @test length(s2.figures[][1].axes[]) == 1
            @test length(s2.figures[][1].axes[][1].plots[]) == 1

            plot2 = s2.figures[][1].axes[][1].plots[][1]
            @test plot2.func == ptype
            @test plot2.type == ptype
            @test plot2.meta.status == :valid

            # 1. Assert args equality by value and by type
            @test typeof(plot2.args) == typeof(orig_plot.args)
            @test length(plot2.args) == length(orig_plot.args)
            for i in 1:length(orig_plot.args)
                @test typeof(plot2.args[i]) == typeof(orig_plot.args[i])
                @test plot2.args[i] == orig_plot.args[i]
                orig_val = decode_typed_value(orig_plot.args[i])
                loaded_val = decode_typed_value(plot2.args[i])
                @test typeof(loaded_val) == typeof(orig_val)
                @test loaded_val == orig_val
            end

            # 2. Assert kwargs equality by value and by type
            @test typeof(plot2.kwargs) == typeof(orig_plot.kwargs)
            for (k, orig_tv) in orig_plot.kwargs
                @test haskey(plot2.kwargs, k)
                loaded_tv = plot2.kwargs[k]
                @test typeof(loaded_tv) == typeof(orig_tv)
                @test loaded_tv == orig_tv

                # Decoded value preservation by type and value
                orig_val = decode_typed_value(orig_tv)
                loaded_val = decode_typed_value(loaded_tv)
                @test typeof(loaded_val) == typeof(orig_val)
                if orig_val isa Colors.Colorant
                    @test isapprox(Float64(loaded_val.r), Float64(orig_val.r); atol=0.01)
                    @test isapprox(Float64(loaded_val.g), Float64(orig_val.g); atol=0.01)
                    @test isapprox(Float64(loaded_val.b), Float64(orig_val.b); atol=0.01)
                else
                    @test loaded_val == orig_val
                end
            end

            # 3. Explicit check that non-default attributes preserved their types and values
            for (k, expected_v) in non_defaults
                loaded_tv = plot2.kwargs[k]
                decoded = decode_typed_value(loaded_tv)
                @test typeof(decoded) == typeof(expected_v)
                if expected_v isa Colors.Colorant
                    @test isapprox(Float64(decoded.r), Float64(expected_v.r); atol=0.01)
                    @test isapprox(Float64(decoded.g), Float64(expected_v.g); atol=0.01)
                    @test isapprox(Float64(decoded.b), Float64(expected_v.b); atol=0.01)
                else
                    @test decoded == expected_v
                end
            end

            # 4. Render the loaded session via existing path; assert no error
            makie_fig = Makie.Figure()
            renderer = Renderer(s2, makie_fig)
            @test renderer isa Renderer
            @test haskey(renderer.plot_handles, plot2.id)
        end
    end
end

@testset "M14 preserve-and-warn — unknown kwarg preserved with status :unresolved" begin
    s, orig_plot = _make_session_with_plot(:line, Dict{Symbol, Any}(:linewidth => 3.0))
    tmp = joinpath(mktempdir(), "unknown_kwarg.mvz")
    save_session(s, tmp)

    # Read TOML and inject an unknown kwarg key
    raw = open(tmp) do io
        TOML.parse(io)
    end
    raw["figure"][1]["axis"][1]["plot"][1]["kwargs"]["custom_unknown_key"] = Dict(
        "type" => "Real",
        "value" => 99.5
    )
    open(tmp, "w") do io
        TOML.print(io, raw)
    end

    # Load session and verify preserve-and-warn
    s2 = @test_logs (:warn, r"Unknown kwarg key 'custom_unknown_key' for plot type :line preserved with status :unresolved") load_session(tmp)

    plot2 = s2.figures[][1].axes[][1].plots[][1]
    @test plot2.meta.status == :unresolved
    @test haskey(plot2.kwargs, :custom_unknown_key)
    @test plot2.kwargs[:custom_unknown_key].type == :Real
    @test plot2.kwargs[:custom_unknown_key].value == 99.5
    @test haskey(plot2.attrs, :custom_unknown_key)
    @test plot2.attrs[:custom_unknown_key][] == 99.5

    # Re-save and assert unknown key survives
    tmp2 = joinpath(mktempdir(), "resaved_unknown.mvz")
    save_session(s2, tmp2)
    raw2 = open(tmp2) do io
        TOML.parse(io)
    end
    @test haskey(raw2["figure"][1]["axis"][1]["plot"][1]["kwargs"], "custom_unknown_key")
    @test raw2["figure"][1]["axis"][1]["plot"][1]["meta"]["status"] == "unresolved"
end
