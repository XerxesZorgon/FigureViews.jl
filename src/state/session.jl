
function new_session()::Session
    return Session(
        v"1.0.0",
        Observable(Figure[]),
        Dict{String,Any}(),
        Dict{String, AbstractArray}(),
        Observable{Union{Nothing,String}}(nothing),
        Observable{Union{Nothing, Tuple{DataSource, String}}}(nothing)
    )
end

function add_figure!(s::Session; title::String = "Untitled")::Figure
    fig = Figure(
        string(uuid4()),
        Observable(title),
        Observable(LayoutSpec(1, 1)),
        Observable(Union{Axis, UnknownNode}[])
    )
    s.figures[] = [s.figures[]..., fig]
    return fig
end

function add_axis!(fig::Figure; kind::Symbol = :axis2d, title::String = "")::Axis
    if kind != :axis2d && kind != :axis3d
        throw(ArgumentError("kind must be :axis2d or :axis3d"))
    end
    ax = Axis(
        string(uuid4()),
        kind,
        Observable(title),                                      # title
        Observable(""),                                         # xlabel
        Observable(""),                                         # ylabel
        Observable(""),                                         # zlabel
        Observable{Union{Nothing,Tuple{Float64,Float64}}}(nothing), # xlim
        Observable{Union{Nothing,Tuple{Float64,Float64}}}(nothing), # ylim
        Observable(:linear),                                    # xscale
        Observable(:linear),                                    # yscale
        Observable(true),                                       # gridlines
        Observable(true),                                       # legend
        Observable{Union{Nothing,String}}(nothing),             # tickformat
        Observable{Union{Nothing,CameraSpec}}(nothing),         # camera
        Observable(Union{Plot, UnknownNode}[])                  # plots
    )
    fig.axes[] = [fig.axes[]..., ax]
    return ax
end

"""
    _seed_attr_from_prefs(spec, prefs, palette_index) -> value

Return the seed value for one attr: the matching preference if present, else spec.default.
Convention: `default_<attr>` seeds `<attr>`; `palette` seeds `:color` cyclically.
"""
function _seed_attr_from_prefs(name::Symbol, spec::AttrSpec, prefs::Dict{String,Any}, palette_index::Int)
    if name == :color && haskey(prefs, "palette")
        pal = prefs["palette"]
        if pal isa AbstractVector && !isempty(pal)
            hex = pal[mod1(palette_index, length(pal))]
            return parse(Colors.RGB, hex)
        end
    end
    key = "default_" * string(name)
    if haskey(prefs, key)
        v = prefs[key]
        kind = spec.type
        if kind in (:color, :Colorant) && v isa String
            return parse(Colors.RGB, v)
        elseif kind in (:enum, :Symbol)
            return Symbol(v)
        elseif kind in (:number, :Real, :Int)
            return Float64(v)
        else
            return v
        end
    end
    return spec.default
end

_seed_attr_from_prefs(spec::AttrSpec, prefs::Dict{String,Any}, palette_index::Int) =
    _seed_attr_from_prefs(spec.name, spec, prefs, palette_index)

function _init_attrs(plot_type::Symbol; prefs::Union{Nothing,Dict{String,Any}} = nothing,
                     palette_index::Int = 1)::Dict{Symbol, Observable{Any}}
    d = Dict{Symbol, Observable{Any}}()
    if haskey(REGISTRY, plot_type)
        entry = REGISTRY[plot_type]
        for (name, spec) in entry.attributes
            val = prefs === nothing ? spec.default : _seed_attr_from_prefs(name, spec, prefs, palette_index)
            d[name] = Observable{Any}(val)
        end
    elseif haskey(PLOT_SCHEMAS, plot_type)
        for spec in PLOT_SCHEMAS[plot_type]
            val = prefs === nothing ? spec.default : _seed_attr_from_prefs(spec.name, spec, prefs, palette_index)
            d[spec.name] = Observable{Any}(val)
        end
    end
    return d
end

"""
    reset_to_preferences!(plot, prefs; palette_index=1)

Overwrite each of `plot`'s attrs with the preference value (or spec default if the
preference does not declare it). Fires each attr observable so the renderer updates.
"""
function reset_to_preferences!(plot::Plot, prefs::Dict{String,Any}; palette_index::Int = 1)
    if haskey(REGISTRY, plot.func)
        entry = REGISTRY[plot.func]
        for (name, spec) in entry.attributes
            haskey(plot.attrs, name) || continue
            plot.attrs[name][] = _seed_attr_from_prefs(name, spec, prefs, palette_index)
        end
    elseif haskey(PLOT_SCHEMAS, plot.type)
        for spec in PLOT_SCHEMAS[plot.type]
            haskey(plot.attrs, spec.name) || continue
            plot.attrs[spec.name][] = _seed_attr_from_prefs(spec.name, spec, prefs, palette_index)
        end
    end
    return plot
end

"""
    ingest!(session, source, id) -> snapshot_id::String

Snapshot one variable from `source` into `session.data_snapshots`.
Returns a fresh UUIDv4 string usable as `DataRef.snapshot_id`.
"""
function ingest!(session::Session, source::DataSource, id::String)::String
    arr = snapshot(source, id)
    snap_id = string(uuid4())
    session.data_snapshots[snap_id] = arr
    return snap_id
end

"""
    animate_plot!(session, plot_node, snapshot_id, frame_count; fps=30) -> AnimBinding

Bind an animation to `plot_node`. `snapshot_id` must key a 3D array in
`session.data_snapshots` with dimensions [x, y, t] where t is the time axis.
Sets `plot_node.animation_binding[]` and returns the AnimBinding.
"""
function animate_plot!(session::Session, plot_node::Plot,
                       snapshot_id::String, frame_count::Int;
                       fps::Int = 30)::AnimBinding
    @assert haskey(session.data_snapshots, snapshot_id) "snapshot_id not found in data_snapshots"
    arr = session.data_snapshots[snapshot_id]
    @assert ndims(arr) == 3 "animate_plot! requires a 3D array A[x, y, t]"
    @assert size(arr, 3) == frame_count "frame_count does not match size(array, 3)"
    binding = AnimBinding(snapshot_id, frame_count, fps, 1)
    plot_node.animation_binding[] = binding
    return binding
end

"""
    build_dataref(source, id, role, snapshot_id) -> DataRef

Construct a DataRef with provenance fields filled from the source type.
- CsvSource: absolute_path = abspath(source.path), relative_path = source.path, column = id
- Hdf5Source: absolute_path = abspath(source.path), relative_path = source.path, dataset = id
- MainSource: variable = Symbol(id)
"""
function build_dataref(source::DataSource, id::String, role::Symbol, snapshot_id::String)::DataRef
    if source isa CsvSource
        abs_p = abspath(source.path)
        DataRef(role, snapshot_id, :csv, id, abs_p, source.path, id, nothing, nothing)
    elseif source isa Hdf5Source
        abs_p = abspath(source.path)
        DataRef(role, snapshot_id, :hdf5, id, abs_p, source.path, nothing, id, nothing)
    else  # MainSource
        DataRef(role, snapshot_id, :main, id, nothing, nothing, nothing, nothing, Symbol(id))
    end
end

"""
    add_plot!(ax, plot_type, data_refs; attrs...) -> Plot

Generic plot constructor. `data_refs` is a `Vector{DataRef}` built by the caller
after calling `ingest!` for each array. Keyword `attrs` override schema defaults.
"""
function add_plot!(ax::Axis, plot_type::Symbol, data_refs::Vector{DataRef};
                   plot_id::String = string(uuid4()),
                   prefs::Union{Nothing,Dict{String,Any}} = nothing,
                   attrs...)::Plot
    palette_index = length(ax.plots[]) + 1   # cyclic color per plot in this axis
    a = _init_attrs(plot_type; prefs = prefs, palette_index = palette_index)
    for (k, v) in attrs
        if haskey(a, k)
            a[k][] = v
        end
    end
    api = haskey(REGISTRY, plot_type) ? REGISTRY[plot_type].api : (makie_major = 0, makie_minor = 24)
    status = haskey(REGISTRY, plot_type) ? REGISTRY[plot_type].status : :valid
    args = Any[typed_value(r) for r in data_refs]
    kwargs = Dict{Symbol, Any}(k => typed_value(obs[]) for (k, obs) in a)
    plot = Plot(plot_id, ax.id, plot_type, args, kwargs, api, PlotMeta(v"1.0.0", status),
                plot_type, Observable(data_refs), a,
                Observable{Union{Nothing,AnimBinding}}(nothing))
    for (k, obs) in a
        on(obs) do val
            plot.kwargs[k] = typed_value(val)
        end
    end
    on(plot.data_refs) do refs
        plot.args = Any[typed_value(r) for r in refs]
    end
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
