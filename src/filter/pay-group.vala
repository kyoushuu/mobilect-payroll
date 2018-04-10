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
			public MonthInfo.HolidayType holiday_type { get; private set; }
			public double rate { get; private set; }
			public PayPeriod[] periods { get; private set; }
			public double[] minus_period_rates { get; private set; }
			public Filter[] filters { get; private set; }


			public PayGroup (string name,
			                 bool is_sunday_work,
			                 MonthInfo.HolidayType holiday_type,
			                 double rate,
			                 PayPeriod[] periods,
			                 double[]? minus_period_rates) {
				this.name = name;
				this.is_sunday_work = is_sunday_work;
				this.holiday_type = holiday_type;
				this.rate = rate;
				this.periods = periods;
				this.minus_period_rates = minus_period_rates;
				this.filters = new Filter[periods.length];

				for (int i = 0; i < periods.length; i++) {
					var filter = new Filter ();
					filter.time_periods = periods[i].time_periods;
					filter.use_holiday_type = true;
					filter.holiday_type = holiday_type;
					filter.sunday_work = is_sunday_work;
					filter.period = periods[i].is_overtime? 1.0 : 4.0;
					this.filters[i] = filter;
				}
			}

			public Filter create_filter (int period, Date start, Date end) requires (period >= 0 && period < periods.length) {
				var filter = this.filters[period].duplicate ();
				filter.date_start = start;
				filter.date_end = end;
				return filter;
			}

		}

	}

}
