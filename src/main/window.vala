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

		public class Window : Gtk.Window {

			public int PAGE_LOGIN_EMPLOYEE;
			public int PAGE_LOGIN_ADMIN;
			public int PAGE_ADMIN;

			public Application app { get; private set; }

			public UIManager ui_manager { get; private set; }
			public MenuBar menubar { get; private set; }
			public Toolbar toolbar { get; private set; }
			public Notebook notebook { get; private set; }


			public Window (Application app) {
				this.title = _("Mobilect Payroll");
				this.default_width = 600;
				this.default_height = 400;
				this.application = app;
				this.app = app;


				push_composite_child ();


				var box = new Box (Orientation.VERTICAL, 0);
				this.add (box);
				box.show ();


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = "file",
						label = _("_File")
					},
					Gtk.ActionEntry () {
						name = "file-quit",
						stock_id = Stock.QUIT,
						accelerator = _("<Control>Q"),
						tooltip = _("Quit"),
						callback = (a) => {
							destroy ();
						}
					},
					Gtk.ActionEntry () {
						name = "edit",
						label = _("_Edit")
					},
					Gtk.ActionEntry () {
						name = "view",
						label = _("_View")
					},
					Gtk.ActionEntry () {
						name = "help",
						label = _("_Help")
					},
					Gtk.ActionEntry () {
						name = "help-contents",
						label = _("_Contents"),
						stock_id = Stock.HELP,
						accelerator = _("F1"),
						tooltip = _("Open manual"),
						callback = (a) => {
							this.app.show_help (null, null);
						}
					},
					Gtk.ActionEntry () {
						name = "help-about",
						stock_id = Stock.ABOUT,
						tooltip = _("About this application"),
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
							                   "logo-icon-name", PACKAGE);
						}
					}
				};

				Gtk.ToggleActionEntry[] toggle_actions = {
					Gtk.ToggleActionEntry () {
						name = "view-toolbar",
						label = _("_Toolbar"),
						tooltip = _("Show or hide the toolbar"),
						callback = (a) => {
							var visible = (a as ToggleAction).active;
							toolbar.visible = visible;
							this.app.settings.main.set_boolean ("toolbar-visible", visible);
						},
						is_active = this.app.settings.main.get_boolean ("toolbar-visible")
					}
				};

				var action_group = new Gtk.ActionGroup ("payroll");
				action_group.add_actions (actions, this);
				action_group.add_toggle_actions (toggle_actions, this);

				ui_manager = new UIManager ();
				ui_manager.insert_action_group (action_group, -1);
				this.add_accel_group (ui_manager.get_accel_group ());

				try {
					ui_manager.add_ui_from_resource ("/com/mobilectpower/Payroll/mobilect-payroll-ui.xml");
				} catch (Error e) {
					error ("Failed to add UI to UI Manager: %s", e.message);
				}

				menubar = ui_manager.get_widget ("/menubar") as MenuBar;
				box.add (menubar);
				menubar.show ();

				toolbar = ui_manager.get_widget ("/toolbar") as Toolbar;
				(toolbar as Toolbar).set_style (ToolbarStyle.BOTH_HORIZ);
				toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);
				box.add (toolbar);
				toolbar.visible = this.app.settings.main.get_boolean ("toolbar-visible");

				notebook = new Notebook ();
				notebook.show_border = false;
				notebook.show_tabs = false;
				notebook.margin = 12;
				notebook.halign = Align.FILL;
				notebook.valign = Align.FILL;
				box.add (notebook);
				notebook.show ();


				/* Employee Login Page */
				var emp_login_page = new EmployeeLoginPage (this);
				PAGE_LOGIN_EMPLOYEE = notebook.append_page (emp_login_page);
				emp_login_page.show ();

				/* Administrator Login Page */
				var admin_login_page = new AdminLoginPage (this);
				PAGE_LOGIN_ADMIN = notebook.append_page (admin_login_page);
				admin_login_page.show ();

				/* Administrator Page */
				var cpanel = new CPanel (this);
				cpanel.hexpand = true;
				cpanel.vexpand = true;
				PAGE_ADMIN = notebook.append_page (cpanel);
				cpanel.show ();


				pop_composite_child ();


				/* Grab default */
				emp_login_page.button_admin.clicked.connect ((t) => {
					admin_login_page.username_entry.grab_focus ();
					admin_login_page.button_login.grab_default ();
				});

				admin_login_page.button_cancel.clicked.connect ((t) => {
					emp_login_page.name_combobox.grab_focus ();
					emp_login_page.button_login.grab_default ();
				});

				emp_login_page.name_combobox.grab_focus ();
				emp_login_page.button_login.grab_default ();
			}

			public void show_error_dialog (string primary, string secondary) {
				var dialog = new MessageDialog (this, DialogFlags.MODAL,
				                                MessageType.ERROR, ButtonsType.OK,
				                                primary);
				dialog.secondary_text = secondary;
				dialog.run ();
				dialog.destroy ();
			}

		}

	}

}
