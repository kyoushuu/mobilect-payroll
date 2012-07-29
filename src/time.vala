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

		public struct Time {

			private int _hour;
			public int hour {
				public get {
					return _hour;
				}
				public set {
					if (value >= 0 && value <= 23) {
						_hour = value;
					}
				}
			}

			private int _minute;
			public int minute {
				public get {
					return _minute;
				}
				public set {
					if (value >= 0 && value <= 60) {
						_minute = value;
					}
				}
			}


			public Time (int hour, int minute) {
				set (hour, minute);
			}

			public void set (int hour, int minute) {
				this.hour = hour;
				this.minute = minute;
			}

			public Time duplicate () {
				return new Time (hour, minute);
			}

			public bool is_equal (Time time) {
				return
					time.hour == this.hour &&
					time.minute == this.minute;
			}

		}

	}

}
