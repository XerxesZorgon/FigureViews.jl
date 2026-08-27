struct HostSpecs
    total_memory_bytes::Int              # Sys.total_memory()
    cpu_threads::Int                     # Sys.CPU_THREADS
    vram_bytes::Union{Nothing,Int}       # best-effort; nothing when undetectable (SDD FR-026)
    gpu_name::Union{Nothing,String}      # best-effort label; nothing when unknown
end

function _detect_gpu()
    try
        if Sys.which("nvidia-smi") !== nothing
            output = readchomp(`nvidia-smi --query-gpu=memory.total,name --format=csv,noheader,nounits`)
            lines = split(output, '\n')
            if !isempty(lines)
                first_line = lines[1]
                parts = split(first_line, ", ")
                if length(parts) == 2
                    mib = parse(Int, strip(parts[1]))
                    bytes = mib * 1024 * 1024
                    return (bytes, String(strip(parts[2])))
                end
            end
        elseif Sys.isapple() && Sys.which("system_profiler") !== nothing
            output = readchomp(`system_profiler SPDisplaysDataType`)
            for line in split(output, '\n')
                line = strip(line)
                if startswith(line, "VRAM (Total):")
                    parts = split(line, ":")
                    if length(parts) >= 2
                        val_str = strip(parts[2])
                        val_parts = split(val_str, " ")
                        if length(val_parts) >= 2
                            num = parse(Int, val_parts[1])
                            unit = val_parts[2]
                            if unit == "GB"
                                return (num * 1024 * 1024 * 1024, nothing)
                            elseif unit == "MB"
                                return (num * 1024 * 1024, nothing)
                            end
                        end
                    end
                end
            end
        end
    catch
        # never throws (SDD FR-026)
    end
    return (nothing, nothing)
end

function detect_host_specs()::HostSpecs
    vram, name = _detect_gpu()
    return HostSpecs(
        Int(Sys.total_memory()),
        Sys.CPU_THREADS,
        vram,
        name
    )
end
