# src/state/schema.jl

struct AttrSpec
    name::Symbol
    kind::Symbol       # :color | :number | :int | :enum | :bool | :string | :vec2 | :vec3
    default::Any
    range::Any         # nothing, or (lo, hi), or Vector for :enum
    label::String
    tooltip::String
end

const PLOT_SCHEMAS = Dict{Symbol, Vector{AttrSpec}}()

PLOT_SCHEMAS[:line] = [
    AttrSpec(:color,     :color,  RGB(0.1, 0.4, 0.8), nothing,          "Color",     "Line color"),
    AttrSpec(:linewidth, :number, 1.5,                 (0.1, 20.0),      "Linewidth", "Line width in points"),
    AttrSpec(:linestyle, :enum,   :solid,              [:solid, :dash, :dot, :dashdot], "Style",     "Dash pattern"),
    AttrSpec(:label,     :string, "",                  nothing,          "Label",     "Legend label (empty = no legend entry)"),
    AttrSpec(:visible,   :bool,   true,                nothing,          "Visible",   "Show/hide this plot"),
]
