# src/state/registry.jl

struct AttrSpec
    type::Symbol        # :Colorant, :Real, :Symbol, :String, :Bool, :Vector, ...
    default::Any        # serializable default value
    widget::Symbol      # :colorpicker, :numeric, :dropdown, :text, :checkbox
    name::Symbol
    range::Any
    label::String
    tooltip::String

    function AttrSpec(type::Symbol, default::Any, widget::Symbol)
        new(type, default, widget, :_unnamed, nothing, "", "")
    end

    function AttrSpec(name::Symbol, kind::Symbol, default::Any, range::Any, label::String, tooltip::String)
        w = if kind == :color
            :colorpicker
        elseif kind in (:number, :int)
            :numeric
        elseif kind == :enum
            :dropdown
        elseif kind == :bool
            :checkbox
        else
            :text
        end
        new(kind, default, w, name, range, label, tooltip)
    end
end

Base.getproperty(s::AttrSpec, sym::Symbol) = sym === :kind ? getfield(s, :type) : getfield(s, sym)
Base.propertynames(::AttrSpec) = (:type, :default, :widget, :name, :kind, :range, :label, :tooltip)

struct PlotTypeEntry
    func::Symbol
    conversion_trait::Symbol            # :PointBased, :CellGrid, :VertexGrid, :VolumeLike, ...
    positional_shape::Vector{Symbol}    # e.g. [:x_vector, :y_vector]
    attributes::Dict{Symbol, AttrSpec}
    api::NamedTuple                     # (makie_major=0, makie_minor=24)
    status::Symbol                      # :valid or :needs_manual_review
end

include("registry_generated.jl")
include("function_registry.jl")

const REFERENCE_7 = Dict{Symbol, PlotTypeEntry}(
    :line => PlotTypeEntry(
        :line,
        :PointBased,
        [:x_vector, :y_vector],
        Dict{Symbol, AttrSpec}(
            :color     => AttrSpec(:Colorant, Colors.RGB(0.1, 0.4, 0.8), :colorpicker),
            :linewidth => AttrSpec(:Real, 1.5, :numeric),
            :linestyle => AttrSpec(:Symbol, :solid, :dropdown),
            :label     => AttrSpec(:String, "", :text),
            :visible   => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :scatter => PlotTypeEntry(
        :scatter,
        :PointBased,
        [:x_vector, :y_vector],
        Dict{Symbol, AttrSpec}(
            :color      => AttrSpec(:Colorant, Colors.RGB(0.8, 0.2, 0.2), :colorpicker),
            :markersize => AttrSpec(:Real, 8.0, :numeric),
            :marker     => AttrSpec(:Symbol, :circle, :dropdown),
            :label      => AttrSpec(:String, "", :text),
            :visible    => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :bar => PlotTypeEntry(
        :bar,
        :PointBased,
        [:x_vector, :y_vector],
        Dict{Symbol, AttrSpec}(
            :color     => AttrSpec(:Colorant, Colors.RGB(0.2, 0.6, 0.2), :colorpicker),
            :width     => AttrSpec(:Real, 0.8, :numeric),
            :direction => AttrSpec(:Symbol, :vertical, :dropdown),
            :label     => AttrSpec(:String, "", :text),
            :visible   => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :heatmap => PlotTypeEntry(
        :heatmap,
        :CellGrid,
        [:matrix],
        Dict{Symbol, AttrSpec}(
            :colormap   => AttrSpec(:Symbol, :viridis, :dropdown),
            :colorrange => AttrSpec(:Vector, (0.0, 1.0), :numeric),
            :label      => AttrSpec(:String, "", :text),
            :visible    => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :contour => PlotTypeEntry(
        :contour,
        :VertexGrid,
        [:x_vector, :y_vector, :matrix],
        Dict{Symbol, AttrSpec}(
            :color     => AttrSpec(:Colorant, Colors.RGB(0.3, 0.3, 0.7), :colorpicker),
            :levels    => AttrSpec(:Int, 10, :numeric),
            :linewidth => AttrSpec(:Real, 1.0, :numeric),
            :label     => AttrSpec(:String, "", :text),
            :visible   => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :surface => PlotTypeEntry(
        :surface,
        :VertexGrid,
        [:x_vector, :y_vector, :matrix],
        Dict{Symbol, AttrSpec}(
            :colormap => AttrSpec(:Symbol, :viridis, :dropdown),
            :shading  => AttrSpec(:Symbol, :smooth, :dropdown),
            :label    => AttrSpec(:String, "", :text),
            :visible  => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :volume => PlotTypeEntry(
        :volume,
        :VolumeLike,
        [:matrix],
        Dict{Symbol, AttrSpec}(
            :colormap   => AttrSpec(:Symbol, :viridis, :dropdown),
            :algorithm  => AttrSpec(:Symbol, :mip, :dropdown),
            :colorrange => AttrSpec(:Vector, (0.0, 1.0), :numeric),
            :absorption => AttrSpec(:Real, 1.0, :numeric),
            :visible    => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
)

const REGISTRY = merge(REGISTRY_GENERATED, REFERENCE_7)

const AXIS_KIND_FOR_TYPE = Dict{Symbol, Symbol}(
    # :axis2d only
    :band         => :axis2d,
    :bar          => :axis2d,
    :barplot      => :axis2d,
    :boxplot      => :axis2d,
    :contourf     => :axis2d,
    :density      => :axis2d,
    :errorbars    => :axis2d,
    :heatmap      => :axis2d,
    :hexbin       => :axis2d,
    :hist         => :axis2d,
    :image        => :axis2d,
    :line         => :axis2d,
    :pie          => :axis2d,
    :rangebars    => :axis2d,
    :spy          => :axis2d,
    :stairs       => :axis2d,
    :stem         => :axis2d,
    :streamplot   => :axis2d,
    # :axis3d only
    :surface      => :axis3d,
    :volume       => :axis3d,
    # :any (works on both Axis and Axis3)
    :arrows       => :any,
    :contour      => :any,
    :lines        => :any,
    :linesegments => :any,
    :mesh         => :any,
    :meshscatter  => :any,
    :poly         => :any,
    :scatter      => :any,
    :scatterlines => :any,
    :text         => :any,
)

@assert Set(keys(AXIS_KIND_FOR_TYPE)) == Set(keys(REGISTRY)) "AXIS_KIND_FOR_TYPE must cover all keys in REGISTRY"

const SHAPE_TO_VAR_KIND = Dict{Symbol, Vector{Symbol}}(
    :x_vector   => [:vector],
    :y_vector   => [:vector],
    :z_vector   => [:vector],
    :x_range    => [:vector],
    :y_range    => [:vector],
    :y_lower    => [:vector],
    :y_upper    => [:vector],
    :low        => [:vector],
    :high       => [:vector],
    :values     => [:vector],
    :strings    => [:vector],
    :points     => [:vector, :matrix],
    :positions  => [:vector, :matrix],
    :vertices   => [:vector, :matrix],  # Nx3 matrix or vector of Point3
    :matrix     => [:matrix],
    :faces      => [:matrix, :vector],  # Nx3 index matrix or vector of ints
    :field_func => [:function, :any],
)
