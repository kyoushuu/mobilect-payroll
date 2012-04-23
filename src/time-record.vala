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

		public class TimeRecord : Object {

			public int id { get; set; }

			private Employee _employee;
			public Employee employee {
				get {
					return _employee;
				}
				set {
					if (value != null) {
						_employee = value;
					}
				}
			}

			/* -1 if not found */
			public int employee_id {
				get {
					return _employee != null? _employee.id : -1;
				}
				set {
					var e = database.get_employee (value);
					if (e != null) {
						_employee = e;
					}
				}
			}

			public DateTime start { get; set; }
			public DateTime end { get; set; }

			internal weak Database database { get; private set; }
			internal weak TimeRecordList list { get; set; }

			public TimeRecord (int id, Database database, Employee? employee) {
				this.id = id;
				this.database = database;

				Value cell_data;
				var time_val = TimeVal ();

				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				if (id != 0) {
					/* Get data from database */
					try {
						var stmt = database.cnc.parse_sql_string ("SELECT employee_id, start, end" +
						                                          "  FROM time_records" +
						                                          "  WHERE id=##id::int",
						                                          out stmt_params);
						stmt_params.get_holder ("id").set_value (value_id);
						var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						if (employee != null) {
							this.employee = employee;
						} else {
							cell_data = data_model.get_value_at (0, 0);
							this.employee_id = cell_data.get_int ();
						}

						cell_data = data_model.get_value_at (1, 0);
						if (time_val.from_iso8601 (database.dh_string.get_str_from_value (cell_data).replace (" ", "T") + "Z")) {
							this.start = new DateTime.from_timeval_local (time_val);
						}

						cell_data = data_model.get_value_at (2, 0);
						if (time_val.from_iso8601 (database.dh_string.get_str_from_value (cell_data).replace (" ", "T") + "Z")) {
							this.end = new DateTime.from_timeval_local (time_val);
						}
					} catch (Error e) {
						stderr.printf ("Error: %s\n", e.message);
					}
				}
			}

			public string get_start_string (bool to_local) {
				var dt = this.start;

				if (to_local) {
					dt = dt.to_local ();
				} else {
					dt = dt.to_utc ();
				}

				return dt.format ("%F %T");
			}

			public string? get_end_string (bool to_local) {
				var dt = this.end;

				if (dt == null) {
					return null;
				}

				if (to_local) {
					dt = dt.to_local ();
				} else {
					dt = dt.to_utc ();
				}

				return dt.format ("%F %T");
			}

			public void update () throws DatabaseError {
				Set stmt_params;
				var value_id = Value (typeof (int));
				var value_employee_id = Value (typeof (int));

				value_id.set_int (this.id);
				value_employee_id.set_int (this.employee_id);

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE time_records" +
					                                          "  SET employee_id=##employee_id::int," +
					                                          "      start=##start::string," +
					                                          "      end=##end::string::null" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("employee_id").set_value (value_employee_id);
					stmt_params.get_holder ("start").set_value_str (database.dh_string, this.get_start_string (false));
					stmt_params.get_holder ("end").set_value_str (database.dh_string, this.get_end_string (false));
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
					var stmt = database.cnc.parse_sql_string ("DELETE FROM time_records" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					throw new DatabaseError.UNKNOWN (_("Unknown error occured: %s").printf (e.message));
				}
			}

		}

	}

}
