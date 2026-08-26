# src/data/csv_source.jl
using CSV, DataFrames

struct CsvSource <: DataSource
    path::String
    _df::DataFrame
end

function CsvSource(path::String)
    df = CSV.File(path, missingstring="") |> DataFrame
    return CsvSource(path, df)
end

function enumerate_variables(src::CsvSource)::Vector{DataVar}
    vars = DataVar[]
    for name in names(src._df)
        col = src._df[!, name]
        kind = eltype(col) <: Real ? :vector : :unsupported
        push!(vars, DataVar(string(name), string(name), kind, (length(col),)))
    end
    return vars
end

function snapshot(src::CsvSource, id::String)::AbstractArray
    col = src._df[!, id]
    return copy(convert(Vector{Float64}, col))   # copy ensures independence from the DataFrame
end
