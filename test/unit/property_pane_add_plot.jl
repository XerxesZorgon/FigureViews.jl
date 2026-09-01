using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!,
                   REGISTRY, AXIS_KIND_FOR_TYPE, _add_plot_to_axis!

@testset "property_pane_add_plot" begin
    # a. Asserts Set(keys(AXIS_KIND_FOR_TYPE)) == Set(keys(REGISTRY)) — every REGISTRY entry has an axis-kind entry.
    @test Set(keys(AXIS_KIND_FOR_TYPE)) == Set(keys(REGISTRY))

    # b. Asserts every value in AXIS_KIND_FOR_TYPE is one of :axis2d, :axis3d, :any.
    for (k, v) in AXIS_KIND_FOR_TYPE
        @test v in (:axis2d, :axis3d, :any)
    end

    # c. Builds a session with one figure and one :axis2d. Calls _add_plot_to_axis!(session, ax_node, :line) directly.
    #    Asserts the axis now has 1 plot with plot.func == :line and isempty(plot.data_refs[]).
    session2d = new_session()
    fig2d = add_figure!(session2d; title = "Fig 2D")
    ax2d = add_axis!(fig2d; kind = :axis2d, title = "Ax 2D")
    plot2d = _add_plot_to_axis!(session2d, ax2d, :line)
    @test length(ax2d.plots[]) == 1
    @test plot2d.type == :line
    @test plot2d.func == :line
    @test isempty(plot2d.data_refs[])

    # d. Builds a session with one figure and one :axis3d. Calls _add_plot_to_axis!(session, ax_node, :surface).
    #    Asserts success (1 plot, func/type == :surface, empty data_refs).
    session3d = new_session()
    fig3d = add_figure!(session3d; title = "Fig 3D")
    ax3d = add_axis!(fig3d; kind = :axis3d, title = "Ax 3D")
    plot3d = _add_plot_to_axis!(session3d, ax3d, :surface)
    @test length(ax3d.plots[]) == 1
    @test plot3d.type == :surface
    @test plot3d.func == :surface
    @test isempty(plot3d.data_refs[])

    # e. Filter test: computes eligible_for_3d = Set(k for (k,v) in AXIS_KIND_FOR_TYPE if v in (:axis3d, :any)).
    #    Asserts :line ∉ eligible_for_3d and :surface ∈ eligible_for_3d.
    eligible_for_3d = Set(k for (k, v) in AXIS_KIND_FOR_TYPE if v in (:axis3d, :any))
    @test :line ∉ eligible_for_3d
    @test :surface ∈ eligible_for_3d
end
