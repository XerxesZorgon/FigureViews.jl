# test/unit/add_plot_dialog_logic.jl
using Test
using FigureViews
using FigureViews: REGISTRY, SHAPE_TO_VAR_KIND, _confirm_add_plot,
                   new_session, add_figure!, add_axis!, MainSource

module _APDTestFixture
    x = collect(1.0:10.0)
    y = sin.(collect(1.0:10.0))
end

@testset "add_plot_dialog_logic" begin
    # a. Asserts SHAPE_TO_VAR_KIND covers every symbol appearing in any REGISTRY[t].positional_shape
    all_shapes = union((Set(REGISTRY[t].positional_shape) for t in keys(REGISTRY)
                         if REGISTRY[t].status == :valid)...)
    @test all_shapes ⊆ keys(SHAPE_TO_VAR_KIND)

    # b. Creates a fixture module with x and y. Calls _confirm_add_plot
    session = new_session()
    fig_node = add_figure!(session; title = "Test Figure")
    ax_node = add_axis!(fig_node; kind = :axis2d, title = "Test Axis")

    plot = _confirm_add_plot(session, ax_node, :line,
                Dict(:x_vector => "x", :y_vector => "y");
                source = MainSource(_APDTestFixture))

    @test length(ax_node.plots[]) == 1
    @test plot.func == :line
    @test length(plot.data_refs[]) == 2

    # c. For each ref in plot.data_refs[]: asserts ref.role in (:x_vector, :y_vector)
    # and haskey(session.data_snapshots, ref.snapshot_id).
    for ref in plot.data_refs[]
        @test ref.role in (:x_vector, :y_vector)
        @test haskey(session.data_snapshots, ref.snapshot_id)
    end

    # d. session.data_snapshots_version[] == 2 (two ingest! calls fired the version counter).
    @test session.data_snapshots_version[] == 2
end
