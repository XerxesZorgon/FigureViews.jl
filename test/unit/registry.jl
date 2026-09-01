using Test
using FigureViews
using FigureViews: REGISTRY, PlotTypeEntry, AttrSpec, TypedValue, PlotMeta,
                   new_session, add_figure!, add_axis!, add_plot!, ingest!,
                   DataRef, MainSource, Renderer
using Makie
using Colors

@testset "M14 registry — 7 existing types registered and valid" begin
    @test length(REGISTRY) >= 7
    @test length(FigureViews.REFERENCE_7) == 7
    expected_types = [:line, :scatter, :bar, :heatmap, :contour, :surface, :volume]
    for sym in expected_types
        @test haskey(REGISTRY, sym)
        entry = REGISTRY[sym]
        @test entry isa PlotTypeEntry
        @test entry.func == sym
        @test entry.status == :valid
        @test entry.api.makie_major == 0
        @test entry.api.makie_minor == 24
        @test !isempty(entry.attributes)
        for (attr_name, attr_spec) in entry.attributes
            @test attr_spec isa AttrSpec
            @test attr_spec.type isa Symbol
            @test attr_spec.widget in (:colorpicker, :numeric, :dropdown, :text, :checkbox)
        end
    end
end

@testset "M14 registry — generic plot node has all 7 fields populated for all 7 types" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax2d = add_axis!(fig_node; kind = :axis2d)
    ax3d = add_axis!(fig_node; kind = :axis3d)

    # Ingest test data into session
    x = collect(1.0:10.0)
    y = collect(1.0:10.0)
    mat = [sin(i/2) * cos(j/2) for i in 1:10, j in 1:10]
    vol = [Float64(i + j + k) for i in 1:5, j in 1:5, k in 1:5]

    _m = Module(:_T_reg)
    Core.eval(_m, :(x = $x))
    Core.eval(_m, :(y = $y))
    Core.eval(_m, :(mat = $mat))
    Core.eval(_m, :(vol = $vol))
    src = MainSource(_m)

    snap_x = ingest!(s, src, "x")
    snap_y = ingest!(s, src, "y")
    snap_mat = ingest!(s, src, "mat")
    snap_vol = ingest!(s, src, "vol")

    ref_x = DataRef(:x, snap_x, :main, "x")
    ref_y = DataRef(:y, snap_y, :main, "y")
    ref_mat = DataRef(:matrix, snap_mat, :main, "mat")
    ref_vol = DataRef(:volume, snap_vol, :main, "vol")

    type_refs = Dict(
        :line    => (ax2d, [ref_x, ref_y]),
        :scatter => (ax2d, [ref_x, ref_y]),
        :bar     => (ax2d, [ref_x, ref_y]),
        :heatmap => (ax2d, [ref_mat]),
        :contour => (ax2d, [ref_x, ref_y, ref_mat]),
        :surface => (ax3d, [ref_x, ref_y, ref_mat]),
        :volume  => (ax3d, [ref_vol]),
    )

    for (sym, (ax, refs)) in type_refs
        plot = add_plot!(ax, sym, refs)
        
        # Verify all 7 ADR-026 generic fields are populated
        @test !isempty(plot.id)
        @test plot.target == ax.id
        @test plot.func == sym
        @test !isempty(plot.args)
        @test !isempty(plot.kwargs)
        @test plot.api == (makie_major = 0, makie_minor = 24)
        @test plot.meta isa PlotMeta
        @test plot.meta.status == :valid
        @test plot.meta.schema_version == v"1.0.0"

        # Verify kwargs keys match registry entry attributes
        reg_entry = REGISTRY[sym]
        for attr_name in keys(reg_entry.attributes)
            @test haskey(plot.kwargs, attr_name)
            @test plot.kwargs[attr_name] isa TypedValue
        end

        # Verify backward compatibility fields
        @test plot.type == sym
        @test length(plot.data_refs[]) == length(refs)
        @test !isempty(plot.attrs)
    end
end

@testset "M14 registry — sanity render of all 7 types via existing path succeeds" begin
    s = new_session()
    fig_node = add_figure!(s)
    ax2d = add_axis!(fig_node; kind = :axis2d)
    ax3d = add_axis!(fig_node; kind = :axis3d)

    x = collect(1.0:10.0)
    y = collect(1.0:10.0)
    mat = [sin(i/2) * cos(j/2) for i in 1:10, j in 1:10]
    vol = [Float64(i + j + k) for i in 1:5, j in 1:5, k in 1:5]

    _m = Module(:_T_reg_render)
    Core.eval(_m, :(x = $x))
    Core.eval(_m, :(y = $y))
    Core.eval(_m, :(mat = $mat))
    Core.eval(_m, :(vol = $vol))
    src = MainSource(_m)

    snap_x = ingest!(s, src, "x")
    snap_y = ingest!(s, src, "y")
    snap_mat = ingest!(s, src, "mat")
    snap_vol = ingest!(s, src, "vol")

    ref_x = DataRef(:x, snap_x, :main, "x")
    ref_y = DataRef(:y, snap_y, :main, "y")
    ref_mat = DataRef(:matrix, snap_mat, :main, "mat")
    ref_vol = DataRef(:volume, snap_vol, :main, "vol")

    p_line    = add_plot!(ax2d, :line, [ref_x, ref_y])
    p_scatter = add_plot!(ax2d, :scatter, [ref_x, ref_y])
    p_bar     = add_plot!(ax2d, :bar, [ref_x, ref_y])
    p_heatmap = add_plot!(ax2d, :heatmap, [ref_mat])
    p_contour = add_plot!(ax2d, :contour, [ref_x, ref_y, ref_mat])
    p_surface = add_plot!(ax3d, :surface, [ref_x, ref_y, ref_mat])
    p_volume  = add_plot!(ax3d, :volume, [ref_vol])

    plots = [p_line, p_scatter, p_bar, p_heatmap, p_contour, p_surface, p_volume]

    makie_fig = Makie.Figure()
    renderer = Renderer(s, makie_fig)

    @test haskey(renderer.axis_handles, ax2d.id)
    @test haskey(renderer.axis_handles, ax3d.id)

    for p in plots
        @test haskey(renderer.plot_handles, p.id)
        @test renderer.plot_handles[p.id] !== nothing
    end
end
