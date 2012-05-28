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

		public class CPanelPreferences : CPanelTab {

			public const string ACTION = "cpanel-preferences";

			public Grid grid { get; private set; }

			public DateTimeEntry start_entry { get; private set; }
			public DateTimeEntry end_entry { get; private set; }

			public CPanelPreferences (CPanel cpanel) {
				base (cpanel, ACTION);
				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add_with_viewport (grid);

				var start_label = new Label (_("_Start:"));
				start_label.use_underline = true;
				start_label.xalign = 0.0f;
				grid.add (start_label);

				start_entry = new DateTimeEntry ();
				start_entry.set_date_time (this.cpanel.filter.get_start_as_date_time ());
				grid.attach_next_to (start_entry,
				                     start_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var end_label = new Label (_("_End:"));
				end_label.use_underline = true;
				end_label.xalign = 0.0f;
				grid.add (end_label);

				end_entry = new DateTimeEntry ();
				end_entry.set_date_time (this.cpanel.filter.get_end_as_date_time ());
				grid.attach_next_to (end_entry,
				                     end_label,
				                     PositionType.RIGHT,
				                     2, 1);
			}

		}

	}

}
