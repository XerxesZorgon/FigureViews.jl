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

PLOT_SCHEMAS[:scatter] = [
    AttrSpec(:color,      :color,  RGB(0.8, 0.2, 0.2), nothing,           "Color",      "Marker fill color"),
    AttrSpec(:markersize, :number, 8.0,                 (1.0, 40.0),       "Marker size", "Marker diameter in points"),
    AttrSpec(:marker,     :enum,   :circle,             [:circle, :rect, :diamond, :cross, :xcross, :utriangle, :dtriangle], "Marker", "Marker shape"),
    AttrSpec(:label,      :string, "",                  nothing,           "Label",      "Legend label"),
    AttrSpec(:visible,    :bool,   true,                nothing,           "Visible",    "Show/hide this plot"),
]

PLOT_SCHEMAS[:bar] = [
    AttrSpec(:color,     :color,  RGB(0.2, 0.6, 0.2), nothing,           "Color",     "Bar fill color"),
    AttrSpec(:width,     :number, 0.8,                 (0.1, 1.0),        "Width",     "Bar width as fraction of spacing"),
    AttrSpec(:direction, :enum,   :vertical,           [:vertical, :horizontal], "Direction", "Bar orientation"),
    AttrSpec(:label,     :string, "",                  nothing,           "Label",     "Legend label"),
    AttrSpec(:visible,   :bool,   true,                nothing,           "Visible",   "Show/hide this plot"),
]

PLOT_SCHEMAS[:heatmap] = [
    AttrSpec(:colormap,   :enum,   :viridis,   [:viridis, :plasma, :inferno, :magma, :cividis, :grays, :blues, :reds], "Colormap",   "Color mapping"),
    AttrSpec(:colorrange, :vec2,   (0.0, 1.0), nothing,    "Color range", "(min, max) data range for colormap"),
    AttrSpec(:label,      :string, "",         nothing,    "Label",       "Legend label"),
    AttrSpec(:visible,    :bool,   true,        nothing,    "Visible",     "Show/hide this plot"),
]

PLOT_SCHEMAS[:contour] = [
    AttrSpec(:color,     :color,  RGB(0.3, 0.3, 0.7), nothing,       "Color",     "Contour line color"),
    AttrSpec(:levels,    :int,    10,                  (2, 50),       "Levels",    "Number of contour levels"),
    AttrSpec(:linewidth, :number, 1.0,                 (0.1, 10.0),   "Linewidth", "Contour line width"),
    AttrSpec(:label,     :string, "",                  nothing,       "Label",     "Legend label"),
    AttrSpec(:visible,   :bool,   true,                nothing,       "Visible",   "Show/hide this plot"),
]

PLOT_SCHEMAS[:surface] = [
    AttrSpec(:colormap, :enum,   :viridis, [:viridis, :plasma, :inferno, :magma, :cividis, :grays, :blues, :reds], "Colormap", "Surface color mapping"),
    AttrSpec(:shading,  :enum,   :smooth,  [:none, :fast, :smooth], "Shading",  "Surface shading mode"),
    AttrSpec(:label,    :string, "",       nothing, "Label",   "Legend label"),
    AttrSpec(:visible,  :bool,   true,     nothing, "Visible", "Show/hide this plot"),
]

PLOT_SCHEMAS[:volume] = [
    AttrSpec(:colormap,   :enum,   :viridis,   [:viridis, :plasma, :inferno, :magma, :cividis, :grays, :blues, :reds], "Colormap",   "Volume color mapping"),
    AttrSpec(:algorithm,  :enum,   :mip,       [:mip, :iso, :absorption, :additive], "Algorithm",  "Volume rendering algorithm"),
    AttrSpec(:colorrange, :vec2,   (0.0, 1.0), nothing, "Color range", "(min, max) data range for colormap"),
    AttrSpec(:absorption, :number, 1.0,        (0.0, 10.0), "Absorption", "Absorption coefficient (:absorption algorithm)"),
    AttrSpec(:visible,    :bool,   true,       nothing, "Visible", "Show/hide this plot"),
]

const AXIS_SCHEMAS = Dict{Symbol, Vector{AttrSpec}}()

AXIS_SCHEMAS[:axis3d] = [
    AttrSpec(:azimuth,   :number, 1.275, (-2π, 2π),   "Azimuth",   "Camera azimuth angle (radians)"),
    AttrSpec(:elevation, :number, 0.785, (-2π, 2π),   "Elevation", "Camera elevation angle (radians)"),
    AttrSpec(:zoom,      :number, 1.0,   (0.1, 10.0), "Zoom",      "Camera zoom factor"),
]
