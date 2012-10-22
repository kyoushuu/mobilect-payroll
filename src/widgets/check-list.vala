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


using Gee;
using Gtk;


namespace Mobilect {

	namespace Payroll {

		public class CheckList : ArrayList<Object>, TreeModel {

			public int stamp { get; private set; }


			public enum Columns {
				OBJECT,
				CHECKED,
				NUM
			}


			public CheckList () {
				stamp = (int) Random.next_int ();
			}

			public new void add (Object object) {
				object.notify.connect ((o, p) => {
					TreeIter iter;
					create_iter (out iter, o as Object);
					row_changed (get_path (iter), iter);
				});
				(this as ArrayList<Object>).add (object);

				TreeIter iter;
				create_iter (out iter, object);
				row_inserted (get_path (iter), iter);
			}

			public new void remove (Object object) {
				TreeIter iter;
				create_iter (out iter, object);
				row_deleted (get_path (iter));

				(this as ArrayList<Object>).remove (object);
			}

			public new void remove_all () {
				var list = new Object[0];

				foreach (var object in this) {
					list += object;
				}

				foreach (var object in list) {
					remove (object);
				}
			}

			/* TreeModel implementation */
			public Type get_column_type (int index_) {
				switch (index_) {
					case Columns.OBJECT:
						return typeof (Object);
					case Columns.CHECKED:
						return typeof (bool);
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
				path.append_index (this.index_of (iter.user_data as Object));

				return path;
			}

			public void get_value (TreeIter iter, int column, out Value value) requires (iter_valid (iter)) {
				switch (column) {
					case Columns.OBJECT:
						value = iter.user_data as Object;
						break;
					case Columns.CHECKED:
						value = (bool) iter.user_data2;
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

				return get_iter_from_object (out iter, this.first ());
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
				return get_iter_with_index (out iter, this.index_of (iter.user_data as Object) + 1);
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
			public bool iter_valid (TreeIter iter) {
				return iter.stamp == this.stamp && iter.user_data != null;
			}

			public bool get_iter_from_object (out TreeIter iter, Object object) {
				if (object in this) {
					create_iter (out iter, object);
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

				var object = (this as ArrayList<Object>).get (index);

				assert (object != null);

				create_iter (out iter, object);

				return true;
			}

			private void create_iter (out TreeIter iter, Object object) {
				/* We simply store a pointer to our custom record in the iter */
				iter = TreeIter () {
					stamp      = this.stamp,
					user_data  = object,
					user_data2 = (void*) false
				};
			}

		}

	}

}
