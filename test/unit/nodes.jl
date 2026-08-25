using MakieViews: Session, Figure, Axis, Plot, UnknownNode, LayoutSpec, CameraSpec, AnimBinding, DataRef
using Observables: Observable, on

@testset "M2 nodes — Session construction" begin
    s = Session(v"1.0.0", Observable(Figure[]), Dict{String,Any}(), Observable{Union{Nothing,String}}(nothing))
    @test s.schema_version == v"1.0.0"
    @test isempty(s.figures[])
    @test s.selection[] === nothing
end

@testset "M2 nodes — Figure/Axis/Plot construction with observable fires" begin
    fig = Figure("fig-id", Observable("Untitled"), Observable(LayoutSpec(1,1)), Observable(Axis[]))
    fired = Ref(0)
    on(fig.title) do _; fired[] += 1; end
    fig.title[] = "New Title"
    @test fired[] == 1
    @test fig.title[] == "New Title"
end

@testset "M2 nodes — Plot.attrs per-attribute observation" begin
    p = Plot("plot-id", :line, Observable(DataRef[]), Dict{Symbol,Observable{Any}}(:linewidth => Observable{Any}(1.5)), Observable{Union{Nothing,AnimBinding}}(nothing))
    lw_fired = Ref(0)
    on(p.attrs[:linewidth]) do _; lw_fired[] += 1; end
    p.attrs[:linewidth][] = 2.5
    @test lw_fired[] == 1
    @test p.attrs[:linewidth][] == 2.5
end

@testset "M2 nodes — UnknownNode preserves payload" begin
    u = UnknownNode("future_recipe_xyz", Dict{String,Any}("foo" => "bar", "n" => 42))
    @test u.original_type == "future_recipe_xyz"
    @test u.payload["n"] == 42
end
