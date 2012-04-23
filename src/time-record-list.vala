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

		public class TimeRecordList : ArrayList<TimeRecord>, TreeModel {

			public int stamp { get; private set; }

			internal weak Database database { get; set; }

			public enum Columns {
				OBJECT,
				ID,
				EMPLOYEE,
				EMPLOYEE_ID,
				START,
				END,
				EMPLOYEE_STRING,
				START_STRING,
				END_STRING,
				NUM
			}

			public TimeRecordList () {
				stamp = (int) Random.next_int ();
			}

			public new void add (TimeRecord time_record) {
				time_record.list = this;
				(this as ArrayList<TimeRecord>).add (time_record);
			}

			public bool contains_id (int id) {
				foreach (var time_record in this) {
					if (time_record.id == id) {
						return true;
					}
				}

				return false;
			}

			public TimeRecord? get_with_id (int id) {
				foreach (var time_record in this) {
					if (time_record.id == id) {
						return time_record;
					}
				}

				return null;
			}

			public TimeRecord? get_with_employee_id (int employee_id) {
				foreach (var time_record in this) {
					if (time_record.employee_id == employee_id) {
						return time_record;
					}
				}

				return null;
			}

			/* TreeModel implementation */
			public Type get_column_type (int index_) {
				switch (index_) {
					case Columns.OBJECT:
						return typeof (TimeRecord);
						break;
					case Columns.ID:
						return typeof (int);
						break;
					case Columns.EMPLOYEE:
						return typeof (Employee);
						break;
					case Columns.EMPLOYEE_ID:
						return typeof (int);
						break;
					case Columns.START:
						return typeof (DateTime);
						break;
					case Columns.END:
						return typeof (DateTime);
						break;
					case Columns.EMPLOYEE_STRING:
						return typeof (string);
						break;
					case Columns.START_STRING:
						return typeof (string);
						break;
					case Columns.END_STRING:
						return typeof (string);
						break;
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

			public TreePath? get_path (TreeIter iter) requires (iter.user_data != null) {
				var path = new TreePath ();
				path.append_index (this.index_of (iter.user_data as TimeRecord));

				return path;
			}

			public void get_value (TreeIter iter, int column, out Value value) {
				value.init (get_column_type (column));
				var time_record = iter.user_data as TimeRecord;

				switch (column) {
					case Columns.OBJECT:
						value.set_object (time_record);
						break;
					case Columns.ID:
						value.set_int (time_record.id);
						break;
					case Columns.EMPLOYEE:
						value.set_object (time_record.employee);
						break;
					case Columns.EMPLOYEE_ID:
						value.set_int (time_record.employee_id);
						break;
					case Columns.START:
						value.set_pointer (time_record.start);
						break;
					case Columns.END:
						value.set_pointer (time_record.end);
						break;
					case Columns.EMPLOYEE_STRING:
						value.set_string (time_record.employee != null? time_record.employee.get_name () : null);
						break;
					case Columns.START_STRING:
						value.set_string (time_record.get_start_string (true));
						break;
					case Columns.END_STRING:
						value.set_string (time_record.get_end_string (true));
						break;
				}
			}

			public bool iter_children (out TreeIter iter, TreeIter? parent) {
				if (parent != null || this.size == 0) {
					iter = TreeIter ();
					return false;
				}

				return get_iter_time_record (out iter, this.first ());
			}

			public bool iter_has_child (TreeIter iter) {
				return false;
			}

			public int iter_n_children (TreeIter? iter) {
				if (iter != null) {
					return 0;
				}

				return this.size;
			}

			public bool iter_next (ref TreeIter iter) {
				return get_iter_with_index (out iter, this.index_of (iter.user_data as TimeRecord) + 1);
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
			public bool get_iter_time_record (out TreeIter iter, TimeRecord time_record) {
				if (time_record in this) {
					create_iter (out iter, time_record);
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

				var time_record = (this as ArrayList<TimeRecord>).get (index);

				assert (time_record != null);

				create_iter (out iter, time_record);

				return true;
			}

			private void create_iter (out TreeIter iter, TimeRecord time_record) {
				/* We simply store a pointer to our custom record in the iter */
				iter = TreeIter () {
					stamp      = this.stamp,
					user_data  = time_record
				};
			}

		}

	}

}
