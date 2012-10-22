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

		public class BranchList : ArrayList<Branch>, TreeModel {

			public int stamp { get; private set; }

			internal weak Database database { get; set; }

			public enum Columns {
				OBJECT,
				ID,
				NAME,
				NUM
			}


			public BranchList (Database database) {
				stamp = (int) Random.next_int ();

				this.database = database;
			}

			public new void add (Branch branch) {
				branch.list = this;
				branch.notify.connect ((o, p) => {
					TreeIter iter;
					create_iter (out iter, o as Branch);
					row_changed (get_path (iter), iter);
				});
				(this as ArrayList<Branch>).add (branch);

				TreeIter iter;
				create_iter (out iter, branch);
				row_inserted (get_path (iter), iter);
			}

			public new void remove (Branch branch) {
				TreeIter iter;
				create_iter (out iter, branch);
				row_deleted (get_path (iter));

				branch.list = null;
				(this as ArrayList<Branch>).remove (branch);
			}

			public new void remove_all () {
				var list = new Branch[0];

				foreach (var branch in this) {
					list += branch;
				}

				foreach (var branch in list) {
					remove (branch);
				}
			}

			public bool contains_id (int id) {
				foreach (var branch in this) {
					if (branch.id == id) {
						return true;
					}
				}

				return false;
			}

			public bool contains_name (string name) {
				return get_with_name (name) != null;
			}

			public Branch? get_with_id (int id) {
				foreach (var branch in this) {
					if (branch.id == id) {
						return branch;
					}
				}

				return null;
			}

			public Branch? get_with_name (string name) {
				foreach (var branch in this) {
					if (branch.name == name) {
						return branch;
					}
				}

				return null;
			}

			/* TreeModel implementation */
			public Type get_column_type (int index_) {
				switch (index_) {
					case Columns.OBJECT:
						return typeof (Branch);
					case Columns.ID:
						return typeof (int);
					case Columns.NAME:
						return typeof (string);
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
				var record = get_from_iter (iter);

				switch (column) {
					case Columns.OBJECT:
						value = record;
						break;
					case Columns.ID:
						value = record.id;
						break;
					case Columns.NAME:
						value = record.name;
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

				return get_iter_from_branch (out iter, this.first ());
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
			public Branch get_from_iter (TreeIter iter) requires (iter_valid (iter)) {
				return iter.user_data as Branch;
			}

			public bool iter_valid (TreeIter iter) {
				return iter.stamp == this.stamp && iter.user_data != null;
			}

			public bool get_iter_from_branch (out TreeIter iter, Branch branch) {
				if (branch in this) {
					create_iter (out iter, branch);
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

				var branch = (this as ArrayList<Branch>).get (index);

				assert (branch != null);

				create_iter (out iter, branch);

				return true;
			}

			public bool get_iter_with_id (out TreeIter iter, int id) {
				var branch = this.get_with_id (id);

				if (branch == null) {
					iter = TreeIter ();
					return false;
				}

				create_iter (out iter, branch);

				return true;
			}

			private void create_iter (out TreeIter iter, Branch branch) {
				/* We simply store a pointer to our custom record in the iter */
				iter = TreeIter () {
					stamp      = this.stamp,
					user_data  = branch
				};
			}

		}

	}

}
