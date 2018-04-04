/*
 * Mobilect Payroll
 * Copyright (C) 2012 - Arnel A. Borja (kyoushuu@yahoo.com)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */


using Gtk;
using Gdk;
using Cairo;
using Config;


namespace Mobilect {

	namespace Payroll {

		public class PrintPreviewWindow : Gtk.Window {

			public PrintOperation op { get; private set; }
			public PrintContext context { get; private set; }

			public SurfaceDrawWidget image { get; private set; }
			public Entry pagenum_entry { get; private set; }
			public Label pagenum_label { get; private set; }

			public int current_page { get; private set; }
			public double page_width { get; private set; }
			public double page_height { get; private set; }

			private double screen_dpi;
			private ulong handler;


			public PrintPreviewWindow (PrintOperation op, PrintContext context, Gtk.Window parent) {
				this.title = _("Mobilect Payroll - Report Print Preview");
				this.default_width = 600;
				this.default_height = 400;
				this.icon_name = PACKAGE;
				this.transient_for = parent;
				this.op = op;
				this.context = context;


				push_composite_child ();


				var box = new Box (Orientation.VERTICAL, 0);
				this.add (box);
				box.show ();

				var toolbar = new Toolbar ();
				toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);
				box.add (toolbar);
				toolbar.show ();


				/* Document area */
				var sw = new ScrolledWindow (null, null);
				sw.expand = true;
				box.add (sw);
				sw.show ();

				var translucent_color = RGBA ();
				translucent_color.alpha = 0;

				var viewport = new Viewport (null, null);
				viewport.shadow_type = ShadowType.ETCHED_IN;
				viewport.override_background_color (StateFlags.NORMAL, translucent_color);
				sw.add (viewport);
				viewport.show ();

				image = new SurfaceDrawWidget ();
				image.halign = Align.CENTER;
				image.valign = Align.CENTER;
				viewport.add (image);
				image.show ();


				/* Previous/next page toolitems */
				var prev_toolbutton = new ToolButton.from_stock (Stock.GO_UP);
				prev_toolbutton.clicked.connect (() => {
					if (current_page > 0) {
						current_page--;
						render ();
						show_page ();
					}
				});
				toolbar.insert (prev_toolbutton, -1);
				prev_toolbutton.show ();

				var next_toolbutton = new ToolButton.from_stock (Stock.GO_DOWN);
				next_toolbutton.clicked.connect (() => {
					if (current_page + 1 < op.n_pages) {
						current_page++;
						render ();
						show_page ();
					}
				});
				toolbar.insert (next_toolbutton, -1);
				next_toolbutton.show ();

				var separator1 = new SeparatorToolItem ();
				toolbar.insert (separator1, -1);
				separator1.show ();


				/* Page number toolitem */
				var pagenum_toolitem = new ToolItem ();
				toolbar.insert (pagenum_toolitem, -1);
				pagenum_toolitem.show ();

				var pagenum_box = new Box (Orientation.HORIZONTAL, 0);
				pagenum_toolitem.add (pagenum_box);
				pagenum_box.show ();

				pagenum_entry = new Entry ();
				pagenum_entry.width_chars = 3;
				pagenum_entry.activate.connect (() => {
					var page = int.parse (pagenum_entry.text) - 1;
					if (page < op.n_pages) {
						current_page = page;
						render ();
						show_page ();
					}
				});
				pagenum_box.add (pagenum_entry);
				pagenum_entry.show ();

				pagenum_label = new Label ("");
				pagenum_box.add (pagenum_label);
				pagenum_label.show ();

				var separator2 = new SeparatorToolItem ();
				toolbar.insert (separator2, -1);
				separator2.show ();


				/* Zoom toolitems */
				var zoom100_toolbutton = new ToolButton.from_stock (Stock.ZOOM_100);
				zoom100_toolbutton.clicked.connect (() => {
					image.zoom = 1.0;
					show_page ();
				});
				toolbar.insert (zoom100_toolbutton, -1);
				zoom100_toolbutton.show ();

				var zoomfit_toolbutton = new ToolButton.from_stock (Stock.ZOOM_FIT);
				zoomfit_toolbutton.clicked.connect (() => {
					var width_zoomfit = sw.get_allocated_width () / page_width;
					var height_zoomfit = sw.get_allocated_height () / page_height;
					image.zoom = width_zoomfit < height_zoomfit? width_zoomfit : height_zoomfit;
					show_page ();
				});
				toolbar.insert (zoomfit_toolbutton, -1);
				zoomfit_toolbutton.show ();

				var zoomin_toolbutton = new ToolButton.from_stock (Stock.ZOOM_IN);
				zoomin_toolbutton.clicked.connect (() => {
					if (image.zoom < 4.0) {
						if (image.zoom >= 2.0) {
							image.zoom += 1.0;
						} else if (image.zoom >= 1.0) {
							image.zoom += 0.25;
						} else if (image.zoom >= 0.5) {
							image.zoom += 0.15;
						} else {
							image.zoom += 0.10;
						}
						show_page ();
					}
				});
				toolbar.insert (zoomin_toolbutton, -1);
				zoomin_toolbutton.show ();

				var zoomout_toolbutton = new ToolButton.from_stock (Stock.ZOOM_OUT);
				zoomout_toolbutton.clicked.connect (() => {
					if (image.zoom > 0.2) {
						if (image.zoom >= 3.0) {
							image.zoom -= 1.0;
						} else if (image.zoom >= 1.25) {
							image.zoom -= 0.25;
						} else if (image.zoom >= 0.65) {
							image.zoom -= 0.15;
						} else {
							image.zoom -= 0.10;
						}
						show_page ();
					}
				});
				toolbar.insert (zoomout_toolbutton, -1);
				zoomout_toolbutton.show ();


				pop_composite_child ();


				PageSetup page_setup;
				if (op.default_page_setup != null) {
					page_setup = op.default_page_setup.copy ();
				} else {
					page_setup = new PageSetup ();
				}

				var settings = op.print_settings;
				if (settings != null) {
					if (settings.has_key (PRINT_SETTINGS_ORIENTATION)) {
						page_setup.set_orientation (settings.get_orientation ());
					}

					PaperSize paper_size = settings.get_paper_size ();
					if (paper_size != null) {
						page_setup.set_paper_size (paper_size);
					}
				}

				/* Set screen dpi and update when screen or screen size changes */
				set_screen_dpi ();
				screen_changed.connect (screen_changed_handler);

				/* Set default surface */
				{
					/* Convert from points to inch to pixels */
					page_width = page_setup.get_paper_width (Unit.POINTS) * (screen_dpi / 72);
					page_height = page_setup.get_paper_height (Unit.POINTS) * (screen_dpi / 72);

					var extents = Cairo.Rectangle ();
					extents.x = extents.y = 0;
					extents.width = page_width;
					extents.height = page_height;

					var surface = new RecordingSurface (Content.COLOR_ALPHA, extents);
					surface.set_fallback_resolution (screen_dpi, screen_dpi);

					context.set_cairo_context (new Cairo.Context (surface), screen_dpi, screen_dpi);
				}

				op.got_page_size.connect ((context, curr_page_setup) => {
					/* Convert from points to inch to pixels */
					page_width = curr_page_setup.get_paper_width (Unit.POINTS) * (screen_dpi / 72);
					page_height = curr_page_setup.get_paper_height (Unit.POINTS) * (screen_dpi / 72);

					var extents = Cairo.Rectangle ();
					extents.x = extents.y = 0;
					extents.width = page_width;
					extents.height = page_height;

					var surface = new RecordingSurface (Content.COLOR_ALPHA, extents);
					surface.set_fallback_resolution (screen_dpi, screen_dpi);

					var cr = new Cairo.Context (surface);
					cr.set_source_rgb (1, 1, 1);
					cr.paint ();
					cr.set_source_rgb (0, 0, 0);
					context.set_cairo_context (cr, screen_dpi, screen_dpi);
				});

				op.ready.connect ((context) => {
					current_page = 0;
					render ();
					show_page ();
				});
			}

			private void render () {
				op.render_page (current_page);

				var surface = (RecordingSurface) context.get_cairo_context ().get_target ();
				image.set_cairo_surface (surface, page_width, page_height);
			}

			private void show_page () {
				pagenum_entry.text = (current_page + 1).to_string ();
				pagenum_label.label = _("(%d of %d)").printf (current_page + 1, op.n_pages);
			}

			public override bool delete_event (EventAny event) {
				op.end_preview ();

				return false;
			}

			private void set_screen_dpi () {
				var screen = get_screen ();
				screen_dpi = (screen.get_width () * 25.4) / screen.get_width_mm ();
			}

			private void screen_changed_handler (Widget widget, Screen? previous_screen) {
				/* Remove update from previous screen */
				if (previous_screen != null) {
					previous_screen.disconnect (handler);
				}

				/* Update when screen size changes */
				handler = get_screen ().size_changed.connect (set_screen_dpi);
			}

		}

	}

}
