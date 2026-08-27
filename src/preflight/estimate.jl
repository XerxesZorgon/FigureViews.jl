# Provisional reference GPU for the v0.1 fallback regime (ADR-015 shape; the measured
# reference is deferred to the M11 pass — option C). 8 GiB ≈ mid-range 2020-class dGPU.
const REFERENCE_VRAM_BYTES = 8 * 1024^3
const _3D_PLOT_TYPES = (:surface, :volume)

function estimate_footprint(a::AbstractArray)::Int
    return length(a) * sizeof(eltype(a))
end

function _user_scale(host::HostSpecs)::Float64
    if host.vram_bytes === nothing
        return 0.5
    else
        return clamp(host.vram_bytes / REFERENCE_VRAM_BYTES, 0.1, 10.0)
    end
end

function estimate_fps(plot_type::Symbol, n_points::Integer, host::HostSpecs)::Float64
    base = plot_type in _3D_PLOT_TYPES ? 30.0 : 60.0
    raw = base / sqrt(max(n_points, 1) / 1e6)
    return raw * _user_scale(host)
end
