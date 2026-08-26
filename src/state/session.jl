
function new_session()::Session
    return Session(
        v"1.0.0",
        Observable(Figure[]),
        Dict{String,Any}(),
        Dict{String, AbstractArray}(),
        Observable{Union{Nothing,String}}(nothing)
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

function _init_attrs(plot_type::Symbol)::Dict{Symbol, Observable{Any}}
    d = Dict{Symbol, Observable{Any}}()
    for spec in PLOT_SCHEMAS[plot_type]
        d[spec.name] = Observable{Any}(spec.default)
    end
    return d
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
                   plot_id::String = string(uuid4()), attrs...)::Plot
    a = _init_attrs(plot_type)
    for (k, v) in attrs
        if haskey(a, k)
            a[k][] = v
        end
    end
    plot = Plot(
        plot_id,
        plot_type,
        Observable(data_refs),
        a,
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
