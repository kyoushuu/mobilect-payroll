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

		public class Filter : Object {

			public Date date_start = Date ();
			public Date date_end = Date ();

			public TimePeriod[] time_periods { get; set; }

			public bool use_holiday_type = false;
			public MonthInfo.HolidayType holiday_type;
			public bool sunday_work = false;
			public double period = 4.0;


			public Filter () {
			}

			/*
			public DateTime get_start_as_date_time () {
				return new DateTime.local (date_start.get_year (),
				                           date_start.get_month (),
				                           date_start.get_day (),
				                           time_start.hour, time_start.minute, 0);
			}

			public DateTime get_end_as_date_time () {
				return new DateTime.local (date_end.get_year (),
				                           date_end.get_month (),
				                           date_end.get_day (),
				                           time_end.hour, time_end.minute, 0);
			}

			public void set_start_from_date_time (DateTime dt) {
				date_start.set_dmy ((DateDay) dt.get_day_of_month (),
				                    (DateMonth) dt.get_month (),
				                    (DateYear) dt.get_year ());
				time_start.set (dt.get_hour (), dt.get_minute ());
			}

			public void set_end_from_date_time (DateTime dt) {
				date_end.set_dmy ((DateDay) dt.get_day_of_month (),
				                  (DateMonth) dt.get_month (),
				                  (DateYear) dt.get_year ());
				time_end.set (dt.get_hour (), dt.get_minute ());
			}
			*/

			public Filter duplicate () {
				var filter = new Filter ();

				filter.date_start = date_start;
				filter.date_end = date_end;

				filter.time_periods = new TimePeriod[this.time_periods.length];
				for (int i = 0; i < this.time_periods.length; i++) {
					filter.time_periods[i] = this.time_periods[i].duplicate ();
				}

				filter.use_holiday_type = use_holiday_type;
				filter.holiday_type = holiday_type;
				filter.sunday_work = sunday_work;
				filter.period = period;

				return filter;
			}

			public bool is_equal (Filter filter) {
				if (filter.time_periods.length != this.time_periods.length) {
					return false;
				}

				for (int i = 0; i < this.time_periods.length; i++) {
					if (this.time_periods[i].is_equal (filter.time_periods[i]) == false) {
						return false;
					}
				}

				return
					filter.date_start.compare (this.date_start) == 0 &&
					filter.date_end.compare (this.date_end) == 0 &&
					filter.use_holiday_type == this.use_holiday_type &&
					filter.holiday_type == this.holiday_type &&
					filter.sunday_work == this.sunday_work &&
					filter.period == this.period;
			}

		}

	}

}
