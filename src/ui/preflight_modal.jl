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

"""
    _apply_preflight_choice(session, plot, choice, downsample_spec) -> Plot

Apply the user's pre-flight choice to an already-added plot.
`choice` ∈ :accept | :override | :downsample.
`downsample_spec` is a DownsampleAlgorithm (e.g. LTTB(500)) or nothing.
Returns the (possibly mutated) plot.
"""
function _apply_preflight_choice(session::Session,
                                 plot::Plot,
                                 choice::Symbol,
                                 downsample_spec::Union{Nothing, DownsampleAlgorithm} = nothing)::Plot
    if choice == :accept
        # keep at full size — nothing to do
    elseif choice == :override
        @info "pre-flight override accepted"
        # keep at full size — nothing to do
    elseif choice == :downsample
        if downsample_spec === nothing
            @info "downsample cancelled — plot kept at full size"
        else
            apply_downsample!(session, plot, downsample_spec)
        end
    else
        @warn "unknown pre-flight choice: $choice — treating as :accept"
    end
    return plot
end

"""
    _show_downsample_dialog(parent_window) -> Union{Nothing, DownsampleAlgorithm}

Display a dialog allowing the user to select an algorithm (LTTB, MinMaxDecimation, UniformStride) and target points.
Returns the constructed DownsampleAlgorithm or nothing if cancelled.
"""
function _show_downsample_dialog(parent_window)::Union{Nothing, DownsampleAlgorithm}
    dialog = GtkWindow("Downsample Options", 350, 200)
    dialog.modal = true
    if parent_window !== nothing
        try
            Gtk4.G_.set_transient_for(dialog, parent_window)
        catch
        end
    end

    main_box = GtkBox(:v)
    main_box.spacing = 10
    main_box.margin_start = 12
    main_box.margin_end = 12
    main_box.margin_top = 12
    main_box.margin_bottom = 12
    dialog[] = main_box

    algo_labels = ["LTTB", "MinMaxDecimation", "UniformStride"]
    algo_dropdown = GtkDropDown(algo_labels)

    algo_box = GtkBox(:h)
    algo_box.spacing = 8
    push!(algo_box, GtkLabel("Algorithm:"))
    push!(algo_box, algo_dropdown)
    push!(main_box, algo_box)

    spin_btn = GtkSpinButton(100, 1_000_000, 100)
    spin_btn.value = 10_000

    n_box = GtkBox(:h)
    n_box.spacing = 8
    push!(n_box, GtkLabel("Target points:"))
    push!(n_box, spin_btn)
    push!(main_box, n_box)

    btn_box = GtkBox(:h)
    btn_box.spacing = 8
    btn_box.halign = Gtk4.Align_END
    cancel_btn = GtkButton("Cancel")
    ok_btn = GtkButton("OK")
    push!(btn_box, cancel_btn)
    push!(btn_box, ok_btn)
    push!(main_box, btn_box)

    res = Ref{Union{Nothing, DownsampleAlgorithm}}(nothing)
    c = Condition()

    signal_connect(cancel_btn, "clicked") do _
        res[] = nothing
        notify(c)
        Gtk4.destroy(dialog)
    end

    signal_connect(ok_btn, "clicked") do _
        target_n = Int(round(spin_btn.value))
        idx = algo_dropdown.selected
        if idx == 0
            res[] = LTTB(target_n)
        elseif idx == 1
            res[] = MinMaxDecimation(target_n)
        elseif idx == 2
            res[] = UniformStride(target_n)
        else
            res[] = LTTB(target_n)
        end
        notify(c)
        Gtk4.destroy(dialog)
    end

    show(dialog)
    wait(c)
    return res[]
end
