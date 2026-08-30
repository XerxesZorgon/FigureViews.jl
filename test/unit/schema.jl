using FigureViews: AttrSpec, PLOT_SCHEMAS

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

@testset "M3 schema — PLOT_SCHEMAS[:scatter] populated" begin
    @test haskey(PLOT_SCHEMAS, :scatter)
    specs = PLOT_SCHEMAS[:scatter]
    names = [s.name for s in specs]
    @test :color in names
    @test :markersize in names
    @test :marker in names
    @test specs[1].kind == :color
end

@testset "M3 schema — PLOT_SCHEMAS[:bar] populated" begin
    @test haskey(PLOT_SCHEMAS, :bar)
    specs = PLOT_SCHEMAS[:bar]
    names = [s.name for s in specs]
    @test :color in names
    @test :width in names
    @test :direction in names
    @test specs[1].kind == :color
end

@testset "M3 schema — PLOT_SCHEMAS[:heatmap] populated" begin
    @test haskey(PLOT_SCHEMAS, :heatmap)
    specs = PLOT_SCHEMAS[:heatmap]
    names = [s.name for s in specs]
    @test :colormap in names
    @test :colorrange in names
    @test :label in names
    @test specs[1].kind == :enum
end

@testset "M3 schema — PLOT_SCHEMAS[:contour] populated" begin
    @test haskey(PLOT_SCHEMAS, :contour)
    specs = PLOT_SCHEMAS[:contour]
    names = [s.name for s in specs]
    @test :color in names
    @test :levels in names
    @test :linewidth in names
    @test specs[1].kind == :color
end

@testset "M4 schema — PLOT_SCHEMAS[:surface] populated" begin
    @test haskey(PLOT_SCHEMAS, :surface)
    specs = PLOT_SCHEMAS[:surface]
    names = [s.name for s in specs]
    @test :colormap in names
    @test :shading in names
    @test :visible in names
    @test specs[1].kind == :enum
end

@testset "M4 schema — PLOT_SCHEMAS[:volume] populated" begin
    @test haskey(PLOT_SCHEMAS, :volume)
    specs = PLOT_SCHEMAS[:volume]
    names = [s.name for s in specs]
    @test :colormap in names
    @test :algorithm in names
    @test :colorrange in names
    @test :absorption in names
    @test :visible in names
    @test specs[1].kind == :enum
end

@testset "M4 schema — registry size" begin
    @test length(PLOT_SCHEMAS) == 7
end
