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
using Config;
using Portability;


namespace Mobilect {

	namespace Payroll {

		public class Window : Gtk.Window {

			public const string ACTION_TOOLBAR = "view-toolbar";
			public const string ACTION_STATUSBAR = "view-statusbar";

			public enum Page {
				LOGIN_EMPLOYEE,
				LOGIN_ADMIN,
				CONTROL_PANEL
			}

			public Application app { get; private set; }

			public UIManager ui_manager { get; private set; }
			public MenuBar menubar { get; private set; }
			public Toolbar toolbar { get; private set; }
			public Statusbar statusbar { get; private set; }
			public Notebook notebook { get; private set; }


			public Window (Application app) {
				this.title = _("Mobilect Payroll");
				this.application = app;
				this.app = app;
				this.default_width = 600;
				this.default_height = 400;
				this.icon_name = PACKAGE;


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
						accelerator = _("<Primary>Q"),
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
							help (null, null);
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
							                   "copyright", _("Copyright © 2012 Mobilect Power Corp."),
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
						name = ACTION_TOOLBAR,
						label = _("_Toolbar"),
						tooltip = _("Show or hide the toolbar")
					},
					Gtk.ToggleActionEntry () {
						name = ACTION_STATUSBAR,
						label = _("_Statusbar"),
						tooltip = _("Show or hide the statusbar")
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
				toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);
				box.add (toolbar);

				/* Bind toolbar visibility to setting */
				this.app.settings.view.bind ("toolbar-visible",
				                             toolbar,
				                             "visible", SettingsBindFlags.DEFAULT);
				this.app.settings.view.bind ("toolbar-visible",
				                             action_group.get_action (ACTION_TOOLBAR),
				                             "active", SettingsBindFlags.DEFAULT);


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
				notebook.insert_page (emp_login_page, null, Page.LOGIN_EMPLOYEE);
				emp_login_page.show ();

				/* Administrator Login Page */
				var admin_login_page = new AdminLoginPage (this);
				notebook.insert_page (admin_login_page, null, Page.LOGIN_ADMIN);
				admin_login_page.show ();

				/* Control Panel Page */
				var cpanel = new CPanel (this);
				cpanel.hexpand = true;
				cpanel.vexpand = true;
				notebook.insert_page (cpanel, null, Page.CONTROL_PANEL);
				cpanel.show ();

				/* Bind employee login page visibility to setting */
				this.app.settings.view.bind ("employee-log-in",
				                             emp_login_page,
				                             "visible", SettingsBindFlags.DEFAULT);
				this.app.settings.view.bind ("employee-log-in",
				                             admin_login_page.button_cancel,
				                             "visible", SettingsBindFlags.DEFAULT);


				statusbar = new Statusbar ();
				box.add (statusbar);
				statusbar.show ();

				/* Bind toolbar visibility to setting */
				this.app.settings.view.bind ("statusbar-visible",
				                             statusbar,
				                             "visible", SettingsBindFlags.DEFAULT);
				this.app.settings.view.bind ("statusbar-visible",
				                             action_group.get_action (ACTION_STATUSBAR),
				                             "active", SettingsBindFlags.DEFAULT);


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

				if (this.app.settings.view.get_boolean ("employee-log-in")) {
					emp_login_page.name_combobox.grab_focus ();
					emp_login_page.button_login.grab_default ();
				} else {
					admin_login_page.username_entry.grab_focus ();
					admin_login_page.button_login.grab_default ();
				}
			}

			public void show_error_dialog (Gtk.Window? parent = null, string primary, string secondary) {
				var dialog = new MessageDialog (parent?? this, DialogFlags.MODAL,
				                                MessageType.ERROR, ButtonsType.OK,
				                                primary);
				dialog.secondary_text = secondary;
				dialog.run ();
				dialog.destroy ();
			}

			public void help (string? name, string? link_id) {
				try {
					var page = Path.build_filename(get_prefix (), "share", "help", "C",
					                               name?? PACKAGE,
					                               "%s.html".printf (link_id?? "index"));

					if (AppInfo.get_default_for_uri_scheme ("help") == null &&
					    FileUtils.test (page, FileTest.IS_REGULAR)) {
						if (!show_file (this, page)) {
							warning ("Failed to display the help");
						}
					} else {
						show_uri (get_screen (),
						          "help:%s/%s".printf (name?? PACKAGE, link_id?? "index"),
						          CURRENT_TIME);
					}
				} catch (Error e) {
					show_error_dialog (null, _("Failed to display the help"), e.message);
				}
			}

		}

	}

}
