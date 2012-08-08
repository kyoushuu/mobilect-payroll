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

		public class CPanelAdministrators : CPanelTab {

			public const string ACTION = "cpanel-administrators";
			public const string ACTION_ADD = "cpanel-administrators-add";
			public const string ACTION_REMOVE = "cpanel-administrators-remove";
			public const string ACTION_PROPERTIES = "cpanel-administrators-properties";
			public const string ACTION_PASSWORD = "cpanel-administrators-password";
			public const string ACTION_SELECT_ALL = "cpanel-administrators-select-all";
			public const string ACTION_DESELECT_ALL = "cpanel-administrators-deselect-all";
			public const string ACTION_SORT_BY = "cpanel-administrators-sort-by";
			public const string ACTION_REFRESH = "cpanel-administrators-refresh";

			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }
			public AdministratorList list;


			public CPanelAdministrators (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-administrators-ui.xml");

				this.list = this.cpanel.window.app.database.administrator_list;

				sort = new TreeModelSort.with_model (this.list);
				sort.set_sort_func (AdministratorList.Columns.USERNAME, (model, a, b) => {
					var administrator1 = a.user_data as Administrator;
					var administrator2 = b.user_data as Administrator;

					return strcmp (administrator1.username,
					               administrator2.username);
				});


				push_composite_child ();


				tree_view = new TreeView.with_model (sort);
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
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
				tree_view.key_press_event.connect ((w, e) => {
					/* Has key modifier or not menu key? */
					if (e.state != 0 || e.keyval != Key.Menu) {
						return false;
					}

					return show_popup (0, e.time);
				});
				this.add (tree_view);
				tree_view.show ();

				var column = new TreeViewColumn.with_attributes (_("Username"),
				                                                 new CellRendererText (),
				                                                 "text", AdministratorList.Columns.USERNAME);
				column.sort_column_id = AdministratorList.Columns.USERNAME;
				column.expand = true;
				tree_view.append_column (column);


				pop_composite_child ();


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						accelerator = _("<Control>I"),
						tooltip = _("Add an administrator to database"),
						callback = (a) => {
							add_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_REMOVE,
						stock_id = Stock.REMOVE,
						accelerator = _("Delete"),
						tooltip = _("Remove the selected administrators from database"),
						callback = (a) => {
							remove_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PROPERTIES,
						stock_id = Stock.PROPERTIES,
						accelerator = _("<Alt>Return"),
						tooltip = _("Edit information about the selected administrators"),
						callback = (a) => {
							properties_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PASSWORD,
						stock_id = Stock.DIALOG_AUTHENTICATION,
						label = _("_Change Password"),
						tooltip = _("Change password of selected administrators"),
						callback = (a) => {
							change_password_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_SELECT_ALL,
						stock_id = Stock.SELECT_ALL,
						accelerator = _("<Control>A"),
						tooltip = _("Select all administrators"),
						callback = (a) => {
							tree_view.get_selection ().select_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_DESELECT_ALL,
						label = _("_Deselect All"),
						accelerator = _("<Shift><Control>A"),
						tooltip = _("Deselects all selected administrators"),
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
								d.destroy ();
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
							this.cpanel.window.app.database.update_administrators ();
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_ADD).is_important = true;
				this.action_group.get_action (ACTION_REMOVE).sensitive = false;
				this.action_group.get_action (ACTION_PROPERTIES).sensitive = false;
				this.action_group.get_action (ACTION_PASSWORD).sensitive = false;
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().count_selected_rows () > 0;
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_PROPERTIES).sensitive = selected;
					this.action_group.get_action (ACTION_PASSWORD).sensitive = selected;
				});
			}


			private GLib.List<Administrator> get_selected (TreeSelection selection) {
				var administrators = new GLib.List<Administrator>();

				foreach (var p in selection.get_selected_rows (null)) {
					Administrator administrator;
					TreePath path;
					TreeIter iter;

					path = sort.convert_path_to_child_path (p);
					list.get_iter (out iter, path);
					this.list.get (iter, AdministratorList.Columns.OBJECT, out administrator);
					administrators.append (administrator);
				}

				return administrators;
			}

			private void add_action () {
				var database = this.cpanel.window.app.database;
				var administrator = new Administrator (0, database);

				var dialog = new AdministratorEditDialog (_("Add Administrator"),
				                                          this.cpanel.window,
				                                          administrator);

				var password_label = new Label (_("_Password:"));
				password_label.use_underline = true;
				password_label.xalign = 0.0f;
				dialog.widget.grid.add (password_label);
				password_label.show ();

				var password_entry = new Entry ();
				password_entry.hexpand = true;
				password_entry.activates_default = true;
				password_entry.visibility = false;
				dialog.widget.grid.attach_next_to (password_entry,
				                                   password_label,
				                                   PositionType.RIGHT,
				                                   2, 1);
				password_entry.show ();

				dialog.response.connect ((d, r) => {
					d.hide ();

					if (r == ResponseType.ACCEPT) {
						database.add_administrator (administrator.username,
						                            password_entry.text);
					}

					d.destroy ();
				});
				dialog.show ();
			}

			private void remove_action () {
				var selection = tree_view.get_selection ();
				var administrators = get_selected (selection);

				int selected_count = selection.count_selected_rows ();
				if (selected_count < 1) {
					return;
				}

				if (this.list.size - selected_count < 1) {
					this.cpanel.window.show_error_dialog (ngettext ("Can't remove selected administrator",
					                                                "Can't remove selected administrators",
					                                                selected_count),
					                                      _("There should be at least one administrator."));

					return;
				}

				var dialog = new MessageDialog (this.cpanel.window,
				                                DialogFlags.MODAL,
				                                MessageType.WARNING,
				                                ButtonsType.NONE,
				                                ngettext ("Are you sure you want to remove the selected administrator?",
				                                          "Are you sure you want to remove the %d selected administrators?",
				                                          selected_count).printf (selected_count));
				dialog.secondary_text = ngettext ("All information about this administrator will be deleted and cannot be restored.",
				                                  "All information about these administrators will be deleted and cannot be restored.",
				                                  selected_count);
				dialog.add_buttons (Stock.CANCEL, ResponseType.REJECT,
				                    Stock.DELETE, ResponseType.ACCEPT);

				if (dialog.run () == ResponseType.ACCEPT) {
					dialog.hide ();
					foreach (var administrator in administrators) {
						administrator.remove ();
					}
				}

				dialog.destroy ();
			}

			private void properties_action () {
				var selection = tree_view.get_selection ();
				var administrators = get_selected (selection);

				foreach (var administrator in administrators) {
					var dialog = new AdministratorEditDialog (_("Administrator Properties"),
					                                          this.cpanel.window,
					                                          administrator);
					dialog.response.connect ((d, r) => {
						d.hide ();

						if (r == ResponseType.ACCEPT) {
							dialog.administrator.update ();
						}

						d.destroy ();
					});
					dialog.show ();
				}
			}

			private void change_password_action () {
				var selection = tree_view.get_selection ();
				var administrators = get_selected (selection);
				Administrator administrator;

				foreach (var a in administrators) {
					administrator = a;

					var dialog = new PasswordDialog (_("Change Password"),
					                                 this.cpanel.window);

					dialog.response.connect ((d, r) => {
						d.hide ();

						if (r == ResponseType.ACCEPT) {
							administrator.change_password (dialog.widget.get_password ());
						}

						d.destroy ();
					});
					dialog.show ();
				}
			}

			private bool show_popup (uint button, uint32 time) {
				/* Has any selected rows? */
				if (tree_view.get_selection ().count_selected_rows () <= 0) {
					return false;
				}

				var menu = cpanel.window.ui_manager.get_widget ("/popup-administrators") as Gtk.Menu;
				menu.popup (null, null, null, button, time);
				return true;
			}

		}

	}

}
