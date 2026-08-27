abstract type DownsampleAlgorithm end
struct UniformStride    <: DownsampleAlgorithm; k::Int end
struct MinMaxDecimation <: DownsampleAlgorithm; n_buckets::Int end
struct LTTB             <: DownsampleAlgorithm; n_target::Int end

# 1) Uniform stride: every k-th point, first + last always included.
function downsample(algo::UniformStride, x::AbstractVector, y::AbstractVector)
    k = max(algo.k, 1)
    idx = collect(1:k:length(x))
    if isempty(idx) || last(idx) != length(x)
        push!(idx, length(x))
    end
    return (x[idx], y[idx])
end

# 2) Min/max decimation: per bucket keep the min-y and max-y points (x-order); first + last included.
function downsample(algo::MinMaxDecimation, x::AbstractVector, y::AbstractVector)
    n = length(x)
    nb = max(algo.n_buckets, 1)
    n <= 2 && return (x[1:n], y[1:n])
    idx = Int[1]
    bs = n / nb
    for b in 1:nb
        lo = floor(Int, (b - 1) * bs) + 1
        hi = min(floor(Int, b * bs), n)
        lo > hi && continue
        imin = lo + argmin(@view y[lo:hi]) - 1
        imax = lo + argmax(@view y[lo:hi]) - 1
        a, c = minmax(imin, imax)
        for i in (a, c)
            i != last(idx) && push!(idx, i)
        end
    end
    last(idx) != n && push!(idx, n)
    return (x[idx], y[idx])
end

# 3) LTTB (Steinarsson 2013): largest-triangle-three-buckets; exactly n_target points.
function downsample(algo::LTTB, x::AbstractVector, y::AbstractVector)
    n = length(x)
    thr = algo.n_target
    (thr >= n || thr < 3) && return (collect(float.(x)), collect(float.(y)))
    xout = Vector{Float64}(undef, thr); yout = Vector{Float64}(undef, thr)
    xout[1] = x[1]; yout[1] = y[1]
    bs = (n - 2) / (thr - 2)
    a = 1
    for i in 1:(thr - 2)
        cur_lo = floor(Int, (i - 1) * bs) + 2
        cur_hi = min(floor(Int, i * bs) + 1, n - 1)
        next_lo = floor(Int, i * bs) + 2
        next_hi = min(floor(Int, (i + 1) * bs) + 1, n - 1)
        if next_lo > next_hi
            avg_x = float(x[n]); avg_y = float(y[n])
        else
            avg_x = 0.0; avg_y = 0.0
            for j in next_lo:next_hi
                avg_x += x[j]; avg_y += y[j]
            end
            cnt = next_hi - next_lo + 1
            avg_x /= cnt; avg_y /= cnt
        end
        ax = float(x[a]); ay = float(y[a])
        max_area = -1.0; chosen = cur_lo
        for j in cur_lo:cur_hi
            area = abs((ax - avg_x) * (float(y[j]) - ay) - (ax - float(x[j])) * (avg_y - ay))
            if area > max_area
                max_area = area; chosen = j
            end
        end
        xout[i + 1] = x[chosen]; yout[i + 1] = y[chosen]
        a = chosen
    end
    xout[thr] = x[n]; yout[thr] = y[n]
    return (xout, yout)
end
