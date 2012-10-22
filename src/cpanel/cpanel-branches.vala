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


using Gtk;
using Gdk;


namespace Mobilect {

	namespace Payroll {

		public class CPanelBranches : CPanelTab {

			public const string ACTION = "cpanel-branches";
			public const string ACTION_ADD = "cpanel-branches-add";
			public const string ACTION_REMOVE = "cpanel-branches-remove";
			public const string ACTION_PROPERTIES = "cpanel-branches-properties";
			public const string ACTION_SELECT_ALL = "cpanel-branches-select-all";
			public const string ACTION_DESELECT_ALL = "cpanel-branches-deselect-all";
			public const string ACTION_SORT_BY = "cpanel-branches-sort-by";
			public const string ACTION_REFRESH = "cpanel-branches-refresh";

			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }
			public BranchList list;


			public CPanelBranches (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-branches-ui.xml");

				this.list = this.cpanel.window.app.database.branch_list;

				sort = new TreeModelSort.with_model (this.list);
				sort.set_sort_func (BranchList.Columns.NAME, (model, a, b) => {
					var branch1 = a.user_data as Branch;
					var branch2 = b.user_data as Branch;

					return strcmp (branch1.name,
					               branch2.name);
				});


				push_composite_child ();


				var sw = new ScrolledWindow (null, null);
				this.add (sw);
				sw.show ();

				tree_view = new TreeView.with_model (sort);
				tree_view.expand = true;
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
				tree_view.search_column = (int) BranchList.Columns.NAME;
				tree_view.row_activated.connect ((t, p, c) => {
					properties_action ();
				});
				tree_view.button_press_event.connect ((w, e) => {
					/* Is not right-click? */
					if (e.button != 3) {
						return false;
					}

					return show_popup (3, e.time);
				});
				tree_view.popup_menu.connect ((w) => {
					return show_popup (0, get_current_event_time ());
				});
				sw.add (tree_view);
				tree_view.show ();

				var column = new TreeViewColumn.with_attributes (_("Name"),
				                                                 new CellRendererText (),
				                                                 "text", BranchList.Columns.NAME);
				column.sort_column_id = BranchList.Columns.NAME;
				column.expand = true;
				column.reorderable = true;
				column.resizable = true;
				tree_view.append_column (column);


				pop_composite_child ();


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						accelerator = _("<Control>I"),
						tooltip = _("Add an branch to database"),
						callback = (a) => {
							add_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_REMOVE,
						stock_id = Stock.REMOVE,
						accelerator = _("Delete"),
						tooltip = _("Remove the selected branches from database"),
						callback = (a) => {
							remove_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PROPERTIES,
						stock_id = Stock.PROPERTIES,
						accelerator = _("<Alt>Return"),
						tooltip = _("Edit information about the selected branches"),
						callback = (a) => {
							properties_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_SELECT_ALL,
						stock_id = Stock.SELECT_ALL,
						accelerator = _("<Control>A"),
						tooltip = _("Select all branches"),
						callback = (a) => {
							tree_view.get_selection ().select_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_DESELECT_ALL,
						label = _("_Deselect All"),
						accelerator = _("<Shift><Control>A"),
						tooltip = _("Deselects all selected branches"),
						callback = (a) => {
							tree_view.get_selection ().unselect_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_SORT_BY,
						label = _("_Sort By..."),
						tooltip = _("Sort the view using a column"),
						callback = (a) => {
							var dialog = new SortTreeViewDialog (this.cpanel.window,
							                                     tree_view);
							dialog.response.connect ((d, r) => {
								if (r == ResponseType.ACCEPT ||
								    r == ResponseType.REJECT) {
									d.destroy ();
								}
							});
							dialog.show ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_REFRESH,
						stock_id = Stock.REFRESH,
						accelerator = _("<Control>R"),
						tooltip = _("Reload information from database"),
						callback = (a) => {
							this.cpanel.window.app.database.update_branches ();
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_ADD).is_important = true;
				this.action_group.get_action (ACTION_REMOVE).sensitive = false;
				this.action_group.get_action (ACTION_PROPERTIES).sensitive = false;
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().count_selected_rows () > 0;
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_PROPERTIES).sensitive = selected;
				});
			}


			private GLib.List<Branch> get_selected (TreeSelection selection) {
				var branches = new GLib.List<Branch>();

				foreach (var p in selection.get_selected_rows (null)) {
					TreePath path;
					TreeIter iter;

					path = sort.convert_path_to_child_path (p);
					list.get_iter (out iter, path);
					branches.append (this.list.get_from_iter (iter));
				}

				return branches;
			}

			private void add_action () {
				var database = this.cpanel.window.app.database;
				var branch = new Branch (0, database);

				var dialog = new BranchEditDialog (_("Add Branch"),
				                                   this.cpanel.window,
				                                   branch);
				dialog.help_link_id = "branches-add";
				dialog.action = Stock.ADD;

				dialog.response.connect ((d, r) => {
					if (r == ResponseType.ACCEPT) {
						dialog.hide ();
						database.add_branch (branch.name);
						dialog.destroy ();
					} else if (r == ResponseType.REJECT) {
						dialog.destroy ();
					}
				});
				dialog.show ();
			}

			private void remove_action () {
				var selection = tree_view.get_selection ();
				var branches = get_selected (selection);

				int selected_count = selection.count_selected_rows ();
				if (selected_count < 1) {
					return;
				}

				if (this.list.size - selected_count < 1) {
					this.cpanel.window.show_error_dialog (ngettext ("Can't remove selected branch",
					                                                "Can't remove selected branches",
					                                                selected_count),
					                                      _("There should be at least one branch."));

					return;
				}

				var dialog = new MessageDialog (this.cpanel.window,
				                                DialogFlags.MODAL,
				                                MessageType.WARNING,
				                                ButtonsType.NONE,
				                                ngettext ("Are you sure you want to remove the selected branch?",
				                                          "Are you sure you want to remove the %d selected branches?",
				                                          selected_count).printf (selected_count));
				dialog.secondary_text = ngettext ("All information about this branch will be deleted and cannot be restored.",
				                                  "All information about these branches will be deleted and cannot be restored.",
				                                  selected_count);
				dialog.add_buttons (Stock.CANCEL, ResponseType.REJECT,
				                    Stock.DELETE, ResponseType.ACCEPT);
				dialog.set_alternative_button_order (ResponseType.ACCEPT, ResponseType.REJECT);

				if (dialog.run () == ResponseType.ACCEPT) {
					dialog.hide ();
					foreach (var branch in branches) {
						branch.remove ();
					}
				}

				dialog.destroy ();
			}

			private void properties_action () {
				var selection = tree_view.get_selection ();
				var branches = get_selected (selection);

				foreach (var branch in branches) {
					var dialog = new BranchEditDialog (_("Branch Properties"),
					                                   this.cpanel.window,
					                                   branch);
					dialog.help_link_id = "branches-edit";
					dialog.action = Stock.SAVE;
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							dialog.hide ();
							dialog.branch.update ();
							dialog.destroy ();
						} else if (r == ResponseType.REJECT) {
							dialog.destroy ();
						}
					});
					dialog.show ();
				}
			}

			private bool show_popup (uint button, uint32 time) {
				/* Has any selected rows? */
				if (tree_view.get_selection ().count_selected_rows () <= 0) {
					return false;
				}

				var menu = cpanel.window.ui_manager.get_widget ("/popup-branches") as Gtk.Menu;
				menu.popup (null, null, null, button, time);
				return true;
			}

		}

	}

}
