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


using Gda;


namespace Mobilect {

	namespace Payroll {

		public class Employee : Object {

			public int id { get; set; }
			public string lastname { get; set; }
			public string firstname { get; set; }
			public string middlename { get; set; }
			public string tin { get; set; }
			public int rate { get; set; }
			public double rate_per_day { get { return rate / 26.0; } }
			public double rate_per_hour { get { return rate / (26.0 * 8.0); } }

			internal weak Database database { get; private set; }
			internal weak EmployeeList list { get; set; }

			private Filter cached_filter;
			private double cached_hours;

			public Employee (int id, Database database) {
				this.id = id;
				this.database = database;


				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				if (id != 0) {
					try {
						/* Get employee data from database */
						var stmt = database.cnc.parse_sql_string ("SELECT lastname, firstname, middlename, tin, rate" +
						                                          "  FROM employees" +
						                                          "  WHERE id=##id::int",
						                                          out stmt_params);
						stmt_params.get_holder ("id").set_value (value_id);
						var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						var cell_data_lastname = data_model.get_value_at (0, 0);
						this.lastname = database.dh_string.get_str_from_value (cell_data_lastname);

						var cell_data_firstname = data_model.get_value_at (1, 0);
						this.firstname = database.dh_string.get_str_from_value (cell_data_firstname);

						var cell_data_middlename = data_model.get_value_at (2, 0);
						this.middlename = database.dh_string.get_str_from_value (cell_data_middlename);

						var cell_data_tin = data_model.get_value_at (3, 0);
						this.tin = database.dh_string.get_str_from_value (cell_data_tin);

						var cell_data_rate = data_model.get_value_at (4, 0);
						this.rate = cell_data_rate.get_int ();
					} catch (Error e) {
						critical ("Failed to get employee data from database: %s", e.message);
					}
				}
			}

			public string get_name () {
				return lastname + ", " + firstname + " " + middlename;
			}

			public int get_open_time_records_num () {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				try {
					var stmt = database.cnc.parse_sql_string ("SELECT id FROM time_records" +
					                                          "  WHERE employee_id=##employee_id::int" +
					                                          "  AND end IS NULL" +
					                                          "  ORDER BY id DESC",
					                                          out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

					return data_model.get_n_rows ();
				} catch (Error e) {
					critical ("Failed to get open time records of employee from database: %s", e.message);
					return -1;
				}
			}

			public void log_employee_in () {
				database.add_time_record (this.id, new DateTime.now_local (), null);
			}

			public void log_employee_out () {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				try {
					var stmt = database.cnc.parse_sql_string ("SELECT id FROM time_records" +
					                                          "  WHERE employee_id=##employee_id::int" +
					                                          "  AND end IS NULL" +
					                                          "  ORDER BY id DESC",
					                                          out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

					var record_id = data_model.get_value_at (0, 0);

					stmt = database.cnc.parse_sql_string ("UPDATE time_records" +
					                                      "  SET end=##end::string" +
					                                      "  WHERE id=##id::int",
					                                      out stmt_params);
					stmt_params.get_holder ("id").set_value (record_id);
					stmt_params.get_holder ("end").set_value_str (database.dh_string, new DateTime.now_local ().format ("%F %T"));
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					critical ("Failed to update time record in database for employee logout: %s", e.message);
				}
			}

			public double get_hours (Filter filter) {
				if (this.cached_filter != null &&
				    filter.is_equal (this.cached_filter)) {
					return this.cached_hours;
				}

				double hours_span = 0.0;
				DateTime record_start, record_end;

				Date date_start = filter.date_start;
				Date date_end = filter.date_end;

				MonthInfo month_info = null;

				Set stmt_params;
				var value_id = Value (typeof (int));
				value_id.set_int (this.id);

				try {
					/* Get time records */
					var stmt = database.cnc.parse_sql_string ("SELECT id, start, end" +
					                                          "  FROM time_records" +
					                                          "  WHERE employee_id=##employee_id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						for (int period = 0; period < filter.time_periods.length; period++)
						{
							Time time_start = filter.time_periods[period].start;
							Time time_end = filter.time_periods[period].end;

							var range_start = new DateTime.local (date_start.get_year (),
							                                      date_start.get_month (),
							                                      date_start.get_day (),
							                                      time_start.hour, time_start.minute, 0);
							var range_end = new DateTime.local (date_end.get_year (),
							                                    date_end.get_month (),
							                                    date_end.get_day (),
							                                    time_start.hour, time_start.minute, 0);
							int minutes =
								((time_end.hour * 60) + time_end.minute) -
								((time_start.hour * 60) + time_start.minute);
							if (minutes < 0) {
								minutes += 24 * 60;
							}
							range_end = range_end.add_minutes (minutes);

							var time_record = new TimeRecord (data_model.get_value_at (0, i).get_int (), database, this);

							if (time_record.end == null) {
								continue;
							}

							record_start = time_record.start;
							record_end = time_record.end;

							/* Used to make sure to get 'real' day info when period passes 12 midnight */
							var record_start_dummy = record_start;
							bool next_day = (range_start.get_hour () > range_end.get_hour () && record_start.get_day_of_month () == record_end.get_day_of_month ());
							if (next_day) {
								/* Already next day! */
								record_start_dummy = record_start_dummy.add_days (-1);
							}


							if (month_info == null ||
							    month_info.month != record_start.get_month () ||
							    month_info.year != record_start.get_year ()) {
								month_info = new MonthInfo (database,
								                            record_start.get_year (),
								                            record_start.get_month ());
							}

							if (filter.use_holiday_type) {
								if (month_info.get_day_type (record_start_dummy.get_day_of_month ()) !=
								    filter.holiday_type) {
									continue;
								}
							}

							if (filter.sunday_work !=
							    (month_info.get_weekday (record_start_dummy.get_day_of_month ()) == DateWeekday.SUNDAY)) {
								continue;
							}

							/* Check if time record date is in range */
							if ((record_start.compare (range_end) == -1 && record_end.compare (range_start) != -1) ||
							    (record_start.compare (range_end) != 1 && record_end.compare (range_start) == 1)) {
								/* Get times of record and period */
								var period_start = new DateTime.local (record_start.get_year (),
								                                       record_start.get_month (),
								                                       record_start.get_day_of_month (),
								                                       time_start.hour, time_start.minute, 0);
								var period_end = period_start.add_minutes (minutes);

								if (next_day) {
									/* Already next day! */
									period_start = period_start.add_days (-1);
									period_end = period_end.add_days (-1);
								}

								/* Check if time record date is in period */
								if ((record_start.compare (period_end) == -1 && record_end.compare (period_start) != -1) ||
								    (record_start.compare (period_end) != 1 && record_end.compare (period_start) == 1)) {
									/* Get span of paid period */
									var span_start = record_start.compare (period_start) == 1? record_start : period_start;
									var span_end = record_end.compare (period_end) == -1? record_end : period_end;

									double hours = span_end.difference (span_start)/TimeSpan.HOUR;
									hours_span += Math.floor (hours/filter.period)*filter.period;
									if (Math.floor ((hours + (filter.period/4)) / filter.period) >
									    Math.floor (hours / filter.period)) {
										hours_span += filter.period;
									}
								}
							}
						}
					}
				} catch (Error e) {
					critical ("Failed to get time record of employee from database: %s", e.message);
				}

				this.cached_filter = filter.duplicate ();
				this.cached_hours = hours_span;

				return hours_span;
			}

			public void update () {
				Set stmt_params;
				var value_id = Value (typeof (int));
				var value_rate = Value (typeof (int));

				value_id.set_int (this.id);
				value_rate.set_int (this.rate);

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE employees" +
					                                          "  SET lastname=##lastname::string," +
					                                          "    firstname=##firstname::string," +
					                                          "    middlename=##middlename::string," +
					                                          "    tin=##tin::string," +
					                                          "    rate=##rate::int" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("lastname").set_value_str (database.dh_string, this.lastname);
					stmt_params.get_holder ("firstname").set_value_str (database.dh_string, this.firstname);
					stmt_params.get_holder ("middlename").set_value_str (database.dh_string, this.middlename);
					stmt_params.get_holder ("tin").set_value_str (database.dh_string, this.tin);
					stmt_params.get_holder ("rate").set_value (value_rate);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					critical ("Failed to update employee in database: %s", e.message);
				}
			}

			public void remove () {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				if (list != null) {
					list.remove (this);
				}

				try {
					var stmt = database.cnc.parse_sql_string ("DELETE FROM employees WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);

					stmt = database.cnc.parse_sql_string ("DELETE FROM time_records WHERE employee_id=##employee_id::int",
					                                      out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					critical ("Failed to remove employee from database: %s", e.message);
				}
			}

			public string? get_password_checksum () {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				try {
					var stmt = database.cnc.parse_sql_string ("SELECT password" +
					                                          "  FROM employees" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

					var cell_data = data_model.get_value_at (0, 0);
					return cell_data.get_string ();
				} catch (Error e) {
					critical ("Failed to get employee password from database: %s", e.message);
					return null;
				}
			}

			public void change_password (string password) {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE employees" +
					                                          "  SET password=##password::string" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("password").set_value_str (database.dh_string,
					                                                   Checksum.compute_for_string (ChecksumType.SHA256, password, -1));
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					critical ("Failed to update employee password in database: %s", e.message);
				}
			}

		}

	}

}
