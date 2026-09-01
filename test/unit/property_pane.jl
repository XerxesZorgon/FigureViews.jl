# test/unit/property_pane.jl
# M14 Task 095: Generic property panel driven by REGISTRY

using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, build_property_pane,
                  Plot, DataRef, PlotMeta, TypedValue, typed_value, REGISTRY
using Gtk4
using Observables
using Colors

@testset "generic property panel — REGISTRY-driven" begin
    s = new_session()
    fig = add_figure!(s; title = "F1")
    ax = add_axis!(fig; kind = :axis2d, title = "A1")

    prop_box = build_property_pane(s)
    @test prop_box isa GtkBox

    # Test unknown plot type displays fallback message
    p_unknown = Plot(
        "p_unk",
        ax.id,
        :unregistered_type,
        Any[],
        Dict{Symbol, Any}(),
        (makie_major = 0, makie_minor = 24),
        PlotMeta(v"1.0.0", :unresolved),
        :unregistered_type,
        Observable(DataRef[]),
        Dict{Symbol, Observable{Any}}(),
        Observable{Union{Nothing, FigureViews.AnimBinding}}(nothing)
    )
    push!(ax.plots[], p_unknown)
    s.selection[] = "p_unk"
    sleep(0.05)

    labels = String[]
    for child in prop_box
        if child isa GtkLabel
            push!(labels, Gtk4.text(child))
        end
    end
    @test any(occursin("Unknown plot type: unregistered_type", l) for l in labels)

    # Test known plot type from REGISTRY
    s.data_snapshots["x"] = [1.0, 2.0]
    s.data_snapshots["y"] = [3.0, 4.0]
    refs = [DataRef(:x, "x", :main, "x"), DataRef(:y, "y", :main, "y")]
    attrs = Dict{Symbol, Observable{Any}}(
        :color => Observable{Any}(RGB(0.1, 0.4, 0.8)),
        :linewidth => Observable{Any}(2.5),
        :label => Observable{Any}("TestLine"),
        :visible => Observable{Any}(true)
    )
    kwargs = Dict{Symbol, Any}(
        :linestyle => typed_value(:solid)
    )
    p_line = Plot(
        "p_line",
        ax.id,
        :line,
        Any[typed_value(r) for r in refs],
        kwargs,
        (makie_major = 0, makie_minor = 24),
        PlotMeta(v"1.0.0", :valid),
        :line,
        Observable(refs),
        attrs,
        Observable{Union{Nothing, FigureViews.AnimBinding}}(nothing)
    )
    push!(ax.plots[], p_line)
    s.selection[] = "p_line"
    sleep(0.05)

    # Verify rows were added for both plot.attrs (Observable) and plot.kwargs (read-only)
    rows = collect(prop_box)
    @test length(rows) >= 5
end
