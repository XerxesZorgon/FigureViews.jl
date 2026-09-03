# src/ui/drop_target.jl

"""
    _parse_var_drop_payload(s::String) -> Union{Tuple{Symbol,String}, Nothing}

Parse a variable drag-and-drop payload string of format `"figureviews-var:<source_kind>:<var_id>"`.
Returns `(source_kind, var_id)` as `(Symbol, String)` on success, or `nothing` if the format
is invalid or contains an empty variable ID.
"""
function _parse_var_drop_payload(s::String)::Union{Tuple{Symbol,String}, Nothing}
    if !startswith(s, "figureviews-var:")
        return nothing
    end
    parts = split(s, ':'; limit=3)
    if length(parts) == 3 && !isempty(parts[2]) && !isempty(parts[3])
        return (Symbol(parts[2]), String(parts[3]))
    end
    return nothing
end

_parse_var_drop_payload(s::AbstractString) = _parse_var_drop_payload(String(s))
_parse_var_drop_payload(::Any) = nothing

"""
    _find_selected_axis(session::Session) -> Union{Axis, Nothing}

Return the currently-selected Axis, or the first Axis in the first Figure if
nothing is selected, or `nothing` if the session has no axes.
"""
function _find_selected_axis(session::Session)::Union{Axis, Nothing}
    # Try selection first
    sel_id = session.selection[]
    if sel_id !== nothing
        ax = _find_axis(session, sel_id)
        ax !== nothing && return ax
    end
    # Fallback: first axis of first figure
    isempty(session.figures[]) && return nothing
    fig = session.figures[][1]
    for node in fig.axes[]
        node isa Axis && return node
    end
    return nothing
end
