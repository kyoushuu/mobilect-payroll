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


namespace Mobilect {

	namespace Payroll {

		public class CPanelEmployees : CPanelTab {

			public TreeView tree_view { get; private set; }
			public EmployeeList list;

			public const string ACTION = "cpanel-employees";
			public const string ACTION_ADD = "cpanel-employees-add";
			public const string ACTION_REMOVE = "cpanel-employees-remove";
			public const string ACTION_EDIT = "cpanel-employees-edit";

			public CPanelEmployees (CPanel cpanel) {
				base (cpanel, "cpanel-employees");

				this.changed_to.connect (() => {
					reload ();
				});

				tree_view = new TreeView ();
				tree_view.row_activated.connect ((t, p, c) => {
					edit ();
				});
				this.add (tree_view);

				var column = new TreeViewColumn.with_attributes ("Employee Name",
				                                                 new CellRendererText (),
				                                                 "text", EmployeeList.Columns.NAME,
				                                                 null);
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
					"        </placeholder>" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </toolbar>" +
					"</ui>";

				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION,
						stock_id = null,
						label = "_Employees"
					},
					Gtk.ActionEntry () {
						name = ACTION_ADD,
						stock_id = Stock.ADD,
						label = "_Add Employee",
						accelerator = "<Control>A",
						tooltip = "Add an employee to database",
						callback = (a) => {
							var employee = new Employee (0);
							employee.database = list.database;

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
									this.list.database.add_employee (employee.lastname,
									                                 employee.firstname,
									                                 password_entry.text);
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
						label = "_Remove Employee",
						accelerator = "<Control>R",
						tooltip = "Remove the selected employee from database",
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
									employee.remove ();
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
						label = "_Edit Employee",
						accelerator = "<Control>E",
						tooltip = "Edit information about the selected employee",
						callback = (a) => {
							edit ();
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
							dialog.employee.update ();
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
				try {
					this.list = this.cpanel.window.app.database.get_employees ();
					this.tree_view.model = this.list ;
				} catch (Error e) {
					var m_dialog = new MessageDialog (this.cpanel.window, DialogFlags.DESTROY_WITH_PARENT,
					                                  MessageType.ERROR, ButtonsType.CLOSE,
					                                  _("Error: %s"), e.message);
					m_dialog.run ();
					m_dialog.destroy ();
				}
			}

		}

	}

}
