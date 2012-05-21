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
			public TimeRecordList time_records { get; private set; }

			internal weak Database database { get; private set; }
			internal weak EmployeeList list { get; set; }

			public Employee (int id, Database database) {
				this.id = id;
				this.database = database;


				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				time_records = new TimeRecordList ();
				time_records.database = database;


				if (id != 0) {
					try {
						/* Get employee data from database */
						var stmt = database.cnc.parse_sql_string ("SELECT lastname, firstname, middlename" +
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


						/* Get time records */
						stmt = database.cnc.parse_sql_string ("SELECT id, start, end" +
						                                      "  FROM time_records" +
						                                      "  WHERE employee_id=##employee_id::int",
						                                      out stmt_params);
						stmt_params.get_holder ("employee_id").set_value (value_id);
						data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						for (int i = 0; i < data_model.get_n_rows (); i++) {
							var time_record = new TimeRecord (data_model.get_value_at (0, i).get_int (), database, this);
							time_record.employee = this;
							time_records.add (time_record);
						}
					} catch (Error e) {
						stderr.printf ("Error: %s\n", e.message);
					}
				}
			}

			public string get_name () {
				return lastname + ", " + firstname + " " + middlename;
			}

			public int get_open_time_records_num () throws ApplicationError {
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
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public void log_employee_in () throws ApplicationError {
				database.add_time_record (this.id, new DateTime.now_local (), null);
			}

			public void log_employee_out () throws ApplicationError {
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
					stmt_params.get_holder ("end").set_value_str (database.dh_string, new DateTime.now_utc ().format ("%F %T"));
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (DataModelError.ROW_OUT_OF_RANGE_ERROR e) {
					throw new ApplicationError.EMPLOYEE_NOT_FOUND (_("Not logged in.").printf (id));
				} catch (Error e) {
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			private DateTime date_time_marginalize (DateTime dt) {
				int min = dt.get_minute ();
				double period = Math.round (min / 30.0);

				return dt
					.add_seconds (-dt.get_seconds ())
					.add_minutes (((int) period * 30) - min);
			}

			public double get_hours (Filter filter) {
				double hours_span = 0.0;
				DateTime record_start, record_end;

				Time time_start = filter.time_start;
				Time time_end = filter.time_end;
				Date date_start = filter.date_start;
				Date date_end = filter.date_end;

				int minutes =
					((time_end.hour * 60) + time_end.minute) -
					((time_start.hour * 60) + time_start.minute);
				if (minutes < 0) {
					minutes += 24 * 60;
				}

				var range_start = new DateTime.local (date_start.get_year (),
				                                      date_start.get_month (),
				                                      date_start.get_day (),
				                                      time_start.hour, time_start.minute, 0);
				var range_end = new DateTime.local (date_end.get_year (),
				                                    date_end.get_month (),
				                                    date_end.get_day (),
				                                    time_start.hour, time_start.minute, 0);
				range_end = range_end.add_minutes (minutes);

				foreach (var time_record in time_records) {
					if (time_record.end == null) {
						continue;
					}

					record_start = time_record.start;
					record_end = time_record.end;

					/* Check if time record date is in range */
					if ((record_start.compare (range_end) == -1 && record_end.compare (range_start) != -1) ||
					    (record_start.compare (range_end) != 1 && record_end.compare (range_start) == 1)) {
						/* Get times of record and period */
						var period_start = new DateTime.local (record_start.get_year (),
						                                       record_start.get_month (),
						                                       record_start.get_day_of_month (),
						                                       time_start.hour, time_start.minute, 0);
						var period_end = period_start.add_minutes (minutes);

						/* Check if time record date is in period */
						if ((record_start.compare (period_end) == -1 && record_end.compare (period_start) != -1) ||
						    (record_start.compare (period_end) != 1 && record_end.compare (period_start) == 1)) {
							/* Get span of paid period */
							var span_start = record_start.compare (period_start) == 1? record_start : period_start;
							var span_end = record_end.compare (period_end) == -1? record_end : period_end;

							/* Round to 30-minute boundaries */
							span_start = date_time_marginalize (span_start);
							span_end = date_time_marginalize (span_end);

							/* Get hours in between, per 30 mins each */
							hours_span += (int) (span_end.difference (span_start)/(TimeSpan.HOUR / 2)) / 2.0;

							stdout.printf ("Hours: %lf\n", (int) (span_end.difference (span_start)/(TimeSpan.HOUR / 2)) / 2.0);
						}
					}
				}

				return hours_span;
			}

			public void change_password (string password) throws ApplicationError {
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
				} catch (ApplicationError e) {
					throw e;
				} catch (Error e) {
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public void update () throws ApplicationError {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE employees" +
					                                          "  SET lastname=##lastname::string," +
					                                          "    firstname=##firstname::string," +
					                                          "    middlename=##middlename::string" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("lastname").set_value_str (database.dh_string, this.lastname);
					stmt_params.get_holder ("firstname").set_value_str (database.dh_string, this.firstname);
					stmt_params.get_holder ("middlename").set_value_str (database.dh_string, this.middlename);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (ApplicationError e) {
					throw e;
				} catch (Error e) {
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public void remove () throws ApplicationError {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

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
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public string get_password_checksum () throws ApplicationError {
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
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

		}

	}

}
