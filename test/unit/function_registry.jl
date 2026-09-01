# test/unit/function_registry.jl
# M14 Task 096: Non-serializable Symbol->Function registry

using Test
using FigureViews: FUNCTION_REGISTRY

@testset "function_registry" begin
    @test FUNCTION_REGISTRY[:identity] === identity
    @test FUNCTION_REGISTRY[:sqrt] === sqrt
    @test !haskey(FUNCTION_REGISTRY, :foobar)
end
