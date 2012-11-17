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
				base (window, _("Employee Log In"));

				this.list = this.window.app.database.employee_list;


				push_composite_child ();


				var name_label = new Label.with_mnemonic (_("_Name:"));
				name_label.xalign = 0.0f;
				grid.add (name_label);
				name_label.show ();

				name_combobox = new ComboBox.with_model (this.list);
				name_combobox.hexpand = true;
				grid.attach_next_to (name_combobox,
				                     name_label,
				                     PositionType.RIGHT,
				                     1, 1);
				name_label.mnemonic_widget = name_combobox;
				name_combobox.show ();

				TreeIter iter;
				if (this.list.get_iter_first (out iter)) {
					this.name_combobox.set_active_iter (iter);
				}

				var name_cell_renderer = new CellRendererText ();
				name_combobox.pack_start (name_cell_renderer, true);
				name_combobox.add_attribute (name_cell_renderer,
				                             "text", EmployeeList.Columns.NAME);

				var password_label = new Label.with_mnemonic (_("_Password:"));
				password_label.xalign = 0.0f;
				grid.add (password_label);
				password_label.show ();

				password_entry = new Entry ();
				password_entry.hexpand = true;
				password_entry.activates_default = true;
				password_entry.visibility = false;
				grid.attach_next_to (password_entry,
				                     password_label,
				                     PositionType.RIGHT,
				                     1, 1);
				password_label.mnemonic_widget = password_entry;
				password_entry.show ();

				button_login = new Button.with_mnemonic (_("Log _In"));
				button_login.can_default = true;
				button_box.add (button_login);
				button_login.show ();

				button_logout = new Button.with_mnemonic (_("Log _Out"));
				button_logout.can_default = true;
				button_box.add (button_logout);
				button_logout.show ();

				button_admin = new Button.with_mnemonic (_("_Admin"));
				button_box.add (button_admin);
				button_box.set_child_secondary (button_admin, true);
				button_admin.show ();


				pop_composite_child ();


				this.button_login.clicked.connect ((t) => {
					try {
						if (this.name_combobox.get_active_iter (out iter) == false) {
							return;
						}

						var employee = this.list.get_from_iter (iter);

						employee.log_in (this.password_entry.text);

						var dialog = new MessageDialog (this.window, DialogFlags.DESTROY_WITH_PARENT,
						                                MessageType.INFO, ButtonsType.OK,
						                                _("Logged in successfully."));
						dialog.run ();
						dialog.destroy ();

						this.password_entry.text = "";
					} catch (Error e) {
						this.window.show_error_dialog (_("Failed to log in"), e.message);
					}
				});

				this.button_logout.clicked.connect ((t) => {
					try {
						if (this.name_combobox.get_active_iter (out iter) == false) {
							return;
						}

						var employee = this.list.get_from_iter (iter);

						employee.log_out (this.password_entry.text);

						var dialog = new MessageDialog (this.window, DialogFlags.DESTROY_WITH_PARENT,
						                                  MessageType.INFO, ButtonsType.OK,
						                                  _("Logged out successfully."));
						dialog.run ();
						dialog.destroy ();

						this.password_entry.text = "";
					} catch (Error e) {
						this.window.show_error_dialog (_("Failed to log out"), e.message);
					}
				});

				this.button_admin.clicked.connect ((t) => {
					this.window.notebook.page = Window.Page.LOGIN_ADMIN;
				});
			}

		}

	}

}
