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
			public const string ACTION_PRINT = "cpanel-employees-print";
			public const string ACTION_PRINT_PREVIEW = "cpanel-employees-print-preview";

			public CPanelEmployees (CPanel cpanel) {
				base (cpanel, ACTION);

				this.changed_to.connect (() => {
					reload ();
				});

				tree_view = new TreeView ();
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

				column = new TreeViewColumn ();
				renderer = new CellRendererText ();
				column.title = _("Hours");
				column.pack_start (renderer, false);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value;
					m.get_value (i, EmployeeList.Columns.HOURS, out value);
					(r as CellRendererText).text = "%.1lf".printf (value.get_double ());
				});
				tree_view.append_column (column);

				column = new TreeViewColumn ();
				renderer = new CellRendererText ();
				column.title = _("Earnings");
				column.pack_start (renderer, false);
				column.set_cell_data_func (renderer, (c, r, m, i) => {
					Value value_hours, value_hourrate;
					m.get_value (i, EmployeeList.Columns.HOURS, out value_hours);
					m.get_value (i, EmployeeList.Columns.HOURRATE, out value_hourrate);
					(r as CellRendererText).text = "%.2lf".printf (value_hours.get_double () * value_hourrate.get_double ());
				});
				tree_view.append_column (column);

				reload ();


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
					"          <separator />" +
					"          <menuitem name=\"PrintEmployee\" action=\"" + ACTION_PRINT + "\" />" +
					"          <menuitem name=\"PrintPreviewEmployee\" action=\"" + ACTION_PRINT_PREVIEW + "\" />" +
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
					"          <separator />" +
					"          <toolitem name=\"PrintEmployee\" action=\"" + ACTION_PRINT + "\" />" +
					"          <toolitem name=\"PrintPreviewEmployee\" action=\"" + ACTION_PRINT_PREVIEW + "\" />" +
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
						accelerator = _("<Control>A"),
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
										                                 password_entry.text,
										                                 employee.rate);
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
															              MessageType.ERROR, ButtonsType.CLOSE,
															              _("Error: %s"), e.message);
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
						accelerator = _("<Control>R"),
						tooltip = _("Remove the selected employee from database"),
						callback = (a) => {
							TreeIter iter;
							Employee employee;

							if (tree_view.get_selection ().get_selected (null, out iter)) {
								this.list.get (iter, EmployeeList.Columns.OBJECT, out employee);
								var m_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.INFO,
								                                  ButtonsType.YES_NO,
								                                  _("Are you sure you want to remove the selected employee? The changes will be permanent."));

								if (m_dialog.run () == ResponseType.YES) {
									try {
										employee.remove ();
									} catch (ApplicationError e) {
										var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
															              MessageType.ERROR, ButtonsType.CLOSE,
															              _("Error: %s"), e.message);
										e_dialog.run ();
										e_dialog.destroy ();
									}

									reload ();
								}

								m_dialog.destroy ();
							} else {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No employee selected."));
								e_dialog.run ();
								e_dialog.destroy ();
							}
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_EDIT,
						stock_id = Stock.EDIT,
						label = _("_Edit"),
						accelerator = _("<Control>E"),
						tooltip = _("Edit information about the selected employee"),
						callback = (a) => {
							edit ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PASSWORD,
						stock_id = Stock.PROPERTIES,
						label = _("_Change Password"),
						tooltip = _("Change password of selected employee"),
						callback = (a) => {
							TreeIter iter;
							Employee employee;

							if (tree_view.get_selection ().get_selected (null, out iter)) {
								this.list.get (iter, EmployeeList.Columns.OBJECT, out employee);
								var dialog = new PasswordDialog (_("Change Employee Password"),
									                              this.cpanel.window);

								dialog.response.connect((d, r) => {
									if (r == ResponseType.ACCEPT) {
										var password = dialog.widget.get_password ();

										if (password != null) {
											try {
												employee.change_password (password);
											} catch (ApplicationError e) {
												var e_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
																			      MessageType.ERROR, ButtonsType.CLOSE,
																			      _("Error: %s"), e.message);
												e_dialog.run ();
												e_dialog.destroy ();
											}
										} else {
											return;
										}
									}

									d.destroy ();
								});
								dialog.show_all ();
							} else {
								var e_dialog = new MessageDialog (this.cpanel.window,
								                                  DialogFlags.MODAL,
								                                  MessageType.ERROR,
								                                  ButtonsType.OK,
								                                  _("No employee selected."));
								e_dialog.run ();
								e_dialog.destroy ();
							}
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PRINT,
						stock_id = Stock.PRINT,
						label = _("_Print"),
						accelerator = _("<Control>P"),
						tooltip = _("Print information about each employees for the current period selected"),
						callback = (a) => {
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PRINT_PREVIEW,
						stock_id = Stock.PRINT_PREVIEW,
						label = _("Print Previe_w"),
						accelerator = _("<Shift><Control>P"),
						tooltip = _("Show print preview of information about each employees for the current period selected"),
						callback = (a) => {
						}
					}
				};

				this.action_group.add_actions (actions, this);
				tree_view.get_selection ().changed.connect ((s) => {
					var selected = tree_view.get_selection ().get_selected (null, null);
					this.action_group.get_action (ACTION_REMOVE).sensitive = selected;
					this.action_group.get_action (ACTION_EDIT).sensitive = selected;
				});
			}

			public void edit () {
				TreeIter iter;
				Employee employee;

				if (tree_view.get_selection ().get_selected (null, out iter)) {
					this.list.get (iter, EmployeeList.Columns.OBJECT, out employee);

					var dialog = new EmployeeEditDialog (_("Employee \"%s\" Properties").printf (employee.get_name ()),
					                                     this.cpanel.window,
					                                     employee);
					dialog.response.connect ((d, r) => {
						if (r == ResponseType.ACCEPT) {
							try {
								dialog.employee.update ();
							} catch (Error e) {
								stderr.printf ("Error: %s\n", e.message);
							}

							reload ();
						}

						d.destroy ();
					});
					dialog.show_all ();
				} else {
					var e_dialog = new MessageDialog (this.cpanel.window,
					                                  DialogFlags.MODAL,
					                                  MessageType.ERROR,
					                                  ButtonsType.OK,
					                                  _("No employee selected."));
					e_dialog.run ();
					e_dialog.destroy ();
				}
			}

			public void reload () {
				this.list = this.cpanel.window.app.database.get_employees ();
				this.list.filter = this.cpanel.filter;
				this.tree_view.model = this.list ;
			}

		}

	}

}
