# test/unit/file_menu_handlers.jl
using Test
using FigureViews
using FigureViews: new_session, add_figure!, add_axis!,
                   _do_save, _do_load, _do_save_if_known

@testset "file_menu_handlers" begin
    # a. Constructs a session with one figure and one axis.
    # Calls _do_save(session, tmp_path) where tmp_path = joinpath(mktempdir(), "test.mvz").
    # Asserts the file exists and session.file_path[] == tmp_path.
    session = new_session()
    fig = add_figure!(session; title = "Figure 1")
    ax = add_axis!(fig; kind = :axis2d, title = "Axis 1")

    tmp_dir = mktempdir()
    tmp_path = joinpath(tmp_dir, "test.mvz")
    _do_save(session, tmp_path)

    @test isfile(tmp_path)
    @test session.file_path[] == tmp_path

    # b. Calls _do_load(tmp_path).
    # Asserts the loaded session has length(session2.figures[]) == 1 and the axis count matches.
    session2 = _do_load(tmp_path)
    @test length(session2.figures[]) == 1
    @test length(session2.figures[][1].axes[]) == 1

    # c. Calls _do_load("/nonexistent/path/test.mvz") inside a @test_throws
    # asserts it throws any exception (SystemError or otherwise).
    @test_throws Exception _do_load("/nonexistent/path/test.mvz")

    # d. Constructs a synthetic bad .mvz TOML string with a data_inline key and writes it to a temp file.
    # Calls _do_load(bad_path). Asserts it throws an exception whose message contains "v0.2".
    bad_path = joinpath(tmp_dir, "bad.mvz")
    bad_toml = """
    schema_version = "1.0.0"

    [[figure]]
    id = "fig1"

    [[figure.axis]]
    id = "ax1"

    [[figure.axis.plot]]
    id = "plot1"
    type = "scatter"
    data_inline = "dummy"
    """
    write(bad_path, bad_toml)
    err = try
        _do_load(bad_path)
        nothing
    catch e
        e
    end
    @test err !== nothing
    @test occursin("v0.2", sprint(showerror, err))

    # e. Tests _do_save_if_known on a session with file_path[] = nothing;
    # asserts it returns false without writing any file.
    session_unsaved = new_session()
    @test session_unsaved.file_path[] === nothing
    @test _do_save_if_known(session_unsaved) == false

    # f. Calls _do_save(session, tmp_path2) then _do_save_if_known(session);
    # asserts the second call returns true and the file exists.
    tmp_path2 = joinpath(tmp_dir, "test2.mvz")
    _do_save(session, tmp_path2)
    @test session.file_path[] == tmp_path2
    @test _do_save_if_known(session) == true
    @test isfile(tmp_path2)
end
