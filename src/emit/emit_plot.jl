# src/emit/emit_plot.jl

"""
    _emit_value(v) -> String

Render a Julia literal value as code.
"""
function _emit_value(v)::String
    if v isa Symbol
        return ":$(v)"
    elseif v isa String
        return "\"$(v)\""
    elseif v isa Bool
        return v ? "true" : "false"
    elseif v isa Integer
        return string(v)
    elseif v isa Real
        return string(v)
    elseif v isa Colors.Colorant
        return "\"#" * Colors.hex(v) * "\""
    else
        return string(v)
    end
end

function _matches_emit_role(r_role::Symbol, target_role::Symbol)::Bool
    return (
        r_role == target_role ||
        (target_role in (:x, :x_vector) && r_role in (:x, :x_vector)) ||
        (target_role in (:y, :y_vector) && r_role in (:y, :y_vector)) ||
        (target_role in (:z, :z_vector) && r_role in (:z, :z_vector)) ||
        (target_role in (:matrix, :matrix_data) && r_role in (:matrix, :matrix_data)) ||
        (target_role in (:volume, :volume_data) && r_role in (:volume, :volume_data))
    )
end

"""
    emit_plot_code(plot::Plot; axis_var::String="ax") -> String

Emit the Makie mutating call string for a single `Plot` node referencing data by variable name.
"""
function emit_plot_code(plot::Plot; axis_var::String="ax")::String
    fname = string(plot.func) * "!"
    entry = get(REGISTRY, plot.func, nothing)
    if entry === nothing
        entry = get(REGISTRY, plot.type, nothing)
    end

    pos_args = String[]
    if entry !== nothing && !isempty(entry.positional_shape)
        for role in entry.positional_shape
            idx = findfirst(r -> _matches_emit_role(r.role, role), plot.data_refs[])
            if idx !== nothing
                push!(pos_args, plot.data_refs[][idx].label)
            end
        end
    else
        for r in plot.data_refs[]
            push!(pos_args, r.label)
        end
    end

    # Keyword args from attrs sorted alphabetically
    kw_pairs = Tuple{Symbol, Any}[]
    for (k, obs) in plot.attrs
        v = obs isa Observables.AbstractObservable ? obs[] : obs
        if v !== nothing && v !== :automatic
            push!(kw_pairs, (k, v))
        end
    end
    sort!(kw_pairs, by = x -> string(x[1]))

    kw_strs = String["$(k)=$(_emit_value(v))" for (k, v) in kw_pairs]

    all_pos = [axis_var, pos_args...]
    pos_str = join(all_pos, ", ")

    if isempty(kw_strs)
        return "$(fname)($(pos_str))"
    else
        return "$(fname)($(pos_str); $(join(kw_strs, ", ")))"
    end
end
