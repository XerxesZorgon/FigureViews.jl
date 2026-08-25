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
    # M7 fills this in. For M2, empty struct is fine — field is Observable{Union{Nothing, AnimBinding}} so nothing is the M2 value.
end

struct DataRef
    role::Symbol                                     # :x | :y | :z | :heat | ...
    source::Symbol                                   # :main | :csv | :hdf5
    absolute_path::Union{Nothing, String}            # per ADR-012 — nothing for :main source
    relative_path::Union{Nothing, String}            # per ADR-012
    column::Union{Nothing, String}                   # for csv
    dataset::Union{Nothing, String}                  # for hdf5
    variable::Union{Nothing, Symbol}                 # for main
end
