mutable struct Renderer
    fig::Makie.Figure
    session::Session
    axis_handles::Dict{String, Any}
    plot_handles::Dict{String, Any}
    _observer_handles::Vector{Any}
end

function Renderer(session::Session, fig::Makie.Figure)
    renderer = Renderer(fig, session, Dict{String, Any}(), Dict{String, Any}(), Any[])
    
    _rebuild_from_session!(renderer)
    
    h = on(session.figures) do _
        empty!(renderer.fig)
        _rebuild_from_session!(renderer)
    end
    push!(renderer._observer_handles, h)
    
    return renderer
end

function _rebuild_from_session!(renderer::Renderer)
    axis_index = 0
    for fig_node in renderer.session.figures[]
        for ax_node in fig_node.axes[]
            axis_index += 1
            # v0.1 layout rule: one row per axis so 2D/3D axes never share a cell.
            # General rows×cols LayoutSpec placement is deferred to a later milestone.
            _render_axis!(renderer, renderer.fig, ax_node, renderer.fig[axis_index, 1])
            
            h = on(ax_node.plots) do _
                empty!(renderer.fig)
                _rebuild_from_session!(renderer)
            end
            push!(renderer._observer_handles, h)
        end
        h = on(fig_node.axes) do _
            empty!(renderer.fig)
            _rebuild_from_session!(renderer)
        end
        push!(renderer._observer_handles, h)
    end
end

function _render_axis!(renderer::Renderer, fig::Makie.Figure, ax::Axis, position)::Union{Makie.Axis, Makie.Axis3}
    makie_ax = if ax.kind == :axis3d
        Makie.Axis3(position)
    else
        Makie.Axis(position)
    end
    renderer.axis_handles[ax.id] = makie_ax
    
    # Initialize basic attributes
    makie_ax.title[] = ax.title[]
    makie_ax.xlabel[] = ax.xlabel[]
    makie_ax.ylabel[] = ax.ylabel[]
    
    _register_axis_observer!(renderer, ax)
    
    for plot in ax.plots[]
        _render_plot!(renderer, makie_ax, plot)
    end
    
    return makie_ax
end

function _render_plot!(renderer::Renderer, makie_ax, plot::Plot)
    # Helper: look up the snapshot array for a given role
    function arr(role::Symbol)
        ref = only(r for r in plot.data_refs[] if r.role == role)
        return renderer.session.data_snapshots[ref.snapshot_id]
    end

    if plot.type == :line
        handle = Makie.lines!(makie_ax, arr(:x), arr(:y);
            color     = plot.attrs[:color][],
            linewidth = plot.attrs[:linewidth][],
            linestyle = plot.attrs[:linestyle][],
            label     = plot.attrs[:label][],
            visible   = plot.attrs[:visible][]
        )
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :scatter
        handle = Makie.scatter!(makie_ax, arr(:x), arr(:y);
            color      = plot.attrs[:color][],
            markersize = plot.attrs[:markersize][],
            marker     = plot.attrs[:marker][],
            label      = plot.attrs[:label][],
            visible    = plot.attrs[:visible][]
        )
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :bar
        direction = plot.attrs[:direction][]
        handle = if direction == :vertical
            Makie.barplot!(makie_ax, arr(:x), arr(:y);
                color   = plot.attrs[:color][],
                width   = plot.attrs[:width][],
                label   = plot.attrs[:label][],
                visible = plot.attrs[:visible][])
        else
            Makie.barplot!(makie_ax, arr(:y), arr(:x);
                color     = plot.attrs[:color][],
                width     = plot.attrs[:width][],
                direction = :x,
                label     = plot.attrs[:label][],
                visible   = plot.attrs[:visible][])
        end
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :heatmap
        handle = Makie.heatmap!(makie_ax, arr(:matrix);
            colormap   = plot.attrs[:colormap][],
            colorrange = plot.attrs[:colorrange][],
            label      = plot.attrs[:label][],
            visible    = plot.attrs[:visible][])
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :contour
        handle = Makie.contour!(makie_ax, arr(:x), arr(:y), arr(:matrix);
            color     = plot.attrs[:color][],
            levels    = plot.attrs[:levels][],
            linewidth = plot.attrs[:linewidth][],
            label     = plot.attrs[:label][],
            visible   = plot.attrs[:visible][])
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :surface
        shading_on = plot.attrs[:shading][] != :none
        handle = Makie.surface!(makie_ax, arr(:x), arr(:y), arr(:matrix);
            colormap = plot.attrs[:colormap][],
            shading  = shading_on,
            visible  = plot.attrs[:visible][])
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :volume
        handle = Makie.volume!(makie_ax, arr(:volume);
            colormap   = plot.attrs[:colormap][],
            algorithm  = plot.attrs[:algorithm][],
            colorrange = plot.attrs[:colorrange][],
            visible    = plot.attrs[:visible][])
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    end
end

function _register_axis_observer!(renderer::Renderer, ax::Axis)
    makie_ax = renderer.axis_handles[ax.id]
    h1 = on(ax.title) do t; makie_ax.title[] = t; end
    h2 = on(ax.xlabel) do t; makie_ax.xlabel[] = t; end
    h3 = on(ax.ylabel) do t; makie_ax.ylabel[] = t; end
    h4 = nothing
    h5 = nothing
    if ax.kind != :axis3d
        h4 = on(ax.xlim) do lim; if lim !== nothing makie_ax.limits[] = (lim[1], lim[2], makie_ax.limits[][3], makie_ax.limits[][4]) end; end
        h5 = on(ax.ylim) do lim; if lim !== nothing makie_ax.limits[] = (makie_ax.limits[][1], makie_ax.limits[][2], lim[1], lim[2]) end; end
    end
    
    push!(renderer._observer_handles, h1)
    push!(renderer._observer_handles, h2)
    push!(renderer._observer_handles, h3)
    if h4 !== nothing
        push!(renderer._observer_handles, h4)
    end
    if h5 !== nothing
        push!(renderer._observer_handles, h5)
    end

    if ax.kind == :axis3d && makie_ax isa Makie.Axis3
        hc = on(ax.camera) do cam
            if cam !== nothing
                makie_ax.azimuth[]   = cam.azimuth
                makie_ax.elevation[] = cam.elevation
                # zoom: Axis3 has no scalar zoom Observable; azimuth/elevation are the tested path.
            end
        end
        push!(renderer._observer_handles, hc)
    end
end

function _register_plot_observer!(renderer::Renderer, plot::Plot)
    for (name, obs) in plot.attrs
        # :shading live-mutation needs shading_map translation; deferred to M5
        if name == :shading
            continue
        end
        h = on(obs) do val
            handle = renderer.plot_handles[plot.id]
            handle[name] = val
        end
        push!(renderer._observer_handles, h)
    end

    # Animation binding observer: swap frame data when current_frame changes
    hb = on(plot.animation_binding) do b
        b === nothing && return
        handle = get(renderer.plot_handles, plot.id, nothing)
        handle === nothing && return
        arr3d = get(renderer.session.data_snapshots, b.snapshot_id, nothing)
        arr3d === nothing && return
        mat_t = arr3d[:, :, b.current_frame]
        if hasproperty(handle, :matrix)
            handle.matrix[] = mat_t
        elseif hasproperty(handle, :color)
            handle.color[] = mat_t
        end
    end
    push!(renderer._observer_handles, hb)
end
