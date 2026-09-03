@testset "M17 tri-pane layout — container hierarchy" begin
    w = FigureViews._open_shell(new_session())
    sleep(0.2)  # let GTK settle

    # root_box: GtkBox with 3 children (menubar + toolbar + main_paned)
    root = w[]
    @test root isa GtkBox
    root_children = collect(root)
    @test length(root_children) == 3

    # toolbar: horizontal GtkBox with CSS class "toolbar"
    toolbar = root_children[2]
    @test toolbar isa GtkBox
    @test Gtk4.G_.has_css_class(toolbar, "toolbar")
    toolbar_children = collect(toolbar)
    @test length(toolbar_children) == 9

    # Document group buttons (sensitive)
    btn_new = toolbar_children[1]
    btn_open = toolbar_children[2]
    btn_save = toolbar_children[3]
    @test btn_new isa GtkButton && btn_new.sensitive == true
    @test btn_open isa GtkButton && btn_open.sensitive == true
    @test btn_save isa GtkButton && btn_save.sensitive == true

    # Separator 1
    @test toolbar_children[4] isa GtkSeparator

    # Structure group buttons
    btn_add_axis = toolbar_children[5]
    btn_add_plot = toolbar_children[6]
    @test btn_add_axis isa GtkButton && btn_add_axis.sensitive == false
    @test btn_add_plot isa GtkButton && btn_add_plot.sensitive == true

    # Separator 2
    @test toolbar_children[7] isa GtkSeparator

    # History group buttons
    btn_undo = toolbar_children[8]
    btn_redo = toolbar_children[9]
    @test btn_undo isa GtkButton && btn_undo.sensitive == false
    @test btn_redo isa GtkButton && btn_redo.sensitive == false

    # main_paned: horizontal GtkPaned
    main_paned = root_children[3]
    @test main_paned isa GtkPaned

    # child-1 of main_paned: left_column (vertical GtkPaned)
    left_column = main_paned[1]
    @test left_column isa GtkPaned

    # left_column child-1: data_notebook (GtkNotebook)
    @test left_column[1] isa GtkNotebook

    # left_column child-2: derived_drawer_placeholder (GtkBox)
    @test left_column[2] isa GtkBox

    # child-2 of main_paned: center_paned (horizontal GtkPaned)
    center_paned = main_paned[2]
    @test center_paned isa GtkPaned

    # center_paned child-1: viewport_widget (Makie/GL widget)
    viewport = center_paned[1]
    @test occursin(r"Makie|GL", string(typeof(viewport)))

    # center_paned child-2: right_column (vertical GtkPaned)
    right_column = center_paned[2]
    @test right_column isa GtkPaned

    # right_column child-1: right_top_paned (vertical GtkPaned)
    right_top_paned = right_column[1]
    @test right_top_paned isa GtkPaned

    # right_column child-2: recipe_drawer_placeholder (GtkBox)
    @test right_column[2] isa GtkBox

    # right_top_paned children: tree_pane (GtkScrolledWindow) and property_pane (GtkBox)
    @test right_top_paned[1] isa GtkScrolledWindow  # build_tree_pane returns GtkScrolledWindow
    @test right_top_paned[2] isa GtkBox              # build_property_pane returns GtkBox

    # width_request constraints
    @test left_column.width_request >= 280
    @test right_column.width_request >= 280

    Gtk4.destroy(w)
end
