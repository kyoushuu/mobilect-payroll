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

		public class DateTimeEntry : Box {

			public Entry time_entry { get; private set; }
			public Entry date_entry { get; private set; }

			public DateTimeEntry () {
				this.time_entry = new Entry ();
				time_entry.focus_out_event.connect ((e) => {
					update_time_entry ();
					return false;
				});
				time_entry.activate.connect ((e) => {
					update_time_entry ();
				});
				this.add (time_entry);

				this.date_entry = new Entry ();
				this.date_entry.focus_out_event.connect ((e) => {
					update_time_entry ();
					return false;
				});
				this.date_entry.activate.connect ((e) => {
					update_time_entry ();
				});
				this.add (date_entry);
			}

			public DateTime get_date_time () {
				int year, month, day;
				int hour, minute, second;

				if (date_entry.text == "" || time_entry.text == "") {
					set_date_time (new DateTime.now_local ());
				}

				/* %F format string */
				date_entry.text.scanf ("%04d-%02d-%02d",
				                       out year, out month, out day);

				/* %T format string */
				time_entry.text.scanf ("%02d:%02d:%02d",
				                       out hour, out minute, out second);

				var tz = new TimeZone.local ();
				return new DateTime (tz,
				                     year, month, day,
				                     hour, minute, second);
			}

			public void set_date_time (DateTime date_time) {
				date_entry.text = date_time.format ("%F");
				time_entry.text = date_time.format ("%T");
			}

			private void update_time_entry () {
				int hour, minute, second;

				/* %T format string */
				this.time_entry.text.scanf ("%02d:%02d:%02d",
				                            out hour, out minute, out second);

				var tz = new TimeZone.local ();
				var dt = new DateTime (tz, 1, 1, 1, hour, minute, second);
				var text = dt.format ("%T");

				if (this.time_entry.text != text) {
					this.time_entry.text = text;
				}
			}

			private void update_date_entry () {
				int year, month, day;

				/* %F format string */
				this.date_entry.text.scanf ("%04d-%02d-%02d",
				                            out year, out month, out day);

				var tz = new TimeZone.local ();
				var dt = new DateTime (tz, year, month, day, 0, 0, 0);
				var text = dt.format ("%F");

				if (this.date_entry.text != text) {
					this.date_entry.text = text;
				}
			}

		}

	}

}
