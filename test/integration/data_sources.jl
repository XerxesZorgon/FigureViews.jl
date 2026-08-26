using Test, MakieViews, CSV, DataFrames, HDF5

@testset "M5 MainSource — enumerate and snapshot" begin
    m = Module(:TestMain)
    Core.eval(m, :(x = collect(1.0:10.0)))
    Core.eval(m, :(mat = [Float64(i*j) for i in 1:4, j in 1:4]))
    Core.eval(m, :(s = "not plottable"))

    src  = MakieViews.MainSource(m)
    vars = MakieViews.enumerate_variables(src)
    ids  = [v.id for v in vars]

    @test "x"   in ids
    @test "mat" in ids
    x_var   = only(v for v in vars if v.id == "x")
    mat_var = only(v for v in vars if v.id == "mat")
    @test x_var.kind   == :vector
    @test mat_var.kind == :matrix
    s_idx = findfirst(v -> v.id == "s", vars)
    if s_idx !== nothing
        @test vars[s_idx].kind == :unsupported
    end

    arr = MakieViews.snapshot(src, "x")
    @test arr ≈ collect(1.0:10.0)
    arr[1] = 999.0
    @test getproperty(m, :x)[1] ≈ 1.0   # snapshot is independent
end

@testset "M5 CsvSource — enumerate and snapshot" begin
    csv_path = joinpath(@__DIR__, "..", "data", "csv", "clean_2col.csv")
    src  = MakieViews.CsvSource(csv_path)
    vars = MakieViews.enumerate_variables(src)
    ids  = [v.id for v in vars]
    @test "x" in ids
    @test "y" in ids
    x_var = only(v for v in vars if v.id == "x")
    @test x_var.kind == :vector

    arr = MakieViews.snapshot(src, "x")
    @test arr ≈ [1.0, 2.0, 3.0, 4.0, 5.0]
    arr[1] = 999.0
    @test MakieViews.snapshot(src, "x")[1] ≈ 1.0   # snapshot is independent
end

@testset "M5 Hdf5Source — enumerate and snapshot" begin
    h5_path = joinpath(@__DIR__, "..", "data", "hdf5", "flat.h5")
    src  = MakieViews.Hdf5Source(h5_path)
    vars = MakieViews.enumerate_variables(src)
    ids  = [v.id for v in vars]
    @test "x"   in ids
    @test "mat" in ids
    x_var   = only(v for v in vars if v.id == "x")
    mat_var = only(v for v in vars if v.id == "mat")
    @test x_var.kind   == :vector
    @test mat_var.kind == :matrix

    arr = MakieViews.snapshot(src, "x")
    @test arr ≈ collect(1.0:5.0)
end
