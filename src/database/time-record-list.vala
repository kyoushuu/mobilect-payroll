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
				START,
				END,
				NUM
			}


			public TimeRecordList (Database database) {
				stamp = (int) Random.next_int ();

				this.database = database;
			}

			public new void add (TimeRecord time_record) {
				time_record.list = this;
				time_record.notify.connect ((o, p) => {
					TreeIter iter;
					create_iter (out iter, o as TimeRecord);
					row_changed (get_path (iter), iter);
				});
				(this as ArrayList<TimeRecord>).add (time_record);

				TreeIter iter;
				create_iter (out iter, time_record);
				row_inserted (get_path (iter), iter);
			}

			public new void remove (TimeRecord time_record) {
				TreeIter iter;
				create_iter (out iter, time_record);
				row_deleted (get_path (iter));

				time_record.list = null;
				(this as ArrayList<TimeRecord>).remove (time_record);
			}

			public new void remove_all () {
				var list = new TimeRecord[0];

				foreach (var time_record in this) {
					list += time_record;
				}

				foreach (var time_record in list) {
					remove (time_record);
				}
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

			public TimeRecordList get_subset_with_branch (Branch branch) requires (branch.database == database) {
				var list = new TimeRecordList (database);

				foreach (var time_record in this) {
					if (time_record.employee.branch == branch) {
						list.add (time_record);
					}
				}

				return list;
			}

			public TimeRecordList get_subset_with_employee (Employee employee) requires (employee.database == database) {
				var list = new TimeRecordList (database);

				foreach (var time_record in this) {
					if (time_record.employee == employee) {
						list.add (time_record);
					}
				}

				return list;
			}

			public TimeRecordList get_subset_open () {
				var list = new TimeRecordList (database);

				foreach (var time_record in this) {
					if (time_record.end == null) {
						list.add (time_record);
					}
				}

				return list;
			}


			/* TreeModel implementation */
			public Type get_column_type (int index_) {
				switch (index_) {
					case Columns.OBJECT:
						return typeof (TimeRecord);
					case Columns.ID:
						return typeof (int);
					case Columns.EMPLOYEE:
						return typeof (Employee);
					case Columns.START:
						return typeof (DateTime);
					case Columns.END:
						return typeof (DateTime);
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
				assert (path.get_depth () == 1);

				/* the n-th top level row */
				return get_iter_with_index (out iter, path.get_indices ()[0]);
			}

			public int get_n_columns () {
				return Columns.NUM;
			}

			public TreePath? get_path (TreeIter iter) requires (iter_valid (iter)) {
				var path = new TreePath ();
				path.append_index (this.index_of (get_from_iter (iter)));

				return path;
			}

			public void get_value (TreeIter iter, int column, out Value value) requires (iter_valid (iter)) {
				var time_record = get_from_iter (iter);

				switch (column) {
					case Columns.OBJECT:
						value = time_record;
						break;
					case Columns.ID:
						value = time_record.id;
						break;
					case Columns.EMPLOYEE:
						value = time_record.employee;
						break;
					case Columns.START:
						value = time_record.start;
						break;
					case Columns.END:
						value = time_record.end;
						break;
					default:
						value = Value (Type.INVALID);
						break;
				}
			}

			public bool iter_children (out TreeIter iter, TreeIter? parent) {
				if (parent != null || this.size == 0) {
					iter = TreeIter ();
					return false;
				}

				return get_iter_from_time_record (out iter, this.first ());
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

			public bool iter_next (ref TreeIter iter) requires (iter_valid (iter)) {
				return get_iter_with_index (out iter, this.index_of (get_from_iter (iter)) + 1);
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
			public TimeRecord get_from_iter (TreeIter iter) requires (iter_valid (iter)) {
				return iter.user_data as TimeRecord;
			}

			public bool iter_valid (TreeIter iter) {
				return iter.stamp == this.stamp && iter.user_data != null;
			}

			public bool get_iter_from_time_record (out TreeIter iter, TimeRecord time_record) {
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
