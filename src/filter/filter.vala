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

			private Date cached_date_start = Date ();
			private Date cached_date_end = Date ();
			private Date[] dates_affected { get; set; }
			private Database cached_database;


			public Filter () {
			}

			public Date[] get_affected_dates (Database database) {
				if (date_start.compare (date_end) > 0) {
					return new Date[0];
				}

				if (cached_date_start.valid () && date_start.compare (cached_date_start) == 0 &&
				    cached_date_end.valid () && date_end.compare (cached_date_end) == 0 &&
				    database == cached_database &&
				    dates_affected != null) {
					return dates_affected;
				}

				MonthInfo month_info = null;
				var dates = new Date[0];

				for (var date = date_start; date.compare (date_end) <= 0; date.add_days (1)) {
					if (month_info == null ||
					    month_info.month != date.get_month () ||
					    month_info.year != date.get_year ()) {
						month_info = new MonthInfo (database,
						                            date.get_year (),
						                            date.get_month ());
					}

					if (use_holiday_type) {
						if (month_info.get_day_type (date.get_day ()) != holiday_type) {
							continue;
						}
					}

					if (sunday_work !=
					    (month_info.get_weekday (date.get_day ()) == DateWeekday.SUNDAY)) {
						continue;
					}

					dates += date;
				}

				cached_date_start = date_start;
				cached_date_end = date_end;
				dates_affected = dates;
				cached_database = database;

				return dates_affected;
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
					filter.time_periods[i] = this.time_periods[i];
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
