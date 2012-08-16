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
using Config;


namespace Mobilect {

	namespace Payroll {

		public class Database : Object {

			public Connection cnc { get; private set; }
			public DataHandler dh_string { get; private set; }

			public EmployeeList employee_list { get; private set; }
			public AdministratorList administrator_list { get; private set; }


			public Database (Application app) throws Error {
				/* Create config directory with permission 0754 */
				var db_dir = Path.build_filename (Environment.get_user_config_dir (), PACKAGE);
				DirUtils.create_with_parents (db_dir, 0754);

				/* Connect to database */
				cnc = Connection.open_from_string (app.settings.main.get_string ("database-provider"),
				                                   "DB_DIR=%s;DB_NAME=%s".printf (db_dir, PACKAGE),
				                                   null,
				                                   ConnectionOptions.NONE);

				dh_string = cnc.get_provider ().get_data_handler_g_type (cnc, typeof (string));

				/* Create employees table if doesn't exists */
				execute_sql ("CREATE TABLE IF NOT EXISTS employees (" +
				             "  id integer primary key autoincrement," +
				             "  lastname string not null," +
				             "  firstname string not null," +
				             "  middlename string not null," +
				             "  tin string not null," +
				             "  password string not null," +
				             "  rate integer" +
				             ")");

				/* Create time_records table if doesn't exists */
				execute_sql ("CREATE TABLE IF NOT EXISTS time_records (" +
				             "  id integer primary key autoincrement," +
				             "  employee_id integer," +
				             "  year integer," +
				             "  month integer," +
				             "  day integer," +
				             "  start timestamp not null," +
				             "  end timestamp" +
				             ")");

				/* Create deductions table if doesn't exists */
				execute_sql ("CREATE TABLE IF NOT EXISTS deductions (" +
				             "  id integer primary key autoincrement," +
				             "  employee_id integer," +
				             "  period integer," +
				             "  tax double," +
				             "  loan double," +
				             "  pagibig double," +
				             "  sssloan double," +
				             "  vale double," +
				             "  moesala_loan double," +
				             "  moesala_savings double" +
				             ")");

				/* Create administrators table if doesn't exists */
				execute_sql ("CREATE TABLE IF NOT EXISTS administrators (" +
				             "  id integer primary key autoincrement," +
				             "  username string not null," +
				             "  password string not null" +
				             ")");

				/* Create holidays table if doesn't exists */
				execute_sql ("CREATE TABLE IF NOT EXISTS holidays (" +
				             "  id integer primary key autoincrement," +
				             "  year integer," +
				             "  month integer," +
				             "  day integer," +
				             "  type integer" +
				             ")");

				/* Create a default administrator if nothing exists */
				Set stmt_params;
				var stmt = cnc.parse_sql_string ("SELECT id" +
				                                 "  FROM administrators",
				                                 null);
				var data_model = cnc.statement_execute_select (stmt, null);
				if (data_model.get_n_rows () < 1) {
					stmt = cnc.parse_sql_string ("INSERT INTO administrators (id, username, password)" +
					                             "  VALUES (1, ##username::string, ##password::string)",
					                             out stmt_params);
					stmt_params.get_holder ("username")
						.set_value_str (null, "admin");
					stmt_params.get_holder ("password")
						.set_value_str (null,
						                Checksum.compute_for_string (ChecksumType.SHA256,
						                                             "admin", -1));
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				}

				employee_list = new EmployeeList ();
				update_employees ();

				administrator_list = new AdministratorList ();
				update_administrators ();
			}

			private void execute_sql (string sql) {
				try {
					var stmt = cnc.parse_sql_string (sql, null);
					cnc.statement_execute_non_select (stmt, null, null);
				} catch (Error e) {
					critical ("Failed to execute SQL: %s", e.message);
				}
			}

			public void update_administrators () {
				administrator_list.remove_all ();

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
					                                 "  FROM administrators",
					                                 null);
					var data_model = cnc.statement_execute_select (stmt, null);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						administrator_list.add (new Administrator (data_model.get_value_at (0, i).get_int (), this));
					}
				} catch (Error e) {
					critical ("Failed to update administrator list: %s", e.message);
				}
			}

			public void add_administrator (string username, string password) {
				Set stmt_params, last_insert_row;

				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO administrators (username, password)" +
					                                 "  VALUES (##username::string, ##password::string)",
					                                 out stmt_params);
					stmt_params.get_holder ("username").set_value_str (null, username);
					stmt_params.get_holder ("password").set_value_str (null, Checksum.compute_for_string (ChecksumType.SHA256, password, -1));
					cnc.statement_execute_non_select (stmt, stmt_params, out last_insert_row);
					if (last_insert_row != null) {
						administrator_list.add (new Administrator (last_insert_row.get_holder_value ("+0").get_int (), this));
					} else {
						update_administrators ();
					}
				} catch (Error e) {
					critical ("Failed to add administrator to database: %s", e.message);
				}
			}

			public void update_employees () {
				employee_list.remove_all ();

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
					                                 "  FROM employees",
					                                 null);
					var data_model = cnc.statement_execute_select (stmt, null);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						employee_list.add (new Employee (data_model.get_value_at (0, i).get_int (), this));
					}
				} catch (Error e) {
					critical ("Failed to update employee list: %s", e.message);
				}
			}

			public void add_employee (string lastname, string firstname, string middlename, string tin, string password, int rate) {
				Set stmt_params, last_insert_row;

				Value value_rate = rate;

				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO employees (lastname, firstname, middlename, tin, password, rate)" +
					                                 "  VALUES (##lastname::string, ##firstname::string, ##middlename::string, ##tin::string, ##password::string, ##rate::int)",
					                                 out stmt_params);
					stmt_params.get_holder ("lastname").set_value_str (null, lastname);
					stmt_params.get_holder ("firstname").set_value_str (null, firstname);
					stmt_params.get_holder ("middlename").set_value_str (null, middlename);
					stmt_params.get_holder ("tin").set_value_str (null, tin);
					stmt_params.get_holder ("password").set_value_str (null, Checksum.compute_for_string (ChecksumType.SHA256, password, -1));
					stmt_params.get_holder ("rate").set_value (value_rate);
					cnc.statement_execute_non_select (stmt, stmt_params, out last_insert_row);
					if (last_insert_row != null) {
						employee_list.add (new Employee (last_insert_row.get_holder_value ("+0").get_int (), this));
					} else {
						update_employees ();
					}
				} catch (Error e) {
					critical ("Failed to add employee to database: %s", e.message);
				}
			}

			public TimeRecordList get_time_records_within_date (Date start, Date end) {
				var list = new TimeRecordList ();

				if (start.compare (end) > 0) {
					end = start;
				}

				var stmt_str = "SELECT id, employee_id, start, end FROM time_records WHERE ";
				if (start.get_year () == end.get_year ()) {
					if (start.get_month () == end.get_month ()) {
						if (start.get_day () == end.get_day ()) {
							stmt_str += "year=##start_year::int AND month=##start_month::int AND day=##start_day::int";
						} else {
							stmt_str += "year=##start_year::int AND month=##start_month::int AND (day>=##start_day::int AND day<=##end_day::int)";
						}
					} else {
						stmt_str += "year=##start_year::int AND ((month=##start_month::int AND day>=##start_day::int) OR (month>##start_month::int AND month<##end_month::int) OR (month=##end_month::int AND day<=##end_day::int))";
					}
				} else {
					stmt_str += "(year=##start_year::int AND ((month=##start_month::int AND day>=##start_day::int) OR month>##start_month::int)) OR (year=##end_year::int AND ((month=##end_month::int AND day<=##end_day::int) OR month<##end_month::int)) OR (year>##start_year::int AND year<##end_year::int)";
				}

				try {
					Set stmt_params;
					var stmt = cnc.parse_sql_string (stmt_str, out stmt_params);

					Value value;
					Holder holder;

					holder = stmt_params.get_holder ("start_year");
					if (holder != null) {
						value = (int) start.get_year ();
						holder.set_value (value);
					}

					holder = stmt_params.get_holder ("start_month");
					if (holder != null) {
						value = (int) start.get_month ();
						holder.set_value (value);
					}

					holder = stmt_params.get_holder ("start_day");
					if (holder != null) {
						value = (int) start.get_day ();
						holder.set_value (value);
					}

					holder = stmt_params.get_holder ("end_year");
					if (holder != null) {
						value = (int) end.get_year ();
						holder.set_value (value);
					}

					holder = stmt_params.get_holder ("end_month");
					if (holder != null) {
						value = (int) end.get_month ();
						holder.set_value (value);
					}

					holder = stmt_params.get_holder ("end_day");
					if (holder != null) {
						value = (int) end.get_day ();
						holder.set_value (value);
					}

					var data_model = cnc.statement_execute_select (stmt, stmt_params);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						Value cell_data = data_model.get_value_at (0, i);
						var time_record = new TimeRecord (cell_data.get_int (), this, null);

						list.add (time_record);
					}
				} catch (Error e) {
					list = new TimeRecordList ();
					critical ("Failed to get time records fro database: %s", e.message);
				}

				return list;
			}

			public void add_time_record (int employee_id, DateTime start, DateTime? end) {
				Set stmt_params;
				Value value_id = employee_id;
				Value value_year = (int) start.get_year ();
				Value value_month = (int) start.get_month ();
				Value value_day = (int) start.get_day_of_month ();

				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO time_records (employee_id, year, month, day, start, end)" +
					                                 "  VALUES (##employee_id::int, ##year::int, ##month::int, ##day::int, ##start::string, ##end::string::null)",
					                                 out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					stmt_params.get_holder ("year").set_value (value_year);
					stmt_params.get_holder ("month").set_value (value_month);
					stmt_params.get_holder ("day").set_value (value_day);
					stmt_params.get_holder ("start").set_value_str (this.dh_string, start.format ("%F %T"));
					stmt_params.get_holder ("end").set_value_str (this.dh_string, end != null? end.format ("%F %T") : null);
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					critical ("Failed to add time record to database: %s", e.message);
				}
			}

		}

	}

}
