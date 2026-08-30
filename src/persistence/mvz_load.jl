# src/persistence/mvz_load.jl

const _LOADER_VERSION = v"1.0.0"

"""
    load_session(path::String) -> Session

Deserialize a `.mvz` TOML file into a new Session.
Raises an error for major-version mismatch or `data_inline` content.
Warns for same-major, newer-minor version.
Unknown plot/axis type strings become UnknownNode (verbatim round-trip).
DataRef arrays are NOT reloaded from disk (v0.1: in-memory only).
"""
function load_session(path::String)::Session
    raw = open(path) do io TOML.parse(io) end
    _check_schema_version(raw)
    _reject_data_inline(raw)
    return _dict_to_session(raw)
end

function _check_schema_version(raw::Dict)
    ver_str = get(raw, "schema_version", "1.0")
    file_ver = VersionNumber(ver_str)
    if file_ver.major > _LOADER_VERSION.major
        error("This .mvz file requires FigureViews v$(file_ver.major).x or newer. " *
              "Please upgrade FigureViews.")
    end
    if file_ver > _LOADER_VERSION && file_ver.major == _LOADER_VERSION.major
        @warn "This .mvz was saved by a newer minor version of FigureViews. " *
              "Unknown fields will be preserved but may not render."
    end
end

function _reject_data_inline(raw::Dict)
    for fig in get(raw, "figure", [])
        for ax in get(fig, "axis", [])
            for plot in get(ax, "plot", [])
                if haskey(plot, "data_inline")
                    error("This .mvz contains inline data (data_inline), which requires " *
                          "FigureViews v0.2 or later. Loading aborted.")
                end
            end
        end
    end
end

function _dict_to_session(raw::Dict)::Session
    s = new_session()
    s.preferences_snapshot = Dict{String,Any}(get(raw, "preferences_snapshot", Dict()))
    for fig_dict in get(raw, "figure", [])
        fig = _dict_to_figure(fig_dict)
        s.figures[] = [s.figures[]..., fig]
    end
    return s
end

function _dict_to_figure(d::Dict)::Figure
    layout_d = get(d, "layout", Dict("rows" => 1, "cols" => 1))
    fig = Figure(
        get(d, "id", string(uuid4())),
        Observable(get(d, "title", "Untitled")),
        Observable(LayoutSpec(get(layout_d, "rows", 1), get(layout_d, "cols", 1))),
        Observable(Union{Axis, UnknownNode}[])
    )
    for ax_dict in get(d, "axis", [])
        ax = _dict_to_axis(ax_dict)
        fig.axes[] = [fig.axes[]..., ax]
    end
    return fig
end

function _dict_to_axis(d::Dict)::Axis
    kind_sym = Symbol(get(d, "kind", "axis2d"))
    cam = if haskey(d, "camera")
        cd = d["camera"]
        CameraSpec(Float64(get(cd, "azimuth", 45.0)),
                   Float64(get(cd, "elevation", 30.0)),
                   Float64(get(cd, "zoom", 1.0)))
    else
        nothing
    end
    xlim_raw = get(d, "xlim", nothing)
    ylim_raw = get(d, "ylim", nothing)
    ax = Axis(
        get(d, "id", string(uuid4())),
        kind_sym,
        Observable(get(d, "title", "")),
        Observable(get(d, "xlabel", "")),
        Observable(get(d, "ylabel", "")),
        Observable(get(d, "zlabel", "")),
        Observable{Union{Nothing,Tuple{Float64,Float64}}}(
            xlim_raw !== nothing ? (Float64(xlim_raw[1]), Float64(xlim_raw[2])) : nothing),
        Observable{Union{Nothing,Tuple{Float64,Float64}}}(
            ylim_raw !== nothing ? (Float64(ylim_raw[1]), Float64(ylim_raw[2])) : nothing),
        Observable(Symbol(get(d, "xscale", "linear"))),
        Observable(Symbol(get(d, "yscale", "linear"))),
        Observable(get(d, "gridlines", true)),
        Observable(get(d, "legend", true)),
        Observable{Union{Nothing,String}}(get(d, "tickformat", nothing)),
        Observable{Union{Nothing,CameraSpec}}(cam),
        Observable(Union{Plot, UnknownNode}[])
    )
    for plot_dict in get(d, "plot", [])
        plot = _dict_to_plot(plot_dict)
        ax.plots[] = [ax.plots[]..., plot]
    end
    return ax
end

const _KNOWN_PLOT_TYPES = Set([:line, :scatter, :bar, :heatmap, :contour, :surface, :volume])

function _dict_to_plot(d::Dict)::Union{Plot, UnknownNode}
    type_str = get(d, "type", "")
    type_sym = Symbol(type_str)
    if !(type_sym in _KNOWN_PLOT_TYPES)
        payload = copy(d)
        delete!(payload, "type")
        return UnknownNode(type_str, payload)
    end
    attrs = _init_attrs(type_sym)
    for (k_str, v) in get(d, "attrs", Dict())
        k = Symbol(k_str)
        if haskey(attrs, k)
            attrs[k][] = _coerce_attr(type_sym, k, v)
        end
    end
    refs = [_dict_to_dataref(r) for r in get(d, "data_refs", [])]
    anim_binding = if haskey(d, "animation")
        ad = d["animation"]
        AnimBinding(
            get(ad, "snapshot_id",   ""),
            get(ad, "frame_count",   1),
            get(ad, "fps",           30),
            get(ad, "current_frame", 1)
        )
    else
        nothing
    end
    return Plot(
        get(d, "id", string(uuid4())),
        type_sym,
        Observable(refs),
        attrs,
        Observable{Union{Nothing,AnimBinding}}(anim_binding)
    )
end

function _coerce_attr(plot_type::Symbol, name::Symbol, v)::Any
    specs = get(PLOT_SCHEMAS, plot_type, AttrSpec[])
    idx = findfirst(s -> s.name == name, specs)
    idx === nothing && return v
    spec = specs[idx]
    if spec.kind == :color
        v isa String && return parse(Colors.RGB, v)
        return v
    elseif spec.kind == :enum
        return Symbol(v)
    elseif spec.kind == :number
        return Float64(v)
    elseif spec.kind == :bool
        return Bool(v)
    elseif spec.kind == :vec2
        return (Float64(v[1]), Float64(v[2]))
    elseif spec.kind == :vec3
        return (Float64(v[1]), Float64(v[2]), Float64(v[3]))
    else
        return v
    end
end

function _dict_to_dataref(d::Dict)::DataRef
    DataRef(
        Symbol(get(d, "role",   "x")),
        "",    # snapshot_id empty on load — data not embedded in v0.1
        Symbol(get(d, "source", "main")),
        get(d, "label", ""),
        get(d, "absolute_path", nothing),
        get(d, "relative_path", nothing),
        get(d, "column",        nothing),
        get(d, "dataset",       nothing),
        let v = get(d, "variable", nothing); v !== nothing ? Symbol(v) : nothing end
    )
end
