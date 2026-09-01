# tools/gen_registry.jl
#
# Generates src/state/registry_generated.jl by introspecting Makie plot types.
# Run via: julia --project=. tools/gen_registry.jl

using Makie
using Colors
using Printf

# Include existing reference registry definitions to enable self-check
include(joinpath(@__DIR__, "..", "src", "state", "types.jl"))

# Define AttrSpec and PlotTypeEntry structs if not defined
if !@isdefined(AttrSpec)
    struct AttrSpec
        type::Symbol
        default::Any
        widget::Symbol
        name::Symbol
        range::Any
        label::String
        tooltip::String

        function AttrSpec(type::Symbol, default::Any, widget::Symbol)
            new(type, default, widget, :_unnamed, nothing, "", "")
        end
    end
end

if !@isdefined(PlotTypeEntry)
    struct PlotTypeEntry
        func::Symbol
        conversion_trait::Symbol
        positional_shape::Vector{Symbol}
        attributes::Dict{Symbol, AttrSpec}
        api::NamedTuple
        status::Symbol
    end
end

const REFERENCE_7 = Dict{Symbol, PlotTypeEntry}(
    :line => PlotTypeEntry(
        :line,
        :PointBased,
        [:x_vector, :y_vector],
        Dict{Symbol, AttrSpec}(
            :color     => AttrSpec(:Colorant, Colors.RGB(0.1, 0.4, 0.8), :colorpicker),
            :linewidth => AttrSpec(:Real, 1.5, :numeric),
            :linestyle => AttrSpec(:Symbol, :solid, :dropdown),
            :label     => AttrSpec(:String, "", :text),
            :visible   => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :scatter => PlotTypeEntry(
        :scatter,
        :PointBased,
        [:x_vector, :y_vector],
        Dict{Symbol, AttrSpec}(
            :color      => AttrSpec(:Colorant, Colors.RGB(0.2, 0.2, 0.2), :colorpicker),
            :markersize => AttrSpec(:Real, 9.0, :numeric),
            :marker     => AttrSpec(:Symbol, :circle, :dropdown),
            :label      => AttrSpec(:String, "", :text),
            :visible    => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :bar => PlotTypeEntry(
        :bar,
        :PointBased,
        [:x_vector, :y_vector],
        Dict{Symbol, AttrSpec}(
            :color     => AttrSpec(:Colorant, Colors.RGB(0.2, 0.6, 0.8), :colorpicker),
            :direction => AttrSpec(:Symbol, :vertical, :dropdown),
            :label     => AttrSpec(:String, "", :text),
            :visible   => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :heatmap => PlotTypeEntry(
        :heatmap,
        :CellGrid,
        [:matrix],
        Dict{Symbol, AttrSpec}(
            :colormap   => AttrSpec(:Symbol, :viridis, :dropdown),
            :colorrange => AttrSpec(:Vector, (0.0, 1.0), :numeric),
            :label      => AttrSpec(:String, "", :text),
            :visible    => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :contour => PlotTypeEntry(
        :contour,
        :VertexGrid,
        [:x_vector, :y_vector, :matrix],
        Dict{Symbol, AttrSpec}(
            :color     => AttrSpec(:Colorant, Colors.RGB(0.3, 0.3, 0.7), :colorpicker),
            :levels    => AttrSpec(:Int, 10, :numeric),
            :linewidth => AttrSpec(:Real, 1.0, :numeric),
            :label     => AttrSpec(:String, "", :text),
            :visible   => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :surface => PlotTypeEntry(
        :surface,
        :VertexGrid,
        [:x_vector, :y_vector, :matrix],
        Dict{Symbol, AttrSpec}(
            :colormap => AttrSpec(:Symbol, :viridis, :dropdown),
            :shading  => AttrSpec(:Symbol, :smooth, :dropdown),
            :label    => AttrSpec(:String, "", :text),
            :visible  => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
    :volume => PlotTypeEntry(
        :volume,
        :VolumeLike,
        [:matrix],
        Dict{Symbol, AttrSpec}(
            :colormap   => AttrSpec(:Symbol, :viridis, :dropdown),
            :algorithm  => AttrSpec(:Symbol, :mip, :dropdown),
            :colorrange => AttrSpec(:Vector, (0.0, 1.0), :numeric),
            :absorption => AttrSpec(:Real, 1.0, :numeric),
            :visible    => AttrSpec(:Bool, true, :checkbox),
        ),
        (makie_major = 0, makie_minor = 24),
        :valid
    ),
)

function trait_to_sym(trait)::Symbol
    if trait isa Makie.PointBased
        return :PointBased
    elseif trait isa Makie.VertexGrid
        return :VertexGrid
    elseif trait isa Makie.CellGrid
        return :CellGrid
    elseif trait isa Makie.VolumeLike
        return :VolumeLike
    elseif trait isa Makie.ImageLike
        return :ImageLike
    elseif trait isa Makie.SampleBased
        return :SampleBased
    elseif trait isa Makie.GridBased
        return :CellGrid
    else
        return :None
    end
end

function derive_positional_shape(sym::Symbol, trait_sym::Symbol)::Vector{Symbol}
    # 7 reference shapes:
    if sym in (:line, :scatter, :bar)
        return [:x_vector, :y_vector]
    elseif sym == :heatmap
        return [:matrix]
    elseif sym in (:contour, :surface)
        return [:x_vector, :y_vector, :matrix]
    elseif sym == :volume
        return [:matrix]
    end

    # Standard mappings derived from convert_arguments
    if sym in (:lines, :scatterlines, :linesegments, :barplot, :stairs, :stem, :hexbin, :boxplot)
        return [:x_vector, :y_vector]
    elseif sym in (:contourf,)
        return [:x_vector, :y_vector, :matrix]
    elseif sym in (:image, :spy)
        return [:matrix]
    elseif sym in (:hist, :density, :pie)
        return [:values]
    elseif sym in (:band,)
        return [:x_vector, :y_lower, :y_upper]
    elseif sym in (:errorbars,)
        return [:x_vector, :y_vector, :low, :high]
    elseif sym in (:rangebars,)
        return [:x_vector, :low, :high]
    elseif sym in (:meshscatter,)
        return [:x_vector, :y_vector, :z_vector]
    elseif sym in (:mesh,)
        return [:vertices, :faces]
    elseif sym in (:arrows,)
        return [:x_vector, :y_vector, :u_vector, :v_vector]
    elseif sym in (:streamplot,)
        return [:field_func, :x_range, :y_range]
    elseif sym in (:poly,)
        return [:points]
    elseif sym in (:text,)
        return [:positions, :strings]
    elseif trait_sym == :PointBased
        return [:x_vector, :y_vector]
    elseif trait_sym in (:CellGrid, :ImageLike, :VolumeLike)
        return [:matrix]
    elseif trait_sym == :VertexGrid
        return [:x_vector, :y_vector, :matrix]
    else
        return [:values]
    end
end

function classify_default(val)
    if val isa Colorant
        return (:Colorant, :colorpicker, val)
    elseif val isa Bool
        return (:Bool, :dropdown, val)
    elseif val isa Integer
        return (:Int, :numeric, Int64(val))
    elseif val isa Number
        return (:Real, :numeric, Float64(val))
    elseif val isa Symbol
        return (:Symbol, :dropdown, val)
    elseif val isa AbstractString
        return (:String, :text, string(val))
    elseif val isa Makie.Automatic
        return (:Automatic, :auto, :automatic)
    elseif val isa Union{AbstractVector, Tuple}
        items = collect(val)
        if all(x -> x isa Union{Number, Symbol, String, Bool, Colorant}, items)
            return (:Vector, :generic, items)
        else
            return (:Vector, :generic, Any[])
        end
    else
        return (:Other, :generic, nothing)
    end
end

function repr_val(v)
    if v isa Colorant
        r = Float64(Colors.red(v))
        g = Float64(Colors.green(v))
        b = Float64(Colors.blue(v))
        if v isa Colors.AlphaColor || v isa Colors.ColorAlpha
            a = Float64(Colors.alpha(v))
            return "Colors.RGBA($(r), $(g), $(b), $(a))"
        else
            return "Colors.RGB($(r), $(g), $(b))"
        end
    elseif v isa Symbol
        return repr(v)
    elseif v isa Bool
        return string(v)
    elseif v isa Number
        return string(v)
    elseif v isa AbstractString
        return repr(v)
    elseif v isa AbstractVector
        items = collect(v)
        if isempty(items)
            return "Any[]"
        elseif all(x -> x isa Union{Number, Symbol, String, Bool}, items)
            return repr(items)
        else
            return "Any[]"
        end
    elseif v === :automatic
        return ":automatic"
    elseif v === nothing
        return "nothing"
    else
        return "nothing"
    end
end

const PLOT_SPECS = [
    # 7 Reference Types
    (:line, :lines),
    (:scatter, :scatter),
    (:bar, :barplot),
    (:heatmap, :heatmap),
    (:contour, :contour),
    (:surface, :surface),
    (:volume, :volume),

    # Broader plot types
    (:lines, :lines),
    (:scatterlines, :scatterlines),
    (:linesegments, :linesegments),
    (:barplot, :barplot),
    (:hist, :hist),
    (:density, :density),
    (:boxplot, :boxplot),
    (:image, :image),
    (:contourf, :contourf),
    (:mesh, :mesh),
    (:meshscatter, :meshscatter),
    (:arrows, :arrows),
    (:streamplot, :streamplot),
    (:poly, :poly),
    (:band, :band),
    (:errorbars, :errorbars),
    (:rangebars, :rangebars),
    (:stairs, :stairs),
    (:stem, :stem),
    (:pie, :pie),
    (:hexbin, :hexbin),
    (:spy, :spy),
    (:text, :text),
]

function generate_registry()
    generated_entries = Dict{Symbol, PlotTypeEntry}()

    for (name, makie_sym) in PLOT_SPECS
        if !isdefined(Makie, makie_sym)
            @warn "Makie.$makie_sym not defined; skipping"
            continue
        end

        f = getfield(Makie, makie_sym)
        P = Plot{f}

        trait = try Makie.conversion_trait(P) catch; nothing end
        trait_sym = trait_to_sym(trait)
        pos_shape = derive_positional_shape(name, trait_sym)

        th = nothing
        try
            th = Makie.default_theme(nothing, P)
        catch
        end

        status = :valid
        attrs = Dict{Symbol, AttrSpec}()

        if th === nothing || isempty(th)
            status = :needs_manual_review
        else
            for (k, v) in th
                val = v isa Observable ? v[] : v
                type_sym, widget_sym, default_val = classify_default(val)
                attrs[k] = AttrSpec(type_sym, default_val, widget_sym)
            end

            # Ensure all reference attributes are present for the 7 reference types
            if haskey(REFERENCE_7, name)
                for (ref_k, ref_spec) in REFERENCE_7[name].attributes
                    if !haskey(attrs, ref_k)
                        attrs[ref_k] = ref_spec
                    end
                end
            end
        end

        entry = PlotTypeEntry(
            name,
            trait_sym,
            pos_shape,
            attrs,
            (makie_major = 0, makie_minor = 24),
            status
        )
        generated_entries[name] = entry
    end

    # Step 3: Self-check against the 7 reference types
    println("--- Step 3: Self-Check against Reference 7 Types ---")
    for (ref_name, ref_entry) in REFERENCE_7
        if !haskey(generated_entries, ref_name)
            @warn "Reference type :$ref_name not found in generated registry"
            continue
        end
        gen_entry = generated_entries[ref_name]
        if gen_entry.func != ref_entry.func
            @warn "[:$ref_name] func mismatch: generated=$(gen_entry.func), reference=$(ref_entry.func)"
        end
        if gen_entry.conversion_trait != ref_entry.conversion_trait
            @warn "[:$ref_name] conversion_trait mismatch: generated=$(gen_entry.conversion_trait), reference=$(ref_entry.conversion_trait)"
        end
        if gen_entry.positional_shape != ref_entry.positional_shape
            @warn "[:$ref_name] positional_shape mismatch: generated=$(gen_entry.positional_shape), reference=$(ref_entry.positional_shape)"
        end
        for (attr_k, ref_attr) in ref_entry.attributes
            if !haskey(gen_entry.attributes, attr_k)
                @warn "[:$ref_name] reference attribute :$attr_k not found in generated attributes"
            end
        end
    end
    println("Self-check completed.")

    # Step 2: Emit src/state/registry_generated.jl
    out_path = joinpath(@__DIR__, "..", "src", "state", "registry_generated.jl")
    open(out_path, "w") do io
        println(io, "# src/state/registry_generated.jl")
        println(io, "# AUTO-GENERATED by tools/gen_registry.jl — DO NOT EDIT MANUALLY")
        println(io, "# Regenerate via: julia --project=. tools/gen_registry.jl\n")
        println(io, "const REGISTRY_GENERATED = Dict{Symbol, PlotTypeEntry}(")

        for (name, entry) in sort(collect(generated_entries), by = x -> string(x[1]))
            println(io, "    $(repr(name)) => PlotTypeEntry(")
            println(io, "        $(repr(entry.func)),")
            println(io, "        $(repr(entry.conversion_trait)),")
            println(io, "        $(repr(entry.positional_shape)),")
            println(io, "        Dict{Symbol, AttrSpec}(")
            for (ak, aspec) in sort(collect(entry.attributes), by = x -> string(x[1]))
                val_code = repr_val(aspec.default)
                println(io, "            $(repr(ak)) => AttrSpec($(repr(aspec.type)), $val_code, $(repr(aspec.widget))),")
            end
            println(io, "        ),")
            println(io, "        (makie_major = 0, makie_minor = 24),")
            println(io, "        $(repr(entry.status))")
            println(io, "    ),")
        end

        println(io, ")")
    end
    println("Wrote $(length(generated_entries)) entries to $out_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    generate_registry()
end
