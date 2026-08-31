struct AddPlotOp
    ax_node::Axis
    plot::Plot
end

struct RemovePlotOp
    plot_id::String
end

struct AddAxisOp
    fig_node::Figure
    ax_node::Axis
end

struct RemoveAxisOp
    ax_id::String
end

_window_is_live(renderer::Renderer) = renderer.viewport_widget !== nothing

function _post_to_queue!(renderer::Renderer, op)
    lock(renderer._queue_lock) do
        push!(renderer._mutation_queue, op)
    end
    # Arm a one-shot g_idle_add drain (fires on main thread at next GLib idle).
    # Captures renderer and viewport_widget by reference in the closure.
    widget = renderer.viewport_widget
    Gtk4.GLib.g_idle_add(Gtk4.GLib.PRIORITY_DEFAULT) do
        try
            # Drain all pending ops on the main thread.
            ops = lock(renderer._queue_lock) do
                ops = copy(renderer._mutation_queue)
                empty!(renderer._mutation_queue)
                ops
            end
            for op in ops
                _apply_structural_direct!(renderer, op)
            end
            # Single queue_render after all ops applied.
            if widget !== nothing
                Gtk4.queue_render(widget)
            end
        catch err
            @error "g_idle_add drain failed" exception=(err, catch_backtrace())
        end
        return false  # one-shot: do not re-arm automatically
    end
    ccall((:g_main_context_wakeup, Gtk4.GLib.libglib), Cvoid, (Ptr{Cvoid},), C_NULL)
end

function apply_structural!(renderer::Renderer, op)
    if _window_is_live(renderer)
        _post_to_queue!(renderer, op)
    else
        _apply_structural_direct!(renderer, op)
    end
end

function _apply_structural_direct!(renderer::Renderer, op::AddPlotOp)
    _add_plot_handle!(renderer, op.ax_node, op.plot)
end

function _apply_structural_direct!(renderer::Renderer, op::RemovePlotOp)
    _remove_plot_handle!(renderer, op.plot_id)
end

function _apply_structural_direct!(renderer::Renderer, op::AddAxisOp)
    _add_axis!(renderer, op.fig_node, op.ax_node)
end

function _apply_structural_direct!(renderer::Renderer, op::RemoveAxisOp)
    _remove_axis!(renderer, op.ax_id)
end
