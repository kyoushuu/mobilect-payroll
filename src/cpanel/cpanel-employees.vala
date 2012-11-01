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

		public class CPanelEmployees : CPanelTab {

			public const string ACTION = "cpanel-employees";
			public const string ACTION_ADD = "cpanel-employees-add";
			public const string ACTION_REMOVE = "cpanel-employees-remove";
			public const string ACTION_PROPERTIES = "cpanel-employees-properties";
			public const string ACTION_PASSWORD = "cpanel-employees-password";
			public const string ACTION_SELECT_ALL = "cpanel-employees-select-all";
			public const string ACTION_DESELECT_ALL = "cpanel-employees-deselect-all";
			public const string ACTION_SORT_BY = "cpanel-employees-sort-by";
			public const string ACTION_REFRESH = "cpanel-employees-refresh";

			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }
			public EmployeeList list;


			public CPanelEmployees (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-employees-ui.xml");

				list = this.cpanel.window.app.database.employee_list;

				sort = new TreeModelSort.with_model (this.list);
				sort.set_sort_func (EmployeeList.Columns.NAME, (model, a, b) => {
					var employee1 = a.user_data as Employee;
					var employee2 = b.user_data as Employee;

					return strcmp (employee1.get_name (),
					               employee2.get_name ());
				});
				sort.set_sort_func (EmployeeList.Columns.TIN, (model, a, b) => {
					var employee1 = a.user_data as Employee;
					var employee2 = b.user_data as Employee;

					return strcmp (employee1.tin, employee2.tin);
				});
				sort.set_sort_func (EmployeeList.Columns.RATE, (model, a, b) => {
					var employee1 = a.user_data as Employee;
					var employee2 = b.user_data as Employee;

					return employee1.rate - employee2.rate;
				});
				sort.set_sort_func (EmployeeList.Columns.DAYRATE, (model, a, b) => {
					var employee1 = a.user_data as Employee;
					var employee2 = b.user_data as Employee;

					return (int) Math.round(employee1.rate_per_day - employee2.rate_per_day);
				});
				sort.set_sort_func (EmployeeList.Columns.HOURRATE, (model, a, b) => {
					var employee1 = a.user_data as Employee;
					var employee2 = b.user_data as Employee;

					return (int) Math.round(employee1.rate_per_hour - employee2.rate_per_hour);
				});
				sort.set_sort_func (EmployeeList.Columns.BRANCH, (model, a, b) => {
					var employee1 = a.user_data as Employee;
					var employee2 = b.user_data as Employee;

					return strcmp (employee1.branch.name,
					               employee2.branch.name);
				});


				push_composite_child ();


				var sw = new ScrolledWindow (null, null);
				this.add (sw);
				sw.show ();

				tree_view = new TreeView.with_model (sort);
				tree_view.expand = true;
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
				tree_view.search_column = (int) EmployeeList.Columns.NAME;
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

				TreeViewColumn column;
				CellRendererText renderer;

				column = new TreeViewColumn.with_attributes (_("Employee Name"),
				                                             new CellRendererText (),
				                                             "text", EmployeeList.Columns.NAME);
				column.sort_column_id = EmployeeList.Columns.NAME;
				column.expand = true;
				column.reorderable = true;
				column.resizable = true;
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				column = new TreeViewColumn.with_attributes (_("Branch"), renderer);
				column.sort_column_id = EmployeeList.Columns.BRANCH;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					TreeIter iter;
					(m as TreeModelSort).convert_iter_to_child_iter (out iter, i);
					(r as CellRendererText).text = list.get_from_iter (iter).branch.name;
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				renderer.xalign = 1;
				column = new TreeViewColumn.with_attributes (_("Monthly Rate"), renderer);
				column.sort_column_id = EmployeeList.Columns.RATE;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					TreeIter iter;
					(m as TreeModelSort).convert_iter_to_child_iter (out iter, i);
					(r as CellRendererText).text = list.get_from_iter (iter).rate.to_string ();
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				renderer.xalign = 1;
				column = new TreeViewColumn.with_attributes (_("Daily Rate"), renderer);
				column.sort_column_id = EmployeeList.Columns.DAYRATE;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					TreeIter iter;
					(m as TreeModelSort).convert_iter_to_child_iter (out iter, i);
					(r as CellRendererText).text = "%.2lf".printf (list.get_from_iter (iter).rate_per_day);
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				renderer.xalign = 1;
				column = new TreeViewColumn.with_attributes (_("Hourly Rate"), renderer);
				column.sort_column_id = EmployeeList.Columns.HOURRATE;
				column.reorderable = true;
				column.resizable = true;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					TreeIter iter;
					(m as TreeModelSort).convert_iter_to_child_iter (out iter, i);
					(r as CellRendererText).text = "%.2lf".printf (list.get_from_iter (iter).rate_per_hour);
				});
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes (_("TIN Number"),
				                                             new CellRendererText (),
				                                             "text", EmployeeList.Columns.TIN);
				column.sort_column_id = EmployeeList.Columns.TIN;
				column.reorderable = true;
				column.resizable = true;
				tree_view.append_column (column);


				pop_composite_child ();


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						accelerator = _("<Primary>I"),
						tooltip = _("Add an employee to database"),
						callback = (a) => {
							add_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_REMOVE,
						stock_id = Stock.REMOVE,
						accelerator = _("Delete"),
						tooltip = _("Remove the selected employees from database"),
						callback = (a) => {
							remove_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PROPERTIES,
						stock_id = Stock.PROPERTIES,
						accelerator = _("<Alt>Return"),
						tooltip = _("Edit information about the selected employees"),
						callback = (a) => {
							properties_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PASSWORD,
						stock_id = Stock.DIALOG_AUTHENTICATION,
						label = _("_Change Password"),
						tooltip = _("Change password of selected employees"),
						callback = (a) => {
							change_password_action ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_SELECT_ALL,
						stock_id = Stock.SELECT_ALL,
						accelerator = _("<Primary>A"),
						tooltip = _("Select all employees"),
						callback = (a) => {
							tree_view.get_selection ().select_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_DESELECT_ALL,
						label = _("_Deselect All"),
						accelerator = _("<Shift><Primary>A"),
						tooltip = _("Deselects all selected employees"),
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
						accelerator = _("<Primary>R"),
						tooltip = _("Reload information from database"),
						callback = (a) => {
							this.cpanel.window.app.database.update_employees ();
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


			private GLib.List<Employee> get_selected (TreeSelection selection) {
				var employees = new GLib.List<Employee>();

				foreach (var p in selection.get_selected_rows (null)) {
					TreePath path;
					TreeIter iter;

					path = sort.convert_path_to_child_path (p);
					list.get_iter (out iter, path);
					employees.append (this.list.get_from_iter (iter));
				}

				return employees;
			}

			private void add_action () {
				var database = this.cpanel.window.app.database;
				var employee = new Employee (0, list.database);

				var dialog = new EmployeeEditDialog (_("Add Employee"),
				                                     this.cpanel.window,
				                                     employee);
				dialog.help_link_id = "employees-add";
				dialog.action = Stock.ADD;

				var password_label = new Label.with_mnemonic (_("_Password:"));
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
				                                   1, 1);
				password_label.mnemonic_widget = password_entry;
				password_entry.show ();

				dialog.response.connect ((d, r) => {
					if (r == ResponseType.ACCEPT) {
						dialog.hide ();
						database.add_employee (employee.lastname,
						                       employee.firstname,
						                       employee.middlename,
						                       employee.tin,
						                       password_entry.text,
						                       employee.rate,
						                       employee.branch);
						dialog.destroy ();
					} else if (r == ResponseType.REJECT) {
						dialog.destroy ();
					}
				});
				dialog.show ();
			}

			private void remove_action () {
				var selection = tree_view.get_selection ();
				var employees = get_selected (selection);

				int selected_count = selection.count_selected_rows ();
				if (selected_count < 1) {
					return;
				}

				var dialog = new MessageDialog (this.cpanel.window,
				                                DialogFlags.MODAL,
				                                MessageType.WARNING,
				                                ButtonsType.NONE,
				                                ngettext ("Are you sure you want to remove the selected employee?",
				                                          "Are you sure you want to remove the %d selected employees?",
				                                          selected_count).printf (selected_count));
				dialog.secondary_text = ngettext ("All information about this employee will be deleted and cannot be restored.",
				                                  "All information about these employees will be deleted and cannot be restored.",
				                                  selected_count);
				dialog.add_buttons (Stock.CANCEL, ResponseType.REJECT,
				                    Stock.DELETE, ResponseType.ACCEPT);
				dialog.set_alternative_button_order (ResponseType.ACCEPT, ResponseType.REJECT);

				if (dialog.run () == ResponseType.ACCEPT) {
					dialog.hide ();
					foreach (var employee in employees) {
						employee.remove ();
					}
				}

				dialog.destroy ();
			}

			private void properties_action () {
				var selection = tree_view.get_selection ();
				var employees = get_selected (selection);

				foreach (var employee in employees) {
					var dialog = new EmployeeEditDialog (_("Employee Properties"),
					                                     this.cpanel.window,
					                                     employee);
					dialog.help_link_id = "employees-edit";
					dialog.action = Stock.SAVE;
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							dialog.hide ();
							dialog.employee.update ();
							dialog.destroy ();
						} else if (r == ResponseType.REJECT) {
							dialog.destroy ();
						}
					});
					dialog.show ();
				}
			}

			private void change_password_action () {
				var selection = tree_view.get_selection ();
				var employees = get_selected (selection);
				Employee employee;

				foreach (var e in employees) {
					employee = e;
					var dialog = new PasswordDialog (this.cpanel.window, employee.get_name ());
					dialog.help_link_id = "employees-change-password";

					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							dialog.hide ();
							employee.change_password (dialog.get_password ());
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

				var menu = cpanel.window.ui_manager.get_widget ("/popup-employees") as Gtk.Menu;
				menu.popup (null, null, null, button, time);
				return true;
			}

		}

	}

}
