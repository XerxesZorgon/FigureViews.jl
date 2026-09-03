# src/ui/variable_pane.jl

"""
    _variable_drag_payload(source_kind::Symbol, var_id) -> String

Format the drag payload string for a variable from `source_kind` with identifier `var_id`.
"""
function _variable_drag_payload(source_kind::Symbol, var_id)::String
    return "figureviews-var:$(source_kind):$(var_id)"
end

"""
    build_variable_pane(session::Session) -> GtkBox

Build the variable picker pane showing active data sources and available variables.
"""
function build_variable_pane(session::Session)::GtkBox
    box = GtkBox(:v)
    box.spacing = 6
    box.margin_start = 6
    box.margin_end = 6
    box.margin_top = 6
    box.margin_bottom = 6

    # 1. Source dropdown
    # TODO(Task 106): populate with CSV/HDF5 sources when file-menu data loading lands
    source_dropdown = GtkDropDown(["Main (REPL)"])
    push!(box, source_dropdown)

    current_source = MainSource(Main)

    # 2. Variable list
    list_box = GtkListBox()
    list_box.selection_mode = Gtk4.SelectionMode_SINGLE
    current_vars = Ref{Vector{DataVar}}(DataVar[])

    function rebuild_rows!()
        while (r = Gtk4.G_.get_row_at_index(list_box, 0)) !== nothing
            Gtk4.G_.remove(list_box, r)
        end
        vars = enumerate_variables(current_source)
        current_vars[] = vars
        for var in vars
            row = GtkListBoxRow()
            label_text = "$(var.label)  [$(var.kind)]  $(var.shape)"
            lbl = GtkLabel(label_text)
            lbl.xalign = 0.0
            Gtk4.G_.set_child(row, lbl)
            if var.kind == :unsupported
                row.sensitive = false
            else
                drag_source = GtkDragSource()
                signal_connect(drag_source, "prepare") do _ds, _x, _y
                    payload = _variable_drag_payload(:main, var.id)
                    bytes = Gtk4.GLib.GBytes(Vector{UInt8}(codeunits(payload)))
                    return GdkContentProvider("text/plain", bytes)
                end
                Gtk4.G_.add_controller(row, drag_source)
            end
            push!(list_box, row)
        end
    end

    signal_connect(list_box, "row-selected") do _lb, row
        row === nothing && return
        row.sensitive || return
        idx = Gtk4.G_.get_index(row)
        if 0 <= idx < length(current_vars[])
            var = current_vars[][idx + 1]
            session.selected_variable[] = (current_source, var.id)
        end
    end

    rebuild_rows!()

    scrolled = GtkScrolledWindow()
    scrolled.hscrollbar_policy = Gtk4.PolicyType_AUTOMATIC
    scrolled.vscrollbar_policy = Gtk4.PolicyType_AUTOMATIC
    scrolled[] = list_box
    scrolled.vexpand = true
    scrolled.hexpand = true
    push!(box, scrolled)

    # 3. Refresh button
    refresh_btn = GtkButton("Refresh")
    signal_connect(refresh_btn, "clicked") do _b
        rebuild_rows!()
    end
    push!(box, refresh_btn)

    return box
end
