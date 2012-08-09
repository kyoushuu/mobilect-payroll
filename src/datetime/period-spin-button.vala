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

		public class PeriodSpinButton : SpinButton {

			public int period {
				public get {
					return (int) this.value;
				}
				protected set {
					if (value >= 0 && value < 10000*12*2) {
						this.value = value;
					}
				}
			}


			public PeriodSpinButton () {
				var dt = new DateTime.now_local ();

				adjustment = new Adjustment ((dt.get_year () * 12 * 2) +
				                             ((dt.get_month () - 1) * 2) +
				                             (dt.get_day_of_month () <= 15? 0 : 1),
				                             1*12*2,
				                             10000*12*2-1,
				                             1, 12*2,
				                             0);
				digits = 20;
			}

			public void set_dmy (int day, int month, int year) {
				this.period = (year * 12 * 2) +
					((month-1) * 2) +
					(day <= 15? 0 : 1);
				value_changed ();
			}

			public override int input (out double new_value) {
				var input_text = text;

				if (input_text.has_prefix (_("First Half of"))) {
					input_text = input_text.replace (_("First Half of"), "01");
				} else if (input_text.has_prefix (_("Second Half of"))) {
					input_text = input_text.replace (_("Second Half of"), "16");
				}

				var date = Date ();
				date.set_parse (input_text);

				if (date.valid ()) {
					new_value = (date.get_year () * 12 * 2) +
						((date.get_month ()-1) * 2) +
						(date.get_day () <= 15? 0 : 1);
					return (int) true;
				} else {
					new_value = 0;
					return INPUT_ERROR;
				}
			}

			public override bool output () {
				char s[64];

				var date = Date ();
				date.set_dmy (1, ((period / 2) % 12) + 1, (DateYear) period / (12 * 2));

				if (period % 2 == 0) {
					date.strftime (s, _("First Half of %B, %Y"));
				} else {
					date.strftime (s, _("Second Half of %B, %Y"));
				}
				text = (string) s;

				return true;
			}

		}

	}

}
