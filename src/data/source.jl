# src/data/source.jl

struct DataVar
    id::String       # stable key within its source (column name, HDF5 path, binding name)
    label::String    # display label
    kind::Symbol     # :vector | :matrix | :array3 | :unsupported
    shape::Tuple     # size(data); empty Tuple for :unsupported
end

abstract type DataSource end

"""
    enumerate_variables(source::DataSource)::Vector{DataVar}

Return plottable variables from this source. :unsupported entries are listed but
cannot be ingested.
"""
function enumerate_variables(src::DataSource)::Vector{DataVar}
    error("enumerate_variables not implemented for $(typeof(src))")
end

"""
    snapshot(source::DataSource, id::String)::AbstractArray

Return an independent copy of the variable identified by `id`.
Mutating the return value must not affect the source or any prior snapshot.
"""
function snapshot(src::DataSource, id::String)::AbstractArray
    error("snapshot not implemented for $(typeof(src))")
end
