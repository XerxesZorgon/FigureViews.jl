# test/unit/registry_generated.jl
# M14 Task 094: Registry generator validation and headless smoke renders

using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, Renderer, apply_structural!,
                  AddPlotOp, Plot, DataRef, PlotMeta, TypedValue, typed_value,
                  REGISTRY, REGISTRY_GENERATED, REFERENCE_7
import CairoMakie
import Makie
using Observables

@testset "registry_generated" begin
    @testset "reference 7 types matching in generated registry" begin
        ref_7_keys = [:line, :scatter, :bar, :heatmap, :contour, :surface, :volume]
        for k in ref_7_keys
            @test haskey(REGISTRY_GENERATED, k)
            @test haskey(REGISTRY, k)

            gen = REGISTRY_GENERATED[k]
            ref = REFERENCE_7[k]

            @test gen.func == ref.func
            @test gen.conversion_trait == ref.conversion_trait
            @test gen.positional_shape == ref.positional_shape
            @test gen.status == :valid

            # Verify all reference attributes are present in generated attributes
            for (attr_k, ref_spec) in ref.attributes
                @test haskey(gen.attributes, attr_k)
            end

            # In merged REGISTRY, the reference entry takes precedence
            @test REGISTRY[k] == ref
        end
    end

    @testset "status valid or needs_manual_review across all entries" begin
        for (sym, entry) in REGISTRY
            @test entry.status in (:valid, :needs_manual_review)
            @test !isempty(entry.positional_shape)
        end
    end

    @testset "at least 20 entries with status = :valid" begin
        valid_entries = filter(p -> p.second.status == :valid, collect(REGISTRY))
        @test length(valid_entries) >= 20
        # Specific known entry that needs review: arrows
        if haskey(REGISTRY, :arrows)
            @test REGISTRY[:arrows].status == :needs_manual_review
        end
    end

    @testset "headless smoke renders of 3 newly-covered :valid types (CairoMakie)" begin
        CairoMakie.activate!()
        new_types = [:scatterlines, :hist, :band]
        # Assert they are not among the original 7
        ref_7_keys = [:line, :scatter, :bar, :heatmap, :contour, :surface, :volume]
        for t in new_types
            @test !(t in ref_7_keys)
            @test haskey(REGISTRY, t)
            @test REGISTRY[t].status == :valid
        end

        # 1. Smoke render :scatterlines (PointBased: [:x_vector, :y_vector])
        begin
            s1 = new_session()
            fig_node = add_figure!(s1; title="SmokeScatterLines")
            ax_node = add_axis!(fig_node; kind=:axis2d, title="AxSL")
            makie_fig = CairoMakie.Figure()
            renderer = Renderer(s1, makie_fig)

            s1.data_snapshots["sl_x"] = collect(1.0:10.0)
            s1.data_snapshots["sl_y"] = sin.(1.0:10.0)
            refs = [
                DataRef(:x_vector, "sl_x", :main, "x"),
                DataRef(:y_vector, "sl_y", :main, "y")
            ]
            plot_node = Plot(
                "plot_sl",
                ax_node.id,
                :scatterlines,
                Any[typed_value(r) for r in refs],
                Dict{Symbol, Any}(k => typed_value(s.default) for (k, s) in REGISTRY[:scatterlines].attributes),
                (makie_major = 0, makie_minor = 24),
                PlotMeta(v"1.0.0", :valid),
                :scatterlines,
                Observable(refs),
                Dict{Symbol, Observable{Any}}(k => Observable{Any}(s.default) for (k, s) in REGISTRY[:scatterlines].attributes),
                Observable{Union{Nothing, FigureViews.AnimBinding}}(nothing)
            )

            @test_nowarn apply_structural!(renderer, AddPlotOp(ax_node, plot_node))
            @test haskey(renderer.plot_handles, "plot_sl")
            @test renderer.plot_handles["plot_sl"] isa Makie.ScatterLines
        end

        # 2. Smoke render :hist (NoConversion: [:values])
        begin
            s2 = new_session()
            fig_node = add_figure!(s2; title="SmokeHist")
            ax_node = add_axis!(fig_node; kind=:axis2d, title="AxHist")
            makie_fig = CairoMakie.Figure()
            renderer = Renderer(s2, makie_fig)

            s2.data_snapshots["hist_vals"] = randn(50)
            refs = [DataRef(:values, "hist_vals", :main, "values")]
            plot_node = Plot(
                "plot_hist",
                ax_node.id,
                :hist,
                Any[typed_value(r) for r in refs],
                Dict{Symbol, Any}(k => typed_value(s.default) for (k, s) in REGISTRY[:hist].attributes),
                (makie_major = 0, makie_minor = 24),
                PlotMeta(v"1.0.0", :valid),
                :hist,
                Observable(refs),
                Dict{Symbol, Observable{Any}}(k => Observable{Any}(s.default) for (k, s) in REGISTRY[:hist].attributes),
                Observable{Union{Nothing, FigureViews.AnimBinding}}(nothing)
            )

            @test_nowarn apply_structural!(renderer, AddPlotOp(ax_node, plot_node))
            @test haskey(renderer.plot_handles, "plot_hist")
            @test renderer.plot_handles["plot_hist"] isa Makie.Hist
        end

        # 3. Smoke render :band (NoConversion: [:x_vector, :y_lower, :y_upper])
        begin
            s3 = new_session()
            fig_node = add_figure!(s3; title="SmokeBand")
            ax_node = add_axis!(fig_node; kind=:axis2d, title="AxBand")
            makie_fig = CairoMakie.Figure()
            renderer = Renderer(s3, makie_fig)

            s3.data_snapshots["band_x"] = collect(1.0:10.0)
            s3.data_snapshots["band_yl"] = rand(10)
            s3.data_snapshots["band_yu"] = s3.data_snapshots["band_yl"] .+ 1.0
            refs = [
                DataRef(:x_vector, "band_x", :main, "x"),
                DataRef(:y_lower, "band_yl", :main, "y_lower"),
                DataRef(:y_upper, "band_yu", :main, "y_upper"),
            ]
            plot_node = Plot(
                "plot_band",
                ax_node.id,
                :band,
                Any[typed_value(r) for r in refs],
                Dict{Symbol, Any}(k => typed_value(s.default) for (k, s) in REGISTRY[:band].attributes),
                (makie_major = 0, makie_minor = 24),
                PlotMeta(v"1.0.0", :valid),
                :band,
                Observable(refs),
                Dict{Symbol, Observable{Any}}(k => Observable{Any}(s.default) for (k, s) in REGISTRY[:band].attributes),
                Observable{Union{Nothing, FigureViews.AnimBinding}}(nothing)
            )

            @test_nowarn apply_structural!(renderer, AddPlotOp(ax_node, plot_node))
            @test haskey(renderer.plot_handles, "plot_band")
            @test renderer.plot_handles["plot_band"] isa Makie.Band
        end
    end
end
