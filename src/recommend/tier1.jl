# src/recommend/tier1.jl

"""
    recommend_plot_type(var_kind::Symbol, ndims::Int, axis_kind::Symbol) -> Union{Symbol, Nothing}

Determine a recommended Makie plot type for a variable with kind `var_kind` and dimensionality `ndims`
on an axis of kind `axis_kind`. Returns a single plot type symbol if a rule matches, or `nothing`.
"""
function recommend_plot_type(var_kind::Symbol, ndims::Int, axis_kind::Symbol)::Union{Symbol, Nothing}
    if axis_kind == :axis2d && var_kind == :vector && ndims == 1
        return :lines
    elseif axis_kind == :axis2d && var_kind == :matrix && ndims == 2
        return :heatmap
    elseif axis_kind == :axis3d && var_kind == :matrix && ndims == 2
        return :surface
    elseif axis_kind == :axis3d && var_kind == :matrix && ndims == 3
        return :volume
    else
        return nothing
    end
end

"""
    recommend_from_var(var::DataVar, axis_kind::Symbol) -> Union{Symbol, Nothing}

Helper to recommend a plot type directly from a `DataVar` and `axis_kind`.
"""
function recommend_from_var(var::DataVar, axis_kind::Symbol)::Union{Symbol, Nothing}
    return recommend_plot_type(var.kind, length(var.shape), axis_kind)
end
