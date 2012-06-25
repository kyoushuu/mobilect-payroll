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

			public string name { get; set; }
			public bool is_sunday_work { get; set; }
			public MonthInfo.HolidayType holiday_type { get; set; }
			public double rate { get; set; }
			public PayPeriod[] periods { get; set; }
			public double[] minus_period_rates { get; set; }


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
			}

		}

	}

}
