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

		public class Administrator : Object {

			public int id { get; set; }
			public string username { get; set; }
			public TimeRecordList time_records { get; private set; }

			internal weak Database database { get; private set; }
			internal weak AdministratorList list { get; set; }

			public Administrator (int id, Database database) {
				this.id = id;
				this.database = database;


				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				time_records = new TimeRecordList ();
				time_records.database = database;


				if (id != 0) {
					try {
						/* Get administrator data from database */
						var stmt = database.cnc.parse_sql_string ("SELECT username" +
						                                          "  FROM administrators" +
						                                          "  WHERE id=##id::int",
						                                          out stmt_params);
						stmt_params.get_holder ("id").set_value (value_id);
						var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						var cell_data_username = data_model.get_value_at (0, 0);
						this.username = database.dh_string.get_str_from_value (cell_data_username);
					} catch (Error e) {
						stderr.printf ("Error: %s\n", e.message);
					}
				}
			}

			public void update () throws ApplicationError {
				Set stmt_params;
				var value_id = Value (typeof (int));

				value_id.set_int (this.id);

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE administrators" +
					                                          "  SET username=##username::string" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("username").set_value_str (database.dh_string, this.username);
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
					var stmt = database.cnc.parse_sql_string ("DELETE FROM administrators WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);

					stmt = database.cnc.parse_sql_string ("DELETE FROM time_records WHERE administrator_id=##administrator_id::int",
					                                      out stmt_params);
					stmt_params.get_holder ("administrator_id").set_value (value_id);
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
					                                          "  FROM administrators" +
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
