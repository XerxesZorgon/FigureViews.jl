# src/state/nodes.jl

abstract type Node end

# Escape hatch for forward compatibility (ADR-004, §3.5):
mutable struct UnknownNode <: Node
    original_type::String
    payload::Dict{String, Any}                       # verbatim TOML sub-table
end

mutable struct Plot <: Node
    id::String                                       # immutable
    type::Symbol                                     # :line | :scatter | :bar | :heatmap | :contour | :surface | :volume, immutable
    data_refs::Observable{Vector{DataRef}}           # e.g. [DataRef(:x), DataRef(:y)]
    attrs::Dict{Symbol, Observable{Any}}             # one Observable per attribute; keys match PLOT_SCHEMAS[type]; validated at every set
    animation_binding::Observable{Union{Nothing, AnimBinding}}
end

mutable struct Axis <: Node
    id::String                                       # immutable
    kind::Symbol                                     # :axis2d | :axis3d, immutable
    title::Observable{String}
    xlabel::Observable{String}
    ylabel::Observable{String}
    zlabel::Observable{String}                       # unused for :axis2d
    xlim::Observable{Union{Nothing, Tuple{Float64,Float64}}}
    ylim::Observable{Union{Nothing, Tuple{Float64,Float64}}}
    xscale::Observable{Symbol}                       # :linear | :log10 | :log2 | :ln
    yscale::Observable{Symbol}
    gridlines::Observable{Bool}
    legend::Observable{Bool}
    tickformat::Observable{Union{Nothing, String}}
    camera::Observable{Union{Nothing, CameraSpec}}   # :axis3d only
    plots::Observable{Vector{Union{Plot, UnknownNode}}}
end

mutable struct Figure <: Node
    id::String                                       # UUIDv4, immutable
    title::Observable{String}
    layout::Observable{LayoutSpec}                   # rows/cols/positions per Makie
    axes::Observable{Vector{Union{Axis, UnknownNode}}}
end

mutable struct Session <: Node
    schema_version::VersionNumber                    # e.g. v"1.0.0"
    figures::Observable{Vector{Figure}}
    preferences_snapshot::Dict{String,Any}           # copy taken at session creation
    data_snapshots::Dict{String, AbstractArray}   # snapshot_id => array; key is UUIDv4
    selection::Observable{Union{Nothing, String}}    # id of currently-selected node
end
