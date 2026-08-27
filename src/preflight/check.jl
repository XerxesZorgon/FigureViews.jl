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
