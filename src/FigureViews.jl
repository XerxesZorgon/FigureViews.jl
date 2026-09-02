module FigureViews

using Gtk4, Gtk4Makie, GLMakie, CairoMakie, Observables, Colors, UUIDs, TOML, Scratch

include("data/source.jl")
include("data/main_source.jl")
include("data/csv_source.jl")
include("data/hdf5_source.jl")
include("state/types.jl")
include("state/nodes.jl")
include("state/registry.jl")
include("state/schema.jl")
include("state/session.jl")
include("render/renderer.jl")
include("render/structural.jl")
include("render/export.jl")
include("ui/tree_pane.jl")
include("ui/property_pane.jl")
include("ui/variable_pane.jl")
include("ui/data_pane.jl")
include("persistence/mvz_save.jl")
include("persistence/mvz_load.jl")
include("persistence/preferences.jl")
include("preflight/detect.jl")
include("preflight/estimate.jl")
include("preflight/downsample.jl")
include("preflight/check.jl")
include("ui/preflight_modal.jl")
include("ui/add_plot_dialog.jl")

export makieviews, save_session, load_session,
       add_plot!, add_plot_checked!, ingest!, build_dataref, animate_plot!, render_animation, export_figure, render_session,
       apply_structural!, AddPlotOp, RemovePlotOp, AddAxisOp, RemoveAxisOp,
       DataRef, MainSource, CsvSource, Hdf5Source, DataVar, AnimBinding,
       load_preferences, save_preferences, preferences_path, reset_to_preferences!,
       REGISTRY, REGISTRY_GENERATED, FUNCTION_REGISTRY, AXIS_KIND_FOR_TYPE, SHAPE_TO_VAR_KIND, PlotTypeEntry, AttrSpec, TypedValue, PlotMeta,
       _add_plot_to_axis!, _open_shell, build_variable_pane, build_data_pane, _rebuild_snapshot_list!,
       _confirm_add_plot, show_add_plot_dialog,
       _do_save, _do_load, _do_save_if_known, _do_new,
       show_preflight_modal, _format_preflight_body,
       _apply_preflight_choice, _show_downsample_dialog,
       _DATA_INLINE_MAX_ELEMENTS

const _current_session = Ref{Union{Nothing, Session}}(nothing)
const _current_renderer = Ref{Union{Nothing, Renderer}}(nothing)

module _FigureViewsDemo
    x      = collect(1.0:100.0)
    y_line = sin.(collect(1.0:100.0) ./ 10)
    y_scat = cos.(collect(1.0:100.0) ./ 8) .+ 0.3 .* randn(100)
    xs3d   = collect(LinRange(-3.0, 3.0, 30))
    ys3d   = collect(LinRange(-3.0, 3.0, 30))
    zs3d   = [exp(-(i^2 + j^2)) for i in collect(LinRange(-3.0, 3.0, 30)),
                                     j in collect(LinRange(-3.0, 3.0, 30))]
end

"""
    _has_interactive_thread() -> Bool

Returns `true` if Julia was started with an interactive thread pool
(`--threads N,1` or `JULIA_NUM_THREADS=N,1`). Required for the `g_idle_add`
drain used by live structural editing (ADR-024 constraint 1).
"""
_has_interactive_thread()::Bool = Threads.nthreads(:interactive) > 0

"""
    makieviews() -> Gtk4.GtkWindow
    makieviews(session::Session) -> Gtk4.GtkWindow

Open the primary FigureViews application window.

With no arguments, auto-populates a demo session with a 2D axis and a sine wave line plot.
With a `Session` argument, opens the shell window displaying that session.

Note: FigureViews v0.1 reads variables from REPL Main. If invoked outside a REPL, a warning is emitted and variables defined later in the script will not appear. File loading (CSV / HDF5) works normally.
"""
function _build_demo_session()::Session
    session = new_session()
    fig_node = add_figure!(session; title = "Demo Figure")

    _demo_src = MainSource(_FigureViewsDemo)

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

    return session
end

function makieviews()
    session = _build_demo_session()
    return makieviews(session)
end

function makieviews(session::Session)
    if !_has_interactive_thread()
        error("""
FigureViews requires an interactive thread pool for live structural editing.
Start Julia with:  julia --threads 4,1
or set:            JULIA_NUM_THREADS=4,1
Without an interactive thread, adding or removing plots/axes on a displayed
window will deadlock. See ADR-024 for details.
""")
    end
    if !(isinteractive() && isdefined(Base, :active_repl))
        @warn "FigureViews v0.1 reads variables from REPL Main. You appear to be running outside a REPL. Variables defined in this script/context so far are visible; variables you define later will not appear. File loading (CSV / HDF5) works normally."
    end
    if isempty(AXIS_SCHEMAS)
        _init_schemas()
    end

    return _open_shell(session)
end

"""
    _do_save(session::Session, path::String)

Save the session to `path` and record the path on the session.
"""
function _do_save(session::Session, path::String)
    save_session(session, path)
    session.file_path[] = path
end

"""
    _do_load(path::String) -> Session

Load and return a session from `path`. Raises on bad schema, data_inline,
or missing file — caller is responsible for showing an error dialog.
"""
function _do_load(path::String)::Session
    return load_session(path)
end

"""
    _do_save_if_known(session::Session)

Save to the session's known path if one exists; returns `true` on success,
`false` if no path is set (caller should fall back to Save As).
"""
function _do_save_if_known(session::Session)::Bool
    session.file_path[] === nothing && return false
    _do_save(session, session.file_path[])
    return true
end

function _show_error_dialog(parent, title::String, msg::String)
    dlg = GtkMessageDialog(msg, [("OK", 1)], Gtk4.DialogFlags_MODAL, Gtk4.MessageType_ERROR, parent)
    dlg.title = title
    signal_connect(dlg, "response") do _, _id
        Gtk4.destroy(dlg)
    end
    show(dlg)
end

"""
    _do_new(old_window::Union{Nothing, GtkWindow} = nothing)

Discard the current session and replace it with a fresh empty session.
Assumes the caller has already obtained user confirmation.
Opens a new shell window for the fresh session and destroys the old one.
"""
function _do_new(old_window::Union{Nothing, GtkWindow} = nothing)
    fresh = new_session()
    _current_session[] = fresh
    w_new = _open_shell(fresh)
    if old_window !== nothing
        Gtk4.destroy(old_window)
    end
    return w_new
end

function _open_shell(session::Session)
    w = GtkWindow("FigureViews", 1400, 900)

    makie_fig = Makie.Figure()
    viewport_widget = Gtk4Makie.GtkMakieWidget()
    push!(viewport_widget, makie_fig)
    viewport_widget.hexpand = true
    viewport_widget.vexpand = true

    renderer = Renderer(session, makie_fig)

    tree_pane = build_tree_pane(session)
    tree_pane.height_request = 250
    property_pane = build_property_pane(session)
    property_pane.height_request = 350
    variable_pane = build_variable_pane(session)
    variable_pane.height_request = 200
    data_pane = build_data_pane(session)
    data_pane.height_request = 200

    # Task 104: Option A (tab strip) chosen to avoid cramping four vertically-stacked panes
    data_notebook = GtkNotebook()
    push!(data_notebook, variable_pane, "Variables")
    push!(data_notebook, data_pane, "Snapshots")

    inner_paned = GtkPaned(:v)
    inner_paned[1] = property_pane
    inner_paned[2] = data_notebook
    inner_paned.position = 220

    outer_paned = GtkPaned(:v)
    outer_paned.width_request = 320
    outer_paned[1] = tree_pane
    outer_paned[2] = inner_paned
    outer_paned.position = 280

    main_paned = GtkPaned(:h)
    main_paned[1] = outer_paned
    main_paned[2] = viewport_widget
    main_paned.position = 320

    # Action group for window
    group = Gtk4.GLib.GSimpleActionGroup()
    action_map = Gtk4.GLib.GActionMap(group)

    # File > New
    Gtk4.GLib.add_action(action_map, "file_new", _ -> begin
        # TODO(M18): replace fixed prompt with unsaved-changes check once
        # session.dirty::Observable{Bool} lands (M18 deferred item).
        ask_dialog("Discard current session and start a new one?", w;
                   no_text = "Cancel", yes_text = "Discard") do response
            if response   # true = user chose the affirmative button
                _do_new(w)
            end
        end
    end)
    # File > Open…
    Gtk4.GLib.add_action(action_map, "file_open", _ -> begin
        open_dialog("Open session", w) do path
            isempty(path) && return
            try
                new_session_obj = _do_load(path)
                makieviews(new_session_obj)
                Gtk4.destroy(w)
            catch e
                _show_error_dialog(w, "Could not open session", sprint(showerror, e))
            end
        end
    end)
    # File > Save
    Gtk4.GLib.add_action(action_map, "file_save", _ -> begin
        if !_do_save_if_known(_current_session[])
            # No known path — fall through to Save As
            Gtk4.GLib.activate(Gtk4.GLib.GActionGroup(group), "file_save_as")
        end
    end)
    # File > Save As…
    Gtk4.GLib.add_action(action_map, "file_save_as", _ -> begin
        save_dialog("Save session", w) do path
            isempty(path) && return
            try
                _do_save(_current_session[], path)
            catch e
                _show_error_dialog(w, "Could not save session", sprint(showerror, e))
            end
        end
    end)
    # File > Quit
    Gtk4.GLib.add_action(action_map, "file_quit",
        _ -> Gtk4.destroy(w))
    # Plot > Add plot…
    Gtk4.GLib.add_action(action_map, "plot_add", _ -> begin
        sel_id = session.selection[]
        ax = sel_id === nothing ? nothing : _find_axis(session, sel_id)
        if ax !== nothing
            show_add_plot_dialog(session, ax, w)
        else
            @info "Plot > Add plot…: no axis selected"
        end
    end)

    Gtk4.G_.insert_action_group(w, "app", Gtk4.GLib.GActionGroup(group))

    # File menu
    file_menu = Gtk4.GLib.GMenu()
    push!(file_menu, Gtk4.GLib.GMenuItem("New", "app.file_new"))
    push!(file_menu, Gtk4.GLib.GMenuItem("Open…", "app.file_open"))
    push!(file_menu, Gtk4.GLib.GMenuItem("Save", "app.file_save"))
    push!(file_menu, Gtk4.GLib.GMenuItem("Save As…", "app.file_save_as"))

    quit_section = Gtk4.GLib.GMenu()
    push!(quit_section, Gtk4.GLib.GMenuItem("Quit", "app.file_quit"))
    Gtk4.GLib.G_.append_section(file_menu, nothing, quit_section)

    # Plot menu
    plot_menu = Gtk4.GLib.GMenu()
    push!(plot_menu, Gtk4.GLib.GMenuItem("Add plot…", "app.plot_add"))

    menu_bar_model = Gtk4.GLib.GMenu()
    push!(menu_bar_model, Gtk4.GLib.GMenuItem("File", file_menu))
    push!(menu_bar_model, Gtk4.GLib.GMenuItem("Plot", plot_menu))

    menubar = GtkPopoverMenuBar(menu_bar_model)

    root_box = GtkBox(:v)
    push!(root_box, menubar)
    push!(root_box, main_paned)
    main_paned.vexpand = true
    w[] = root_box
    show(w)

    # Ensure the GLib main loop is running (required for g_idle_add drain).
    # Gtk4.__init__ starts it only in interactive sessions; makieviews() may be
    # called from Pkg.test() or a script where isinteractive() == false.
    Gtk4.GLib.start_main_loop()

    # Activate live-queued structural-mutation path (ADR-024 Part A).
    renderer.viewport_widget = viewport_widget

    signal_connect(viewport_widget, "destroy") do _
        renderer.viewport_widget = nothing
    end
    signal_connect(viewport_widget, "unrealize") do _
        renderer.viewport_widget = nothing
    end

    # Keyboard shortcut: Ctrl+P calls show_add_plot_dialog for currently-selected axis
    key_controller = GtkEventControllerKey()
    signal_connect(key_controller, "key-pressed") do _c, keyval, keycode, state
        is_ctrl = (Int(state) & Int(Gtk4.ModifierType_CONTROL_MASK)) != 0
        if is_ctrl && (keyval == UInt32('p') || keyval == UInt32('P'))
            sel_id = session.selection[]
            if sel_id !== nothing
                ax = _find_axis(session, sel_id)
                if ax !== nothing
                    show_add_plot_dialog(session, ax, w)
                    return true
                end
            end
        end
        return false
    end
    Gtk4.G_.add_controller(w, key_controller)

    _current_session[] = session
    _current_renderer[] = renderer

    return w
end

end # module FigureViews
