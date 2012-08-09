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

		public class AdministratorList : ArrayList<Administrator>, TreeModel {

			public int stamp { get; private set; }

			internal weak Database database { get; set; }

			public enum Columns {
				OBJECT,
				ID,
				USERNAME,
				NUM
			}


			public AdministratorList () {
				stamp = (int) Random.next_int ();
			}

			public new void add (Administrator administrator) {
				administrator.list = this;
				administrator.notify.connect ((o, p) => {
					TreeIter iter;
					create_iter (out iter, o as Administrator);
					row_changed (get_path (iter), iter);
				});
				(this as ArrayList<Administrator>).add (administrator);

				TreeIter iter;
				create_iter (out iter, administrator);
				row_inserted (get_path (iter), iter);
			}

			public new void remove (Administrator administrator) {
				TreeIter iter;
				create_iter (out iter, administrator);
				row_deleted (get_path (iter));

				administrator.list = null;
				(this as ArrayList<Administrator>).remove (administrator);
			}

			public new void remove_all () {
				var list = new Administrator[0];

				foreach (var administrator in this) {
					list += administrator;
				}

				foreach (var administrator in list) {
					remove (administrator);
				}
			}

			public bool contains_id (int id) {
				foreach (var administrator in this) {
					if (administrator.id == id) {
						return true;
					}
				}

				return false;
			}

			public bool contains_username (string username) {
				return get_with_username (username) != null;
			}

			public Administrator? get_with_id (int id) {
				foreach (var administrator in this) {
					if (administrator.id == id) {
						return administrator;
					}
				}

				return null;
			}

			public Administrator? get_with_username (string username) {
				foreach (var administrator in this) {
					if (administrator.username == username) {
						return administrator;
					}
				}

				return null;
			}

			/* TreeModel implementation */
			public Type get_column_type (int index_) {
				switch (index_) {
					case Columns.OBJECT:
						return typeof (Administrator);
					case Columns.ID:
						return typeof (int);
					case Columns.USERNAME:
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
				return this.Columns.NUM;
			}

			public TreePath? get_path (TreeIter iter) requires (iter.stamp == this.stamp) requires (iter.user_data != null) {
				var path = new TreePath ();
				path.append_index (this.index_of (iter.user_data as Administrator));

				return path;
			}

			public void get_value (TreeIter iter, int column, out Value value) requires (iter.stamp == this.stamp) requires (iter.user_data != null) {
				var record = iter.user_data as Administrator;

				switch (column) {
					case Columns.OBJECT:
						value = record;
						break;
					case Columns.ID:
						value = record.id;
						break;
					case Columns.USERNAME:
						value = record.username;
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

				return get_iter_administrator (out iter, this.first ());
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

			public bool iter_next (ref TreeIter iter) requires (iter.stamp == this.stamp) {
				return get_iter_with_index (out iter, this.index_of (iter.user_data as Administrator) + 1);
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
			public bool get_iter_administrator (out TreeIter iter, Administrator administrator) {
				if (administrator in this) {
					create_iter (out iter, administrator);
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

				var administrator = (this as ArrayList<Administrator>).get (index);

				assert (administrator != null);

				create_iter (out iter, administrator);

				return true;
			}

			public bool get_iter_with_id (out TreeIter iter, int id) {
				var administrator = this.get_with_id (id);

				if (administrator == null) {
					iter = TreeIter ();
					return false;
				}

				create_iter (out iter, administrator);

				return true;
			}

			private void create_iter (out TreeIter iter, Administrator administrator) {
				/* We simply store a pointer to our custom record in the iter */
				iter = TreeIter () {
					stamp      = this.stamp,
					user_data  = administrator
				};
			}

		}

	}

}
