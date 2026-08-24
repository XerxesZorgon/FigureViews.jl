module MakieViews

using Gtk4
using Gtk4Makie
using GLMakie

export makieviews

"""
    makieviews() -> Gtk4.GtkWindow

Creates a MakieViews main window (1024×768) and embeds an empty Figure with one Axis via Gtk4Makie. Returns the Gtk4 window handle.

Note: MakieViews v0.1 reads variables from REPL Main. If invoked outside a REPL, a warning is emitted and variables defined later in the script will not appear.
"""
function makieviews()
    if !(isinteractive() && isdefined(Base, :active_repl))
        @warn "MakieViews v0.1 reads variables from REPL Main. You appear to be running outside a REPL. Variables defined in this script/context so far are visible; variables you define later will not appear. File loading (CSV / HDF5) works normally."
    end
    w = GtkWindow("MakieViews", 1024, 768)
    
    fig = Figure()
    ax = Axis(fig[1, 1])
    widget = Gtk4Makie.GtkMakieWidget()
    w[] = widget
    push!(widget, fig)

    show(w)
    return w
end

end # module MakieViews
