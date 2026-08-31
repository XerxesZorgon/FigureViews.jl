# src/state/types.jl

struct LayoutSpec
    rows::Int
    cols::Int
end

struct CameraSpec
    azimuth::Float64
    elevation::Float64
    zoom::Float64
end

struct AnimBinding
    snapshot_id::String        # key into session.data_snapshots for the 3D array A[x,y,t]
    frame_count::Int           # size(A, 3)
    fps::Int                   # frames per second for export (default 30)
    current_frame::Int         # 1-based; swapped by time slider via observable replacement
end

struct DataRef
    role::Symbol                        # :x | :y | :z | :matrix | :volume
    snapshot_id::String                 # key into Session.data_snapshots (set at ingest)
    source::Symbol                      # :main | :csv | :hdf5
    label::String                       # display label (variable name / column / HDF5 path)
    # Persistence fields — M6 fills these in; M5 leaves them as nothing
    absolute_path::Union{Nothing, String}
    relative_path::Union{Nothing, String}
    column::Union{Nothing, String}
    dataset::Union{Nothing, String}
    variable::Union{Nothing, Symbol}
end

# Convenience constructor for M5 in-memory use (no persistence fields yet)
DataRef(role::Symbol, snapshot_id::String, source::Symbol, label::String) =
    DataRef(role, snapshot_id, source, label, nothing, nothing, nothing, nothing, nothing)

struct PlotMeta
    schema_version::VersionNumber
    status::Symbol                      # :valid | :unresolved | :needs_review
end

struct TypedValue
    type::Symbol                        # :Colorant, :Real, :Int, :Symbol, :String, :Bool, :Vector, :DataRef, etc.
    value::Any
end

Base.:(==)(a::TypedValue, b::TypedValue) = a.type == b.type && a.value == b.value
Base.hash(tv::TypedValue, h::UInt) = hash(tv.type, hash(tv.value, h))

function typed_value(v)
    if v isa TypedValue
        return v
    elseif v isa Colors.Colorant
        return TypedValue(:Colorant, "#" * Colors.hex(v))
    elseif v isa Symbol
        return TypedValue(:Symbol, string(v))
    elseif v isa Bool
        return TypedValue(:Bool, v)
    elseif v isa Integer
        return TypedValue(:Int, Int64(v))
    elseif v isa Real
        return TypedValue(:Real, Float64(v))
    elseif v isa String
        return TypedValue(:String, v)
    elseif v isa Tuple
        return TypedValue(:Tuple, collect(v))
    elseif v isa DataRef
        return TypedValue(:DataRef, v)
    elseif v isa AbstractVector
        return TypedValue(:Vector, collect(v))
    else
        return TypedValue(:Any, v)
    end
end

function decode_typed_value(tv::TypedValue)
    if tv.type == :Colorant
        if tv.value isa Colors.Colorant
            return Colors.RGB{Float64}(tv.value)
        else
            return Colors.RGB{Float64}(parse(Colors.RGB, tv.value))
        end
    elseif tv.type == :Symbol
        return tv.value isa Symbol ? tv.value : Symbol(tv.value)
    elseif tv.type == :Int
        return Int64(tv.value)
    elseif tv.type == :Real
        return Float64(tv.value)
    elseif tv.type == :String
        return string(tv.value)
    elseif tv.type == :Bool
        return Bool(tv.value)
    elseif tv.type == :Tuple
        return tv.value isa Tuple ? tv.value : Tuple(tv.value)
    elseif tv.type == :DataRef
        return tv.value
    else
        return tv.value
    end
end
decode_typed_value(x) = x
