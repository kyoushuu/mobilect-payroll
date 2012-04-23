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
using Config;


namespace Mobilect {

	namespace Payroll {

		public errordomain WindowError {
			WRONG_PASSWORD,
			ALREADY_LOGGED_IN
		}

		public class Window : Gtk.Window {

			public int PAGE_LOGIN_EMPLOYEE;
			public int PAGE_LOGIN_ADMIN;
			public int PAGE_ADMIN;

			public Application app { get; private set; }

			public UIManager ui_manager { get; private set; }
			public Notebook notebook { get; private set; }

			public Window (Application app) {
				this.title = _("Mobilect Payroll");
				this.default_width = 600;
				this.default_height = 400;
				this.application = app;
				this.app = app;

				var box = new Box (Orientation.VERTICAL, 0);
				this.add (box);


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = "file",
						label = _("_File")
					},
					Gtk.ActionEntry () {
						name = "file-quit",
						stock_id = Stock.QUIT,
						accelerator = "<Control>Q",
						tooltip = "Quit",
						callback = (a) => {
							destroy ();
						}
					},
					Gtk.ActionEntry () {
						name = "help",
						label = _("_Help")
					},
					Gtk.ActionEntry () {
						name = "help-about",
						stock_id = Stock.ABOUT,
						accelerator = "F1",
						tooltip = "About",
						callback = (a) => {
							string[] authors = {"Arnel A. Borja <kyoushuu@yahoo.com>", null};
							string license = _("This program is free software; you can redistribute it and/or modify " +
							                   "it under the terms of the GNU General Public License as published by " +
							                   "the Free Software Foundation; either version 3 of the License, or " +
							                   "(at your option) any later version.\n" +
							                   "\n" +
							                   "This program is distributed in the hope that it will be useful, " +
							                   "but WITHOUT ANY WARRANTY; without even the implied warranty of " +
							                   "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the " +
							                   "GNU General Public License for more details.\n" +
							                   "\n" +
							                   "You should have received a copy of the GNU General Public License along " +
							                   "with this program.  If not, see <http:/" + "/www.gnu.org/licenses/>.");

							show_about_dialog (this,
							                   "program-name", _("Mobilect Payroll"),
							                   "version", PACKAGE_VERSION,
							                   "title", _("About Mobilect Payroll"),
							                   "comments", _("Payroll application of Mobilect Power Corp."),
							                   "website", PACKAGE_URL,
							                   "copyright", _("Copyright (c) 2012  Mobilect Power Corp."),
							                   "license-type", License.GPL_3_0,
							                   "license", license,
							                   "wrap-license", true,
							                   "authors", authors,
							                   "logo-icon-name", PACKAGE_NAME);
						}
					}
				};

				var action_group = new Gtk.ActionGroup ("payroll");
				action_group.add_actions (actions, this);

				string ui =
					"<ui>" +
					"  <menubar name=\"menubar\">" +
					"    <menu name=\"FileMenu\" action=\"file\">" +
					"      <placeholder name=\"FileMenuAdditions\" />" +
					"      <separator/>" +
					"      <menuitem name=\"Quit\" action=\"file-quit\" />" +
					"    </menu>" +
					"    <placeholder name=\"MenuAdditions\" />" +
					"    <menu name=\"HelpMenu\" action=\"help\">" +
					"      <placeholder name=\"HelpMenuAdditions\" />" +
					"      <separator/>" +
					"      <menuitem name=\"About\" action=\"help-about\"/>" +
					"    </menu>" +
					"  </menubar>" +
					"  <toolbar action=\"toolbar\">" +
					"    <placeholder name=\"ToolbarAdditions\" />" +
					"    <separator/>" +
					"    <placeholder name=\"FileToolItems\">" +
					"      <toolitem name=\"Quit\" action=\"file-quit\" />" +
					"    </placeholder>" +
					"  </toolbar>" +
					"</ui>";

				try {
					ui_manager = new UIManager ();
					ui_manager.insert_action_group (action_group, -1);
					ui_manager.add_ui_from_string (ui, -1);
					this.add_accel_group (ui_manager.get_accel_group ());
					box.add (ui_manager.get_widget ("/menubar"));
				} catch (Error e) {
					stderr.printf ("Error: %s\n", e.message);
				}

				var toolbar = ui_manager.get_widget ("/toolbar");
				(toolbar as Toolbar).set_style (ToolbarStyle.BOTH_HORIZ);
				toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);
				box.add (toolbar);

				notebook = new Notebook ();
				notebook.show_border = false;
				notebook.show_tabs = false;
				notebook.margin = 12;
				notebook.halign = Align.FILL;
				notebook.valign = Align.FILL;
				box.add (notebook);


				/* Employee Login Page */
				var emp_login_page = new EmployeeLoginPage (this);
				PAGE_LOGIN_EMPLOYEE = notebook.append_page (emp_login_page);


				/* Administrator Login Page */
				var admin_login_page = new AdminLoginPage (this);
				PAGE_LOGIN_ADMIN = notebook.append_page (admin_login_page);


				/* Administrator Page */
				var cpanel = new CPanel (this);
				cpanel.hexpand = true;
				cpanel.vexpand = true;
				PAGE_ADMIN = notebook.append_page (cpanel);


				this.show_all ();


				/* Grab default */
				emp_login_page.button_admin.clicked.connect ((t) => {
					admin_login_page.username_entry.grab_focus ();
					admin_login_page.button_ok.grab_default ();
				});

				admin_login_page.button_cancel.clicked.connect ((t) => {
					emp_login_page.name_combobox.grab_focus ();
					emp_login_page.button_login.grab_default ();
				});

				admin_login_page.username_entry.grab_focus ();
				admin_login_page.button_ok.grab_default ();
			}

		}

	}

}
