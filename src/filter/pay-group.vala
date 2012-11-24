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


namespace Mobilect {

	namespace Payroll {

		public class PayGroup : Object {

			public string name { get; private set; }
			public bool is_sunday_work { get; private set; }
			public bool straight_time { get; private set; }
			public MonthInfo.HolidayType holiday_type { get; private set; }
			public double rate { get; private set; }
			public Filter filter { get; private set; }


			public PayGroup (string? name,
			                 bool straight_time,
			                 bool is_sunday_work,
			                 MonthInfo.HolidayType holiday_type,
			                 double rate) {
				this.name = name;
				this.is_sunday_work = is_sunday_work;
				this.straight_time = straight_time;
				this.holiday_type = holiday_type;
				this.rate = rate;

				/* Cache filter */
				filter = new Filter ();
				filter.use_holiday_type = true;
				filter.holiday_type = holiday_type;
				filter.sunday_work = is_sunday_work;
				filter.straight_time = straight_time;
				filter.include_break = is_sunday_work;
			}

			public Filter create_filter (PayPeriod period, Date start, Date end) {
				var filter = this.filter.duplicate ();

				filter.time_periods = period.time_periods;
				filter.time_periods_break = period.time_periods_break;
				filter.enlist = period.is_overtime ||
					straight_time ||
					holiday_type != MonthInfo.HolidayType.NON_HOLIDAY ||
					is_sunday_work;
				filter.period = filter.enlist? 1.0 : 4.0;
				filter.date_start = start;
				filter.date_end = end;

				return filter;
			}

		}

	}

}
