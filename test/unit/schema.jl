using MakieViews: AttrSpec, PLOT_SCHEMAS

@testset "M2 schema — PLOT_SCHEMAS[:line] populated" begin
    @test haskey(PLOT_SCHEMAS, :line)
    specs = PLOT_SCHEMAS[:line]
    @test length(specs) >= 5
    names = [s.name for s in specs]
    @test :color in names
    @test :linewidth in names
    @test :linestyle in names
    @test :label in names
    @test :visible in names
end

@testset "M2 schema — AttrSpec fields correct types" begin
    lw_spec = only(s for s in PLOT_SCHEMAS[:line] if s.name == :linewidth)
    @test lw_spec.kind == :number
    @test lw_spec.default == 1.5
    @test lw_spec.range == (0.1, 20.0)
    style_spec = only(s for s in PLOT_SCHEMAS[:line] if s.name == :linestyle)
    @test style_spec.kind == :enum
    @test :solid in style_spec.range
    @test :dashdot in style_spec.range
end

@testset "M2 schema — no plot-type branches in iteration" begin
    # Verify PLOT_SCHEMAS is data, not code — iterating produces the schema without any
    # if plot.type == :line ... elseif ... branches. Test by iterating :line's schema:
    for spec in PLOT_SCHEMAS[:line]
        @test spec isa AttrSpec
        @test spec.name isa Symbol
        @test spec.kind in (:color, :number, :int, :enum, :bool, :string, :vec2, :vec3)
    end
end
