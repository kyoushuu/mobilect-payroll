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

		public class BranchEditWidget : Box {

			public Grid grid { public get; private set; }

			public Entry name_entry { public get; private set; }

			private Branch _branch;
			public Branch branch {
				public get {
					return _branch;
				}
				public set {
					_branch = value;

					if (value != null) {
						name_entry.text = value.name?? "";
					}
				}
			}


			public BranchEditWidget (Branch branch) {
				push_composite_child ();


				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_homogeneous = true;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add (grid);
				grid.show ();


				var name_label = new Label.with_mnemonic (_("_Name:"));
				name_label.xalign = 0.0f;
				grid.add (name_label);
				name_label.show ();

				name_entry = new Entry ();
				name_entry.hexpand = true;
				name_entry.activates_default = true;
				name_entry.secondary_icon_tooltip_text = _("Name is empty");
				name_entry.changed.connect ((e) => {
	if (name_entry.text_length > 0) {
		name_entry.secondary_icon_stock = null;
	} else {
		name_entry.secondary_icon_stock = Stock.DIALOG_WARNING;
	}
});
				grid.attach_next_to (name_entry,
				                     name_label,
				                     PositionType.RIGHT,
				                     1, 1);
				name_label.mnemonic_widget = name_entry;
				name_entry.show ();


				pop_composite_child ();


				this.branch = branch;
			}

			public void save () {
				if (this._branch != null) {
					this._branch.name = this.name_entry.text;
				}
			}

		}

	}

}
