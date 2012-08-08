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

		public class FindWidget : Box {

			public Grid grid { get; private set; }

			public DateSpinButton start_spin { get; private set; }
			public DateSpinButton end_spin { get; private set; }


			public FindWidget () {
				push_composite_child ();


				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_homogeneous = true;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add (grid);
				grid.show ();


				var start_date_label = new Label (_("_Start:"));
				start_date_label.use_underline = true;
				start_date_label.xalign = 0.0f;
				grid.add (start_date_label);
				start_date_label.show ();

				start_spin = new DateSpinButton ();
				start_spin.hexpand = true;
				grid.attach_next_to (start_spin,
				                     start_date_label,
				                     PositionType.RIGHT,
				                     2, 1);
				start_spin.show ();


				var end_date_label = new Label (_("_End:"));
				end_date_label.use_underline = true;
				end_date_label.xalign = 0.0f;
				grid.add (end_date_label);
				end_date_label.show ();

				end_spin = new DateSpinButton ();
				end_spin.hexpand = true;
				grid.attach_next_to (end_spin,
				                     end_date_label,
				                     PositionType.RIGHT,
				                     2, 1);
				end_spin.show ();


				pop_composite_child ();
			}

		}

	}

}
