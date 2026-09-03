# test/unit/variable_pane.jl
using Test
using FigureViews
using FigureViews: new_session, Session, MainSource, DataVar, enumerate_variables
using Observables: on

module _VPFixture
    x = collect(1.0:5.0)
    y = collect(2.0:6.0)
end

@testset "variable_pane" begin
    # a. Constructs a Session via new_session(); asserts session.selected_variable[] === nothing.
    session = new_session()
    @test session isa Session
    @test session.selected_variable[] === nothing

    # b. Constructs src = MainSource(_VPFixture). Calls enumerate_variables(src).
    # Asserts the returned Vector{DataVar} has length >= 2 and includes entries with id == "x" and id == "y".
    src = MainSource(_VPFixture)
    vars = enumerate_variables(src)
    @test vars isa Vector{DataVar}
    @test length(vars) >= 2
    var_ids = [v.id for v in vars]
    @test "x" in var_ids
    @test "y" in var_ids

    # c. Sets session.selected_variable[] = (src, "x"). Uses on(...) with a Ref{Bool}(false) to verify the observable fired.
    # Asserts the ref is true after the assignment.
    fired = Ref{Bool}(false)
    on(session.selected_variable) do val
        if val == (src, "x")
            fired[] = true
        end
    end
    session.selected_variable[] = (src, "x")
    @test fired[] == true
    @test session.selected_variable[] == (src, "x")
end

@testset "variable drag payload" begin
    @test FigureViews._variable_drag_payload(:main, "x") == "figureviews-var:main:x"
    @test FigureViews._variable_drag_payload(:main, "long_name_123") == "figureviews-var:main:long_name_123"
    @test FigureViews._variable_drag_payload(:csv, "col_A") == "figureviews-var:csv:col_A"
end
