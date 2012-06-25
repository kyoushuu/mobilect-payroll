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

		public class EmployeeList : ArrayList<Employee>, TreeModel {

			public int stamp { get; private set; }

			internal weak Database database { get; set; }
			public Filter filter { get; set; }


			public enum Columns {
				OBJECT,
				ID,
				LASTNAME,
				FIRSTNAME,
				MIDDLENAME,
				NAME,
				TIN,
				RATE,
				HOURRATE,
				HOURS,
				NUM
			}


			public EmployeeList () {
				stamp = (int) Random.next_int ();
			}

			public new void add (Employee employee) {
				employee.list = this;
				(this as ArrayList<Employee>).add (employee);
			}

			public bool contains_id (int id) {
				foreach (var employee in this) {
					if (employee.id == id) {
						return true;
					}
				}

				return false;
			}

			public bool contains_name (string name) {
				return get_with_name (name) != null;
			}

			public Employee? get_with_id (int id) {
				foreach (var employee in this) {
					if (employee.id == id) {
						return employee;
					}
				}

				return null;
			}

			public Employee? get_with_name (string name) {
				foreach (var employee in this) {
					if (employee.get_name () == name) {
						return employee;
					}
				}

				return null;
			}

			/* TreeModel implementation */
			public Type get_column_type (int index_) {
				switch (index_) {
					case Columns.OBJECT:
						return typeof (Employee);
					case Columns.ID:
						return typeof (int);
					case Columns.LASTNAME:
						return typeof (string);
					case Columns.FIRSTNAME:
						return typeof (string);
					case Columns.MIDDLENAME:
						return typeof (string);
					case Columns.NAME:
						return typeof (string);
					case Columns.TIN:
						return typeof (string);
					case Columns.RATE:
						return typeof (int);
					case Columns.HOURRATE:
						return typeof (double);
					case Columns.HOURS:
						return typeof (double);
					default:
						return Type.INVALID;
				}
			}

			public TreeModelFlags get_flags () {
				return TreeModelFlags.LIST_ONLY | TreeModelFlags.ITERS_PERSIST;
			}

			public bool get_iter (out TreeIter iter, TreePath path) {
				/* we do not allow children */
				/* depth 1 = top level; a list only has top level nodes and no children */
				assert (path.get_depth() == 1);

				/* the n-th top level row */
				return get_iter_with_index (out iter, path.get_indices()[0]);
			}

			public int get_n_columns () {
				return this.Columns.NUM;
			}

			public TreePath? get_path (TreeIter iter) requires (iter.stamp == this.stamp) requires (iter.user_data != null) {
				var path = new TreePath ();
				path.append_index (this.index_of (iter.user_data as Employee));

				return path;
			}

			public void get_value (TreeIter iter, int column, out Value value) requires (iter.stamp == this.stamp) requires (iter.user_data != null) {
				value = Value (get_column_type (column));
				var record = iter.user_data as Employee;

				switch (column) {
					case Columns.OBJECT:
						value.set_object (record);
						break;
					case Columns.ID:
						value.set_int (record.id);
						break;
					case Columns.LASTNAME:
						value.set_string (record.lastname);
						break;
					case Columns.FIRSTNAME:
						value.set_string (record.firstname);
						break;
					case Columns.MIDDLENAME:
						value.set_string (record.middlename);
						break;
					case Columns.NAME:
						value.set_string (record.get_name ());
						break;
					case Columns.TIN:
						value.set_string (record.tin);
						break;
					case Columns.RATE:
						value.set_int (record.rate);
						break;
					case Columns.HOURRATE:
						value.set_double (record.get_rate_per_hour ());
						break;
					case Columns.HOURS:
						value.set_double (filter != null? record.get_hours (filter) : 0);
						break;
				}
			}

			public bool iter_children (out TreeIter iter, TreeIter? parent) {
				if (parent != null || this.size == 0) {
					iter = TreeIter ();
					return false;
				}

				return get_iter_employee (out iter, this.first ());
			}

			public bool iter_has_child (TreeIter iter) {
				return false;
			}

			public int iter_n_children (TreeIter? iter) requires (iter.stamp == this.stamp) {
				if (iter != null) {
					return 0;
				}

				return this.size;
			}

			public bool iter_next (ref TreeIter iter) requires (iter.stamp == this.stamp) {
				return get_iter_with_index (out iter, this.index_of (iter.user_data as Employee) + 1);
			}

			public bool iter_nth_child (out TreeIter iter, TreeIter? parent, int n) {
				if (parent != null || n >= this.size) {
					iter = TreeIter ();
					return false;
				}

				return get_iter_with_index (out iter, n);
			}

			public bool iter_parent (out TreeIter iter, TreeIter child) {
				iter = TreeIter ();
				return false;
			}

			/* Additional TreeModel implementation */
			public bool get_iter_employee (out TreeIter iter, Employee employee) {
				if (employee in this) {
					create_iter (out iter, employee);
					return true;
				} else {
					iter = TreeIter ();
					return false;
				}
			}

			public bool get_iter_with_index (out TreeIter iter, int index) {
				if (index >= this.size || index < 0) {
					iter = TreeIter ();
					return false;
				}

				var employee = (this as ArrayList<Employee>).get (index);

				assert (employee != null);

				create_iter (out iter, employee);

				return true;
			}

			public bool get_iter_with_id (out TreeIter iter, int id) {
				var employee = this.get_with_id (id);

				if (employee == null) {
					iter = TreeIter ();
					return false;
				}

				create_iter (out iter, employee);

				return true;
			}

			private void create_iter (out TreeIter iter, Employee employee) {
				/* We simply store a pointer to our custom record in the iter */
				iter = TreeIter () {
					stamp      = this.stamp,
					user_data  = employee
				};
			}

		}

	}

}
