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

		public errordomain AdminLoginPageError {
			USERNAME_NOT_FOUND,
			WRONG_PASSWORD
		}

		public class AdminLoginPage : LoginPage {

			public Entry username_entry { get; private set; }
			public Entry password_entry { get; private set; }

			public Button button_login { get; private set; }
			public Button button_cancel { get; private set; }


			public AdminLoginPage (Window window) {
				base (window, _("Administrator Log In"));


				push_composite_child ();


				var username_label = new Label.with_mnemonic (_("_Username:"));
				username_label.xalign = 0.0f;
				grid.add (username_label);
				username_label.show ();

				username_entry = new Entry ();
				username_entry.hexpand = true;
				username_entry.activates_default = true;
				grid.attach_next_to (username_entry,
				                     username_label,
				                     PositionType.RIGHT,
				                     2, 1);
				username_label.mnemonic_widget = username_entry;
				username_entry.show ();

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
				                     2, 1);
				password_label.mnemonic_widget = password_entry;
				password_entry.show ();

				button_cancel = new Button.from_stock (Stock.CANCEL);
				button_box.add (button_cancel);
				button_cancel.show ();

				button_login = new Button.with_mnemonic (_("Log _In"));
				button_login.can_default = true;
				button_box.add (button_login);
				button_login.show ();


				pop_composite_child ();


				if (alternative_dialog_button_order (window.screen)) {
					button_box.reorder_child (button_login, 0);
					button_box.reorder_child (button_cancel, 1);
				}


				button_login.clicked.connect ((t) => {
					try {
						var administrator = (this.window.application as Application).database.administrator_list.get_with_username (this.username_entry.text);

						if (administrator == null) {
							throw new AdminLoginPageError.USERNAME_NOT_FOUND (_("Username not found."));
						}

						if (!administrator.password_matches (this.password_entry.text)) {
							throw new AdminLoginPageError.WRONG_PASSWORD (_("Wrong password."));
						}

						this.window.notebook.page = Window.Page.CONTROL_PANEL;
						this.username_entry.text = "";
						this.password_entry.text = "";
					} catch (Error e) {
						this.window.show_error_dialog (null, _("Failed to log in"), e.message);
					}
				});

				button_cancel.clicked.connect ((t) => {
					this.window.notebook.page = Window.Page.LOGIN_EMPLOYEE;
				});
			}

		}

	}

}
