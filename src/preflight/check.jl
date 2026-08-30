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

"""
    add_plot_checked!(ax, plot_type, data_refs; session, host, downsample) -> (plot, decision, reason)

Pre-flight-aware `add_plot!`. Runs `preflight_decision` on the largest referenced
array; on `:warn` with no `downsample=`, emits an advisory `@warn` and still adds the
plot at full size. `downsample=<DownsampleAlgorithm>` adds then reduces (no warning).
"""
function add_plot_checked!(ax::Axis, plot_type::Symbol, data_refs::Vector{DataRef};
                           session::Session = _current_session[],
                           host::HostSpecs = detect_host_specs(),
                           downsample::Union{Nothing, DownsampleAlgorithm} = nothing)
    session === nothing && throw(ArgumentError("add_plot_checked! needs an active session"))
    arrays = [session.data_snapshots[r.snapshot_id]
              for r in data_refs if haskey(session.data_snapshots, r.snapshot_id)]
    dec = isempty(arrays) ?
          (decision = :accept, reason = :ok, est_fps = Inf, est_bytes = 0) :
          preflight_decision(host, argmax(length, arrays), plot_type)
    plot = add_plot!(ax, plot_type, data_refs)
    if downsample !== nothing
        apply_downsample!(session, plot, downsample)
    elseif dec.decision == :warn
        @warn "FigureViews pre-flight: this $plot_type plot is large and may run slowly or freeze the GUI." estimated_MB = round(dec.est_bytes / 1e6; digits = 1) estimated_fps = round(dec.est_fps; digits = 1) reason = dec.reason tip = "pass downsample=LTTB(n) (or UniformStride / MinMaxDecimation) to reduce it"
    end
    return (plot = plot, decision = dec.decision, reason = dec.reason)
end
