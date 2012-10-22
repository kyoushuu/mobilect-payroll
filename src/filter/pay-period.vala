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

		/**
		 * Class for pay periods
		 *
		 * This is the class for pay periods, the partitioning of a day with each
		 * part with different rates, e.g. Regular, Overtime and Extended Overtime.
		 *
		 * This class is only used in {@link OvertimeReport}, since
		 * {@link RegularReport} only uses one pay period and rate (Regular).
		 */
		public class PayPeriod : Object {

			/**
			 * The name of the pay period.
			 */
			public string name { get; private set; }
			/**
			 * Whether the period is overtime. If it not an overtime, part of it will
			 * be paid in regular, and the remaining will be paid in the overtime
			 * payroll.
			 */
			public bool is_overtime { get; private set; }
			/**
			 * The rate per hour of the period, decimal percentage (e.g. 1.30%).
			 */
			public double rate { get; private set; }
			/**
			 * The time periods of the pay period. This is used to break the time,
			 * skipping unpaid time (e.g. lunch break).
			 */
			public TimePeriod[] time_periods { get; private set; }


			/**
			 * Creates a new pay period.
			 */
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
