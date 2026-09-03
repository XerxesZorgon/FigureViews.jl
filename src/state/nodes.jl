# src/state/nodes.jl

abstract type Node end

# Escape hatch for forward compatibility (ADR-004, §3.5):
mutable struct UnknownNode <: Node
    original_type::String
    payload::Dict{String, Any}                       # verbatim TOML sub-table
end

mutable struct Plot <: Node
    id::String                                       # immutable
    target::String                                   # owning axis id (ADR-026)
    func::Symbol                                     # canonical plot function, e.g. :scatter, :line (ADR-026)
    args::Vector{Any}                                # ordered, typed positional arguments (ADR-026)
    kwargs::Dict{Symbol, Any}                        # attribute name => typed value (ADR-026)
    api::NamedTuple                                  # (makie_major=0, makie_minor=24) (ADR-026)
    meta::PlotMeta                                   # schema_version + status (:valid, etc.) (ADR-026)
    type::Symbol                                     # alias to func for backward compatibility
    data_refs::Observable{Vector{DataRef}}           # reactive data refs
    attrs::Dict{Symbol, Observable{Any}}             # reactive attributes
    animation_binding::Observable{Union{Nothing, AnimBinding}}
end

# Backward-compatible 5-argument constructor
function Plot(id::String, type::Symbol, data_refs::Observable{Vector{DataRef}},
              attrs::Dict{Symbol, Observable{Any}},
              anim_binding::Observable{Union{Nothing, AnimBinding}};
              target::String = "",
              api = (makie_major = 0, makie_minor = 24),
              meta = PlotMeta(v"1.0.0", :valid))
    args = Any[typed_value(r) for r in data_refs[]]
    kwargs = Dict{Symbol, Any}(k => typed_value(obs[]) for (k, obs) in attrs)
    Plot(id, target, type, args, kwargs, api, meta, type, data_refs, attrs, anim_binding)
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
    selected_variable::Observable{Union{Nothing, Tuple{DataSource, String}}}
    data_snapshots_version::Observable{Int}
    file_path::Ref{Union{Nothing, String}}
    dirty::Observable{Bool}                          # true when session has unsaved changes

    function Session(
        schema_version::VersionNumber,
        figures::Observable{Vector{Figure}},
        preferences_snapshot::Dict{String,Any},
        data_snapshots::Dict{String, AbstractArray},
        selection::Observable{Union{Nothing, String}},
        selected_variable::Observable{Union{Nothing, Tuple{DataSource, String}}} = Observable{Union{Nothing, Tuple{DataSource, String}}}(nothing),
        data_snapshots_version::Observable{Int} = Observable{Int}(0),
        file_path::Ref{Union{Nothing, String}} = Ref{Union{Nothing, String}}(nothing),
        dirty::Observable{Bool} = Observable(false)
    )
        new(schema_version, figures, preferences_snapshot, data_snapshots,
            selection, selected_variable, data_snapshots_version, file_path, dirty)
    end
end
