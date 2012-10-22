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

		public class Branch : Object {

			public int id { get; set; }
			public string name { get; set; }

			internal weak Database database { get; private set; }
			internal weak BranchList list { get; set; }

			public Branch (int id, Database database) {
				this.id = id;
				this.database = database;


				Set stmt_params;
				Value value_id = this.id;


				if (id != 0) {
					try {
						/* Get branch data from database */
						var stmt = database.cnc.parse_sql_string ("SELECT name" +
						                                          "  FROM branches" +
						                                          "  WHERE id=##id::int",
						                                          out stmt_params);
						stmt_params.get_holder ("id").set_value (value_id);
						var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						var cell_data_name = data_model.get_value_at (0, 0);
						this.name = database.dh_string.get_str_from_value (cell_data_name);
					} catch (Error e) {
						warning ("Failed to get branch data from database: %s", e.message);
					}
				}
			}

			public void update () {
				Set stmt_params;
				Value value_id = this.id;

				try {
					var stmt = database.cnc.parse_sql_string ("UPDATE branches" +
					                                          "  SET name=##name::string" +
					                                          "  WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					stmt_params.get_holder ("name").set_value_str (database.dh_string, this.name);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					warning ("Failed to update branch in database: %s", e.message);
				}
			}

			public void remove () {
				Set stmt_params;
				Value value_id = this.id;

				if (list != null) {
					list.remove (this);
				}

				try {
					var stmt = database.cnc.parse_sql_string ("DELETE FROM branches WHERE id=##id::int",
					                                          out stmt_params);
					stmt_params.get_holder ("id").set_value (value_id);
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					warning ("Failed to remove branch from database: %s", e.message);
				}
			}

		}

	}

}
