# test/unit/data_inline_save.jl
using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!, add_plot!,
                   _confirm_add_plot, save_session, MainSource, DataRef,
                   _DATA_INLINE_MAX_ELEMENTS
import TOML

module _SaveFixtureMod
    x = collect(1.0:10.0)
    y = sin.(collect(1.0:10.0))
end

@testset "data_inline_save" begin
    # a. Normal inline data save
    session = new_session()
    fig = add_figure!(session)
    ax = add_axis!(fig; kind = :axis2d)
    plot = _confirm_add_plot(session, ax, :line,
                             Dict(:x_vector => "x", :y_vector => "y");
                             source = MainSource(_SaveFixtureMod))

    tmp_path = joinpath(mktempdir(), "test_inline_save.mvz")
    save_session(session, tmp_path)
    @test isfile(tmp_path)

    raw = TOML.parsefile(tmp_path)
    @test raw["schema_version"] == "1.1"

    plot_dict = raw["figure"][1]["axis"][1]["plot"][1]
    @test haskey(plot_dict, "data_inline")
    inline = plot_dict["data_inline"]
    @test length(inline) == 2

    for (snap_id, entry) in inline
        @test haskey(entry, "eltype")
        @test haskey(entry, "shape")
        @test haskey(entry, "data")
        @test entry["shape"] == [10]
        @test length(entry["data"]) == 10
    end

    # b. Exceeds 100,000-element cap
    session_large = new_session()
    fig_large = add_figure!(session_large)
    ax_large = add_axis!(fig_large; kind = :axis2d)
    large_arr = rand(100_001)
    snap_large_id = "snap_large"
    session_large.data_snapshots[snap_large_id] = large_arr
    add_plot!(ax_large, :line, [DataRef(:x, snap_large_id, :main, "large")])

    tmp_large = joinpath(mktempdir(), "test_large.mvz")
    err = try
        save_session(session_large, tmp_large)
        nothing
    catch e
        e
    end
    @test err !== nothing
    @test occursin("exceeds the", sprint(showerror, err))

    # c. Plot with empty data_refs[]
    session_empty = new_session()
    fig_empty = add_figure!(session_empty)
    ax_empty = add_axis!(fig_empty; kind = :axis2d)
    add_plot!(ax_empty, :line, DataRef[])

    tmp_empty = joinpath(mktempdir(), "test_empty.mvz")
    save_session(session_empty, tmp_empty)
    raw_empty = TOML.parsefile(tmp_empty)
    plot_dict_empty = raw_empty["figure"][1]["axis"][1]["plot"][1]
    @test !haskey(plot_dict_empty, "data_inline")
end
