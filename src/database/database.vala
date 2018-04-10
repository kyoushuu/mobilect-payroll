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

			public Database () throws ApplicationError {
				try {
					/* Create config directory with permission 0754 */
					var db_dir = "%s/%s".printf (Environment.get_user_config_dir (), PACKAGE);
					DirUtils.create_with_parents (db_dir, 0754);

					/* Connect to database */
					cnc = Connection.open_from_string ("SQLite",
					                                   "DB_DIR=%s;DB_NAME=%s".printf(db_dir, PACKAGE),
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
				} catch (Error e) {
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			private void execute_sql (string sql) throws Error {
				try {
					var stmt = cnc.parse_sql_string (sql, null);
					cnc.statement_execute_non_select (stmt, null, null);
				} catch (Error e) {
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public AdministratorList get_administrators () {
				var list = new AdministratorList ();
				list.database = this;

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
					                                 "  FROM administrators",
					                                 null);
					var data_model = cnc.statement_execute_select (stmt, null);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						list.add (get_administrator (data_model.get_value_at (0, i).get_int ()));
					}
				} catch (Error e) {
					list = new AdministratorList ();
					list.database = this;
				}

				return list;
			}

			public Administrator? get_administrator (int id) {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (id);

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
					                                 "  FROM administrators" +
					                                 "  WHERE id=##id::int",
					                                 out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					var data_model = cnc.statement_execute_select (stmt, stmt_params);

					if (data_model.get_n_rows () > 0) {
						return new Administrator (id, this);
					} else {
						return null;
					}
				} catch (Error e) {
					return null;
				}
			}

			public Administrator? get_administrator_with_username (string username) {
				Set stmt_params;

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
					                                 "  FROM administrators" +
					                                 "  WHERE username=##username::string",
					                                 out stmt_params);
					stmt_params.get_holder ("username").set_value_str (null, username);
					var data_model = cnc.statement_execute_select (stmt, stmt_params);

					if (data_model.get_n_rows () > 0) {
						return new Administrator (data_model.get_value_at (0, 0).get_int (), this);
					} else {
						return null;
					}
				} catch (Error e) {
					return null;
				}
			}

			public void add_administrator (string username, string password) throws ApplicationError {
				Set stmt_params;


				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO administrators (username, password)" +
					                                 "  VALUES (##username::string, ##password::string)",
					                                 out stmt_params);
					stmt_params.get_holder ("username").set_value_str (null, username);
					stmt_params.get_holder ("password").set_value_str (null, Checksum.compute_for_string (ChecksumType.SHA256, password, -1));
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
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

			public void add_employee (string lastname, string firstname, string middlename, string tin, string password, int rate) throws ApplicationError {
				Set stmt_params;
				var value_rate = Value (typeof (int));
				value_rate.set_int (rate);


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
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

			public TimeRecordList get_time_records () {
				var list = new TimeRecordList ();
				list.database = this;

				try {
					var stmt = cnc.parse_sql_string ("SELECT id, employee_id, start, end" +
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

			public TimeRecordList get_time_records_within_date (Date start, Date end) {
				var list = new TimeRecordList ();
				list.database = this;

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

					var value = Value (typeof (int));
					Holder holder;

					value.set_int (start.get_year ());
					holder = stmt_params.get_holder ("start_year");
					if (holder != null) holder.set_value (value);

					value.set_int (start.get_month ());
					holder = stmt_params.get_holder ("start_month");
					if (holder != null) holder.set_value (value);

					value.set_int (start.get_day ());
					holder = stmt_params.get_holder ("start_day");
					if (holder != null) holder.set_value (value);

					value.set_int (end.get_year ());
					holder = stmt_params.get_holder ("end_year");
					if (holder != null) holder.set_value (value);

					value.set_int (end.get_month ());
					holder = stmt_params.get_holder ("end_month");
					if (holder != null) holder.set_value (value);

					value.set_int (end.get_day ());
					holder = stmt_params.get_holder ("end_day");
					if (holder != null) holder.set_value (value);

					var data_model = cnc.statement_execute_select (stmt, stmt_params);

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

			public void add_time_record (int employee_id, DateTime start, DateTime? end) throws ApplicationError {
				Set stmt_params;
				var value_id = Value (typeof (int));
				var value_year = Value (typeof (int));
				var value_month = Value (typeof (int));
				var value_day = Value (typeof (int));

				value_id.set_int (employee_id);
				value_year.set_int (start.get_year ());
				value_month.set_int (start.get_month ());
				value_day.set_int (start.get_day_of_month ());

				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO time_records (employee_id, year, month, day, start, end)" +
					                                 "  VALUES (##employee_id::int, ##year::int, ##month::int, ##day::int, ##start::string, ##end::string::null)",
					                                 out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					stmt_params.get_holder ("year").set_value (value_year);
					stmt_params.get_holder ("month").set_value (value_month);
					stmt_params.get_holder ("day").set_value (value_day);
					stmt_params.get_holder ("start").set_value_str (this.dh_string, start.to_utc ().format ("%F %T"));
					stmt_params.get_holder ("end").set_value_str (this.dh_string, end != null? end.to_utc ().format ("%F %T") : null);
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (ApplicationError e) {
					throw e;
				} catch (Error e) {
					throw new ApplicationError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

		}

	}

}
