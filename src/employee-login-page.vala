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

		public class EmployeeLoginPage : LoginPage {

			public EmployeeList list { get; private set; }
			public ComboBox name_combobox { get; private set; }
			public Entry password_entry { get; private set; }

			public Button button_login { get; private set; }
			public Button button_logout { get; private set; }
			public Button button_admin { get; private set; }

			public EmployeeLoginPage (Window window) {
				base (window, _("Employee Login"));

				window.notebook.switch_page.connect ((t, p, n) => {
					if (n == window.PAGE_LOGIN_EMPLOYEE) {
						reload ();
					}
				});

				var name_label = new Label (_("_Name:"));
				name_label.use_underline = true;
				name_label.xalign = 0.0f;
				grid.add (name_label);

				name_combobox = new ComboBox ();
				name_combobox.hexpand = true;
				grid.attach_next_to (name_combobox,
				                     name_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var name_cell_renderer = new CellRendererText ();
				name_combobox.pack_start (name_cell_renderer, true);
				name_combobox.add_attribute (name_cell_renderer,
				                             "text", EmployeeList.Columns.NAME);

				var password_label = new Label (_("_Password:"));
				password_label.use_underline = true;
				password_label.xalign = 0.0f;
				grid.add (password_label);

				password_entry = new Entry ();
				password_entry.hexpand = true;
				password_entry.activates_default = true;
				password_entry.visibility = false;
				grid.attach_next_to (password_entry,
				                     password_label,
				                     PositionType.RIGHT,
				                     2, 1);

				button_login = new Button.with_mnemonic (_("Log_in"));
				button_login.can_default = true;
				button_box.add (button_login);

				button_logout = new Button.with_mnemonic (_("Log_out"));
				button_logout.can_default = true;
				button_box.add (button_logout);

				button_admin = new Button.with_mnemonic (_("_Admin"));
				button_box.add (button_admin);
				button_box.set_child_secondary (button_admin, true);

				this.button_login.clicked.connect ((t) => {
					TreeIter iter;
					Employee employee;

					try {
						if (this.name_combobox.get_active_iter (out iter) == false) {
							return;
						}

						this.list.get (iter, EmployeeList.Columns.OBJECT, out employee);

						if (employee.get_password_checksum () !=
						    Checksum.compute_for_string (ChecksumType.SHA256, this.password_entry.text, -1))
							throw new ApplicationError.WRONG_PASSWORD (_("Wrong password."));

						if (employee.get_open_time_records_num () > 0)
							throw new ApplicationError.ALREADY_LOGGED_IN (_("You are already logged in."));

						employee.log_employee_in ();

						var m_dialog = new MessageDialog (this.window, DialogFlags.DESTROY_WITH_PARENT,
						                                  MessageType.INFO, ButtonsType.OK,
						                                  _("Logged in successfully."));
						m_dialog.run ();
						m_dialog.destroy ();

						this.password_entry.text = "";
					} catch (Error e) {
						var e_dialog = new MessageDialog (this.window, DialogFlags.DESTROY_WITH_PARENT,
						                                  MessageType.ERROR, ButtonsType.CLOSE,
						                                  _("Failed to login."));
						e_dialog.secondary_text = e.message;
						e_dialog.run ();
						e_dialog.destroy ();
					}
				});

				this.button_logout.clicked.connect ((t) => {
					TreeIter iter;
					Employee employee;

					try {
						if (this.name_combobox.get_active_iter (out iter) == false) {
							return;
						}

						this.list.get (iter, EmployeeList.Columns.OBJECT, out employee);

						if (employee.get_password_checksum () !=
						    Checksum.compute_for_string (ChecksumType.SHA256, this.password_entry.text, -1))
							throw new ApplicationError.WRONG_PASSWORD (_("Wrong password."));

						employee.log_employee_out ();

						var m_dialog = new MessageDialog (this.window, DialogFlags.DESTROY_WITH_PARENT,
						                                  MessageType.INFO, ButtonsType.OK,
						                                  _("Logged out successfully."));
						m_dialog.run ();
						m_dialog.destroy ();

						this.password_entry.text = "";
					} catch (Error e) {
						var e_dialog = new MessageDialog (this.window, DialogFlags.DESTROY_WITH_PARENT,
						                                  MessageType.ERROR, ButtonsType.CLOSE,
						                                  _("Failed to log out."));
						e_dialog.secondary_text = e.message;
						e_dialog.run ();
						e_dialog.destroy ();
					}
				});

				this.button_admin.clicked.connect ((t) => {
					this.window.notebook.page = this.window.PAGE_LOGIN_ADMIN;
				});
			}

			public void reload () {
				this.list = this.window.app.database.get_employees ();
				this.name_combobox.model = this.list;

				TreeIter iter;
				if (this.list.get_iter_first (out iter)) {
					this.name_combobox.set_active_iter (iter);
				}
			}

		}

	}

}
