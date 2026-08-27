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

function build_property_pane(session::Session)::GtkWidget
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
                _populate_for_plot!(box, plot)
            else
                ax = _find_axis(session, id)
                if ax !== nothing
                    empty!(box)
                    _populate_for_axis!(box, ax)
                else
                    show_placeholder()
                end
            end
        end
    end
    
    return box
end

function _populate_for_plot!(box::GtkBox, plot::Plot)
    specs = PLOT_SCHEMAS[plot.type]
    for spec in specs
        if haskey(plot.attrs, spec.name)
            attr_obs = plot.attrs[spec.name]
            widget = _widget_for_spec(specs, spec, attr_obs)
            
            hbox = GtkBox(:h)
            push!(hbox, GtkLabel(spec.label))
            push!(hbox, widget)
            push!(box, hbox)
        end
    end

    # Time slider: shown only when plot has an animation binding
    if plot.animation_binding[] !== nothing
        _add_time_slider!(box, plot)
    end
end

function _populate_for_axis!(box::GtkBox, ax::Axis)
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
            widget = _widget_for_spec(specs, spec, field_obs[spec.name])
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
end

function _widget_for_spec(specs::Vector{AttrSpec}, spec::AttrSpec, attr_observable::Observable{Any})::GtkWidget
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
                attr_observable[] = res
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
                attr_observable[] = res
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
                    attr_observable[] = res
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
                attr_observable[] = res
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
                attr_observable[] = res
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
