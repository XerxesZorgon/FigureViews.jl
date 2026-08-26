# src/persistence/mvz_save.jl

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
    d["schema_version"] = "1.0"
    d["preferences_snapshot"] = copy(session.preferences_snapshot)
    d["figure"] = [_figure_to_dict(fig) for fig in session.figures[]]
    return d
end

function _figure_to_dict(fig::Figure)::Dict{String,Any}
    d = Dict{String,Any}()
    d["id"]    = fig.id
    d["title"] = fig.title[]
    d["layout"] = Dict{String,Any}("rows" => fig.layout[].rows, "cols" => fig.layout[].cols)
    d["axis"]  = [_axis_to_dict(ax) for ax in fig.axes[]]
    return d
end

function _axis_to_dict(ax::Axis)::Dict{String,Any}
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
    d["plot"] = [_plot_to_dict(p) for p in ax.plots[]]
    return d
end

function _plot_to_dict(plot::Plot)::Dict{String,Any}
    d = Dict{String,Any}()
    d["id"]   = plot.id
    d["type"] = string(plot.type)
    d["data_refs"] = [_dataref_to_dict(r) for r in plot.data_refs[]]
    attrs = Dict{String,Any}()
    for (k, obs) in plot.attrs
        v = obs[]
        if v isa Colors.Colorant
            attrs[string(k)] = "#" * Colors.hex(v)
        else
            attrs[string(k)] = v isa Symbol ? string(v) : v
        end
    end
    d["attrs"] = attrs
    return d
end

function _plot_to_dict(node::UnknownNode)::Dict{String,Any}
    d = copy(node.payload)
    d["type"] = node.original_type
    return d
end

function _dataref_to_dict(ref::DataRef)::Dict{String,Any}
    d = Dict{String,Any}()
    d["role"]   = string(ref.role)
    d["source"] = string(ref.source)
    d["label"]  = ref.label
    if ref.absolute_path !== nothing; d["absolute_path"] = ref.absolute_path; end
    if ref.relative_path !== nothing; d["relative_path"] = ref.relative_path; end
    if ref.column        !== nothing; d["column"]        = ref.column;        end
    if ref.dataset       !== nothing; d["dataset"]       = ref.dataset;       end
    if ref.variable      !== nothing; d["variable"]      = string(ref.variable); end
    return d
end
