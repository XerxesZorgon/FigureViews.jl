# test/unit/data_pane.jl
using Test
using FigureViews
using FigureViews: new_session, Session, MainSource, ingest!, _rebuild_snapshot_list!
using Gtk4

module _DPFixture
    x = collect(1.0:5.0)
    M = ones(3, 3)
end

@testset "data_pane" begin
    # a. Constructs a Session via new_session(); asserts session.data_snapshots_version[] == 0.
    session = new_session()
    @test session isa Session
    @test session.data_snapshots_version[] == 0

    # b. Creates a test fixture module with a real vector x = collect(1.0:5.0) and a matrix M = ones(3,3).
    # Constructs src = MainSource(FixtureMod).
    src = MainSource(_DPFixture)

    # c. Calls ingest!(session, src, "x"); asserts session.data_snapshots_version[] == 1.
    snap_x = ingest!(session, src, "x")
    @test session.data_snapshots_version[] == 1
    @test haskey(session.data_snapshots, snap_x)

    # d. Calls ingest!(session, src, "M"); asserts version is 2.
    snap_m = ingest!(session, src, "M")
    @test session.data_snapshots_version[] == 2
    @test haskey(session.data_snapshots, snap_m)

    # e. Calls ingest!(session, src, "x") again (duplicate); asserts version is 3.
    snap_x2 = ingest!(session, src, "x")
    @test session.data_snapshots_version[] == 3
    @test haskey(session.data_snapshots, snap_x2)

    # f. Calls _rebuild_snapshot_list!(lb, session) where lb = GtkListBox().
    # Asserts Gtk4.G_.get_row_at_index(lb, 2) !== nothing and Gtk4.G_.get_row_at_index(lb, 3) === nothing.
    lb = GtkListBox()
    _rebuild_snapshot_list!(lb, session)
    @test Gtk4.G_.get_row_at_index(lb, 0) !== nothing
    @test Gtk4.G_.get_row_at_index(lb, 1) !== nothing
    @test Gtk4.G_.get_row_at_index(lb, 2) !== nothing
    @test Gtk4.G_.get_row_at_index(lb, 3) === nothing
end
