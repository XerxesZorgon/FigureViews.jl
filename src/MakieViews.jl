module MakieViews

using Gtk4
using Gtk4Makie
using GLMakie

export makieviews

"""
    makieviews() -> Nothing

Placeholder entry point for MakieViews v0.1. Behavior added in later tasks.
"""
function makieviews()
    if !(isinteractive() && isdefined(Base, :active_repl))
        @warn "MakieViews v0.1 reads variables from REPL Main. You appear to be running outside a REPL. Variables defined in this script/context so far are visible; variables you define later will not appear. File loading (CSV / HDF5) works normally."
    end
    return nothing
end

end # module MakieViews
