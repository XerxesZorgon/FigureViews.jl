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
    for fig_node in renderer.session.figures[]
        for ax_node in fig_node.axes[]
            _render_axis!(renderer, renderer.fig, ax_node, renderer.fig[1, 1])
            
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
    makie_ax = Makie.Axis(position)
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
    if plot.type == :line
        x = _DEMO_DATA[plot.id].x
        y = _DEMO_DATA[plot.id].y
        handle = Makie.lines!(makie_ax, x, y;
            color     = plot.attrs[:color][],
            linewidth = plot.attrs[:linewidth][],
            linestyle = plot.attrs[:linestyle][],
            label     = plot.attrs[:label][],
            visible   = plot.attrs[:visible][]
        )
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :scatter
        x = _DEMO_DATA[plot.id].x
        y = _DEMO_DATA[plot.id].y
        handle = Makie.scatter!(makie_ax, x, y;
            color      = plot.attrs[:color][],
            markersize = plot.attrs[:markersize][],
            marker     = plot.attrs[:marker][],
            label      = plot.attrs[:label][],
            visible    = plot.attrs[:visible][]
        )
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :bar
        x = _DEMO_DATA[plot.id].x
        y = _DEMO_DATA[plot.id].y
        direction = plot.attrs[:direction][]
        handle = if direction == :vertical
            Makie.barplot!(makie_ax, x, y;
                color   = plot.attrs[:color][],
                width   = plot.attrs[:width][],
                label   = plot.attrs[:label][],
                visible = plot.attrs[:visible][])
        else
            Makie.barplot!(makie_ax, y, x;   # horizontal: swap x/y
                color       = plot.attrs[:color][],
                width       = plot.attrs[:width][],
                direction   = :x,
                label       = plot.attrs[:label][],
                visible     = plot.attrs[:visible][])
        end
        renderer.plot_handles[plot.id] = handle
        _register_plot_observer!(renderer, plot)
    elseif plot.type == :heatmap
        mat = _DEMO_DATA[plot.id].matrix
        handle = Makie.heatmap!(makie_ax, mat;
            colormap   = plot.attrs[:colormap][],
            colorrange = plot.attrs[:colorrange][],
            label      = plot.attrs[:label][],
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
    h4 = on(ax.xlim) do lim; if lim !== nothing makie_ax.limits[] = (lim[1], lim[2], makie_ax.limits[][3], makie_ax.limits[][4]) end; end
    h5 = on(ax.ylim) do lim; if lim !== nothing makie_ax.limits[] = (makie_ax.limits[][1], makie_ax.limits[][2], lim[1], lim[2]) end; end
    
    push!(renderer._observer_handles, h1)
    push!(renderer._observer_handles, h2)
    push!(renderer._observer_handles, h3)
    push!(renderer._observer_handles, h4)
    push!(renderer._observer_handles, h5)
end

function _register_plot_observer!(renderer::Renderer, plot::Plot)
    for (name, obs) in plot.attrs
        h = on(obs) do val
            handle = renderer.plot_handles[plot.id]
            handle[name] = val
        end
        push!(renderer._observer_handles, h)
    end
end
