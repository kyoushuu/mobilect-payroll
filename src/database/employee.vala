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
using Gee;


namespace Mobilect {

	namespace Payroll {

		public errordomain EmployeeLoginError {
			WRONG_PASSWORD,
			ALREADY_LOGGED_IN,
			NOT_LOGGED_IN
		}

		public class Employee : Object {

			public int id { get; set; }
			public string lastname { get; set; }
			public string firstname { get; set; }
			public string middlename { get; set; }
			public string tin { get; set; }
			public bool regular { default = true; get; set; }
			public int rate { get; set; }
			public double rate_per_day {
				get { return rate / 26.0; }
				set { rate = (int) (value * 26.0); }
			}
			public double rate_per_hour {
				get { return rate / (26.0 * 8.0); }
				set { rate = (int) (value * 26.0 * 8.0); }
			}

			private Branch _branch;
			public Branch branch {
				get {
					return _branch;
				}
				set {
					if (value != null) {
						_branch = value;
					}
				}
			}

			/* -1 if not found */
			public int branch_id {
				get {
					return _branch != null? _branch.id : -1;
				}
				set {
					var e = database.branch_list.get_with_id (value);
					if (e != null) {
						_branch = e;
					}
				}
			}

			internal weak Database database { get; private set; }
			internal weak EmployeeList list { get; set; }

			public Employee (int id, Database database) {
				this.id = id;
				this.database = database;


				Gda.Set stmt_params;
				Value value_id = this.id;

				if (id != 0) {
					try {
						/* Get employee data from database */
						var stmt = database.cnc.parse_sql_string ("SELECT lastname, firstname, middlename, tin, rate, branch_id, regular" +
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
						this.rate = (int) cell_data_rate;

						if (branch != null) {
							this.branch = branch;
						} else {
							var cell_data_branch_id = data_model.get_value_at (5, 0);
							this.branch_id = (int) cell_data_branch_id;
						}

						var cell_data_regular = data_model.get_value_at (6, 0);
						this.regular = (bool) cell_data_regular;
					} catch (Error e) {
						warning ("Failed to get employee data from database: %s", e.message);
					}
				}
			}

			public string get_name () {
				return lastname + ", " + firstname + " " + middlename;
			}

			public int get_open_time_records_num () {
				Gda.Set stmt_params;
				Value value_id = this.id;

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
					warning ("Failed to get open time records of employee from database: %s", e.message);
					return -1;
				}
			}

			public void log_in (string password) throws EmployeeLoginError {
				if (!password_matches (password))
					throw new EmployeeLoginError.WRONG_PASSWORD (_("Wrong password"));

				if (get_open_time_records_num () > 0)
					throw new EmployeeLoginError.ALREADY_LOGGED_IN (_("You are already logged in."));

				try {
					database.add_time_record (this.id, new DateTime.now_local (), null, false, true, false);
				} catch (Error e) {
					warning ("Failed to add time record of employee to database: %s", e.message);
				}
			}

			public void log_out (string password) throws EmployeeLoginError {
				if (!password_matches (password))
					throw new EmployeeLoginError.WRONG_PASSWORD (_("Wrong password."));

				var open_time_records = database.get_time_records_of_employee (this).get_subset_open ();

				if (open_time_records.size < 1)
					throw new EmployeeLoginError.NOT_LOGGED_IN (_("Not logged in."));

				open_time_records.sort ((a, b) => { return a.id - b.id; });

				(open_time_records as ArrayList<TimeRecord>).get (0).close_now ();
			}

			public double get_hours (Filter filter, out LinkedList<Date?> dates = null) {
				int minutes;
				double hours, hours_span_curr, hours_span = 0.0;
				Time time_start, time_end;
				DateTime period_start, period_end;
				DateTime record_start, record_end;
				DateTime span_start, span_end;
				dates = new LinkedList<Date?> ();

				Gda.Set stmt_params;
				Value value_id = this.id;

				try {
					/* Get time records */
					var stmt = database.cnc.parse_sql_string ("SELECT id, start, end" +
					                                          "  FROM time_records" +
					                                          "  WHERE employee_id=##employee_id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						var time_record = new TimeRecord (data_model.get_value_at (0, i).get_int (), database, this);

						/* Open end cannot be computed */
						if (time_record.end == null) {
							continue;
						}

						/* Check if straight time values matches */
						if (filter.straight_time != time_record.straight_time) {
							continue;
						}

						/* Check time record against each affected dates */
						foreach (var date in filter.get_affected_dates (database)) {
							foreach (var period in filter.get_time_periods_with_break (time_record.include_break)) {
								time_start = period.start;
								time_end = period.end;

								//stdout.printf ("Period: %s - %s\n", time_start.to_string (), time_end.to_string ());

								period_start = new DateTime.local (date.get_year (),
								                                   date.get_month (),
								                                   date.get_day (),
								                                   time_start.hour, time_start.minute, 0);
								period_end = new DateTime.local (date.get_year (),
								                                 date.get_month (),
								                                 date.get_day (),
								                                 time_start.hour, time_start.minute, 0);

								minutes =
									((time_end.hour * 60) + time_end.minute) -
									((time_start.hour * 60) + time_start.minute);
								if (minutes < 0) {
									minutes += 24 * 60;
								}
								period_end = period_end.add_minutes (minutes);

								record_start = time_record.start;
								record_end = time_record.end;


								/* Check if period is not in time record */
								if (period_end.compare (record_start) <= 0 ||
								    period_start.compare (record_end) >= 0) {
									//stdout.printf ("Outside range, skipping...\n");
									continue;
								}

								/* Get span of paid period */
								span_start = record_start.compare (period_start) > 0?
									record_start : period_start;
								span_end = record_end.compare (period_end) < 0?
									record_end : period_end;

								/* Get hours spanned */
								hours = span_end.difference (span_start) / TimeSpan.HOUR;
								hours_span_curr = Math.floor (hours/filter.period) * filter.period;

								//stdout.printf ("Hours: %lf\n", hours);

								/* Allow 1/4 of period late */
								if (Math.floor ((hours + (filter.period/4)) / filter.period) >
								    Math.floor (hours / filter.period)) {
									hours_span_curr += filter.period;
								}

								if (filter.enlist) {
									/* Add to list */
									var curr_date = Date ();
									curr_date.set_dmy ((DateDay) span_start.get_day_of_month (),
									                   (DateMonth) span_start.get_month (),
									                   (DateYear) span_start.get_year ());
									dates.add (curr_date);
									//stdout.printf ("%s: %lf\n", Report.format_date (curr_date, "%b %d"), hours_span_curr);
								}

								hours_span += hours_span_curr;
							}
						}
					}
				} catch (Error e) {
					warning ("Failed to get time record of employee from database: %s", e.message);
				}

				return hours_span;
			}

			public void update () {
				Gda.Set stmt_params;
				Value value_id = this.id;
				Value value_rate = this.rate;
				Value value_branch_id = this.branch.id;
				Value value_regular = this.regular;

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE employees" +
					                                          "  SET lastname=##lastname::string," +
					                                          "    firstname=##firstname::string," +
					                                          "    middlename=##middlename::string," +
					                                          "    tin=##tin::string," +
					                                          "    rate=##rate::int," +
					                                          "    branch_id=##branch_id::int," +
					                                          "    regular=##regular::boolean" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("lastname").set_value_str (database.dh_string, this.lastname);
					stmt_params.get_holder ("firstname").set_value_str (database.dh_string, this.firstname);
					stmt_params.get_holder ("middlename").set_value_str (database.dh_string, this.middlename);
					stmt_params.get_holder ("tin").set_value_str (database.dh_string, this.tin);
					stmt_params.get_holder ("rate").set_value (value_rate);
					stmt_params.get_holder ("branch_id").set_value (value_branch_id);
					stmt_params.get_holder ("regular").set_value (value_regular);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					warning ("Failed to update employee in database: %s", e.message);
				}
			}

			public void remove () {
				Gda.Set stmt_params;
				Value value_id = this.id;

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

					stmt = database.cnc.parse_sql_string ("DELETE FROM deductions WHERE employee_id=##employee_id::int",
					                                      out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					warning ("Failed to remove employee from database: %s", e.message);
				}
			}

			public bool password_matches (string password) {
				return get_password_checksum () ==
					Checksum.compute_for_string (ChecksumType.SHA256, password, -1);
			}

			private string? get_password_checksum () {
				Gda.Set stmt_params;
				Value value_id = this.id;

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
					warning ("Failed to get employee password from database: %s", e.message);
					return null;
				}
			}

			public void change_password (string password) {
				Gda.Set stmt_params;
				Value value_id = this.id;

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
					warning ("Failed to update employee password in database: %s", e.message);
				}
			}

		}

	}

}
