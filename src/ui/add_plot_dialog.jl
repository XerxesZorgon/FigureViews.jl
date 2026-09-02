# src/ui/add_plot_dialog.jl

"""
    _confirm_add_plot(session, ax_node, plot_type, role_assignments) -> Plot

Pure function (no dialog). Ingests each assigned variable, constructs DataRefs,
calls add_plot_checked!, and posts AddPlotOp through apply_structural!.

`role_assignments`: Dict{Symbol,String} mapping positional-shape symbol
  (e.g. :x_vector, :y_vector) to a variable id in Main.
Returns the new Plot node on success; rethrows on error.
"""
function _confirm_add_plot(session::Session,
                           ax_node::Axis,
                           plot_type::Symbol,
                           role_assignments::Dict{Symbol,String};
                           source::DataSource = MainSource(Main))::Plot
    refs = DataRef[]
    for (shape_sym, var_id) in role_assignments
        snap_id = ingest!(session, source, var_id)
        push!(refs, build_dataref(source, var_id, shape_sym, snap_id))
    end
    result = add_plot_checked!(ax_node, plot_type, refs; session = session,
                               host = detect_host_specs())
    if result.decision == :warn && _window_is_live(FigureViews._current_renderer[])
        parent = FigureViews._current_renderer[].viewport_widget
        choice = show_preflight_modal(parent, result)
        if choice == :downsample
            ds_spec = _show_downsample_dialog(parent)
            _apply_preflight_choice(session, result.plot, :downsample, ds_spec)
        else
            _apply_preflight_choice(session, result.plot, choice, nothing)
        end
        # headless/test path: add_plot_checked! already emitted @warn above
    end
    # TODO(Task 110): when modal wires in :downsample, apply_downsample! needs updating
    # to match positional-shape role symbols (:x_vector/:y_vector) not the legacy :x/:y.
    apply_structural!(FigureViews._current_renderer[], AddPlotOp(ax_node, result.plot))
    return result.plot
end

"""
    show_add_plot_dialog(session::Session, ax_node::Axis, parent_window = nothing) -> GtkWindow

Open a modal dialog allowing the user to select an eligible plot type and assign variables to each required positional role.
"""
function show_add_plot_dialog(session::Session, ax_node::Axis, parent_window = nothing)
    dialog = GtkWindow("Add Plot", 450, 400)
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

    # Eligible plot types for this axis kind
    eligible_types = [type for (type, entry) in REGISTRY
                      if entry.status == :valid &&
                         get(AXIS_KIND_FOR_TYPE, type, :axis2d) in (ax_node.kind, :any)]
    sort!(eligible_types, by = string)

    type_strings = [string(t) for t in eligible_types]
    type_dropdown = GtkDropDown(type_strings)

    type_box = GtkBox(:h)
    type_box.spacing = 8
    push!(type_box, GtkLabel("Plot type:"))
    push!(type_box, type_dropdown)
    push!(main_box, type_box)

    role_list = GtkListBox()
    role_list.selection_mode = Gtk4.SelectionMode_NONE
    role_scroll = GtkScrolledWindow()
    role_scroll[] = role_list
    role_scroll.vexpand = true
    role_scroll.hexpand = true
    push!(main_box, role_scroll)

    btn_box = GtkBox(:h)
    btn_box.spacing = 8
    btn_box.halign = Gtk4.Align_END
    cancel_btn = GtkButton("Cancel")
    ok_btn = GtkButton("OK")
    ok_btn.sensitive = false
    push!(btn_box, cancel_btn)
    push!(btn_box, ok_btn)
    push!(main_box, btn_box)

    signal_connect(cancel_btn, "clicked") do _
        Gtk4.destroy(dialog)
    end

    role_dropdowns = Dict{Symbol, Tuple{GtkDropDown, Vector{String}}}()

    function update_ok_sensitivity!()
        if isempty(role_dropdowns)
            ok_btn.sensitive = false
            return
        end
        all_selected = all(
            begin
                dd, vids = pair
                !isempty(vids) && dd.selected != 0xffffffff && (dd.selected < length(vids))
            end
            for pair in values(role_dropdowns)
        )
        ok_btn.sensitive = all_selected
    end

    function rebuild_role_rows!()
        while (r = Gtk4.G_.get_row_at_index(role_list, 0)) !== nothing
            Gtk4.G_.remove(role_list, r)
        end
        empty!(role_dropdowns)

        sel_idx = type_dropdown.selected
        if sel_idx == 0xffffffff || sel_idx >= length(eligible_types)
            update_ok_sensitivity!()
            return
        end
        selected_type = eligible_types[sel_idx + 1]
        entry = REGISTRY[selected_type]

        all_vars = enumerate_variables(MainSource(Main))

        for shape_sym in entry.positional_shape
            row = GtkListBoxRow()
            hbox = GtkBox(:h)
            hbox.spacing = 8
            hbox.margin_top = 4
            hbox.margin_bottom = 4

            lbl = GtkLabel(string(shape_sym))
            lbl.xalign = 0.0
            lbl.hexpand = true
            push!(hbox, lbl)

            allowed_kinds = get(SHAPE_TO_VAR_KIND, shape_sym, Symbol[])
            eligible_vars = [v for v in all_vars if v.kind in allowed_kinds && v.kind != :unsupported]

            var_labels = ["$(v.label) [$(v.kind)]" for v in eligible_vars]
            var_ids = [v.id for v in eligible_vars]

            dd = GtkDropDown(var_labels)
            push!(hbox, dd)

            Gtk4.G_.set_child(row, hbox)
            push!(role_list, row)

            role_dropdowns[shape_sym] = (dd, var_ids)

            signal_connect(dd, "notify::selected") do _...
                update_ok_sensitivity!()
            end
        end
        update_ok_sensitivity!()
    end

    signal_connect(type_dropdown, "notify::selected") do _...
        rebuild_role_rows!()
    end

    rebuild_role_rows!()

    signal_connect(ok_btn, "clicked") do _
        sel_idx = type_dropdown.selected
        sel_idx == 0xffffffff && return
        selected_type = eligible_types[sel_idx + 1]

        assignments = Dict{Symbol, String}()
        for (shape_sym, (dd, vids)) in role_dropdowns
            if dd.selected != 0xffffffff && dd.selected < length(vids)
                assignments[shape_sym] = vids[dd.selected + 1]
            end
        end

        try
            _confirm_add_plot(session, ax_node, selected_type, assignments)
            Gtk4.destroy(dialog)
        catch e
            @error "Failed to add plot" exception=(e, catch_backtrace())
        end
    end

    show(dialog)
    return dialog
end
