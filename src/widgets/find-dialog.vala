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

		public class FindDialog : Dialog {

			public FindWidget widget { get; private set; }


			public FindDialog (string title, Window parent) {
				base (title, parent);

				this.action = Stock.FIND;
				this.help_link_id = "time-records-search";

				var content_area = this.get_content_area ();


				push_composite_child ();

				widget = new FindWidget ();
				widget.border_width = 5;
				widget.start_spin.changed.connect (changed);
				widget.end_spin.changed.connect (changed);
				changed ();
				content_area.add (widget);

				widget.show ();

				pop_composite_child ();
			}

			public Date get_start_date () {
				return widget.start_spin.date;
			}

			public void set_start_dmy (int day, int month, int year) {
				widget.start_spin.set_dmy (day, month, year);
			}

			public Date get_end_date () {
				return widget.end_spin.date;
			}

			public void set_end_dmy (int day, int month, int year) {
				widget.end_spin.set_dmy (day, month, year);
			}

			private void changed () {
				set_response_sensitive (ResponseType.ACCEPT,
				                        widget.start_spin.date.compare (widget.end_spin.date) <= 0);
			}

		}

	}

}
