/*
 *  gobject2-tool.c
 *
 *  gcc -o gobject2-tool gobject2-tool.c `pkg-config --cflags --libs gtk+-2.0`
 */

#include <gtk/gtk.h>


typedef GType (* GetTypeFunc) (void);


static void   query_type (GType type,
                          gint  level);


static GetTypeFunc get_type_funcs[] =
{
  gtk_accel_group_get_type,
  gtk_accel_label_get_type,
  gtk_accessible_get_type,
  gtk_adjustment_get_type,
  gtk_alignment_get_type,
  gtk_arrow_get_type,
  gtk_aspect_frame_get_type,
  gtk_bin_get_type,
  gtk_box_get_type,
  gtk_button_box_get_type,
  gtk_button_get_type,
  gtk_calendar_get_type,
  gtk_cell_renderer_get_type,
  gtk_cell_renderer_pixbuf_get_type,
  gtk_cell_renderer_text_get_type,
  gtk_cell_renderer_toggle_get_type,
  gtk_check_button_get_type,
  gtk_check_menu_item_get_type,
  gtk_clist_get_type,
  gtk_color_selection_dialog_get_type,
  gtk_color_selection_get_type,
  gtk_combo_get_type,
  gtk_container_get_type,
  gtk_ctree_get_type,
  gtk_curve_get_type,
  gtk_dialog_get_type,
  gtk_drawing_area_get_type,
  gtk_entry_get_type,
  gtk_event_box_get_type,
  gtk_file_selection_get_type,
  gtk_fixed_get_type,
  gtk_font_selection_dialog_get_type,
  gtk_font_selection_get_type,
  gtk_frame_get_type,
  gtk_gamma_curve_get_type,
  gtk_handle_box_get_type,
  gtk_hbox_get_type,
  gtk_hbutton_box_get_type,
  gtk_hpaned_get_type,
  gtk_hruler_get_type,
  gtk_hscale_get_type,
  gtk_hscrollbar_get_type,
  gtk_hseparator_get_type,
  gtk_icon_factory_get_type,
  gtk_im_context_get_type,
  gtk_im_context_simple_get_type,
  gtk_im_multicontext_get_type,
  gtk_image_get_type,
  gtk_image_menu_item_get_type,
  gtk_input_dialog_get_type,
  gtk_invisible_get_type,
  gtk_item_factory_get_type,
  gtk_item_get_type,
  gtk_label_get_type,
  gtk_layout_get_type,
  gtk_list_get_type,
  gtk_list_item_get_type,
  gtk_list_store_get_type,
  gtk_menu_bar_get_type,
  gtk_menu_get_type,
  gtk_menu_item_get_type,
  gtk_menu_shell_get_type,
  gtk_message_dialog_get_type,
  gtk_misc_get_type,
  gtk_notebook_get_type,
  gtk_object_get_type,
  gtk_option_menu_get_type,
  gtk_paned_get_type,
  gtk_pixmap_get_type,
  gtk_plug_get_type,
  gtk_preview_get_type,
  gtk_progress_bar_get_type,
  gtk_progress_get_type,
  gtk_radio_button_get_type,
  gtk_radio_menu_item_get_type,
  gtk_range_get_type,
  gtk_rc_style_get_type,
  gtk_ruler_get_type,
  gtk_scale_get_type,
  gtk_scrollbar_get_type,
  gtk_scrolled_window_get_type,
  gtk_separator_get_type,
  gtk_separator_menu_item_get_type,
  gtk_settings_get_type,
  gtk_size_group_get_type,
  gtk_socket_get_type,
  gtk_spin_button_get_type,
  gtk_statusbar_get_type,
  gtk_style_get_type,
  gtk_table_get_type,
  gtk_tearoff_menu_item_get_type,
  gtk_text_buffer_get_type,
  gtk_text_child_anchor_get_type,
  gtk_text_mark_get_type,
  gtk_text_tag_get_type,
  gtk_text_tag_table_get_type,
  gtk_text_view_get_type,
  gtk_tips_query_get_type,
  gtk_toggle_button_get_type,
  gtk_toolbar_get_type,
  gtk_tooltips_get_type,
  gtk_tree_model_sort_get_type,
  gtk_tree_selection_get_type,
  gtk_tree_store_get_type,
  gtk_tree_view_column_get_type,
  gtk_tree_view_get_type,
  gtk_vbox_get_type,
  gtk_vbutton_box_get_type,
  gtk_viewport_get_type,
  gtk_vpaned_get_type,
  gtk_vruler_get_type,
  gtk_vscale_get_type,
  gtk_vscrollbar_get_type,
  gtk_vseparator_get_type,
  gtk_widget_get_type,
  gtk_window_get_type,
  gtk_window_group_get_type,
  gtk_editable_get_type,
  gtk_cell_editable_get_type,
  gtk_tree_model_get_type,
  gtk_tree_sortable_get_type,
  gtk_tree_drag_source_get_type,
  gtk_tree_drag_dest_get_type
};


gint
main (gint   argc,
      gchar *argv[])
{
  gint  i;
  GType type;

  g_type_init ();

  g_print("module: gtk-internal\n\n"
          "define interface\n"
          "  #include \"gtk/gtk.h\",\n"
          "    import: all-recursive,\n"
	  "    name-mapper: minimal-name-mapping;\n");
  for (i = 0; i < G_N_ELEMENTS (get_type_funcs); i++)
    query_type (get_type_funcs[i] (), 0);
  g_print("end interface;");
  return 0;
}


/*  private functions  */

static inline void
indent (gint level)
{
  gint i;

  for (i = 0; i < level; i++)
    g_print ("  ");
}

static void
query_type (GType type,
            gint  level)
{
  indent (level);
  if (G_TYPE_IS_CLASSED (type))
    {

      GTypeQuery  type_query;
      GType      *interfaces;
      guint       n_interfaces;

      g_print ("  struct \"struct _%s\",\n    superclasses: {", g_type_name (type));

      g_type_query (type, &type_query);

      if (g_type_is_a (type, G_TYPE_OBJECT))
        {
          GTypeClass   *klass;
          GObjectClass *object_class;
	  GType         parent;
	  
          klass = g_type_class_ref (type);
	  
          object_class = G_OBJECT_CLASS (klass);
	  
	  parent = g_type_parent(type);
	  
          /*  query properties & signals here  */
	  
	  /* query_type(parent, level + 1); */

	  g_print("<%s>", g_type_name (parent));
          g_type_class_unref (klass);
        }
  
      interfaces = g_type_interfaces (type, &n_interfaces);

      if (n_interfaces > 0)
        {
          gint i;

          indent (level);

          for (i = 0; i < n_interfaces; i++)
	    g_print (", <%s>", g_type_name(interfaces[i]));
	  //query_type (interfaces[i], level + 1);
        }

      g_print("};\n");
      g_free (interfaces);
    }
}
