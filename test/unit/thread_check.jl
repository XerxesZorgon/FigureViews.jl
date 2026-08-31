# test/unit/thread_check.jl
using Test
using FigureViews: _has_interactive_thread

@testset "M13 interactive-thread check" begin
    result = _has_interactive_thread()
    @test result isa Bool

    if Threads.nthreads(:interactive) > 0
        @test result == true
        # makieviews() should open a window without error (existing M1 behavior)
        # This is already covered by the M1 shell testsets in runtests.jl.
        # False-branch error path (no interactive thread → error) cannot be tested
        # in-process without restarting Julia; verified manually.
    else
        @test result == false
        # Note: makieviews() would error here with an actionable message.
        # This branch only occurs if the test suite is run without --threads N,1.
        @info "No interactive thread detected — skipping makieviews() open check. Run with --threads 4,1 to exercise the full suite."
    end
end
