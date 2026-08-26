module MakieViews

using Gtk4, Gtk4Makie, GLMakie, Observables, Colors, UUIDs

include("data/source.jl")
include("data/main_source.jl")
include("data/csv_source.jl")
include("data/hdf5_source.jl")
include("state/types.jl")
include("state/nodes.jl")
include("state/schema.jl")
include("state/session.jl")
include("render/renderer.jl")
include("ui/tree_pane.jl")
include("ui/property_pane.jl")

export makieviews

const _current_session = Ref{Union{Nothing, Session}}(nothing)
const _current_renderer = Ref{Union{Nothing, Renderer}}(nothing)

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

    session = new_session()
    fig_node = add_figure!(session; title = "Demo Figure")
    ax_node = add_axis!(fig_node; kind = :axis2d, title = "Sine wave")
    x = collect(1.0:100.0)
    y = sin.(x ./ 10)
    plot_node = add_line_plot!(ax_node; x = x, y = y)

    x_scatter = collect(1.0:100.0)
    y_scatter = cos.(x_scatter ./ 8) .+ 0.3 .* randn(100)
    add_scatter_plot!(ax_node; x = x_scatter, y = y_scatter)

    ax3d_node = add_axis!(fig_node; kind = :axis3d, title = "3D Surface")
    xs = collect(LinRange(-3.0, 3.0, 30))
    ys = collect(LinRange(-3.0, 3.0, 30))
    zs = [exp(-(i^2 + j^2)) for i in xs, j in ys]
    add_surface_plot!(ax3d_node; x = xs, y = ys, z = zs)

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
