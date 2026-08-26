@testset "tree_pane _build_tree_rows" begin
    s = new_session()
    fig = add_figure!(s; title = "F1")
    ax2 = add_axis!(fig; kind = :axis2d, title = "A2D")
    _m = Module(:_T)
    Core.eval(_m, :(x = collect(1.0:5.0)))
    Core.eval(_m, :(y = collect(1.0:5.0)))
    _src = MakieViews.MainSource(_m)
    snap_x = ingest!(s, _src, "x")
    snap_y = ingest!(s, _src, "y")
    add_plot!(ax2, :line, [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y, :main, "y")])
    ax3 = add_axis!(fig; kind = :axis3d, title = "A3D")

    labels, ids = MakieViews._build_tree_rows(s)
    @test length(labels) == 4
    @test length(ids) == 4
    @test labels[1] == "Figure: F1"
    @test occursin("Axis (2D): A2D", labels[2])
    @test occursin("line", labels[3])
    @test occursin("Axis (3D): A3D", labels[4])
    @test ids[1] == fig.id
    @test ids[2] == ax2.id
    @test ids[4] == ax3.id
end
