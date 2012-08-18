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


namespace Mobilect {

	namespace Payroll {

		public class SortTreeViewDialog : Dialog {

			private ComboBoxText column_combo;
			private CheckButton ascending_check;
			private TreeView tree_view;


			public SortTreeViewDialog (Window parent, TreeView tree_view) {
				base (_("Sort By"), parent);

				this.action = _("_Sort");
				this.help_link_id = "control-panel-sort-view";

				var content_area = this.get_content_area ();


				push_composite_child ();


				var grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_homogeneous = true;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				grid.border_width = 5;
				content_area.add (grid);
				grid.show ();

				var column_label = new Label.with_mnemonic (_("Co_lumn:"));
				column_label.xalign = 0.0f;
				grid.add (column_label);
				column_label.show ();

				column_combo = new ComboBoxText ();
				column_combo.hexpand = true;
				if (tree_view.get_n_columns () > 0) {
					foreach (var column in tree_view.get_columns ()) {
						column_combo.append_text (column.title);
					}
					column_combo.active = 0;
				}
				grid.attach_next_to (column_combo,
				                     column_label,
				                     PositionType.RIGHT,
				                     1, 1);
				column_label.mnemonic_widget = column_combo;
				column_combo.show ();

				ascending_check = new CheckButton.with_mnemonic (_("_Ascending"));
				ascending_check.active = true;
				grid.attach_next_to (ascending_check,
				                     column_label,
				                     PositionType.BOTTOM,
				                     2, 1);
				ascending_check.show ();


				pop_composite_child ();


				this.response.connect ((d, r) => {
															 if (r == ResponseType.ACCEPT &&
															     column_combo.active >= 0 &&
															     this.tree_view.model is TreeSortable) {
																 (this.tree_view.model as TreeSortable)
																 .set_sort_column_id (tree_view.get_column (column_combo.active).sort_column_id,
																                      ascending_check.active?
																                      SortType.ASCENDING : SortType.DESCENDING);
															 }
														 });

				this.tree_view = tree_view;
			}

		}

	}

}
