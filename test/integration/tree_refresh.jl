@testset "Bug E — tree pane survives post-launch node additions" begin
    w = makieviews()
    sleep(0.5) # Allow GTK to settle
    
    try
        s = FigureViews._current_session[]
        n0 = length(FigureViews._build_tree_rows(s)[1])
        
        # Post-launch mutation that fires the refresh! observers — threw before the fix.
        # We only use add_figure! here because add_axis! triggers a known GLMakie renderer 
        # deadlock on the main thread when dynamically adding axes to an active screen.
        fig2 = FigureViews.add_figure!(s; title = "post-launch fig")     # must not throw
        sleep(0.2)
        
        @test length(FigureViews._build_tree_rows(s)[1]) > n0            # rows grew
    finally
        Gtk4.destroy(w)
    end
end
