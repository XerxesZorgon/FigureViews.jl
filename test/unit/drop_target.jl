# test/unit/drop_target.jl
using Test
using FigureViews
using FigureViews: _parse_var_drop_payload

@testset "parse_var_drop_payload" begin
    @test _parse_var_drop_payload("figureviews-var:main:x") == (:main, "x")
    @test _parse_var_drop_payload("figureviews-var:csv:col_A") == (:csv, "col_A")
    @test _parse_var_drop_payload("not-a-var-payload") === nothing
    @test _parse_var_drop_payload("figureviews-var:main:") === nothing
end
