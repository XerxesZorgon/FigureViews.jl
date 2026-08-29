# test/runtests_cairo.jl
#
# macOS CI entry point (ADR-023 fallback).
# Runs only the testsets that do not require a GLMakie/Gtk4 display context.
# Excluded: GUI shell, Renderer, Makie.Figure(), Gtk4, animation/export/session renderers.
# Ubuntu CI runs the full runtests.jl suite (72 testsets).
# This file covers the data/logic surface: 42 testsets / ~101 assertions.

using Test
using MakieViews
using MakieViews: new_session, add_figure!, add_axis!, add_plot!, ingest!, DataRef, MainSource,
                  PLOT_SCHEMAS, AXIS_SCHEMAS, CameraSpec, ValidationError

include("unit/nodes.jl")
include("unit/schema.jl")
include("unit/downsample.jl")
include("unit/session.jl")
include("unit/tree_pane.jl")
include("integration/data_sources.jl")
include("integration/persistence.jl")
include("integration/preferences.jl")
include("integration/preflight.jl")
