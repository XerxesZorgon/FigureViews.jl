module MakieViews

using Gtk4, Gtk4Makie, GLMakie, CairoMakie, Observables, Colors, UUIDs, TOML, Scratch

include("data/source.jl")
include("data/main_source.jl")
include("data/csv_source.jl")
include("data/hdf5_source.jl")
include("state/types.jl")
include("state/nodes.jl")
include("state/schema.jl")
include("state/session.jl")
include("render/renderer.jl")
include("render/export.jl")
include("ui/tree_pane.jl")
include("ui/property_pane.jl")
include("persistence/mvz_save.jl")
include("persistence/mvz_load.jl")
include("persistence/preferences.jl")
include("preflight/detect.jl")
include("preflight/estimate.jl")
include("preflight/downsample.jl")

export makieviews, save_session, load_session,
       add_plot!, ingest!, build_dataref, animate_plot!, render_animation, export_figure,
       DataRef, MainSource, CsvSource, Hdf5Source, DataVar, AnimBinding,
       load_preferences, save_preferences, preferences_path, reset_to_preferences!

const _current_session = Ref{Union{Nothing, Session}}(nothing)
const _current_renderer = Ref{Union{Nothing, Renderer}}(nothing)

module _MakieViewsDemo
    x      = collect(1.0:100.0)
    y_line = sin.(collect(1.0:100.0) ./ 10)
    y_scat = cos.(collect(1.0:100.0) ./ 8) .+ 0.3 .* randn(100)
    xs3d   = collect(LinRange(-3.0, 3.0, 30))
    ys3d   = collect(LinRange(-3.0, 3.0, 30))
    zs3d   = [exp(-(i^2 + j^2)) for i in collect(LinRange(-3.0, 3.0, 30)),
                                     j in collect(LinRange(-3.0, 3.0, 30))]
end

"""
    makieviews() -> Gtk4.GtkWindow

Creates a MakieViews main window (1400×900) with a three-pane layout:
tree pane and property pane on the left, and a Makie Figure viewport on the right.
Auto-populates a demo session with a 2D axis and a sine wave line plot.

Note: MakieViews v0.1 reads variables from REPL Main. If invoked outside a REPL, a warning is emitted and variables defined later in the script will not appear.
"""
function makieviews()
    if !(isinteractive() && isdefined(Base, :active_repl))
        @warn "MakieViews v0.1 reads variables from REPL Main. You appear to be running outside a REPL. Variables defined in this script/context so far are visible; variables you define later will not appear. File loading (CSV / HDF5) works normally."
    end
    if isempty(AXIS_SCHEMAS)
        _init_schemas()
    end

    session = new_session()
    fig_node = add_figure!(session; title = "Demo Figure")

    _demo_src = MainSource(_MakieViewsDemo)

    # 2D axis: line + scatter
    ax_node = add_axis!(fig_node; kind = :axis2d, title = "Sine wave")

    snap_x      = ingest!(session, _demo_src, "x")
    snap_y_line = ingest!(session, _demo_src, "y_line")
    add_plot!(ax_node, :line,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y_line, :main, "y_line")])

    snap_y_scat = ingest!(session, _demo_src, "y_scat")
    add_plot!(ax_node, :scatter,
        [DataRef(:x, snap_x, :main, "x"), DataRef(:y, snap_y_scat, :main, "y_scat")])

    # 3D axis: surface
    ax3d_node = add_axis!(fig_node; kind = :axis3d, title = "3D Surface")
    snap_xs3d = ingest!(session, _demo_src, "xs3d")
    snap_ys3d = ingest!(session, _demo_src, "ys3d")
    snap_zs3d = ingest!(session, _demo_src, "zs3d")
    add_plot!(ax3d_node, :surface,
        [DataRef(:x,      snap_xs3d, :main, "xs3d"),
         DataRef(:y,      snap_ys3d, :main, "ys3d"),
         DataRef(:matrix, snap_zs3d, :main, "zs3d")])

    w = GtkWindow("MakieViews", 1400, 900)

    makie_fig = Makie.Figure()
    viewport_widget = Gtk4Makie.GtkMakieWidget()
    push!(viewport_widget, makie_fig)
    viewport_widget.hexpand = true
    viewport_widget.vexpand = true

    renderer = Renderer(session, makie_fig)

    tree_pane = build_tree_pane(session)
    tree_pane.width_request = 300
    tree_pane.height_request = 300
    property_pane = build_property_pane(session)
    property_pane.width_request = 300
    property_pane.height_request = 500

    left_column = GtkPaned(:v)
    left_column[1] = tree_pane
    left_column[2] = property_pane

    main_paned = GtkPaned(:h)
    main_paned[1] = left_column
    main_paned[2] = viewport_widget
    main_paned.position = 300

    w[] = main_paned
    show(w)

    _current_session[] = session
    _current_renderer[] = renderer

    return w
end

end # module MakieViews
