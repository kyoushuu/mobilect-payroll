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

		public class DateSpinButton : SpinButton {

			public Date date {
				public get {
					var date = Date ();
					date.set_julian ((uint) this.value);
					return date;
				}
				public set {
					if (value.valid ()) {
						this.value = value.get_julian ();
					}
				}
			}


			public DateSpinButton () {
				var dt = new DateTime.now_local ();

				var curr_date = Date ();
				curr_date.set_dmy ((DateDay) dt.get_day_of_month (),
				                   (DateMonth) dt.get_month (),
				                   (DateYear) dt.get_year ());

				var lower_date = Date ();
				lower_date.set_dmy (1, 1, 1);

				var upper_date = Date ();
				upper_date.set_dmy (1, 1, 10000);

				adjustment = new Adjustment (curr_date.get_julian (),
				                             lower_date.get_julian (),
				                             upper_date.get_julian (),
				                             1, 7,
				                             0);
				digits = 10;
			}

			public void set_dmy (int day, int month, int year) {
				var date = Date ();
				date.set_dmy ((DateDay) day, (DateMonth) month, (DateYear) year);
				this.date = date;
				value_changed ();
			}

			public override int input (out double new_value) {
				var date = Date ();
				date.set_parse (text);

				if (date.valid ()) {
					DateYear year = date.get_year ();
					if (year >= 0 && year < 70) {
						year += 2000;
					} else if (year >= 70 && year < 100) {
						year += 1900;
					}
					date.set_year (year);

					new_value = date.get_julian ();

					return (int) true;
				} else {
					new_value = 0;

					return INPUT_ERROR;
				}
			}

			public override bool output () {
				char s[64];

				date.strftime (s, _("%a, %d %b, %Y"));
				text = (string) s;

				return true;
			}

		}

	}

}
