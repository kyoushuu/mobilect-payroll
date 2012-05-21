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

		public class PayPeriod : Object {

			public string name { get; set; }
			public bool is_overtime { get; set; }
			public double rate { get; set; }
			public TimePeriod[] time_periods { get; set; }


			public PayPeriod (string name,
			                  bool is_overtime,
			                  double rate,
			                  TimePeriod[] time_periods) {
				this.name = name;
				this.is_overtime = is_overtime;
				this.rate = rate;
				this.time_periods = time_periods;
			}

		}

	}

}
