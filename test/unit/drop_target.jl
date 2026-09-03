# test/unit/drop_target.jl
using Test
using FigureViews
using FigureViews: _parse_var_drop_payload, _find_selected_axis, new_session, add_figure!, add_axis!

@testset "parse_var_drop_payload" begin
    @test _parse_var_drop_payload("figureviews-var:main:x") == (:main, "x")
    @test _parse_var_drop_payload("figureviews-var:csv:col_A") == (:csv, "col_A")
    @test _parse_var_drop_payload("not-a-var-payload") === nothing
    @test _parse_var_drop_payload("figureviews-var:main:") === nothing
end

@testset "find_selected_axis" begin
    # 1. Fresh session with no figures → _find_selected_axis(session) === nothing
    session = new_session()
    @test _find_selected_axis(session) === nothing

    # 2. Session with one figure and one axis, nothing selected → returns that axis
    fig = add_figure!(session)
    ax1 = add_axis!(fig; kind = :axis2d)
    @test _find_selected_axis(session) === ax1

    # 3. Session with one figure and two axes, session.selection[] = axes[2].id → returns axes[2]
    ax2 = add_axis!(fig; kind = :axis3d)
    session.selection[] = ax2.id
    @test _find_selected_axis(session) === ax2
end
