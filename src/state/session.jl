const _DEMO_DATA = Dict{String, NamedTuple}()

function new_session()::Session
    return Session(
        v"1.0.0",
        Observable(Figure[]),
        Dict{String,Any}(),
        Observable{Union{Nothing,String}}(nothing)
    )
end

function add_figure!(s::Session; title::String = "Untitled")::Figure
    fig = Figure(
        string(uuid4()),
        Observable(title),
        Observable(LayoutSpec(1, 1)),
        Observable(Axis[])
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
        Observable(Plot[])                                      # plots
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

# M2-only demo scaffolding, remove at M5
function add_line_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :line,
        Observable(DataRef[]),
        _init_attrs(:line),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=nothing)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end

function add_scatter_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :scatter,
        Observable(DataRef[]),
        _init_attrs(:scatter),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=nothing)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end

function add_bar_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :bar,
        Observable(DataRef[]),
        _init_attrs(:bar),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=nothing)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end

function add_heatmap_plot!(ax::Axis; matrix::AbstractMatrix, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :heatmap,
        Observable(DataRef[]),
        _init_attrs(:heatmap),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=nothing, y=nothing, z=nothing, matrix=matrix)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end

function add_contour_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, z::AbstractMatrix, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :contour,
        Observable(DataRef[]),
        _init_attrs(:contour),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=z)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end

# M2-only demo scaffolding, remove at M5
function add_surface_plot!(ax::Axis; x::AbstractVector, y::AbstractVector, z::AbstractMatrix, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :surface,
        Observable(DataRef[]),
        _init_attrs(:surface),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=x, y=y, z=nothing, matrix=z)   # z-surface stored in matrix field, same as contour
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end

# M2-only demo scaffolding, remove at M5
function add_volume_plot!(ax::Axis; vol::AbstractArray{<:Real,3}, plot_id::String = string(uuid4()))::Plot
    plot = Plot(
        plot_id,
        :volume,
        Observable(DataRef[]),
        _init_attrs(:volume),
        Observable{Union{Nothing,AnimBinding}}(nothing)
    )
    _DEMO_DATA[plot_id] = (x=nothing, y=nothing, z=nothing, matrix=nothing, volume=vol)
    ax.plots[] = [ax.plots[]..., plot]
    return plot
end
