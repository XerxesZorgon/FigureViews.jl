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
        plot = _dict_to_plot(plot_dict, ax.id)
        ax.plots[] = [ax.plots[]..., plot]
    end
    return ax
end

const _KNOWN_PLOT_TYPES = Set([:line, :scatter, :bar, :heatmap, :contour, :surface, :volume])

function _dict_to_typed_value(d::Dict)::TypedValue
    type_sym = Symbol(get(d, "type", "Any"))
    raw_val = get(d, "value", nothing)
    val = if type_sym == :DataRef && raw_val isa Dict
        _dict_to_dataref(raw_val)
    elseif type_sym == :Colorant && raw_val !== nothing
        string(raw_val)
    elseif type_sym == :Symbol && raw_val !== nothing
        string(raw_val)
    elseif type_sym == :Int && raw_val !== nothing
        Int64(raw_val)
    elseif type_sym == :Real && raw_val !== nothing
        Float64(raw_val)
    elseif type_sym == :Bool && raw_val !== nothing
        Bool(raw_val)
    elseif type_sym == :String && raw_val !== nothing
        string(raw_val)
    elseif type_sym == :Tuple && raw_val !== nothing
        collect(raw_val)
    elseif type_sym == :Vector && raw_val !== nothing
        collect(raw_val)
    else
        raw_val
    end
    return TypedValue(type_sym, val)
end
_dict_to_typed_value(x) = typed_value(x)

function _dict_to_plot(d::Dict, default_target::String = "")::Union{Plot, UnknownNode}
    func_str = get(d, "func", get(d, "type", ""))
    func_sym = Symbol(func_str)

    id = get(d, "id", string(uuid4()))
    target = get(d, "target", default_target)

    if !(func_sym in _KNOWN_PLOT_TYPES || (haskey(REGISTRY, func_sym) && REGISTRY[func_sym].status == :valid))
        @warn "FigureViews: unknown plot type :$(func_sym) in .mvz — node preserved, not rendered"
        api = (makie_major = 0, makie_minor = 24)
        meta = PlotMeta(v"1.0.0", :unresolved)
        return Plot(
            id,
            target,
            func_sym,
            Any[],
            Dict{Symbol, Any}(),
            api,
            meta,
            func_sym,
            Observable(DataRef[]),
            Dict{Symbol, Observable{Any}}(),
            Observable{Union{Nothing, AnimBinding}}(nothing)
        )
    end

    # API
    api_d = get(d, "api", Dict())
    api = (makie_major = Int(get(api_d, "makie_major", 0)),
           makie_minor = Int(get(api_d, "makie_minor", 24)))

    # Meta
    meta_d = get(d, "meta", Dict())
    meta_status = Symbol(get(meta_d, "status", "valid"))
    schema_ver = VersionNumber(get(meta_d, "schema_version", "1.0.0"))

    # args and data_refs
    args = Any[]
    refs = DataRef[]
    if haskey(d, "args")
        for a in d["args"]
            tv = a isa Dict ? _dict_to_typed_value(a) : typed_value(a)
            push!(args, tv)
            if tv.type == :DataRef && tv.value isa DataRef
                push!(refs, tv.value)
            end
        end
    elseif haskey(d, "data_refs")
        refs = [_dict_to_dataref(r) for r in d["data_refs"]]
        args = Any[typed_value(r) for r in refs]
    end

    # kwargs and attrs
    kwargs = Dict{Symbol, Any}()
    attrs = Dict{Symbol, Observable{Any}}()
    reg_entry = get(REGISTRY, func_sym, nothing)
    has_unknown_kwarg = false

    if haskey(d, "kwargs")
        for (k_str, tv_raw) in d["kwargs"]
            k = Symbol(k_str)
            tv = tv_raw isa Dict ? _dict_to_typed_value(tv_raw) : typed_value(tv_raw)
            kwargs[k] = tv
            val = decode_typed_value(tv)
            attrs[k] = Observable{Any}(val)

            if reg_entry !== nothing && !haskey(reg_entry.attributes, k)
                has_unknown_kwarg = true
                @warn "Unknown kwarg key '$(k)' for plot type :$(func_sym) preserved with status :unresolved"
            end
        end
        # Seed missing attributes from registry defaults if not in kwargs
        if reg_entry !== nothing
            for (attr_name, attr_spec) in reg_entry.attributes
                if !haskey(kwargs, attr_name)
                    kwargs[attr_name] = typed_value(attr_spec.default)
                    attrs[attr_name] = Observable{Any}(attr_spec.default)
                end
            end
        end
    else
        # Legacy fallback from d["attrs"]
        attrs = _init_attrs(func_sym)
        for (k_str, v) in get(d, "attrs", Dict())
            k = Symbol(k_str)
            if haskey(attrs, k)
                attrs[k][] = _coerce_attr(func_sym, k, v)
            else
                if reg_entry !== nothing && !haskey(reg_entry.attributes, k)
                    has_unknown_kwarg = true
                    @warn "Unknown kwarg key '$(k)' for plot type :$(func_sym) preserved with status :unresolved"
                end
                attrs[k] = Observable{Any}(v)
            end
        end
        kwargs = Dict{Symbol, Any}(k => typed_value(obs[]) for (k, obs) in attrs)
    end

    if has_unknown_kwarg
        meta_status = :unresolved
    end
    meta = PlotMeta(schema_ver, meta_status)

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

    plot = Plot(
        id,
        target,
        func_sym,
        args,
        kwargs,
        api,
        meta,
        func_sym,
        Observable(refs),
        attrs,
        Observable{Union{Nothing,AnimBinding}}(anim_binding)
    )

    for (k, obs) in attrs
        on(obs) do v
            plot.kwargs[k] = typed_value(v)
        end
    end
    on(plot.data_refs) do new_refs
        plot.args = Any[typed_value(r) for r in new_refs]
    end

    return plot
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
        get(d, "snapshot_id",   ""),
        Symbol(get(d, "source", "main")),
        get(d, "label", ""),
        get(d, "absolute_path", nothing),
        get(d, "relative_path", nothing),
        get(d, "column",        nothing),
        get(d, "dataset",       nothing),
        let v = get(d, "variable", nothing); v !== nothing ? Symbol(v) : nothing end
    )
end
