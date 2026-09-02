using Test, FigureViews, Makie, CairoMakie, SHA, Colors
using FigureViews: new_session, add_figure!, add_axis!, Renderer,
                   export_figure, _do_save, _do_load, _confirm_add_plot,
                   MainSource

module _RTFixture
    x = collect(1.0:50.0)
    y = sin.(collect(1.0:50.0) ./ 5.0)
end

@testset "M16 data round-trip SC-004" begin

    # 1. Build session
    session = new_session()
    fig     = add_figure!(session; title = "RT Figure")
    ax      = add_axis!(fig; kind = :axis2d)
    plot    = _confirm_add_plot(session, ax, :line,
                  Dict(:x_vector => "x", :y_vector => "y");
                  source = MainSource(_RTFixture))
    plot.attrs[:color][] = parse(Colorant, "#1a66cc")

    @test length(session.data_snapshots) == 2

    # 2. Export BEFORE save (use CairoMakie headlessly)
    renderer_before = Renderer(session, Makie.Figure())
    png_before = tempname() * ".png"
    export_figure(renderer_before, png_before)
    @test isfile(png_before)
    @test filesize(png_before) > 0

    # 3. Save
    tmp_mvz = tempname() * ".mvz"
    _do_save(session, tmp_mvz)
    @test isfile(tmp_mvz)

    # 4. Load
    loaded = _do_load(tmp_mvz)
    @test length(loaded.figures[]) == 1
    @test length(loaded.figures[][1].axes[]) == 1
    @test length(loaded.figures[][1].axes[][1].plots[]) == 1
    @test length(loaded.data_snapshots) == 2

    # 5. Verify restored arrays match originals
    orig_refs = ax.plots[][1].data_refs[]
    for ref in orig_refs
        orig_arr  = session.data_snapshots[ref.snapshot_id]
        rest_arr  = loaded.data_snapshots[ref.snapshot_id]
        @test isapprox(orig_arr, rest_arr)
    end

    # 6. Export AFTER load and compare pixel hashes
    if get(ENV, "FIGUREVIEWS_GOLDEN", "0") == "1"
        renderer_after = Renderer(loaded, Makie.Figure())
        png_after = tempname() * ".png"
        export_figure(renderer_after, png_after)
        @test isfile(png_after)
        hash_before = bytes2hex(sha256(read(png_before)))
        hash_after  = bytes2hex(sha256(read(png_after)))
        @test hash_before == hash_after
        rm(png_after)
    else
        @info "Skipping pixel-hash comparison (set FIGUREVIEWS_GOLDEN=1 to enable)"
    end

    rm(png_before)
    rm(tmp_mvz)
end
