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

# Returns true when a makieviews() window is displayed and the live-queued branch is active.
# Task 090 replaces this stub with the real flag check.
_window_is_live(renderer::Renderer) = false

function apply_structural!(renderer::Renderer, op)
    if _window_is_live(renderer)
        # Task 090: live-queued branch attaches here
        error("live-queued branch not yet implemented (Task 090)")
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
