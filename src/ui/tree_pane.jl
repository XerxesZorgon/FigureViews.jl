using Gtk4

function _build_tree_rows(session::Session)
    labels = String[]
    ids = String[]
    for fig in session.figures[]
        push!(labels, "Figure: $(fig.title[])")
        push!(ids, fig.id)
        for ax in fig.axes[]
            kind_str = ax.kind == :axis2d ? "2D" : "3D"
            push!(labels, "  Axis ($kind_str): $(ax.title[])")
            push!(ids, ax.id)
            for plot in ax.plots[]
                label_attr = get(plot.attrs, :label, nothing)
                label_str = label_attr === nothing ? plot.id[1:8] : string(label_attr[])
                push!(labels, "    $(plot.type): $label_str")
                push!(ids, plot.id)
            end
        end
    end
    return (labels, ids)
end

function build_tree_pane(session::Session)
    # Build parallel arrays: display labels and node ids
    labels, ids = _build_tree_rows(session)

    model = GtkStringList(labels)
    sel = GtkSingleSelection(GListModel(model))
    
    factory = GtkSignalListItemFactory()
    signal_connect(factory, "setup") do f, li
        lbl = GtkLabel("")
        lbl.halign = Gtk4.Align_START
        set_child(li, lbl)
    end
    signal_connect(factory, "bind") do f, li
        lbl = get_child(li)
        lbl.label = li[].string   # li[] is a GtkStringObject through the selection-wrapped model; .string unwraps it
    end
    
    list_view = GtkListView(GtkSelectionModel(sel), factory)
    
    # Wire selection -> session.selection[]
    # Use notify::selected and read sel.selected (0-based committed value).
    # The selection-changed signal's `pos` is the START of the changed range
    # (min of old and new selection), which is off-by-one on most transitions.
    # Probe (Patch P2) confirmed sel.selected via notify::selected is correct on every transition.
    signal_connect(sel, "notify::selected") do s, _pspec
        idx = Int(s.selected)  # 0-based
        if idx >= 0 && idx < length(ids)
            session.selection[] = ids[idx + 1]
        end
    end
    
    # Observe structural changes for refresh
    function refresh!()
        new_labels, new_ids = _build_tree_rows(session)
        empty!(labels); append!(labels, new_labels)
        empty!(ids);    append!(ids, new_ids)
        # In Gtk4, we can clear the string list and append
        empty!(model)
        for l in labels
            push!(model, l)
        end
    end
    
    on(session.figures) do _
        refresh!()
    end
    for fig in session.figures[]
        on(fig.axes) do _
            refresh!()
        end
        for ax in fig.axes[]
            on(ax.plots) do _
                refresh!()
            end
        end
    end

    # Right-click context menu
    current_popover = Ref{Union{Nothing, GtkPopoverMenu}}(nothing)
    gesture = GtkGestureClick(list_view, 3)
    signal_connect(gesture, "pressed") do _g, _n_press, x, y
        kind, node = _find_selected_node(session, ids)
        kind == :none && return

        if current_popover[] !== nothing
            try
                Gtk4.G_.unparent(current_popover[])
            catch
            end
            current_popover[] = nothing
        end

        menu = Gtk4.GLib.GMenu()
        action_group = Gtk4.GLib.GSimpleActionGroup()
        action_map = Gtk4.GLib.GActionMap(action_group)

        if kind == :figure
            fig_node = node::Figure
            push!(menu, Gtk4.GLib.GMenuItem("Add Axis (2D)", "tree.add_axis_2d"))
            push!(menu, Gtk4.GLib.GMenuItem("Add Axis (3D)", "tree.add_axis_3d"))
            Gtk4.GLib.add_action(action_map, "add_axis_2d", (_a, _p) -> _context_add_axis!(session, fig_node, :axis2d))
            Gtk4.GLib.add_action(action_map, "add_axis_3d", (_a, _p) -> _context_add_axis!(session, fig_node, :axis3d))
        elseif kind == :axis
            ax_node = node::Axis
            push!(menu, Gtk4.GLib.GMenuItem("Add plot…", "tree.add_plot"))
            push!(menu, Gtk4.GLib.GMenuItem("Delete Axis", "tree.delete_axis"))
            Gtk4.GLib.add_action(action_map, "add_plot", (_a, _p) -> show_add_plot_dialog(session, ax_node, Gtk4.root(list_view)))
            Gtk4.GLib.add_action(action_map, "delete_axis", (_a, _p) -> _context_delete_axis!(session, ax_node.id))
        elseif kind == :plot
            plot_node = node::Plot
            push!(menu, Gtk4.GLib.GMenuItem("Delete Plot", "tree.delete_plot"))
            Gtk4.GLib.add_action(action_map, "delete_plot", (_a, _p) -> _context_delete_plot!(session, plot_node.id))
        end

        popover = GtkPopoverMenu(menu)
        current_popover[] = popover
        Gtk4.G_.insert_action_group(popover, "tree", Gtk4.GLib.GActionGroup(action_group))
        Gtk4.G_.set_parent(popover, list_view)
        rect = Ref(Gtk4._GdkRectangle(round(Int, x), round(Int, y), 1, 1))
        Gtk4.G_.set_pointing_to(popover, rect)
        Gtk4.popup(popover)
    end

    sw = GtkScrolledWindow()
    sw[] = list_view
    return sw
end

function _find_selected_node(session::Session, ids::Vector{String})
    sel_id = session.selection[]
    sel_id === nothing && return (:none, nothing)
    sel_id in ids || return (:none, nothing)
    for fig in session.figures[]
        fig.id == sel_id && return (:figure, fig)
        for ax in fig.axes[]
            ax.id == sel_id && return (:axis, ax)
            for plot in ax.plots[]
                plot.id == sel_id && return (:plot, plot)
            end
        end
    end
    return (:none, nothing)
end

function _context_add_axis!(session::Session, fig_node::Figure, kind::Symbol)
    ax_node = add_axis!(fig_node; kind = kind, title = "New Axis")
    op = AddAxisOp(fig_node, ax_node)
    apply_structural!(_current_renderer[], op)
    return ax_node
end

function _context_delete_axis!(session::Session, ax_id::String)
    for fig in session.figures[]
        axes = fig.axes[]
        idx = findfirst(a -> a.id == ax_id, axes)
        if idx !== nothing
            deleted_ax = axes[idx]
            if session.selection[] == ax_id || any(p -> p.id == session.selection[], deleted_ax.plots[])
                session.selection[] = nothing
            end
            fig.axes[] = filter(a -> a.id != ax_id, axes)
            break
        end
    end
    op = RemoveAxisOp(ax_id)
    apply_structural!(_current_renderer[], op)
    return nothing
end

function _context_delete_plot!(session::Session, plot_id::String)
    for fig in session.figures[]
        for ax in fig.axes[]
            plots = ax.plots[]
            idx = findfirst(p -> p.id == plot_id, plots)
            if idx !== nothing
                if session.selection[] == plot_id
                    session.selection[] = nothing
                end
                ax.plots[] = filter(p -> p.id != plot_id, plots)
                break
            end
        end
    end
    op = RemovePlotOp(plot_id)
    apply_structural!(_current_renderer[], op)
    return nothing
end
