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
				this.tab_pos = PositionType.TOP;

				window.notebook.switch_page.connect ((t, p, n) => {
					if (current_page != null) {
						if (n == Window.Page.CONTROL_PANEL) {
							current_page.changed_to ();
							action_group.visible = true;
						} else {
							current_page.changed_from ();
							action_group.visible = false;
						}
					}
				});


				try {
						window.ui_manager.add_ui_from_resource ("/com/mobilectpower/Payroll/mobilect-payroll-cpanel-ui.xml");
				} catch (Error e) {
					warning ("Failed to add UI to UI Manager: %s", e.message);
				}

				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = "cpanel-close",
						stock_id = Stock.CLOSE,
						tooltip = _("Close control panel"),
						callback = (a) => {
							this.window.notebook.page = this.window.app.settings.view.get_boolean ("employee-log-in")?
								Window.Page.LOGIN_EMPLOYEE : Window.Page.LOGIN_ADMIN;
						}
					},
					Gtk.ActionEntry () {
						name = "cpanel-preferences",
						stock_id = Stock.PREFERENCES,
						tooltip = _("Preferences"),
						callback = (a) => {
							var dialog = new PreferencesDialog (this.window);
							dialog.response.connect ((d, r) => {
								if (r == ResponseType.ACCEPT) {
									d.destroy ();
								}
							});
							dialog.show ();
						}
					}
				};

				action_group = new Gtk.ActionGroup ("cpanel");
				action_group.add_actions (actions, this);
				window.ui_manager.insert_action_group (action_group, -1);

				this.add_page (new CPanelEmployees (this), _("Employees"));
				this.add_page (new CPanelTimeRecords (this), _("Time Records"));
				this.add_page (new CPanelDeductions (this), _("Deductions"));
				this.add_page (new CPanelAdministrators (this), _("Administrators"));
				this.add_page (new CPanelBranches (this), _("Branches"));
				this.add_page (new CPanelHolidays (this), _("Holidays"));
				this.add_page (new CPanelReport (this), _("Report"));
			}

			public void add_page (CPanelTab tab, string title) {
				this.append_page (tab, new Label (title));
				tab.show ();
			}

			public override void switch_page (Widget page, uint page_num) {
				base.switch_page (page, page_num);

				if (current_page != null) {
					current_page.changed_from ();
				}

				var tab = (page as CPanelTab);
				tab.changed_to ();

				current_page = tab;
			}

		}

	}

}
