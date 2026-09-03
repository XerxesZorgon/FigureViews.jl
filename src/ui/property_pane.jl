using Gtk4
using Observables
using Colors

struct ValidationError
    message::String
end

function validate(specs::Vector{AttrSpec}, name::Symbol, value)::Union{Any, ValidationError}
    idx = findfirst(s -> s.name == name, specs)
    if idx === nothing
        return ValidationError("Unknown attribute $name")
    end
    spec = specs[idx]
    
    if spec.kind == :number
        lo, hi = spec.range
        if !(lo <= value <= hi)
            return ValidationError("Value $value out of range [$lo, $hi]")
        end
        return value
    elseif spec.kind == :enum
        if !(value in spec.range)
            return ValidationError("Value $value not in $(spec.range)")
        end
        return value
    elseif spec.kind == :bool || spec.kind == :string || spec.kind == :color
        return value
    end
    
    return value
end

function _find_plot(session::Session, id::String)::Union{Nothing, Plot}
    for fig in session.figures[]
        for ax in fig.axes[]
            for plot in ax.plots[]
                plot.id == id && return plot
            end
        end
    end
    return nothing
end

function _find_axis(session::Session, id::String)::Union{Nothing, Axis}
    for fig in session.figures[]
        for ax in fig.axes[]
            ax.id == id && return ax
        end
    end
    return nothing
end

function build_property_pane(session::Session; on_edit::Union{Nothing, Function} = nothing)::GtkWidget
    box = GtkBox(:v)
    
    function show_placeholder()
        empty!(box)
        push!(box, GtkLabel("Select a plot to edit properties"))
    end
    
    show_placeholder()
    
    on(session.selection) do id
        if id === nothing
            show_placeholder()
        else
            plot = _find_plot(session, id)
            if plot !== nothing
                empty!(box)
                _populate_for_plot!(box, plot, on_edit)
            else
                ax = _find_axis(session, id)
                if ax !== nothing
                    empty!(box)
                    _populate_for_axis!(box, ax, session, on_edit)
                else
                    show_placeholder()
                end
            end
        end
    end
    
    return box
end

function _populate_for_plot!(box::GtkBox, plot::Plot, on_edit::Union{Nothing, Function} = nothing)
    entry = get(REGISTRY, plot.func, nothing)
    if entry === nothing
        push!(box, GtkLabel("Unknown plot type: $(plot.func) — properties unavailable"))
        return
    end

    sorted_attrs = sort(collect(entry.attributes), by = x -> string(x[1]))

    for (name, spec) in sorted_attrs
        attr_obs = get(plot.attrs, name, nothing)
        is_observable = attr_obs !== nothing
        current_val = nothing

        if is_observable
            current_val = attr_obs[]
        else
            kw_val = get(plot.kwargs, name, nothing)
            if kw_val === nothing
                continue
            end
            current_val = kw_val isa TypedValue ? decode_typed_value(kw_val) : kw_val
        end

        widget = if spec.widget == :colorpicker
            if current_val isa Colorant
                btn = GtkColorButton()
                btn.rgba = Gtk4.GdkRGBA(Float64(Colors.red(current_val)), Float64(Colors.green(current_val)), Float64(Colors.blue(current_val)), 1.0)
                if is_observable
                    signal_connect(btn, "color-set") do b
                        s = Gtk4.rgba(b)
                        new_val = RGB(s.red, s.green, s.blue)
                        before = attr_obs[]
                        attr_obs[] = new_val
                        if on_edit !== nothing
                            on_edit(attr_obs, before, new_val, string(name))
                        end
                    end
                end
                btn
            else
                GtkLabel(string(current_val))
            end
        elseif spec.widget == :numeric
            if current_val isa Number && !(current_val isa Bool)
                btn = GtkSpinButton(0.0, 1000.0, 1.0)
                btn.value = Float64(current_val)
                if is_observable
                    signal_connect(btn, "value-changed") do b
                        new_val = (spec.type == :Int || current_val isa Integer) ? round(Int, b.value) : b.value
                        before = attr_obs[]
                        attr_obs[] = new_val
                        if on_edit !== nothing
                            on_edit(attr_obs, before, new_val, string(name))
                        end
                    end
                end
                btn
            else
                GtkLabel(string(current_val))
            end
        elseif spec.widget == :dropdown
            val_str = current_val !== nothing ? string(current_val) : string(spec.default)
            GtkDropDown([val_str])
        elseif spec.widget == :text
            en = GtkEntry()
            en.text = current_val !== nothing ? string(current_val) : ""
            if is_observable
                signal_connect(en, "changed") do e
                    new_val = e.text
                    before = attr_obs[]
                    attr_obs[] = new_val
                    if on_edit !== nothing
                        on_edit(attr_obs, before, new_val, string(name))
                    end
                end
            end
            en
        elseif spec.widget == :checkbox
            if current_val isa Bool
                sw = GtkSwitch()
                sw.active = current_val
                if is_observable
                    signal_connect(sw, "notify::active") do s, _
                        new_val = s.active
                        before = attr_obs[]
                        attr_obs[] = new_val
                        if on_edit !== nothing
                            on_edit(attr_obs, before, new_val, string(name))
                        end
                    end
                end
                sw
            else
                GtkLabel(string(current_val))
            end
        else
            GtkLabel(string(current_val))
        end

        hbox = GtkBox(:h)
        lbl = spec.label != "" ? spec.label : string(name)
        push!(hbox, GtkLabel(lbl))
        push!(hbox, widget)
        push!(box, hbox)
    end

    # Time slider: shown only when plot has an animation binding
    if plot.animation_binding[] !== nothing
        _add_time_slider!(box, plot)
    end
end

function _populate_for_axis!(box::GtkBox, ax::Axis, session::Union{Nothing, Session} = nothing, on_edit::Union{Nothing, Function} = nothing)
    if haskey(AXIS_SCHEMAS, ax.kind)
        specs = AXIS_SCHEMAS[ax.kind]
        if ax.camera[] === nothing
            ax.camera[] = CameraSpec(1.275, 0.785, 1.0)
        end
        cam = ax.camera[]
        field_obs = Dict{Symbol, Observable{Any}}(
            :azimuth   => Observable{Any}(cam.azimuth),
            :elevation => Observable{Any}(cam.elevation),
            :zoom      => Observable{Any}(cam.zoom),
        )
        for (fname, obs) in field_obs
            on(obs) do _
                ax.camera[] = CameraSpec(field_obs[:azimuth][], field_obs[:elevation][], field_obs[:zoom][])
            end
        end
        for spec in specs
            widget = _widget_for_spec(specs, spec, field_obs[spec.name]; on_edit = on_edit)
            hbox = GtkBox(:h)
            push!(hbox, GtkLabel(spec.label))
            push!(hbox, widget)
            push!(box, hbox)
        end
    end

    # Recenter button: reset axis limits to fit all data (D5)
    recenter_btn = GtkButton("Recenter")
    signal_connect(recenter_btn, "clicked") do _b
        renderer = _current_renderer[]
        renderer === nothing && return
        handle = get(renderer.axis_handles, ax.id, nothing)
        handle === nothing && return
        Makie.autolimits!(handle)
    end
    push!(box, recenter_btn)

    # "Add plot…" button: opens a popover offering valid plot types for this axis kind
    add_plot_btn = GtkButton("Add plot…")
    popover_ref = Ref{Union{Nothing, GtkPopoverMenu}}(nothing)
    signal_connect(add_plot_btn, "clicked") do _b
        if popover_ref[] !== nothing
            try
                Gtk4.G_.unparent(popover_ref[])
            catch
            end
            popover_ref[] = nothing
        end

        eligible = [type for (type, entry) in REGISTRY
                    if entry.status == :valid &&
                       get(AXIS_KIND_FOR_TYPE, type, :axis2d) in (ax.kind, :any)]
        sort!(eligible, by = string)

        menu = Gtk4.GLib.GMenu()
        action_group = Gtk4.GLib.GSimpleActionGroup()
        action_map = Gtk4.GLib.GActionMap(action_group)

        for (i, ptype) in enumerate(eligible)
            act_name = "add_$(i)"
            push!(menu, Gtk4.GLib.GMenuItem(string(ptype), "axis.$(act_name)"))
            Gtk4.GLib.add_action(action_map, act_name, (_a, _p) -> begin
                if session !== nothing
                    _add_plot_to_axis!(session, ax, ptype)
                else
                    plot = add_plot!(ax, ptype, DataRef[])
                    apply_structural!(FigureViews._current_renderer[], AddPlotOp(ax, plot))
                end
            end)
        end

        popover = GtkPopoverMenu(menu)
        popover_ref[] = popover
        Gtk4.G_.insert_action_group(popover, "axis", Gtk4.GLib.GActionGroup(action_group))
        Gtk4.G_.set_parent(popover, add_plot_btn)
        Gtk4.popup(popover)
    end
    push!(box, add_plot_btn)
end

function _add_plot_to_axis!(session::Session, ax_node::Axis, plot_type::Symbol)
    plot = add_plot!(ax_node, plot_type, DataRef[])
    apply_structural!(FigureViews._current_renderer[], AddPlotOp(ax_node, plot))
    return plot
end

function _widget_for_spec(specs::Vector{AttrSpec}, spec::AttrSpec, attr_observable::Observable{Any}; on_edit::Union{Nothing, Function} = nothing)::GtkWidget
    if spec.kind == :color
        rgb = attr_observable[]
        btn = GtkColorButton()
        btn.rgba = Gtk4.GdkRGBA(rgb.r, rgb.g, rgb.b, 1.0)
        signal_connect(btn, "color-set") do b
            # Gtk4.rgba(btn) returns a _GdkRGBA plain struct with .red/.green/.blue Float32 fields.
            # b.rgba returns an opaque GdkRGBA handle whose .r/.g/.b fields do not exist.
            s = Gtk4.rgba(b)
            new_val = RGB(s.red, s.green, s.blue)
            res = validate(specs, spec.name, new_val)
            if res isa ValidationError
                println(res.message)
                old = attr_observable[]
                b.rgba = Gtk4.GdkRGBA(old.r, old.g, old.b, 1.0)
            else
                before = attr_observable[]
                attr_observable[] = res
                if on_edit !== nothing
                    on_edit(attr_observable, before, res, string(spec.name))
                end
            end
        end
        return btn
    elseif spec.kind == :number
        lo, hi = spec.range
        step = (hi - lo) / 100
        btn = GtkSpinButton(lo, hi, step)
        btn.value = attr_observable[]
        signal_connect(btn, "value-changed") do b
            res = validate(specs, spec.name, b.value)
            if res isa ValidationError
                println(res.message)
                b.value = attr_observable[]
            else
                # TODO: throttle at 60Hz per DESIGN §5
                before = attr_observable[]
                attr_observable[] = res
                if on_edit !== nothing
                    on_edit(attr_observable, before, res, string(spec.name))
                end
            end
        end
        return btn
    elseif spec.kind == :enum
        strings = string.(spec.range)
        dd = GtkDropDown(strings)
        idx = findfirst(==(attr_observable[]), spec.range)
        if idx !== nothing
            dd.selected = idx - 1
        end
        signal_connect(dd, "notify::selected") do d, _
            idx = d.selected + 1
            if idx >= 1 && idx <= length(spec.range)
                new_val = spec.range[idx]
                res = validate(specs, spec.name, new_val)
                if res isa ValidationError
                    println(res.message)
                    old_idx = findfirst(==(attr_observable[]), spec.range)
                    if old_idx !== nothing
                        d.selected = old_idx - 1
                    end
                else
                    before = attr_observable[]
                    attr_observable[] = res
                    if on_edit !== nothing
                        on_edit(attr_observable, before, res, string(spec.name))
                    end
                end
            end
        end
        return dd
    elseif spec.kind == :bool
        sw = GtkSwitch()
        sw.active = attr_observable[]
        signal_connect(sw, "notify::active") do s, _
            res = validate(specs, spec.name, s.active)
            if res isa ValidationError
                println(res.message)
                s.active = attr_observable[]
            else
                before = attr_observable[]
                attr_observable[] = res
                if on_edit !== nothing
                    on_edit(attr_observable, before, res, string(spec.name))
                end
            end
        end
        return sw
    elseif spec.kind == :string
        en = GtkEntry()
        en.text = attr_observable[]
        signal_connect(en, "changed") do e
            res = validate(specs, spec.name, e.text)
            if res isa ValidationError
                println(res.message)
                e.text = attr_observable[]
            else
                before = attr_observable[]
                attr_observable[] = res
                if on_edit !== nothing
                    on_edit(attr_observable, before, res, string(spec.name))
                end
            end
        end
        return en
    else
        return GtkLabel("Unsupported: $(spec.kind)")
    end
end

function _add_time_slider!(box::GtkBox, plot::Plot)
    binding = plot.animation_binding[]
    binding === nothing && return

    sep = GtkSeparator(:h)
    push!(box, sep)
    push!(box, GtkLabel("Frame (1–$(binding.frame_count))"))

    # GtkScale(orientation, min, max, step)
    slider = GtkScale(:h, 1.0, Float64(binding.frame_count), 1.0)
    slider.value = Float64(binding.current_frame)

    signal_connect(slider, "value-changed") do s
        t   = round(Int, s.value)
        old = plot.animation_binding[]
        if old !== nothing && t != old.current_frame
            plot.animation_binding[] = AnimBinding(
                old.snapshot_id, old.frame_count, old.fps, t)
        end
    end
    push!(box, slider)
end
