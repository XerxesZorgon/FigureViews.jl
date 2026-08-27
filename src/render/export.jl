# src/render/export.jl

"""
    render_animation(session, renderer, plot_node, path; fps=nothing) -> String

Render all frames of the animation bound to `plot_node` to `path` (.gif or .mp4).
Blocks on the calling thread (main-thread only, v0.1 per ADR-014).
Returns the path on success.
"""
function render_animation(session::Session, renderer::Renderer,
                          plot_node::Plot, path::String;
                          fps::Union{Nothing,Int} = nothing)::String
    binding = plot_node.animation_binding[]
    binding === nothing && error("plot has no animation binding")
    n_frames   = binding.frame_count
    export_fps = fps !== nothing ? fps : binding.fps
    arr3d      = session.data_snapshots[binding.snapshot_id]
    handle     = get(renderer.plot_handles, plot_node.id, nothing)
    handle === nothing && error("plot not found in renderer.plot_handles")
    ext = lowercase(splitext(path)[2])
    ext in (".mp4", ".gif") || error("Unsupported format $(ext). Use .mp4 or .gif.")

    Makie.record(renderer.fig, path; framerate = export_fps) do io
        for t in 1:n_frames
            mat_t = arr3d[:, :, t]
            if hasproperty(handle, :matrix)
                handle.matrix[] = mat_t
            elseif hasproperty(handle, :color)
                handle.color[] = mat_t
            end
            Makie.recordframe!(io)
        end
    end
    return path
end

"""
    export_figure(renderer::Renderer, path::String) -> String

Export `renderer.fig` to `path` as PNG, SVG, or PDF (format inferred from extension).
Switches to CairoMakie backend for export, then restores GLMakie.
Runs on the calling thread (main thread in GUI context, per ADR-014).
Returns the path on success.
"""
function export_figure(renderer::Renderer, path::String)::String
    ext = lowercase(splitext(path)[2])
    ext in (".png", ".svg", ".pdf") ||
        error("Unsupported export format $ext. Use .png, .svg, or .pdf.")
    mkpath(dirname(abspath(path)))
    # Switch to CairoMakie, export, restore GLMakie even on error
    CairoMakie.activate!()
    try
        CairoMakie.save(path, renderer.fig)
    finally
        GLMakie.activate!()
    end
    return path
end
