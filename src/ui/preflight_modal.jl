# src/ui/preflight_modal.jl

"""
    _format_preflight_body(decision::NamedTuple) -> String

Format the body text for the pre-flight warning dialog.
`decision` must have fields: `reason`, `est_fps`, `est_bytes`.
`reason` ∈ :fps | :vram | :both  (:ok should never reach this function).
"""
function _format_preflight_body(decision::NamedTuple)::String
    mb  = round(decision.est_bytes / 1e6; digits = 1)
    fps = round(decision.est_fps; digits = 1)
    fps_msg  = "Estimated frame rate is below 15 fps (est. $(fps) fps)."
    vram_msg = "Dataset would consume more than 60% of GPU VRAM (est. $(mb) MB)."
    if decision.reason == :fps
        return "$(fps_msg)\n\nDataset size: $(mb) MB."
    elseif decision.reason == :vram
        return "$(vram_msg)\n\nEstimated fps: $(fps)."
    elseif decision.reason == :both
        return "$(fps_msg)\n$(vram_msg)"
    else
        error("_format_preflight_body: unexpected reason $(decision.reason)")
    end
end

"""
    show_preflight_modal(parent_window, decision::NamedTuple) -> Symbol

Display a modal dialog with three options: Accept, Downsample…, and Override.
Returns `:accept`, `:downsample`, or `:override`.
"""
function show_preflight_modal(parent_window, decision::NamedTuple)::Symbol
    res = Ref{Symbol}(:accept)
    c = Condition()

    dlg = GtkMessageDialog(
        _format_preflight_body(decision),
        [("Accept", 1), ("Downsample…", 2), ("Override", 3)],
        Gtk4.DialogFlags_MODAL,
        Gtk4.MessageType_WARNING,
        parent_window
    )
    dlg.title = "Large dataset warning"

    signal_connect(dlg, "response") do _, response_id
        if response_id == 1
            res[] = :accept
        elseif response_id == 2
            res[] = :downsample
        elseif response_id == 3
            res[] = :override
        else
            res[] = :accept
        end
        notify(c)
        Gtk4.destroy(dlg)
    end
    show(dlg)
    wait(c)
    return res[]
end
