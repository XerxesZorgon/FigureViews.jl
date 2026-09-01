# src/state/function_registry.jl
# Bounded Symbol→Function registry for rehydrating function-valued Makie attributes.
# Grows by explicit extension only — never by auto-discovery.
const FUNCTION_REGISTRY = Dict{Symbol, Any}(
    :identity => identity,
    :sqrt     => sqrt,
    :log      => log,
    :log10    => log10,
    :exp      => exp,
    :abs      => abs,
)
