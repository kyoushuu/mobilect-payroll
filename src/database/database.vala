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

		public errordomain DatabaseError {
			BRANCH_SAME_NAME_EXISTS,
			ADMINISTRATOR_SAME_USERNAME_EXISTS,
			EMPLOYEE_SAME_NAME_EXISTS,
			TIME_RECORD_CONFLICT
		}

		public class Database : Object {

			public Connection cnc { get; private set; }
			public DataHandler dh_string { get; private set; }

			public BranchList branch_list { get; private set; }
			public EmployeeList employee_list { get; private set; }
			public AdministratorList administrator_list { get; private set; }


			public Database (string cnc_string) throws Error {
				/* Connect to database */
				cnc = Connection.open_from_string (null,
				                                   cnc_string,
				                                   null,
				                                   ConnectionOptions.NONE);

				dh_string = cnc.get_provider ().get_data_handler_g_type (cnc, typeof (string));

				/* Create branches table if doesn't exists */
				execute_sql ("CREATE TABLE IF NOT EXISTS branches (" +
				             "  id integer primary key autoincrement," +
				             "  name string not null" +
				             ")");

				/* Create employees table if doesn't exists */
				execute_sql ("CREATE TABLE IF NOT EXISTS employees (" +
				             "  id integer primary key autoincrement," +
				             "  lastname string not null," +
				             "  firstname string not null," +
				             "  middlename string not null," +
				             "  tin string not null," +
				             "  password string not null," +
				             "  rate integer," +
				             "  branch_id integer," +
				             "  regular boolean" +
				             ")");

				/* Create time_records table if doesn't exists */
				execute_sql ("CREATE TABLE IF NOT EXISTS time_records (" +
				             "  id integer primary key autoincrement," +
				             "  employee_id integer," +
				             "  year integer," +
				             "  month integer," +
				             "  day integer," +
				             "  start timestamp not null," +
				             "  end timestamp," +
				             "  straight_time boolean," +
				             "  include_break boolean" +
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
				Gda.Set stmt_params;
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

				branch_list = new BranchList (this);
				update_branches ();

				employee_list = new EmployeeList (this);
				update_employees ();

				administrator_list = new AdministratorList (this);
				update_administrators ();
			}

			private void execute_sql (string sql) {
				try {
					var stmt = cnc.parse_sql_string (sql, null);
					cnc.statement_execute_non_select (stmt, null, null);
				} catch (Error e) {
					warning ("Failed to execute SQL: %s", e.message);
				}
			}

			public void update_branches () {
				branch_list.remove_all ();

				try {
					var stmt = cnc.parse_sql_string ("SELECT id" +
					                                 "  FROM branches",
					                                 null);
					var data_model = cnc.statement_execute_select (stmt, null);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						branch_list.add (new Branch (data_model.get_value_at (0, i).get_int (), this));
					}
				} catch (Error e) {
					warning ("Failed to update branch list: %s", e.message);
				}
			}

			public void add_branch (string name) throws DatabaseError {
				Gda.Set stmt_params, last_insert_row;

				foreach (var branch in branch_list) {
					if (branch.name == name) {
						throw new DatabaseError.BRANCH_SAME_NAME_EXISTS (_("A branch with the same name exists in the database."));
					}
				}

				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO branches (name)" +
					                                 "  VALUES (##name::string)",
					                                 out stmt_params);
					stmt_params.get_holder ("name").set_value_str (null, name);
					cnc.statement_execute_non_select (stmt, stmt_params, out last_insert_row);
					if (last_insert_row != null) {
						branch_list.add (new Branch (last_insert_row.get_holder_value ("+0").get_int (), this));
					} else {
						update_branches ();
					}
				} catch (Error e) {
					warning ("Failed to add branch to database: %s", e.message);
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
					warning ("Failed to update administrator list: %s", e.message);
				}
			}

			public void add_administrator (string username, string password) throws DatabaseError {
				Gda.Set stmt_params, last_insert_row;

				foreach (var administrator in administrator_list) {
					if (administrator.username == username) {
						throw new DatabaseError.ADMINISTRATOR_SAME_USERNAME_EXISTS (_("An administrator with the same username exists in the database."));
					}
				}

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
					warning ("Failed to add administrator to database: %s", e.message);
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
					warning ("Failed to update employee list: %s", e.message);
				}
			}

			public void add_employee (string lastname, string firstname, string middlename, string tin, string password, int rate, Branch branch, bool regular) throws DatabaseError {
				Gda.Set stmt_params, last_insert_row;

				Value value_rate = rate;
				Value value_branch_id = branch.id;
				Value value_regular = regular;

				foreach (var employee in employee_list) {
					if (employee.lastname == lastname &&
					    employee.firstname == firstname &&
					    employee.middlename == middlename) {
						throw new DatabaseError.EMPLOYEE_SAME_NAME_EXISTS (_("An employee with the same name exists in the database."));
					}
				}

				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO employees (lastname, firstname, middlename, tin, password, rate, branch_id, regular)" +
					                                 "  VALUES (##lastname::string, ##firstname::string, ##middlename::string, ##tin::string, ##password::string, ##rate::int, ##branch_id::int, ##regular::boolean)",
					                                 out stmt_params);
					stmt_params.get_holder ("lastname").set_value_str (null, lastname);
					stmt_params.get_holder ("firstname").set_value_str (null, firstname);
					stmt_params.get_holder ("middlename").set_value_str (null, middlename);
					stmt_params.get_holder ("tin").set_value_str (null, tin);
					stmt_params.get_holder ("password").set_value_str (null, Checksum.compute_for_string (ChecksumType.SHA256, password, -1));
					stmt_params.get_holder ("rate").set_value (value_rate);
					stmt_params.get_holder ("branch_id").set_value (value_branch_id);
					stmt_params.get_holder ("regular").set_value (value_regular);
					cnc.statement_execute_non_select (stmt, stmt_params, out last_insert_row);
					if (last_insert_row != null) {
						employee_list.add (new Employee (last_insert_row.get_holder_value ("+0").get_int (), this));
					} else {
						update_employees ();
					}
				} catch (Error e) {
					warning ("Failed to add employee to database: %s", e.message);
				}
			}

			public TimeRecordList get_time_records_within_date (Date start, Date end) {
				var list = new TimeRecordList (this);

				if (start.compare (end) > 0) {
					end = start;
				}

				var stmt_str = "SELECT id FROM time_records WHERE ";
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
					Gda.Set stmt_params;
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
					list = new TimeRecordList (this);
					warning ("Failed to get time records from database: %s", e.message);
				}

				return list;
			}

			public TimeRecordList get_time_records_of_employee (Employee employee) requires (employee.database == this) {
				var list = new TimeRecordList (this);

				try {
					Gda.Set stmt_params;
					var stmt = cnc.parse_sql_string ("SELECT id FROM time_records" +
					                                 "  WHERE employee_id=##employee_id::int",
					                                 out stmt_params);

					Value value = (int) employee.id;
					stmt_params.get_holder ("employee_id").set_value (value);

					var data_model = cnc.statement_execute_select (stmt, stmt_params);

					for (int i = 0; i < data_model.get_n_rows (); i++) {
						Value cell_data = data_model.get_value_at (0, i);
						var time_record = new TimeRecord (cell_data.get_int (), this, null);

						list.add (time_record);
					}
				} catch (Error e) {
					list = new TimeRecordList (this);
					warning ("Failed to get time records from database: %s", e.message);
				}

				return list;
			}

			public void add_time_record (int employee_id, DateTime start, DateTime? end, bool straight_time, bool include_break, bool merge) throws DatabaseError {
				Gda.Set stmt_params;
				Value value_id = employee_id;
				Value value_year = (int) start.get_year ();
				Value value_month = (int) start.get_month ();
				Value value_day = (int) start.get_day_of_month ();
				Value value_straight_time = (bool) straight_time;
				Value value_include_break = (bool) include_break;

				var ostart = start;
				var oend = end;

				if (end != null) {
					Date startd = Date (), endd = Date ();
					startd.set_dmy ((DateDay) ostart.get_day_of_month (),
					                (DateMonth) ostart.get_month (),
					                (DateYear) ostart.get_year ());
					endd.set_dmy ((DateDay) oend.get_day_of_month (),
					              (DateMonth) oend.get_month (),
					              (DateYear) oend.get_year ());

					LinkedList<TimeRecord> conflicts = new LinkedList<TimeRecord> ();
					foreach (var time_record in get_time_records_within_date (startd, endd)) {
						if (time_record.employee.id != employee_id) {
							continue;
						}

						/* Check if the time records overlap */
						if (time_record.end.compare (ostart) > 0 &&
						    time_record.start.compare (oend) < 0) {
							conflicts.add (time_record);
						}
					}

					if (conflicts.size > 0) {
						if (merge) {
							foreach (var time_record in conflicts) {
								if (time_record.start.compare (ostart) < 0) {
									ostart = time_record.start;
								}
								if (time_record.end.compare (oend) > 0) {
									oend = time_record.end;
								}

								time_record.remove ();
							}
						} else {
							var msg = _("Conflict with another time record:");

							foreach (var time_record in conflicts) {
								msg += "\n\n" + _("Employee Name: %s\nStart: %s\nEnd: %s")
									.printf (time_record.employee.get_name (),
									         time_record.start.format (_("%a, %d %b, %Y %I:%M %p")),
									         time_record.end.format (_("%a, %d %b, %Y %I:%M %p")));
							}

							throw new DatabaseError.TIME_RECORD_CONFLICT (msg);
						}
					}
				}

				try {
					var stmt = cnc.parse_sql_string ("INSERT INTO time_records (employee_id, year, month, day, start, end, straight_time, include_break)" +
					                                 "  VALUES (##employee_id::int, ##year::int, ##month::int, ##day::int, ##start::string, ##end::string::null, ##straight_time::boolean, ##include_break::boolean)",
					                                 out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_id);
					stmt_params.get_holder ("year").set_value (value_year);
					stmt_params.get_holder ("month").set_value (value_month);
					stmt_params.get_holder ("day").set_value (value_day);
					stmt_params.get_holder ("start").set_value_str (this.dh_string, ostart.format ("%F %T"));
					stmt_params.get_holder ("end").set_value_str (this.dh_string, oend != null? oend.format ("%F %T") : null);
					stmt_params.get_holder ("straight_time").set_value (value_straight_time);
					stmt_params.get_holder ("include_break").set_value (value_include_break);
					cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					warning ("Failed to add time record to database: %s", e.message);
				}
			}

		}

	}

}
