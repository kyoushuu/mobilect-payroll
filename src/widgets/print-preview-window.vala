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
			public PrintOperationPreview preview { get; private set; }
			public PrintContext context { get; private set; }

			public UIManager ui_manager { get; private set; }
			public Toolbar toolbar { get; private set; }
			public Image image { get; private set; }
			public Entry entry { get; private set; }
			public Label label { get; private set; }

			public int current_page { get; private set; }
			public double page_width { get; private set; }
			public double page_height { get; private set; }

			public Pixbuf current_pixbuf { get; private set; }
			public int pixbuf_width { get; private set; }
			public int pixbuf_height { get; private set; }
			public double zoom { get; private set; default = 1.0; }


			public PrintPreviewWindow (PrintOperation op, PrintOperationPreview preview, PrintContext context, Gtk.Window parent) {
				this.title = _("Mobilect Payroll - Report Print Preview");
				this.default_width = 600;
				this.default_height = 400;
				this.icon_name = PACKAGE;
				this.transient_for = parent;
				this.op = op;
				this.preview = preview;
				this.context = context;


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = "print-preview-previous",
						stock_id = Stock.GO_UP,
						accelerator = _("<Alt>Up"),
						tooltip = _("Go to previous page"),
						callback = (a) => {
							if (current_page > 0) {
								current_page--;
								render ();
								show_page ();
							}
						}
					},
					Gtk.ActionEntry () {
						name = "print-preview-next",
						stock_id = Stock.GO_DOWN,
						accelerator = _("<Alt>Down"),
						tooltip = _("Go to next page"),
						callback = (a) => {
							if (current_page + 1 < this.op.n_pages) {
								current_page++;
								render ();
								show_page ();
							}
						}
					}
				};

				var action_group = new Gtk.ActionGroup ("preview");
				action_group.add_actions (actions, this);

				var ui_manager = new UIManager ();
				ui_manager.insert_action_group (action_group, -1);

				try {
					ui_manager.add_ui_from_resource ("/com/mobilectpower/Payroll/mobilect-payroll-print-preview-ui.xml");
				} catch (Error e) {
					error ("Failed to add UI to UI Manager: %s", e.message);
				}


				push_composite_child ();


				var box = new Box (Orientation.VERTICAL, 0);
				this.add (box);
				box.show ();

				var toolbar = ui_manager.get_widget ("/toolbar") as Toolbar;
				toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);
				box.add (toolbar);
				toolbar.show ();

				var entry_item = new ToolItem ();
				toolbar.insert (entry_item, -1);
				entry_item.show ();

				var entry_box = new Box (Orientation.HORIZONTAL, 0);
				entry_item.add (entry_box);
				entry_box.show ();

				entry = new Entry ();
				entry.activate.connect (() => {
					var page = int.parse (entry.text) - 1;
					if (page < op.n_pages) {
						current_page = page;
						render ();
						show_page ();
					}
				});
				entry_box.add (entry);
				entry.show ();

				label = new Label ("");
				entry_box.add (label);
				label.show ();

				var sw = new ScrolledWindow (null, null);
				sw.expand = true;
				box.add (sw);
				sw.show ();

				image = new Image.from_pixbuf (null);
				sw.add_with_viewport (image);
				image.show ();


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

					unowned PaperSize paper_size = settings.get_paper_size ();
					if (paper_size != null) {
						page_setup.set_paper_size (paper_size);
					}
				}

				page_width = page_setup.get_paper_width (Unit.POINTS);
				page_height = page_setup.get_paper_height (Unit.POINTS);

				double longest = page_width > page_height? page_width : page_height;
				var surface = new ImageSurface (Format.ARGB32,
				                                (int) (longest),
				                                (int) (longest));
				surface.set_fallback_resolution (300, 300);

				context.set_cairo_context (new Cairo.Context (surface), 72, 72);

				preview.got_page_size.connect ((context, curr_page_setup) => {
					page_width = curr_page_setup.get_paper_width (Unit.POINTS);
					page_height = curr_page_setup.get_paper_height (Unit.POINTS);

					var curr_surface = new ImageSurface (Format.ARGB32,
					                                     (int) page_width,
					                                     (int) page_height);
					curr_surface.set_fallback_resolution (300, 300);

					var cr = new Cairo.Context (curr_surface);
					context.set_cairo_context (cr, 72, 72);
				});

				preview.ready.connect ((context) => {
					current_page = 0;
					render ();
					show_page ();
				});
			}

			private void render () {
				preview.render_page (current_page);

				var surface = (ImageSurface) context.get_cairo_context ().get_target ();
				pixbuf_width = surface.get_width ();
				pixbuf_height = surface.get_height ();

				current_pixbuf = pixbuf_get_from_surface (surface, 0, 0,
				                                          pixbuf_width, pixbuf_height);
			}

			private void show_page () {
				var pixbuf = current_pixbuf.scale_simple ((int) (pixbuf_width * zoom),
				                                          (int) (pixbuf_height * zoom),
				                                          InterpType.BILINEAR);
				image.set_from_pixbuf (pixbuf);
				entry.text = (current_page + 1).to_string ();
				label.label = _("(%d of %d)").printf (current_page + 1, op.n_pages);
			}

			private void zoom_in () {
				if (zoom < 1.5) {
					zoom += 0.1;
					show_page ();
				}
			}

			private void zoom_out () {
				if (zoom > 0.5) {
					zoom -= 0.1;
					show_page ();
				}
			}

			public override bool delete_event (EventAny event) {
				preview.end_preview ();

				return false;
			}

		}

	}

}
