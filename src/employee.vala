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
						var stmt = database.cnc.parse_sql_string ("SELECT lastname, firstname" +
						                                          "  FROM employees" +
						                                          "  WHERE id=##id::int",
						                                          out stmt_params);
						stmt_params.get_holder ("id").set_value (value_id);
						var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						var cell_data_lastname = data_model.get_value_at (0, 0);
						this.lastname = database.dh_string.get_str_from_value (cell_data_lastname);

						var cell_data_firstname = data_model.get_value_at (1, 0);
						this.firstname = database.dh_string.get_str_from_value (cell_data_firstname);


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
				return lastname + ", " + firstname;
			}

			public int get_open_time_records_num () throws DatabaseError {
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
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public void log_employee_in () throws DatabaseError {
				database.add_time_record (this.id, new DateTime.now_local (), null);
			}

			public void log_employee_out () throws DatabaseError {
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
				} catch (DataModelError.ROW_OUT_OF_RANGE_ERROR e) {
					throw new DatabaseError.EMPLOYEE_NOT_FOUND (_("Not logged in.").printf (id));
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			private DateTime date_time_marginalize (DateTime dt, bool toceil) {
				int min = dt.get_minute ();
				double period = min / 30.0;

				if (toceil) {
					period = Math.ceil (period);
				} else {
					period = Math.floor (period);
				}

				var dt_new = dt.add_seconds (-dt.get_seconds ());

				return dt_new.add_minutes (((int) period * 30) - min);
			}

			public void update () throws DatabaseError {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE employees" +
					                                          "  SET lastname=##lastname::string," +
					                                          "    firstname=##firstname::string" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("lastname").set_value_str (database.dh_string, this.lastname);
					stmt_params.get_holder ("firstname").set_value_str (database.dh_string, this.firstname);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (DatabaseError e) {
					throw e;
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public void remove () throws DatabaseError {
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
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public string get_password_checksum () throws DatabaseError {
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
				} catch (DataModelError.ROW_OUT_OF_RANGE_ERROR e) {
					throw new DatabaseError.USERNAME_NOT_FOUND (_("Employee \"%d\" not found.").printf (id));
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

		}

	}

}
