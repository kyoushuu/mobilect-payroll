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
using Pango;


namespace Mobilect {

	namespace Payroll {

		public class ReportAssistantConfirmPage : ReportAssistantPage {

			private enum Columns {
				TITLE,
				SUBTITLE,
				ICON_NAME,
				NUM
			}

			public enum Actions {
				SAVE,
				PRINT,
				PRINT_PREVIEW
			}


			public TreeView tree_view { get; private set; }


			public ReportAssistantConfirmPage (ReportAssistant assistant) {
				base (assistant);

				var actions = new Gtk.ListStore (Columns.NUM, typeof (string), typeof (string), typeof (string));

				actions.insert_with_values (null, Actions.SAVE,
				                            Columns.TITLE, _("Save"),
				                            Columns.SUBTITLE, _("Export payroll and payslips to a PDF file"),
				                            Columns.ICON_NAME, Stock.SAVE);
				actions.insert_with_values (null, Actions.PRINT,
				                            Columns.TITLE, _("Print"),
				                            Columns.SUBTITLE, _("Print payroll and payslips"),
				                            Columns.ICON_NAME, Stock.PRINT);
				actions.insert_with_values (null, Actions.PRINT_PREVIEW,
				                            Columns.TITLE, _("Print Preview"),
				                            Columns.SUBTITLE, _("Print preview of payroll and payslips"),
				                            Columns.ICON_NAME, Stock.PRINT_PREVIEW);


				push_composite_child ();


				var label = new Label (_("The report has been successfully created. Select an action below."));
				label.xalign = 0.0f;
				this.add (label);
				label.show ();

				var sw = new ScrolledWindow (null, null);
				this.add (sw);
				sw.show ();

				tree_view = new TreeView.with_model (actions);
				tree_view.expand = true;
				tree_view.headers_visible = false;
				tree_view.row_activated.connect ((t, p, c) => {
					assistant.apply ();
					assistant.next_page ();
				});
				sw.add (tree_view);
				tree_view.show ();

				var cell_icon = new CellRendererPixbuf ();
				cell_icon.stock_size = IconSize.LARGE_TOOLBAR;

				var column_icon = new TreeViewColumn.with_attributes (_("Icon"),
				                                                      cell_icon,
				                                                      "stock-id", Columns.ICON_NAME);
				tree_view.append_column (column_icon);

				var vbox = new CellAreaBox ();
				vbox.orientation = Orientation.VERTICAL;

				var column_text = new TreeViewColumn.with_area (vbox);
				tree_view.append_column (column_text);

				var cell_title = new CellRendererText ();
				cell_title.weight = Weight.BOLD;
				column_text.pack_start (cell_title, true);
				column_text.set_attributes (cell_title,
				                            "text", Columns.TITLE);

				var cell_subtitle = new CellRendererText ();
				column_text.pack_start (cell_subtitle, true);
				column_text.set_attributes (cell_subtitle,
				                            "text", Columns.SUBTITLE);

				pop_composite_child ();
			}

		}

	}

}
