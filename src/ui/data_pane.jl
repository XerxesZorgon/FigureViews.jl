# src/ui/data_pane.jl

"""
    kind_label(arr::AbstractArray) -> String

Return "vector" for 1-D, "matrix" for 2-D, "array3" for 3-D, and "arrayN" otherwise.
"""
function kind_label(arr::AbstractArray)::String
    n = ndims(arr)
    n == 1 && return "vector"
    n == 2 && return "matrix"
    n == 3 && return "array3"
    return "arrayN"
end

"""
    _rebuild_snapshot_list!(lb::GtkListBox, session::Session)

Clear and repopulate `lb` with one row per snapshot in `session.data_snapshots`.
"""
function _rebuild_snapshot_list!(lb::GtkListBox, session::Session)
    while (r = Gtk4.G_.get_row_at_index(lb, 0)) !== nothing
        Gtk4.G_.remove(lb, r)
    end
    for (snap_id, arr) in sort!(collect(session.data_snapshots), by = first)
        row = GtkListBoxRow()
        kb = round(Base.summarysize(arr) / 1024, digits = 1)
        text = "$(first(snap_id, 8))  $(kind_label(arr))  $(size(arr))  $(eltype(arr))  $(kb) KB"
        lbl = GtkLabel(text)
        lbl.xalign = 0.0
        Gtk4.G_.set_child(row, lbl)
        push!(lb, row)
    end
end

"""
    build_data_pane(session::Session) -> GtkScrolledWindow

Build the data pane displaying all ingested array snapshots in the session.
"""
function build_data_pane(session::Session)::GtkScrolledWindow
    lb = GtkListBox()
    lb.selection_mode = Gtk4.SelectionMode_NONE

    _rebuild_snapshot_list!(lb, session)

    on(session.data_snapshots_version) do _
        _rebuild_snapshot_list!(lb, session)
    end

    scrolled = GtkScrolledWindow()
    scrolled[] = lb
    scrolled.vexpand = true
    scrolled.hexpand = true
    return scrolled
end
