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
            if plot === nothing
                show_placeholder()
            else
                empty!(box)
                _populate_for_plot!(box, plot)
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
end

function _widget_for_spec(specs::Vector{AttrSpec}, spec::AttrSpec, attr_observable::Observable{Any})::GtkWidget
    if spec.kind == :color
        rgb = attr_observable[]
        btn = GtkColorButton()
        btn.rgba = Gtk4.GdkRGBA(rgb.r, rgb.g, rgb.b, 1.0)
        signal_connect(btn, "color-set") do b
            rgba = b.rgba
            new_val = RGB(rgba.r, rgba.g, rgba.b)
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
