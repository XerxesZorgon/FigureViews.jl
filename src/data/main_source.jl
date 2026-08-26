# src/data/main_source.jl

struct MainSource <: DataSource
    source_module::Module
end
MainSource() = MainSource(Main)

function enumerate_variables(src::MainSource)::Vector{DataVar}
    vars = DataVar[]
    mod_name = nameof(src.source_module)
    for name in names(src.source_module; all=true)
        name === mod_name && continue          # skip the module's own name
        startswith(string(name), "#") && continue  # skip compiler-generated names
        val = try getproperty(src.source_module, name) catch; continue end
        kind, shape = _classify_main(val)
        push!(vars, DataVar(string(name), string(name), kind, shape))
    end
    return vars
end

function snapshot(src::MainSource, id::String)::AbstractArray
    val = getproperty(src.source_module, Symbol(id))
    return deepcopy(val)
end

function _classify_main(val)
    val isa AbstractVector{<:Real}   && return (:vector,  size(val))
    val isa AbstractMatrix{<:Real}   && return (:matrix,  size(val))
    val isa AbstractArray{<:Real, 3} && return (:array3,  size(val))
    return (:unsupported, ())
end
