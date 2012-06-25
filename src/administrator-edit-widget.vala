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

		public class AdministratorEditWidget : Box {

			public Grid grid { get; private set; }

			public Entry username_entry { get; private set; }

			private Administrator _administrator;
			public Administrator administrator {
				get {
					return _administrator;
				}
				set {
					_administrator = value;

					if (value != null) {
						username_entry.text = value.username?? "";
					}
				}
			}


			public AdministratorEditWidget (Administrator administrator) {
				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add (grid);

				var username_label = new Label (_("_Username:"));
				username_label.use_underline = true;
				username_label.xalign = 0.0f;
				grid.add (username_label);

				username_entry = new Entry ();
				username_entry.hexpand = true;
				username_entry.activates_default = true;
				grid.attach_next_to (username_entry,
				                     username_label,
				                     PositionType.RIGHT,
				                     2, 1);

				this.administrator = administrator;
			}

			public void save () {
				if (this._administrator != null) {
					this._administrator.username = this.username_entry.text;
				}
			}

		}

	}

}
