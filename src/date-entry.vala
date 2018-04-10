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

		public class DateEntry : Entry {

			public Date date;


			public DateEntry () {
				var dt = new DateTime.now_local ();
				date.set_dmy ((DateDay) dt.get_day_of_month (),
				              (DateMonth) dt.get_month (),
				              (DateYear) dt.get_year ());
				update_text ();

				focus_out_event.connect ((e) => {
					update_entry ();
					return false;
				});
				activate.connect ((e) => {
					update_entry ();
				});
			}


			private void update_entry () {
				var d = date;
				date.set_parse (text);
				if (!date.valid ()) {
					date = d;
				}
				update_text ();
			}

			private void update_text () {
				char s[50];
				date.strftime (s, "%x");
				text = (string) s;
			}
		}
	}

}
