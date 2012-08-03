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

		public class DateTimeSpinButton : Box {

			public DateSpinButton date_spin { get; private set; }
			public TimeSpinButton time_spin { get; private set; }


			public DateTimeSpinButton () {
				this.spacing = 6;

				push_composite_child ();

				date_spin = new DateSpinButton ();
				this.add (date_spin);
				date_spin.show ();

				time_spin = new TimeSpinButton ();
				this.add (time_spin);
				time_spin.show ();

				pop_composite_child ();
			}

			public DateTime get_date_time () {
				var date = date_spin.date;
				var time = time_spin.time;

				return new DateTime.local (date.get_year (), date.get_month (), date.get_day (),
				                           time.hour, time.minute, 0);
			}

			public void set_date_time (DateTime date_time) {
				date_spin.set_dmy (date_time.get_day_of_month (),
				                   date_time.get_month (),
				                   date_time.get_year ());
				time_spin.set_hm (date_time.get_hour (),
				                  date_time.get_minute ());
			}

		}

	}

}
