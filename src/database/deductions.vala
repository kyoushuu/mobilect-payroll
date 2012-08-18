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
using Gtk;


namespace Mobilect {

	namespace Payroll {

		public class Deductions : Object, TreeModel {

			public enum Category {
				TAX,
				LOAN,
				PAG_IBIG,
				SSS_LOAN,
				VALE,
				MOESALA_LOAN,
				MOESALA_SAVINGS,
				NUM
			}


			public enum Columns {
				EMPLOYEE,
				NUM
			}


			public int stamp { get; private set; }

			public Database database { public set; private get; }

			private int period;
			private EmployeeList list;
			private double[,] amount;


			public Deductions (Database database, int period) {
				this.database = database;
				this.stamp = (int) Random.next_int ();
				this.list = database.employee_list;

				set_period (period);
			}

			public Deductions.with_date (Database database, Date date) {
				this (database,
				      (date.get_year () * 12 * 2) +
				      ((date.get_month ()-1) * 2) +
				      (date.get_day () <= 15? 0 : 1));
			}


			public int get_period () {
				return this.period;
			}


			public void set_period (int period) {
				this.period = period;
				Gda.Set stmt_params;

				Value value_period = this.period;
				Value value_employee_id;

				this.amount = new double[list.size,Category.NUM];
				foreach (var employee in list) {
					var employee_index = list.index_of (employee);
					value_employee_id = employee.id;

					try {
						var stmt = database.cnc.parse_sql_string ("SELECT" +
						                                          "    tax, loan, pagibig, sssloan, vale," +
						                                          "    moesala_loan, moesala_savings" +
						                                          "  FROM deductions" +
						                                          "  WHERE employee_id=##employee_id::int" +
						                                          "  AND period=##period::int",
						                                          out stmt_params);
						stmt_params.get_holder ("employee_id").set_value (value_employee_id);
						stmt_params.get_holder ("period").set_value (value_period);
						var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

						if (data_model.get_n_rows () > 0) {
							for (var i = 0; i < Category.NUM; i++) {
								amount[employee_index, i] = (double) data_model.get_value_at (i, 0);
							}
						}
					} catch (Error e) {
						warning ("Failed to get deduction from database: %s", e.message);
					}
				}
			}

			public double get_deduction_with_category (Employee employee, Category category) requires (category >= 0 && category < Category.NUM) {
				var employee_index = list.index_of (employee);
				return amount[employee_index,category];
			}

			public void set_deduction_with_category (Employee employee, Category category, double value) requires (category >= 0 && category < Category.NUM) {
				var employee_index = list.index_of (employee);
				amount[employee_index, category] = value;


				Gda.Set stmt_params;

				Value value_period = this.period;
				Value value_employee_id = employee.id;
				Value value_amount;

				/* Check if in database */
				try {
					var stmt = database.cnc.parse_sql_string ("SELECT id" +
					                                          "  FROM deductions" +
					                                          "  WHERE employee_id=##employee_id::int" +
					                                          "  AND period=##period::int",
					                                          out stmt_params);
					stmt_params.get_holder ("employee_id").set_value (value_employee_id);
					stmt_params.get_holder ("period").set_value (value_period);
					var data_model = database.cnc.statement_execute_select (stmt, stmt_params);

					if (data_model.get_n_rows () > 0) {
						/* Update if exists */
						stmt = database.cnc.parse_sql_string ("UPDATE deductions" +
						                                      "  SET tax=##tax::gdouble," +
						                                      "      loan=##loan::gdouble," +
						                                      "      pagibig=##pagibig::gdouble," +
						                                      "      sssloan=##sssloan::gdouble," +
						                                      "      vale=##vale::gdouble," +
						                                      "      moesala_loan=##moesala_loan::gdouble," +
						                                      "      moesala_savings=##moesala_savings::gdouble" +
						                                      "  WHERE id=##id::int",
						                                      out stmt_params);
						stmt_params.get_holder ("id").set_value (data_model.get_value_at (0, 0));
					} else {
						/* Insert if not */
						stmt = database.cnc.parse_sql_string ("INSERT INTO" +
						                                      "  deductions (" +
						                                      "    employee_id, period," +
						                                      "    tax, loan, pagibig, sssloan, vale," +
						                                      "    moesala_loan, moesala_savings" +
						                                      "  )" +
						                                      "  VALUES (" +
						                                      "    ##employee_id::int," +
						                                      "    ##period::int," +
						                                      "    ##tax::gdouble," +
						                                      "    ##loan::gdouble," +
						                                      "    ##pagibig::gdouble," +
						                                      "    ##sssloan::gdouble," +
						                                      "    ##vale::gdouble," +
						                                      "    ##moesala_loan::gdouble," +
						                                      "    ##moesala_savings::gdouble" +
						                                      "  )",
						                                      out stmt_params);
						stmt_params.get_holder ("employee_id").set_value (value_employee_id);
						stmt_params.get_holder ("period").set_value (value_period);
					}

					/* Set each amount */
					for (var i = 0; i < Category.NUM; i++) {
						value_amount = amount[employee_index, i];
						stmt_params.get_holder (get_category_column_name (i)).set_value (value_amount);
					}

					/* Execute */
					database.cnc.statement_execute_non_select (stmt, stmt_params, null);
				} catch (Error e) {
					warning ("Failed to set deduction from database: %s", e.message);
				}
			}

			private static string get_category_column_name (Category category) requires (category >= 0 && category < Category.NUM) {
				switch (category) {
					case Category.TAX:
						return "tax";
					case Category.LOAN:
						return "loan";
					case Category.PAG_IBIG:
						return "pagibig";
					case Category.SSS_LOAN:
						return "sssloan";
					case Category.VALE:
						return "vale";
					case Category.MOESALA_LOAN:
						return "moesala_loan";
					case Category.MOESALA_SAVINGS:
						return "moesala_savings";
					default:
						return "<invalid category>";
				}
			}


			/* TreeModel implementation */
			public Type get_column_type (int index_) {
				if (index_ == Columns.EMPLOYEE) {
					return typeof (Employee);
				}
				index_--; /* Make it a category index */

				if (index_ >= 0 && index_ < Category.NUM) {
					return typeof (double);
				} else {
					return Type.INVALID;
				}
			}

			public TreeModelFlags get_flags () {
				return TreeModelFlags.LIST_ONLY | TreeModelFlags.ITERS_PERSIST;
			}

			public bool get_iter (out TreeIter iter, TreePath path) {
				/* we do not allow children */
				/* depth 1 = top level; a list only has top level nodes and no children */
				assert (path.get_depth () == 1);

				/* the n-th top level row */
				return create_iter (out iter, path.get_indices ()[0]);
			}

			public int get_n_columns () {
				return this.Columns.NUM + this.Category.NUM;
			}

			public TreePath? get_path (TreeIter iter) requires (iter.stamp == this.stamp) {
				var path = new TreePath ();
				path.append_index ((int) iter.user_data);

				return path;
			}

			public void get_value (TreeIter iter, int column, out Value value) requires (iter.stamp == this.stamp) {
				var id = (int) iter.user_data;

				if (column == Columns.EMPLOYEE) {
					value = (list as ArrayList<Employee>).get (id);
					return;
				}
				column--; /* Make it a category index */

				if (column >= 0 && column < Category.NUM) {
					value = amount[id, column];
				} else {
					value = Value (Type.INVALID);
				}
			}

			public bool iter_children (out TreeIter iter, TreeIter? parent) {
				if (parent != null) {
					iter = TreeIter ();
					return false;
				}

				return create_iter (out iter, 0);
			}

			public bool iter_has_child (TreeIter iter) {
				return false;
			}

			public int iter_n_children (TreeIter? iter) {
				if (iter != null) {
					return 0;
				}

				return list.size;
			}

			public bool iter_next (ref TreeIter iter) requires (iter.stamp == this.stamp) {
				return create_iter (out iter, ((int) iter.user_data) + 1);
			}

			public bool iter_nth_child (out TreeIter iter, TreeIter? parent, int n) {
				if (parent != null) {
					iter = TreeIter ();
					return false;
				}

				return create_iter (out iter, n);
			}

			public bool iter_parent (out TreeIter iter, TreeIter child) {
				iter = TreeIter ();
				return false;
			}

			private bool create_iter (out TreeIter iter, int index) {
				if ((index) < list.size) {
					/* We simply store a pointer to our custom record in the iter */
					iter = TreeIter () {
						stamp      = this.stamp,
						user_data  = (void*) index
					};
					return true;
				} else {
					iter = TreeIter ();
					return false;
				}
			}

		}

	}

}
