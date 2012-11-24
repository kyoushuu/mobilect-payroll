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
					var e = database.employee_list.get_with_id (value);
					if (e != null) {
						_employee = e;
					}
				}
			}

			public DateTime start { get; set; }
			public DateTime end { get; set; }

			public bool straight_time { get; set; }
			public bool include_break { default = true; get; set; }

			internal weak Database database { get; private set; }
			internal weak TimeRecordList list { get; set; }

			public TimeRecord (int id, Database database, Employee? employee) {
				this.id = id;
				this.database = database;

				pull ();
			}

			public void close_now () {
				end = new DateTime.now_local ();
				update ();
			}

			public void pull () {
				Value cell_data;
				var time_val = TimeVal ();

				Set stmt_params;
				Value value_id = this.id;

				if (id != 0) {
					/* Get data from database */
					try {
						var stmt = database.cnc.parse_sql_string ("SELECT employee_id, start, end, straight_time, include_break" +
						                                          "  FROM time_records" +
						                                          "  WHERE id=##id::int",
						                                          out stmt_params);
						stmt_params.get_holder ("id").set_value (value_id);
						var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						if (employee != null) {
							this.employee = employee;
						} else {
							cell_data = data_model.get_value_at (0, 0);
							this.employee_id = (int) cell_data;
						}

						cell_data = data_model.get_value_at (1, 0);
						if (time_val.from_iso8601 (database.dh_string.get_str_from_value (cell_data).replace (" ", "T"))) {
							this.start = new DateTime.from_timeval_local (time_val);
						}

						cell_data = data_model.get_value_at (2, 0);
						if (time_val.from_iso8601 (database.dh_string.get_str_from_value (cell_data).replace (" ", "T"))) {
							this.end = new DateTime.from_timeval_local (time_val);
						}

						cell_data = data_model.get_value_at (3, 0);
						this.straight_time = (bool) cell_data;

						cell_data = data_model.get_value_at (4, 0);
						this.include_break = (bool) cell_data;
					} catch (Error e) {
						warning ("Failed to get time record data from database: %s", e.message);
					}
				}
			}

			public void update () {
				Set stmt_params;
				Value value_id = this.id;
				Value value_employee_id = this.employee_id;
				Value value_year = (int) start.get_year ();
				Value value_month = (int) start.get_month ();
				Value value_day = (int) start.get_day_of_month ();
				Value value_straight_time = this.straight_time;
				Value value_include_break = this.include_break;

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE time_records" +
					                                          "  SET employee_id=##employee_id::int," +
					                                          "      year=##year::int," +
					                                          "      month=##month::int," +
					                                          "      day=##day::int," +
					                                          "      start=##start::string," +
					                                          "      end=##end::string::null," +
					                                          "      straight_time=##straight_time::boolean," +
					                                          "      include_break=##include_break::boolean" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("employee_id").set_value (value_employee_id);
					stmt_params.get_holder ("year").set_value (value_year);
					stmt_params.get_holder ("month").set_value (value_month);
					stmt_params.get_holder ("day").set_value (value_day);
					stmt_params.get_holder ("start").set_value_str (database.dh_string, this.start.format ("%F %T"));
					stmt_params.get_holder ("end").set_value_str (database.dh_string,
					                                              this.end != null?
					                                              this.end.format ("%F %T") : null);
					stmt_params.get_holder ("straight_time").set_value (value_straight_time);
					stmt_params.get_holder ("include_break").set_value (value_include_break);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					warning ("Failed to update time record in database: %s", e.message);
				}
			}

			public void remove () {
				Set stmt_params;
				Value value_id = this.id;

				if (list != null) {
					list.remove (this);
				}

				try {
					var stmt = database.cnc.parse_sql_string ("DELETE FROM time_records" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					warning ("Failed to remove time record from database: %s", e.message);
				}
			}

		}

	}

}
