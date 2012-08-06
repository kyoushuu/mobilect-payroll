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
using Pango;
using Cairo;
using Gee;


namespace Mobilect {

	namespace Payroll {

		public class CPanelEmployees : CPanelTab {

			public TreeView tree_view { get; private set; }
			public TreeModelSort sort { get; private set; }
			public EmployeeList list;

			public const string ACTION = "cpanel-employees";
			public const string ACTION_ADD = "cpanel-employees-add";
			public const string ACTION_REMOVE = "cpanel-employees-remove";
			public const string ACTION_PROPERTIES = "cpanel-employees-properties";
			public const string ACTION_PASSWORD = "cpanel-employees-password";


			public CPanelEmployees (CPanel cpanel) {
				base (cpanel, ACTION);

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
				sort.set_sort_func (EmployeeList.Columns.HOURRATE, (model, a, b) => {
					var employee1 = a.user_data as Employee;
					var employee2 = b.user_data as Employee;

					return (int) Math.round(employee1.rate_per_hour - employee2.rate_per_hour);
				});

				tree_view = new TreeView.with_model (sort);
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
				tree_view.row_activated.connect ((t, p, c) => {
					edit_action ();
				});
				this.add (tree_view);

				TreeViewColumn column;
				CellRendererText renderer;

				column = new TreeViewColumn.with_attributes (_("Employee Name"),
				                                             new CellRendererText (),
				                                             "text", EmployeeList.Columns.NAME);
				column.sort_column_id = EmployeeList.Columns.NAME;
				column.expand = true;
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes (_("TIN Number"),
				                                             new CellRendererText (),
				                                             "text", EmployeeList.Columns.TIN);
				column.sort_column_id = EmployeeList.Columns.TIN;
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				column = new TreeViewColumn.with_attributes (_("Rate"), renderer);
				column.sort_column_id = EmployeeList.Columns.RATE;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, EmployeeList.Columns.RATE, out value);
					(r as CellRendererText).text = ((int) value).to_string ();
				});
				tree_view.append_column (column);

				renderer = new CellRendererText ();
				column = new TreeViewColumn.with_attributes (_("Rate per Hour"), renderer);
				column.sort_column_id = EmployeeList.Columns.HOURRATE;
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, EmployeeList.Columns.HOURRATE, out value);
					(r as CellRendererText).text = "%.2lf".printf ((double) value);
				});
				tree_view.append_column (column);


				ui_resource_path = "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-employees-ui.xml";


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						accelerator = _("<Control>I"),
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
							edit_action ();
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
					}
				};

				this.action_group.add_actions (actions, this);
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

				int selected_count = selection.count_selected_rows ();
				if (selected_count <= 0) {
					this.cpanel.window.show_error_dialog (_("No employee selected"),
					                                      _("Select at least one employee first."));

					return employees;
				}

				foreach (var p in selection.get_selected_rows (null)) {
					Employee employee;
					TreePath path;
					TreeIter iter;

					path = sort.convert_path_to_child_path (p);
					list.get_iter (out iter, path);
					this.list.get (iter, EmployeeList.Columns.OBJECT, out employee);
					employees.append (employee);
				}

				return employees;
			}

			private void add_action () {
				var database = this.cpanel.window.app.database;
				var employee = new Employee (0, list.database);

				var dialog = new EmployeeEditDialog (_("Add Employee"),
				                                     this.cpanel.window,
				                                     employee);

				var password_label = new Label (_("_Password:"));
				password_label.use_underline = true;
				password_label.xalign = 0.0f;
				dialog.widget.grid.add (password_label);

				var password_entry = new Entry ();
				password_entry.hexpand = true;
				password_entry.activates_default = true;
				password_entry.visibility = false;
				dialog.widget.grid.attach_next_to (password_entry,
				                                   password_label,
				                                   PositionType.RIGHT,
				                                   2, 1);

				dialog.response.connect ((d, r) => {
					d.hide ();

					if (r == ResponseType.ACCEPT) {
						database.add_employee (employee.lastname,
						                       employee.firstname,
						                       employee.middlename,
						                       employee.tin,
						                       password_entry.text,
						                       employee.rate);
					}

					d.destroy ();
				});
				dialog.show_all ();
			}

			private void remove_action () {
				var selection = tree_view.get_selection ();
				var employees = get_selected (selection);

				int selected_count = selection.count_selected_rows ();
				if (selected_count < 1) {
					return;
				}

				var m_dialog = new MessageDialog (this.cpanel.window,
				                                  DialogFlags.MODAL,
				                                  MessageType.WARNING,
				                                  ButtonsType.NONE,
				                                  ngettext ("Are you sure you want to remove the selected employee?",
				                                            "Are you sure you want to remove the %d selected employees?",
				                                            selected_count).printf (selected_count));
				m_dialog.secondary_text = ngettext ("All information about this employee will be deleted and cannot be restored.",
				                                    "All information about these employees will be deleted and cannot be restored.",
				                                    selected_count);
				m_dialog.add_buttons (Stock.CANCEL, ResponseType.REJECT,
				                      Stock.DELETE, ResponseType.ACCEPT);

				if (m_dialog.run () == ResponseType.ACCEPT) {
					foreach (var employee in employees) {
						employee.remove ();
					}
				}

				m_dialog.destroy ();
			}

			private void edit_action () {
				var selection = tree_view.get_selection ();
				var employees = get_selected (selection);

				foreach (var employee in employees) {
					var dialog = new EmployeeEditDialog (_("Employee Properties"),
					                                     this.cpanel.window,
					                                     employee);
					dialog.response.connect ((d, r) => {
						d.hide ();

						if (r == ResponseType.ACCEPT) {
							dialog.employee.update ();
						}

						d.destroy ();
					});
					dialog.show_all ();
				}
			}

			private void change_password_action () {
				var selection = tree_view.get_selection ();
				var employees = get_selected (selection);
				Employee employee;

				foreach (var e in employees) {
					employee = e;
					var dialog = new PasswordDialog (_("Change Password"),
					                                 this.cpanel.window);

					dialog.response.connect ((d, r) => {
						d.hide ();

						if (r == ResponseType.ACCEPT) {
							var password = dialog.widget.get_password ();

							if (password == null) {
								this.cpanel.window.show_error_dialog (_("Failed to change password"),
								                                      _("Passwords didn't match."));

								return;
							}

							employee.change_password (password);
						}

						d.destroy ();
					});
					dialog.show_all ();
				}
			}

		}

	}

}
