mutable struct Renderer
    fig::Makie.Figure
    session::Session
    axis_handles::Dict{String, Any}
    plot_handles::Dict{String, Any}
    _plot_axis::Dict{String, String}
    _plot_observers::Dict{String, Vector{Any}}
    _axis_observers::Dict{String, Vector{Any}}
    _structural_observers::Vector{Any}
    # Live-window state (set by makieviews() after show(w); nothing = headless)
    viewport_widget::Union{Nothing, Any}   # GtkMakieWidget handle
    _mutation_queue::Vector{Any}           # pending structural ops, drained on main thread
    _queue_lock::ReentrantLock             # guards _mutation_queue
end

function Renderer(session::Session, fig::Makie.Figure)
    renderer = Renderer(
        fig,
        session,
        Dict{String, Any}(),
        Dict{String, Any}(),
        Dict{String, String}(),
        Dict{String, Vector{Any}}(),
        Dict{String, Vector{Any}}(),
        Any[],
        nothing,
        Any[],
        ReentrantLock()
    )
    
    _rebuild_from_session!(renderer)
    
    h = on(session.figures) do _
        if !_window_is_live(renderer)
            empty!(renderer.fig)
            _rebuild_from_session!(renderer)
        end
    end
    push!(renderer._structural_observers, h)
    
    return renderer
end

"""
    render_session(session::Session) -> Renderer

Render `session` into a fresh Makie figure and return the `Renderer`. Convenience for
headless export and animation: `export_figure(render_session(s), "out.png")`.
"""
render_session(session::Session) = Renderer(session, Makie.Figure())

function _rebuild_from_session!(renderer::Renderer)
    axis_index = 0
    for fig_node in renderer.session.figures[]
        for ax_node in fig_node.axes[]
            axis_index += 1
            # v0.1 layout rule: one row per axis so 2D/3D axes never share a cell.
            # General rows×cols LayoutSpec placement is deferred to a later milestone.
            _render_axis!(renderer, renderer.fig, ax_node, renderer.fig[axis_index, 1])
            
            h = on(ax_node.plots) do _
                if !_window_is_live(renderer)
                    empty!(renderer.fig)
                    _rebuild_from_session!(renderer)
                end
                # In live mode, structural changes arrive via apply_structural!/queue — no rebuild here.
            end
            push!(renderer._structural_observers, h)
        end
        h = on(fig_node.axes) do _
            if !_window_is_live(renderer)
                empty!(renderer.fig)
                _rebuild_from_session!(renderer)
            end
            # In live mode, structural changes arrive via apply_structural!/queue — no rebuild here.
        end
        push!(renderer._structural_observers, h)
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
        renderer._plot_axis[plot.id] = ax.id
        _render_plot!(renderer, makie_ax, plot)
    end
    
    return makie_ax
end

function _render_plot!(renderer::Renderer, makie_ax, plot::Plot)
    for (aid, h) in renderer.axis_handles
        if h === makie_ax
            renderer._plot_axis[plot.id] = aid
            break
        end
    end

    if plot.meta.status == :unresolved || (isempty(plot.data_refs[]) && isempty(plot.args))
        handle = Makie.text!(makie_ax, "[unresolved: $(plot.func)]";
            position = Point2f(0.5, 0.5),
            space    = :relative,
            align    = (:center, :center))
        renderer.plot_handles[plot.id] = handle
        return
    end

    # Helper: look up the snapshot array for a given role
    function arr(role::Symbol)
        matches_role(r) = r.role == role ||
            (role == :x && r.role == :x_vector) ||
            (role == :y && r.role == :y_vector) ||
            (role == :z && r.role == :z_vector)
        ref = only(r for r in plot.data_refs[] if matches_role(r))
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
    else
        entry = get(REGISTRY, plot.func, nothing)
        if entry !== nothing && entry.status == :valid
            mut_sym = Symbol(string(entry.func), "!")
            if isdefined(Makie, mut_sym)
                plot_fn = getfield(Makie, mut_sym)
                pos_args = Any[]
                if !isempty(plot.data_refs[])
                    for (idx, sym) in enumerate(entry.positional_shape)
                        matched = filter(r -> r.role == sym, plot.data_refs[])
                        if !isempty(matched)
                            push!(pos_args, renderer.session.data_snapshots[matched[1].snapshot_id])
                        elseif length(plot.data_refs[]) >= idx
                            push!(pos_args, renderer.session.data_snapshots[plot.data_refs[][idx].snapshot_id])
                        end
                    end
                elseif !isempty(plot.args)
                    for a in plot.args
                        val = decode_typed_value(a)
                        if val isa DataRef
                            push!(pos_args, renderer.session.data_snapshots[val.snapshot_id])
                        else
                            push!(pos_args, val)
                        end
                    end
                end

                kw_dict = Dict{Symbol, Any}()
                for (k, obs) in plot.attrs
                    v = obs[]
                    if v !== nothing && v !== :automatic
                        kw_dict[k] = v
                    end
                end
                for (k, tv) in plot.kwargs
                    if !haskey(kw_dict, k)
                        v = decode_typed_value(tv)
                        if v !== nothing && v !== :automatic
                            kw_dict[k] = v
                        end
                    end
                end

                for (k, v) in kw_dict
                    if v isa Symbol && haskey(FUNCTION_REGISTRY, v)
                        kw_dict[k] = FUNCTION_REGISTRY[v]
                    end
                end

                handle = plot_fn(makie_ax, pos_args...; kw_dict...)
                renderer.plot_handles[plot.id] = handle
                _register_plot_observer!(renderer, plot)
            end
        end
    end
end

function _register_axis_observer!(renderer::Renderer, ax::Axis)
    obs_list = get!(() -> Any[], renderer._axis_observers, ax.id)
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
    
    push!(obs_list, h1)
    push!(obs_list, h2)
    push!(obs_list, h3)
    if h4 !== nothing
        push!(obs_list, h4)
    end
    if h5 !== nothing
        push!(obs_list, h5)
    end

    if ax.kind == :axis3d && makie_ax isa Makie.Axis3
        hc = on(ax.camera) do cam
            if cam !== nothing
                makie_ax.azimuth[]   = cam.azimuth
                makie_ax.elevation[] = cam.elevation
                # zoom: Axis3 has no scalar zoom Observable; azimuth/elevation are the tested path.
            end
        end
        push!(obs_list, hc)
    end
end

function _register_plot_observer!(renderer::Renderer, plot::Plot)
    obs_list = get!(() -> Any[], renderer._plot_observers, plot.id)
    for (name, obs) in plot.attrs
        # :shading live-mutation needs shading_map translation; deferred to M5
        if name == :shading
            continue
        end
        h = on(obs) do val
            handle = renderer.plot_handles[plot.id]
            handle[name] = val
        end
        push!(obs_list, h)
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
    push!(obs_list, hb)
end

function _add_plot_handle!(renderer::Renderer, ax_node::Axis, plot::Plot)
    makie_ax = get(renderer.axis_handles, ax_node.id, nothing)
    if makie_ax === nothing
        throw(ArgumentError("axis handle not found for ax_node.id=$(ax_node.id)"))
    end
    renderer._plot_axis[plot.id] = ax_node.id
    _render_plot!(renderer, makie_ax, plot)
end

function _remove_plot_handle!(renderer::Renderer, plot_id::String)
    if !haskey(renderer.plot_handles, plot_id)
        return
    end

    handle = renderer.plot_handles[plot_id]
    ax_id = get(renderer._plot_axis, plot_id, nothing)
    makie_ax = ax_id !== nothing ? get(renderer.axis_handles, ax_id, nothing) : nothing
    if makie_ax !== nothing
        Makie.delete!(makie_ax, handle)
    end
    delete!(renderer._plot_axis, plot_id)

    if haskey(renderer._plot_observers, plot_id)
        for h in renderer._plot_observers[plot_id]
            off(h)
        end
        delete!(renderer._plot_observers, plot_id)
    end

    delete!(renderer.plot_handles, plot_id)
    return
end

function _add_axis!(renderer::Renderer, fig_node::Figure, ax_node::Axis)
    N = length(renderer.axis_handles) + 1
    _render_axis!(renderer, renderer.fig, ax_node, renderer.fig[N, 1])
end

function _remove_axis!(renderer::Renderer, ax_id::String)
    if !haskey(renderer.axis_handles, ax_id)
        return
    end

    # 1. Remove all plots belonging to this axis
    plot_ids_to_remove = [pid for (pid, aid) in renderer._plot_axis if aid == ax_id]
    for pid in plot_ids_to_remove
        _remove_plot_handle!(renderer, pid)
    end

    # 2. Call delete! to remove the Makie axis
    makie_ax = renderer.axis_handles[ax_id]
    Makie.delete!(makie_ax)

    # 3. off() each observer in _axis_observers
    if haskey(renderer._axis_observers, ax_id)
        for h in renderer._axis_observers[ax_id]
            off(h)
        end
    end

    # M13 interim constraint: one-row-per-axis layout leaves a gap at row N when an axis is removed.
    # General layout reflow is deferred with LayoutSpec placement (PLAN-v0.2.md M14+).
    delete!(renderer._axis_observers, ax_id)
    delete!(renderer.axis_handles, ax_id)
    return
end

