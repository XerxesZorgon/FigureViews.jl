using Gtk4

function build_tree_pane(session::Session)
    # Build parallel arrays: display labels and node ids
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

    model = GtkStringList(labels)
    sel = GtkSingleSelection(GListModel(model))
    
    factory = GtkSignalListItemFactory()
    signal_connect(factory, "setup") do f, li
        set_child(li, GtkLabel(""); halign=Gtk4.Align_START)
    end
    signal_connect(factory, "bind") do f, li
        label = get_child(li)
        label.label = li[].string
    end
    
    list_view = GtkListView(GtkSelectionModel(sel), factory)
    
    # Wire selection -> session.selection[]
    signal_connect(sel, "selection-changed") do s, pos, n_items
        idx = Gtk4.selected(s)  # 0-based
        if idx < length(ids)
            session.selection[] = ids[idx + 1]
        end
    end
    
    # Observe structural changes for refresh
    # M2 naive refresh: we just keep the widget around, 
    # but the instructions say: 
    # "The tree pane also observes session.figures and each axes / plots Observable 
    # so that when the tree structure changes, the pane refreshes. 
    # For M2 the demo is populated once at launch, so the observers primarily guard against future changes."
    # Since we are creating a static GtkStringList here, true refresh would require rebuilding the model or string list.
    # We can just register observers that could eventually rebuild it. 
    # M2 says: "For M2 the demo is populated once at launch, so the observers primarily guard against future changes." 
    # Actually I should implement a refresh function.
    
    function refresh!()
        empty!(labels)
        empty!(ids)
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
        # In Gtk4, we can clear the string list and append
        splice!(model, 1:length(model))
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
