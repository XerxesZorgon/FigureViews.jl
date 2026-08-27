# Threshold: warn if fps too low OR footprint would blow past 60% of VRAM.
# FR-026: when VRAM is undetectable (nothing), only the fps criterion applies.
function over_threshold(host::HostSpecs, est_bytes::Integer, est_fps::Real)::Bool
    return est_fps < 15 || (host.vram_bytes !== nothing && est_bytes > 0.6 * host.vram_bytes)
end

# Full decision for one array + plot type. `decision` is :accept (load full, no dialog)
# or :warn (over threshold — caller shows the dialog in 064b). `reason` ∈ :ok/:fps/:vram/:both.
function preflight_decision(host::HostSpecs, array::AbstractArray, plot_type::Symbol)
    est_bytes = estimate_footprint(array)
    est_fps   = estimate_fps(plot_type, length(array), host)
    fps_over  = est_fps < 15
    vram_over = host.vram_bytes !== nothing && est_bytes > 0.6 * host.vram_bytes
    over = fps_over || vram_over
    reason = !over ? :ok : (fps_over && vram_over) ? :both : fps_over ? :fps : :vram
    return (decision = over ? :warn : :accept, reason = reason,
            est_fps = est_fps, est_bytes = est_bytes)
end

# Record the chosen downsample algorithm on the plot (DESIGN §7.3). Serialization of the
# algorithm into .mvz is handled by the persistence/docs task, not here.
function record_downsample!(plot::Plot, algo::DownsampleAlgorithm)
    plot.attrs[:downsample_algorithm] = Observable{Any}(algo)
    return plot
end

# Repoint an immutable DataRef to a new snapshot id, preserving all other fields.
_repoint(r::DataRef, new_snap::String) =
    DataRef(r.role, new_snap, r.source, r.label,
            r.absolute_path, r.relative_path, r.column, r.dataset, r.variable)

# Apply a downsample to a 1-D (x,y) plot: materialize reduced snapshots, repoint the
# :x/:y refs, record the algorithm, and keep the full arrays in data_snapshots.
function apply_downsample!(session::Session, plot::Plot, algo::DownsampleAlgorithm)
    refs = plot.data_refs[]
    xi = findfirst(r -> r.role == :x, refs)
    yi = findfirst(r -> r.role == :y, refs)
    (xi === nothing || yi === nothing) && throw(ArgumentError(
        "apply_downsample! requires :x and :y data refs (1-D plots); 2-D field stride is separate"))
    xfull = session.data_snapshots[refs[xi].snapshot_id]
    yfull = session.data_snapshots[refs[yi].snapshot_id]
    rx, ry = downsample(algo, xfull, yfull)
    rxid = string(uuid4()); ryid = string(uuid4())
    session.data_snapshots[rxid] = rx
    session.data_snapshots[ryid] = ry
    newrefs = copy(refs)
    newrefs[xi] = _repoint(refs[xi], rxid)
    newrefs[yi] = _repoint(refs[yi], ryid)
    plot.data_refs[] = newrefs
    record_downsample!(plot, algo)
    return plot
end
