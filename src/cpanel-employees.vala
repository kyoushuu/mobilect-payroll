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
			public EmployeeList list;

			public const string ACTION = "cpanel-employees";
			public const string ACTION_ADD = "cpanel-employees-add";
			public const string ACTION_REMOVE = "cpanel-employees-remove";
			public const string ACTION_EDIT = "cpanel-employees-edit";
			public const string ACTION_PASSWORD = "cpanel-employees-password";

			public CPanelEmployees (CPanel cpanel) {
				base (cpanel, ACTION);

				this.changed_to.connect (() => {
					reload ();
				});

				tree_view = new TreeView ();
				tree_view.get_selection ().mode = SelectionMode.MULTIPLE;
				tree_view.rubber_banding = true;
				tree_view.row_activated.connect ((t, p, c) => {
					edit ();
				});
				this.add (tree_view);

				TreeViewColumn column;
				CellRendererText renderer;

				column = new TreeViewColumn.with_attributes (_("Employee Name"),
				                                             new CellRendererText (),
				                                             "text", EmployeeList.Columns.NAME,
				                                             null);
				tree_view.append_column (column);

				column = new TreeViewColumn.with_attributes (_("TIN Number"),
				                                             new CellRendererText (),
				                                             "text", EmployeeList.Columns.TIN,
				                                             null);
				tree_view.append_column (column);

				column = new TreeViewColumn ();
				renderer = new CellRendererText ();
				column.title = _("Rate");
				column.pack_start (renderer, false);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, EmployeeList.Columns.RATE, out value);
					(r as CellRendererText).text = value.get_int ().to_string ();
				});
				tree_view.append_column (column);

				column = new TreeViewColumn ();
				renderer = new CellRendererText ();
				column.title = _("Rate per Hour");
				column.pack_start (renderer, false);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, EmployeeList.Columns.HOURRATE, out value);
					(r as CellRendererText).text = "%.2lf".printf (value.get_double ());
				});
				tree_view.append_column (column);


				ui_def =
					"<ui>" +
					"  <menubar name=\"menubar\">" +
					"    <placeholder name=\"MenuAdditions\">" +
					"      <placeholder name=\"CPanelMenuAdditions\">" +
					"        <menu name=\"CPanelEmployeesMenu\" action=\"" + ACTION + "\">" +
					"          <menuitem name=\"AddEmployee\" action=\"" + ACTION_ADD + "\" />" +
					"          <menuitem name=\"RemoveEmployee\" action=\"" + ACTION_REMOVE + "\" />" +
					"          <separator />" +
					"          <menuitem name=\"EditEmployee\" action=\"" + ACTION_EDIT + "\" />" +
					"          <menuitem name=\"PasswordEmployee\" action=\"" + ACTION_PASSWORD + "\" />" +
					"        </menu>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </menubar>" +
					"  <toolbar action=\"toolbar\">" +
					"    <placeholder name=\"ToolbarAdditions\">" +
					"      <placeholder name=\"CPanelToolItems\">" +
					"        <placeholder name=\"CPanelToolItemsAdditions\">" +
					"          <toolitem name=\"AddEmployee\" action=\"" + ACTION_ADD + "\" />" +
					"          <toolitem name=\"RemoveEmployee\" action=\"" + ACTION_REMOVE + "\" />" +
					"          <toolitem name=\"EditEmployee\" action=\"" + ACTION_EDIT + "\" />" +
					"          <toolitem name=\"PasswordEmployee\" action=\"" + ACTION_PASSWORD + "\" />" +
					"        </placeholder>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </toolbar>" +
					"</ui>";

				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION,
						stock_id = null,
						label = _("_Employees")
					},
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						label = _("_Add"),
						accelerator = _("<Control>plus"),
						tooltip = _("Add an employee to database"),
						callback = (a) => {
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

							dialog.response.connect((d, r) => {
								if (r == ResponseType.ACCEPT) {
									try {
										this.list.database.add_employee (employee.lastname,
										                                 employee.firstname,
										                                 employee.middlename,
										                                 employee.tin,
										                                 password_entry.text,
										                                 employee.rate);
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
															              MessageType.ERROR, ButtonsType.CLOSE,
															              _("Failed to add employee."));
										e_dialog.secondary_text = e.message;
										e_dialog.run ();
										e_dialog.destroy ();
									}

									reload ();
								}

								d.destroy ();
							});
							dialog.show_all ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_REMOVE,
						stock_id = Stock.REMOVE,
						label = _("_Remove"),
						accelerator = _("<Control>minus"),
						tooltip = _("Remove the selected employees from database"),
						callback = (a) => {
							var selection = tree_view.get_selection ();
							int selected_count = selection.count_selected_rows ();

							if (selected_count <= 0) {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No employee selected."));
								e_dialog.secondary_text = _("Select atleast one employee first.");
								e_dialog.run ();
								e_dialog.destroy ();

								return;
							}

							var m_dialog = new MessageDialog (this.cpanel.window,
							                                  DialogFlags.MODAL,
							                                  MessageType.INFO,
							                                  ButtonsType.YES_NO,
							                                  ngettext("Are you sure you want to remove the selected employee?",
							                                           "Are you sure you want to remove the %d selected employees?",
							                                           selected_count).printf (selected_count));
							m_dialog.secondary_text = _("The changes will be permanent.");

							if (m_dialog.run () == ResponseType.YES) {
								selection.selected_foreach ((m, p, i) => {
									Employee employee;
									this.list.get (i, EmployeeList.Columns.OBJECT, out employee);

									try {
										employee.remove ();
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
										                                  MessageType.ERROR, ButtonsType.CLOSE,
										                                  ngettext("Failed to remove selected employee.",
										                                           "Failed to remove selected employees.",
										                                           selected_count));
										e_dialog.secondary_text = e.message;
										e_dialog.run ();
										e_dialog.destroy ();
									}
								});

								reload ();
							}

							m_dialog.destroy ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_EDIT,
						stock_id = Stock.PROPERTIES,
						label = _("_Edit"),
						accelerator = _("<Control>E"),
						tooltip = _("Edit information about the selected employees"),
						callback = (a) => {
							edit ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PASSWORD,
						stock_id = Stock.DIALOG_AUTHENTICATION,
						label = _("_Change Password"),
						tooltip = _("Change password of selected employees"),
						callback = (a) => {
							var selection = tree_view.get_selection ();
							int selected_count = selection.count_selected_rows ();

							if (selected_count <= 0) {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No employee selected."));
								e_dialog.secondary_text = _("Select atleast one employee first.");
								e_dialog.run ();
								e_dialog.destroy ();

								return;
							}

							selection.selected_foreach ((m, p, i) => {
								Employee employee;
								this.list.get (i, EmployeeList.Columns.OBJECT, out employee);

								var dialog = new PasswordDialog (_("Change Employee Password"),
								                                 this.cpanel.window);

								dialog.response.connect((d, r) => {
									if (r == ResponseType.ACCEPT) {
										var password = dialog.widget.get_password ();

										if (password == null) {
											var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
											                                  MessageType.ERROR, ButtonsType.CLOSE,
											                                  _("Failed to change password."));
											e_dialog.secondary_text = _("Passwords didn't match.");
											e_dialog.run ();
											e_dialog.destroy ();

											return;
										}

										try {
											employee.change_password (password);
										} catch (ApplicationError e) {
											var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
											                                  MessageType.ERROR, ButtonsType.CLOSE,
											                                  _("Failed to change password."));
											e_dialog.secondary_text = e.message;
											e_dialog.run ();
											e_dialog.destroy ();
										}
									}

									d.destroy ();
								});
								dialog.show_all ();
							});
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_REMOVE).sensitive = false;
				this.action_group.get_action (ACTION_EDIT).sensitive = false;
				this.action_group.get_action (ACTION_PASSWORD).sensitive = false;
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().count_selected_rows () > 0;
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_EDIT).sensitive = selected;
					this.action_group.get_action (ACTION_PASSWORD).sensitive = selected;
				});
			}

			public void edit () {
				var selection = tree_view.get_selection ();
				int selected_count = selection.count_selected_rows ();

				if (selected_count <= 0) {
					var e_dialog = new MessageDialog (this.cpanel.window,
					                                  DialogFlags.MODAL,
					                                  MessageType.ERROR,
					                                  ButtonsType.OK,
					                                  _("No employee selected."));
					e_dialog.secondary_text = _("Select atleast one employee first.");
					e_dialog.run ();
					e_dialog.destroy ();

					return;
				}

				selection.selected_foreach ((m, p, i) => {
					Employee employee;
					this.list.get (i, EmployeeList.Columns.OBJECT, out employee);

					var dialog = new EmployeeEditDialog (_("Employee \"%s\" Properties").printf (employee.get_name ()),
					                                     this.cpanel.window,
					                                     employee);
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							try {
								dialog.employee.update ();
							} catch (Error e) {
								stderr.printf (_("Error: %s\n"), e.message);
							}

							reload ();
						}

						d.destroy ();
					});
					dialog.show_all ();
				});
			}

			public void reload () {
				this.list = this.cpanel.window.app.database.get_employees ();
				this.tree_view.model = this.list ;
			}

		}

	}

}
