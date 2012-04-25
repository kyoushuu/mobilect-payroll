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

		public errordomain DatabaseError {
			USERNAME_NOT_FOUND,
			EMPLOYEE_NOT_FOUND,
			UNKNOWN
		}

		public class Database : Object {

			private const string db_name = "mobilect-payroll";

			public Connection cnc { get; private set; }
			public DataHandler dh_string { get; private set; }

			public Database () throws DatabaseError {
				try {
					cnc = Connection.open_from_string ("SQLite",
					                                   "DB_DIR=.;DB_NAME=" + db_name,
					                                   null,
					                                   ConnectionOptions.NONE);

					dh_string = cnc.get_provider ().get_data_handler_g_type (cnc, typeof (string));

					execute_sql ("CREATE TABLE IF NOT EXISTS employees (" +
					             "  id integer primary key autoincrement," +
					             "  lastname string not null," +
					             "  firstname string not null," +
					             "  password string not null" +
					             ")");

					execute_sql ("CREATE TABLE IF NOT EXISTS time_records (" +
					             "  id integer primary key autoincrement," +
					             "  employee_id integer," +
					             "  start timestamp not null," +
					             "  end timestamp" +
					             ")");

					execute_sql ("CREATE TABLE IF NOT EXISTS administrators (" +
					             "  id integer primary key autoincrement," +
					             "  username string not null," +
					             "  password string not null" +
					             ")");

					Set stmt_params;
					var stmt = cnc.parse_sql_string ("INSERT OR IGNORE INTO administrators (id, username, password)" +
					                                 "  VALUES (1, ##username::string, ##password::string)",
					                                 out stmt_params);
					stmt_params.get_holder ("username")
						.set_value_str (null, "admin");
					stmt_params.get_holder ("password")
						.set_value_str (null,
						                Checksum.compute_for_string (ChecksumType.SHA256,
						                                             "admin", -1));
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			private void execute_sql (string sql) throws Error {
				try {
					var stmt = cnc.parse_sql_string (sql, null);
					cnc.statement_execute_non_select (stmt, null, null);
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public EmployeeList get_employees () {
				var list = new EmployeeList ();
				list.database = this;

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
					                                 "  FROM employees",
					                                 null);
					var data_model = cnc.statement_execute_select (stmt, null);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						list.add (get_employee (data_model.get_value_at (0, i).get_int ()));
					}
				} catch (Error e) {
					list = new EmployeeList ();
					list.database = this;
				}

				return list;
			}

			public Employee? get_employee (int id) {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (id);

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
					                                 "  FROM employees" +
					                                 "  WHERE id=##id::int",
					                                 out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					var data_model = cnc.statement_execute_select (stmt, stmt_params);

					if (data_model.get_n_rows () > 0) {
						return new Employee (id, this);
					} else {
						return null;
					}
				} catch (Error e) {
					return null;
				}
			}

			public void add_employee (string lastname, string firstname, string password) throws DatabaseError {
				Set stmt_params;


				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO employees (lastname, firstname, password)" +
					                                 "  VALUES (##lastname::string, ##firstname::string, ##password::string)",
					                                 out stmt_params);
					stmt_params.get_holder ("lastname").set_value_str (null, lastname);
					stmt_params.get_holder ("firstname").set_value_str (null, firstname);
					stmt_params.get_holder ("password").set_value_str (null, Checksum.compute_for_string (ChecksumType.SHA256, password, -1));
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public TimeRecordList get_time_records () {
				var list = new TimeRecordList ();
				list.database = this;

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
						                             "  FROM time_records",
						                             null);
					var data_model = cnc.statement_execute_select (stmt, null);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						Value cell_data = data_model.get_value_at (0, i);
						var time_record = new TimeRecord (cell_data.get_int (), this, null);

						list.add (time_record);
					}
				} catch (Error e) {
					list = new TimeRecordList ();
					list.database = this;
				}

				return list;
			}

			public void add_time_record (int employee_id, DateTime start, DateTime? end) throws DatabaseError {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (employee_id);

				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO time_records (employee_id, start, end)" +
					                                 "  VALUES (##employee_id::int, ##start::string, ##end::string::null)",
					                                 out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					stmt_params.get_holder ("start").set_value_str (this.dh_string, start.to_utc ().format ("%F %T"));
					stmt_params.get_holder ("end").set_value_str (this.dh_string, end != null? end.to_utc ().format ("%F %T") : null);
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (DatabaseError e) {
					throw e;
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public string get_admin_password_checksum (string username) throws DatabaseError {
				Set stmt_params;

				try {
					var stmt = cnc.parse_sql_string ("SELECT password" +
					                                 "  FROM administrators" +
					                                 "  WHERE username=##username::string",
					                                 out stmt_params);
					stmt_params.get_holder ("username").set_value_str (dh_string, username);
					var data_model = cnc.statement_execute_select (stmt, stmt_params);

					var cell_data = data_model.get_value_at (0, 0);
					return cell_data.get_string ();
				} catch (DataModelError.ROW_OUT_OF_RANGE_ERROR e) {
					throw new DatabaseError.USERNAME_NOT_FOUND (_("Username \"%s\" not found.").printf (username));
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

		}

	}

}
