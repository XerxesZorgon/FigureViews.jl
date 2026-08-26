# src/data/hdf5_source.jl
using HDF5

struct Hdf5Source <: DataSource
    path::String
end

function enumerate_variables(src::Hdf5Source)::Vector{DataVar}
    vars = DataVar[]
    HDF5.h5open(src.path, "r") do f
        _walk_hdf5!(vars, f, "")
    end
    return vars
end

function _walk_hdf5!(vars::Vector{DataVar}, group, prefix::String)
    for name in keys(group)
        item = group[name]
        full_path = prefix == "" ? name : "$prefix/$name"
        if item isa HDF5.Dataset
            kind, shape = _classify_hdf5(item)
            push!(vars, DataVar(full_path, full_path, kind, shape))
        elseif item isa HDF5.Group
            _walk_hdf5!(vars, item, full_path)
        end
    end
end

function _classify_hdf5(ds::HDF5.Dataset)
    T = eltype(ds)
    T <: Real || return (:unsupported, ())
    sh = size(ds)
    length(sh) == 1 && return (:vector, sh)
    length(sh) == 2 && return (:matrix, sh)
    length(sh) == 3 && return (:array3, sh)
    return (:unsupported, ())
end

function snapshot(src::Hdf5Source, id::String)::AbstractArray
    HDF5.h5open(src.path, "r") do f
        return read(f[id])
    end
end
