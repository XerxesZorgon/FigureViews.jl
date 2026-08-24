using Test
using MakieViews

@testset "M1 shell — module loads" begin
    @test :makieviews in names(MakieViews)
    @test makieviews() === nothing
end

@testset "M1 shell — non-REPL warning fires" begin
    @test_logs (:warn, r"MakieViews v0.1 reads variables from REPL Main") match_mode=:any makieviews()
end
