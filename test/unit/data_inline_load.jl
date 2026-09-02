# test/unit/data_inline_load.jl
using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, add_plot!,
                   _confirm_add_plot, _do_load, _do_save, save_session,
                   MainSource, DataRef, ingest!

module _LoadFixtureVec
    x = collect(1.0:20.0)
    y = sin.(collect(1.0:20.0))
end

module _LoadFixtureMatrix
    xm = collect(-2:0.5:2)
    ym = collect(-2:0.5:2)
    zm = [exp(-(x^2 + y^2)) for x in -2:0.5:2, y in -2:0.5:2]
end

module _LoadFixtureInt
    arr = Int32[1, 2, 3, 4, 5]
end

@testset "data_inline_load" begin
    # a. Vector round-trip
    s1 = new_session()
    fig1 = add_figure!(s1)
    ax1 = add_axis!(fig1; kind = :axis2d)
    p1 = _confirm_add_plot(s1, ax1, :line,
                           Dict(:x_vector => "x", :y_vector => "y");
                           source = MainSource(_LoadFixtureVec))
    tmp1 = joinpath(mktempdir(), "test_vec.mvz")
    _do_save(s1, tmp1)

    loaded1 = _do_load(tmp1)
    @test length(loaded1.data_snapshots) == 2
    loaded_plot = loaded1.figures[][1].axes[][1].plots[][1]
    x_ref = only(r for r in loaded_plot.data_refs[] if r.role in (:x, :x_vector))
    y_ref = only(r for r in loaded_plot.data_refs[] if r.role in (:y, :y_vector))
    restored_x = loaded1.data_snapshots[x_ref.snapshot_id]
    restored_y = loaded1.data_snapshots[y_ref.snapshot_id]
    @test isapprox(restored_x, _LoadFixtureVec.x)
    @test isapprox(restored_y, _LoadFixtureVec.y)

    # b. Matrix round-trip
    s2 = new_session()
    fig2 = add_figure!(s2)
    ax2 = add_axis!(fig2; kind = :axis3d)
    p2 = _confirm_add_plot(s2, ax2, :surface,
                           Dict(:x_vector => "xm", :y_vector => "ym", :matrix => "zm");
                           source = MainSource(_LoadFixtureMatrix))
    tmp2 = joinpath(mktempdir(), "test_matrix.mvz")
    _do_save(s2, tmp2)

    loaded2 = _do_load(tmp2)
    loaded_plot2 = loaded2.figures[][1].axes[][1].plots[][1]
    zm_ref = only(r for r in loaded_plot2.data_refs[] if r.role in (:matrix, :z))
    restored_zm = loaded2.data_snapshots[zm_ref.snapshot_id]
    @test size(restored_zm) == (9, 9)
    @test isapprox(restored_zm, _LoadFixtureMatrix.zm)

    # c. v0.1 file compatibility
    tmp3 = joinpath(mktempdir(), "v01.mvz")
    v01_toml = """
    schema_version = "1.0"

    [[figure]]
    id = "fig1"
    title = "Old Figure"

    [[figure.axis]]
    id = "ax1"
    kind = "axis2d"
    title = "Old Axis"

    [[figure.axis.plot]]
    id = "plot1"
    type = "line"
    """
    write(tmp3, v01_toml)
    loaded3 = _do_load(tmp3)
    @test length(loaded3.figures[]) == 1
    @test length(loaded3.figures[][1].axes[]) == 1
    @test length(loaded3.figures[][1].axes[][1].plots[]) == 1
    @test isempty(loaded3.data_snapshots)

    # d. eltype preservation
    s4 = new_session()
    fig4 = add_figure!(s4)
    ax4 = add_axis!(fig4; kind = :axis2d)
    snap_int = ingest!(s4, MainSource(_LoadFixtureInt), "arr")
    add_plot!(ax4, :line, [DataRef(:x, snap_int, :main, "arr")])
    tmp4 = joinpath(mktempdir(), "test_int.mvz")
    _do_save(s4, tmp4)

    loaded4 = _do_load(tmp4)
    @test haskey(loaded4.data_snapshots, snap_int)
    restored_int = loaded4.data_snapshots[snap_int]
    @test restored_int ≈ [1.0, 2.0, 3.0, 4.0, 5.0]
end
