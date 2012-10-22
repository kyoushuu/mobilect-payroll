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

		public class TimeSpinButton : SpinButton {

			public Time time {
				public get {
					return Time ((int) this.value / 60, (int) this.value % 60);
				}
				protected set {
					this.value = (value.hour * 60) + value.minute;
				}
			}


			public TimeSpinButton () {
				var dt = new DateTime.now_local ();

				adjustment = new Adjustment ((dt.get_hour () * 60) + dt.get_minute (),
				                             0, (24 * 60) - 1,
				                             1, 15,
				                             0);
				digits = 5;
				wrap = true;
			}

			public void set_hm (int hour, int minute) {
				this.value = (hour * 60) + minute;
				value_changed ();
			}

			public override int input (out double new_value) {
				int hour = 0, minute = 0;
				char ampm[3] = "AM".to_utf8 ();
				bool is_pm = false;

				new_value = 0;

				var scanned = text.scanf ("%u:%u %1s", out hour, out minute, out ampm);

				if (minute < 0 || minute >= 60) {
					return INPUT_ERROR;
				}

				if (scanned == 3) {
					if (((string) ampm).ascii_casecmp ("A") == 0) {
						is_pm = false;
					} else if (((string) ampm).ascii_casecmp ("P") == 0) {
						is_pm = true;
					} else {
						/* Neither AM or PM */
						return INPUT_ERROR;
					}

					if (hour < 1 || hour > 12) {
						return INPUT_ERROR;
					} else if (hour < 12 && is_pm) {
						hour += 12;
					} else if (hour == 12 && !is_pm) {
						hour = 0;
					}

					new_value = (hour * 60) + minute;

					return (int) true;
				} else if (scanned == 2) {
					if (hour < 0 || hour >= 24) {
						return INPUT_ERROR;
					}

					new_value = (hour * 60) + minute;

					return (int) true;
				} else {
					scanned = text.scanf ("%u%1s", out hour, out ampm);
					if (scanned == 2) {
						if (((string) ampm).ascii_casecmp ("A") == 0) {
							is_pm = false;
						} else if (((string) ampm).ascii_casecmp ("P") == 0) {
							is_pm = true;
						} else {
							/* Neither AM or PM */
							return INPUT_ERROR;
						}

						if (hour < 1 || hour > 12) {
							return INPUT_ERROR;
						} else if (hour < 12 && is_pm) {
							hour += 12;
						} else if (hour == 12 && !is_pm) {
							hour = 0;
						}

						new_value = hour * 60;

						return (int) true;
					} else if (scanned == 1) {
						if (hour < 0 || hour >= 24) {
							return INPUT_ERROR;
						}

						new_value = hour * 60;

						return (int) true;
					} else {
						return INPUT_ERROR;
					}
				}
			}

			public override bool output () {
				int hour, minute;
				string ampm;

				hour = (int) this.value / 60;
				minute = (int) this.value % 60;

				if (hour >= 12) {
					if (hour > 12) {
						hour -= 12;
					}

					ampm = "PM";
				} else {
					ampm = "AM";
				}

				if (hour == 0) {
					hour = 12;
				}

				text = "%02d:%02d %s".printf (hour, minute, ampm);

				return true;
			}

		}

	}

}
