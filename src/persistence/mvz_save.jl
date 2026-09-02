const _DATA_INLINE_MAX_ELEMENTS = 100_000

"""
    save_session(session::Session, path::String)

Serialize `session` to a `.mvz` TOML file at `path`.
Creates parent directories if they do not exist.
"""
function save_session(session::Session, path::String)
    mkpath(dirname(abspath(path)))
    d = _session_to_dict(session)
    open(path, "w") do io
        TOML.print(io, d)
    end
end

function _session_to_dict(session::Session)::Dict{String,Any}
    d = Dict{String,Any}()
    d["schema_version"] = "1.1"
    d["preferences_snapshot"] = copy(session.preferences_snapshot)
    d["figure"] = [_figure_to_dict(fig; session) for fig in session.figures[]]
    return d
end

function _figure_to_dict(fig::Figure; session::Union{Session,Nothing} = nothing)::Dict{String,Any}
    d = Dict{String,Any}()
    d["id"]    = fig.id
    d["title"] = fig.title[]
    d["layout"] = Dict{String,Any}("rows" => fig.layout[].rows, "cols" => fig.layout[].cols)
    d["axis"]  = [_axis_to_dict(ax; session) for ax in fig.axes[]]
    return d
end

function _axis_to_dict(ax::Axis; session::Union{Session,Nothing} = nothing)::Dict{String,Any}
    d = Dict{String,Any}()
    d["id"]        = ax.id
    d["kind"]      = string(ax.kind)
    d["title"]     = ax.title[]
    d["xlabel"]    = ax.xlabel[]
    d["ylabel"]    = ax.ylabel[]
    d["zlabel"]    = ax.zlabel[]
    d["xscale"]    = string(ax.xscale[])
    d["yscale"]    = string(ax.yscale[])
    d["gridlines"] = ax.gridlines[]
    d["legend"]    = ax.legend[]
    if ax.xlim[] !== nothing
        d["xlim"] = collect(ax.xlim[])
    end
    if ax.ylim[] !== nothing
        d["ylim"] = collect(ax.ylim[])
    end
    if ax.tickformat[] !== nothing
        d["tickformat"] = ax.tickformat[]
    end
    if ax.camera[] !== nothing
        cam = ax.camera[]
        d["camera"] = Dict{String,Any}("azimuth" => cam.azimuth, "elevation" => cam.elevation, "zoom" => cam.zoom)
    end
    d["plot"] = [_plot_to_dict(p, ax.id; session) for p in ax.plots[]]
    return d
end

function _typed_value_to_dict(tv::TypedValue)::Dict{String,Any}
    val = if tv.type == :DataRef && tv.value isa DataRef
        _dataref_to_dict(tv.value)
    elseif tv.value isa Colors.Colorant
        "#" * Colors.hex(tv.value)
    elseif tv.value isa Symbol
        string(tv.value)
    elseif tv.value isa Tuple
        collect(tv.value)
    else
        tv.value
    end
    return Dict{String,Any}(
        "type" => string(tv.type),
        "value" => val
    )
end
_typed_value_to_dict(v) = _typed_value_to_dict(typed_value(v))

function _plot_to_dict(plot::Plot, target::String = ""; session::Union{Session,Nothing} = nothing)::Dict{String,Any}
    d = Dict{String,Any}()
    d["id"]     = plot.id
    d["target"] = !isempty(plot.target) ? plot.target : target
    d["func"]   = string(plot.func)
    d["type"]   = string(plot.type)
    d["api"]    = Dict{String,Any}(
        "makie_major" => plot.api.makie_major,
        "makie_minor" => plot.api.makie_minor
    )
    d["meta"]   = Dict{String,Any}(
        "schema_version" => string(plot.meta.schema_version),
        "status"         => string(plot.meta.status)
    )

    # Sync attrs to kwargs to ensure latest values are serialized
    for (k, obs) in plot.attrs
        plot.kwargs[k] = typed_value(obs[])
    end
    if !isempty(plot.data_refs[])
        plot.args = Any[typed_value(r) for r in plot.data_refs[]]
    end

    d["args"]      = [_typed_value_to_dict(a) for a in plot.args]
    d["kwargs"]    = Dict{String,Any}(string(k) => _typed_value_to_dict(v) for (k, v) in plot.kwargs)
    d["data_refs"] = [_dataref_to_dict(r) for r in plot.data_refs[]]
    if session !== nothing && !isempty(plot.data_refs[])
        inline = Dict{String,Any}()
        for ref in plot.data_refs[]
            haskey(inline, ref.snapshot_id) && continue        # de-duplicate
            arr = get(session.data_snapshots, ref.snapshot_id, nothing)
            arr === nothing && continue                         # orphaned ref — skip
            n = length(arr)
            if n > _DATA_INLINE_MAX_ELEMENTS
                error("Cannot save: snapshot '$(ref.snapshot_id)' has $(n) elements, " *
                      "which exceeds the $(_DATA_INLINE_MAX_ELEMENTS)-element inline limit. " *
                      "Reduce dataset size or load data from a CSV/HDF5 source.")
            end
            inline[ref.snapshot_id] = Dict{String,Any}(
                "eltype" => string(eltype(arr)),
                "shape"  => collect(Int, size(arr)),
                "data"   => vec(Float64.(arr))
            )
        end
        if !isempty(inline)
            d["data_inline"] = inline
        end
    end
    attrs = Dict{String,Any}()
    for (k, obs) in plot.attrs
        v = obs[]
        if v isa Colors.Colorant
            attrs[string(k)] = "#" * Colors.hex(v)
        elseif v isa Tuple
            attrs[string(k)] = collect(v)
        else
            attrs[string(k)] = v isa Symbol ? string(v) : v
        end
    end
    d["attrs"] = attrs
    if plot.animation_binding[] !== nothing
        b = plot.animation_binding[]
        d["animation"] = Dict{String,Any}(
            "snapshot_id"   => b.snapshot_id,
            "frame_count"   => b.frame_count,
            "fps"           => b.fps,
            "current_frame" => b.current_frame
        )
    end
    return d
end

function _plot_to_dict(node::UnknownNode, target::String = ""; session::Union{Session,Nothing} = nothing)::Dict{String,Any}
    d = copy(node.payload)
    d["type"] = node.original_type
    if !haskey(d, "target") && !isempty(target)
        d["target"] = target
    end
    return d
end

function _dataref_to_dict(ref::DataRef)::Dict{String,Any}
    d = Dict{String,Any}()
    d["role"]        = string(ref.role)
    d["snapshot_id"] = ref.snapshot_id
    d["source"]      = string(ref.source)
    d["label"]       = ref.label
    if ref.absolute_path !== nothing; d["absolute_path"] = ref.absolute_path; end
    if ref.relative_path !== nothing; d["relative_path"] = ref.relative_path; end
    if ref.column        !== nothing; d["column"]        = ref.column;        end
    if ref.dataset       !== nothing; d["dataset"]       = ref.dataset;       end
    if ref.variable      !== nothing; d["variable"]      = string(ref.variable); end
    return d
end
