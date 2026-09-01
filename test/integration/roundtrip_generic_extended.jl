# test/integration/roundtrip_generic_extended.jl
# M14 Task 098: Full generic-node round-trip test suite (10 sampled types)

using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, save_session, load_session,
                  render_session, typed_value, Plot, PlotMeta, DataRef, AnimBinding
using Observables
import CairoMakie

@testset "roundtrip_generic_extended" begin
    # 10 sampled types from REGISTRY (excluding original 7)
    # Note: :rangebars is used in place of :contourf per acceptance criterion
    # (substitute with another :valid type using plain numeric vectors).
    test_cases = [
        (:lines,        [collect(1.0:10.0), rand(10)]),
        (:scatterlines, [collect(1.0:10.0), rand(10)]),
        (:linesegments, [collect(1.0:10.0), rand(10)]),
        (:stairs,       [collect(1.0:10.0), rand(10)]),
        (:stem,         [collect(1.0:10.0), rand(10)]),
        (:band,         [collect(1.0:10.0), rand(10), rand(10) .+ 1.0]),
        (:hist,         [randn(50)]),
        (:density,      [randn(50)]),
        (:rangebars,    [collect(1.0:10.0), rand(10), rand(10) .+ 1.0]),
        (:errorbars,    [collect(1.0:10.0), rand(10), fill(0.1, 10), fill(0.1, 10)]),
    ]

    for (func_sym, d_args) in test_cases
        @testset "$func_sym" begin
            # 1. Build
            s = new_session()
            fig = add_figure!(s; title = "Fig_$func_sym")
            ax = add_axis!(fig; kind = :axis2d, title = "Ax_$func_sym")
            t_args = [typed_value(a) for a in d_args]
            p = Plot(
                string(FigureViews.UUIDs.uuid4()),
                ax.id,
                func_sym,
                t_args,
                Dict{Symbol, Any}(),
                (makie_major = 0, makie_minor = 24),
                PlotMeta(v"1.0.0", :valid),
                func_sym,
                Observable(DataRef[]),
                Dict{Symbol, Observable{Any}}(),
                Observable{Union{Nothing, AnimBinding}}(nothing)
            )
            ax.plots[] = [p]

            # 2. Save
            tmp = tempname() * ".mvz"
            try
                @test_nowarn save_session(s, tmp)
                @test isfile(tmp)

                # 3. Load
                loaded = nothing
                @test_nowarn begin
                    loaded = load_session(tmp)
                end
                @test loaded isa FigureViews.Session
                @test length(loaded.figures[]) == 1

                # 4. Verify load
                loaded_plot = loaded.figures[][1].axes[][1].plots[][1]
                @test loaded_plot.func == func_sym
                @test loaded_plot.meta.status == :valid

                # 5. Render
                CairoMakie.activate!()
                r = nothing
                @test_nowarn begin
                    r = render_session(loaded)
                end
                @test r isa FigureViews.Renderer
                @test haskey(r.plot_handles, loaded_plot.id)
            finally
                rm(tmp, force = true)
            end
        end
    end
end
