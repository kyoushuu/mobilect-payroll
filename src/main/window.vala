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
						name = "edit-preferences",
						stock_id = Stock.PREFERENCES,
						tooltip = _("Preferences"),
						callback = (a) => {
							destroy ();
						}
					},
					Gtk.ActionEntry () {
						name = "format",
						label = _("_Format")
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

				var action_group = new Gtk.ActionGroup ("payroll");
				action_group.add_actions (actions, this);

				string ui =
					"<ui>" +
					"  <menubar name=\"menubar\">" +
					"    <menu name=\"FileMenu\" action=\"file\">" +
					"      <placeholder name=\"FileMenuSaveAdditions\" />" +
					"      <separator/>" +
					"      <placeholder name=\"FileMenuAdditions\" />" +
					"      <separator/>" +
					"      <placeholder name=\"FileMenuExportAdditions\" />" +
					"      <separator/>" +
					"      <placeholder name=\"FileMenuCloseAdditions\" />" +
					"      <menuitem name=\"Quit\" action=\"file-quit\" />" +
					"    </menu>" +
					"    <menu name=\"EditMenu\" action=\"edit\">" +
					"      <placeholder name=\"EditMenuAdditions\" />" +
					"      <separator/>" +
					"      <menuitem name=\"Preferences\" action=\"edit-preferences\" />" +
					"    </menu>" +
					"    <menu name=\"FormatMenu\" action=\"format\">" +
					"      <placeholder name=\"FormatMenuAdditions\" />" +
					"    </menu>" +
					"    <placeholder name=\"MenuAdditions\" />" +
					"    <menu name=\"HelpMenu\" action=\"help\">" +
					"      <menuitem name=\"Contents\" action=\"help-contents\"/>" +
					"      <separator/>" +
					"      <placeholder name=\"HelpMenuAdditions\" />" +
					"      <separator/>" +
					"      <menuitem name=\"About\" action=\"help-about\"/>" +
					"    </menu>" +
					"  </menubar>" +
					"  <toolbar action=\"toolbar\">" +
					"    <placeholder name=\"EditToolbarAdditions\" />" +
					"    <separator/>" +
					"    <placeholder name=\"FormatToolbarAdditions\" />" +
					"    <separator/>" +
					"    <placeholder name=\"ToolbarAdditions\" />" +
					"    <separator/>" +
					"    <placeholder name=\"FileToolbarSaveAdditions\" />" +
					"    <separator/>" +
					"    <placeholder name=\"FileToolbarAdditions\" />" +
					"    <separator/>" +
					"    <placeholder name=\"FileToolbarExportAdditions\" />" +
					"    <separator/>" +
					"    <placeholder name=\"FileToolbarCloseAdditions\" />" +
					"    <separator expand=\"true\" />" +
					"    <toolitem name=\"Quit\" action=\"file-quit\" />" +
					"  </toolbar>" +
					"</ui>";

				try {
					ui_manager = new UIManager ();
					ui_manager.insert_action_group (action_group, -1);
					ui_manager.add_ui_from_string (ui, -1);
					this.add_accel_group (ui_manager.get_accel_group ());
					box.add (ui_manager.get_widget ("/menubar"));
				} catch (Error e) {
					error ("Failed to add UI to UI Manager: %s", e.message);
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
					admin_login_page.button_login.grab_default ();
				});

				admin_login_page.button_cancel.clicked.connect ((t) => {
					emp_login_page.name_combobox.grab_focus ();
					emp_login_page.button_login.grab_default ();
				});

				emp_login_page.name_combobox.grab_focus ();
				emp_login_page.button_login.grab_default ();

				Log.set_handler ("Mobilect-Payroll",
				                 LogLevelFlags.LEVEL_CRITICAL |
				                 LogLevelFlags.LEVEL_WARNING |
				                 LogLevelFlags.LEVEL_MESSAGE,
				                 (d, l, m) => {
													 var text = m;
													 MessageType type = MessageType.INFO;
													 if (l == LogLevelFlags.LEVEL_CRITICAL) {
														 text = _("Critical Error");
														 type = MessageType.ERROR;
													 } else if (l == LogLevelFlags.LEVEL_WARNING) {
														 text = _("Warning");
														 type = MessageType.WARNING;
													 }

													 var dialog = new MessageDialog (this, DialogFlags.DESTROY_WITH_PARENT,
													                                 type, ButtonsType.OK,
													                                 text);

													 if (l != LogLevelFlags.LEVEL_MESSAGE) {
														 dialog.secondary_text = m;
													 }

													 dialog.run ();
													 dialog.destroy ();
												 });
			}

			public void show_error_dialog (string primary, string secondary) {
				var e_dialog = new MessageDialog (this, DialogFlags.MODAL,
				                                  MessageType.ERROR, ButtonsType.OK,
				                                  primary);
				e_dialog.secondary_text = secondary;
				e_dialog.run ();
				e_dialog.destroy ();
			}

		}

	}

}
