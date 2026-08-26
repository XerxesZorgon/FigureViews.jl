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
