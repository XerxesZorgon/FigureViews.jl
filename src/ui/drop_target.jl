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
