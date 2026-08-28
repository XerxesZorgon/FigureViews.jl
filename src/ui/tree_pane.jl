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

    sw = GtkScrolledWindow()
    sw[] = list_view
    return sw
end
