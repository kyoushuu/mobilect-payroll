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

			public Time time_start = new Time (0, 0);
			public Time time_end = new Time (0, 0);

			public bool use_holiday_type = false;
			public MonthInfo.HolidayType holiday_type;
			public bool sunday_work = false;
			public double period = 4.0;


			public Filter () {
			}

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

			public Filter duplicate () {
				var filter = new Filter ();

				filter.date_start = date_start;
				filter.date_end = date_end;

				filter.time_start = time_start.duplicate ();
				filter.time_end = time_end.duplicate ();

				return filter;
			}

			public bool is_equal (Filter filter) {
				return filter.date_start.compare (this.date_start) == 0 &&
					filter.date_end.compare (this.date_end) == 0 &&
					filter.time_start.is_equal (this.time_start) &&
					filter.time_end.is_equal (this.time_end) &&
					filter.use_holiday_type == this.use_holiday_type &&
					filter.holiday_type == this.holiday_type &&
					filter.sunday_work == this.sunday_work &&
					filter.period == this.period;
			}

		}

	}

}
