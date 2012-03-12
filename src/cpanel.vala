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

		public class CPanel : Notebook {

			public weak Window window { get; internal set; }
			public weak CPanelTab current_page { get; internal set; }
			public Gtk.ActionGroup action_group { get; internal set; }

			public CPanel (Window window) {
				this.window = window;
				this.tab_pos = PositionType.LEFT;

				window.notebook.switch_page.connect ((t, p, n) => {
					if (current_page != null) {
						if (n == window.PAGE_ADMIN) {
							current_page.changed_to ();
							action_group.visible = true;
						} else {
							current_page.changed_from ();
							action_group.visible = false;
						}
					}
				});

				this.switch_page.connect ((t, p, n) => {
					if (current_page != null) {
						current_page.changed_from ();
					}

					var page = (p as CPanelTab);
					page.changed_to ();

					current_page = page;
				});


				string ui_def =
					"<ui>" +
					"  <menubar name=\"menubar\">" +
					"    <placeholder name=\"MenuAdditions\">" +
					"      <menu name=\"CPanelMenu\" action=\"cpanel\">" +
					"        <menuitem name=\"Logout\" action=\"cpanel-logout\" />" +
					"      </menu>" +
					"      <placeholder name=\"CPanelMenuAdditions\" />" +
					"    </placeholder>" +
					"  </menubar>" +
					"  <toolbar action=\"toolbar\">" +
					"    <placeholder name=\"ToolbarAdditions\">" +
					"      <placeholder name=\"CPanelToolItems\">" +
					"        <placeholder name=\"CPanelToolItemsAdditions\" />" +
					"        <separator />" +
					"        <toolitem name=\"Logout\" action=\"cpanel-logout\" />" +
					"      </placeholder>" +
					"    </placeholder>" +
					"  </toolbar>" +
					"</ui>";
				window.ui_manager.add_ui_from_string (ui_def, -1);

				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name="cpanel",
						stock_id=null,
						label="_Administrator"
					},
					Gtk.ActionEntry () {
						name = "cpanel-logout",
						stock_id = Stock.STOP,
						label = "_Log out",
						tooltip = "Log out",
						callback = (a) => {
							this.window.notebook.page = this.window.PAGE_LOGIN_EMPLOYEE;
						}
					}
				};

				action_group = new Gtk.ActionGroup ("cpanel");
				action_group.add_actions (actions, this);
				window.ui_manager.insert_action_group (action_group, -1);

				this.add_page (new CPanelEmployees (this), _("Employees"));
				this.add_page (new CPanelAdministrators (this), _("Administrators"));
				this.add_page (new CPanelTimeRecords (this), _("Time Records"));
				this.add_page (new CPanelPreferences (this), _("Preferences"));
			}

			public void add_page (CPanelTab tab, string title) {
				this.append_page (tab, new Label.with_mnemonic (title));

				window.ui_manager.insert_action_group (tab.action_group, -1);
				if (tab.ui_def != null) {
					window.ui_manager.add_ui_from_string (tab.ui_def, -1);
				}
			}

		}

	}

}
