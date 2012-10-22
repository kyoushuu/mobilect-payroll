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
using Pango;
using Gee;


namespace Mobilect {

	namespace Payroll {

		public class CPanelReport : CPanelTab {

			public const string ACTION = "cpanel-report";
			public const string ACTION_NEW = "cpanel-report-new";
			public const string ACTION_PAGE_SETUP = "cpanel-report-page-setup";

			public Grid grid { get; private set; }

			private PageSetup page_setup;
			private PrintSettings print_settings;


			/* Philippines Legal / FanFold German Legal / US Foolscap */
			public const string PAPER_NAME_FANFOLD_GERMAN_LEGAL = "na_foolscap";


			public CPanelReport (CPanel cpanel) {
				base (cpanel, ACTION, "/com/mobilectpower/Payroll/mobilect-payroll-cpanel-report-ui.xml");

				this.orientation = Orientation.HORIZONTAL;

				/* Load page setup */
				if (FileUtils.test (this.cpanel.window.app.settings.page_setup, FileTest.IS_REGULAR)) {
					try {
						page_setup = new PageSetup.from_file (this.cpanel.window.app.settings.page_setup);
					} catch (Error e) {
						this.cpanel.window.show_error_dialog (_("Failed to load page setup"),
						                                      e.message);
					}
				} else {
					page_setup = new PageSetup ();
					page_setup.set_paper_size (new PaperSize (PAPER_NAME_FANFOLD_GERMAN_LEGAL));
				}

				/* Load print settings */
				if (FileUtils.test (this.cpanel.window.app.settings.print_settings, FileTest.IS_REGULAR)) {
					try {
						print_settings = new PrintSettings.from_file (this.cpanel.window.app.settings.print_settings);
					} catch (Error e) {
						this.cpanel.window.show_error_dialog (_("Failed to load print settings"),
						                                      e.message);
					}
				} else {
					print_settings = new PrintSettings ();
					print_settings.set_paper_size (new PaperSize (PAPER_NAME_FANFOLD_GERMAN_LEGAL));
				}


				Gtk.ActionEntry[] actions = {
					Gtk.ActionEntry () {
						name = ACTION_NEW,
						stock_id = Stock.NEW,
						tooltip = _("Create a new report using the Report Assistant"),
						callback = (a) => {
							var assistant = new ReportAssistant (this.cpanel.window, page_setup, print_settings);
							assistant.cancel.connect ((assistant) => {
														assistant.destroy ();
													});
							assistant.close.connect ((assistant) => {
														assistant.destroy ();
													});
							assistant.show ();
						}
					},
					Gtk.ActionEntry () {
						name = ACTION_PAGE_SETUP,
						stock_id = Stock.PAGE_SETUP,
						tooltip = _("Customize the page size, orientation and margins"),
						callback = (a) => {
							var new_page_setup = print_run_page_setup_dialog (this.cpanel.window, page_setup, print_settings);

							try {
								page_setup = new_page_setup;
								page_setup.to_file (this.cpanel.window.app.settings.page_setup);

								print_settings.to_file (this.cpanel.window.app.settings.print_settings);
							} catch (Error e) {
								this.cpanel.window.show_error_dialog (_("Failed to save page setup and print settings"),
								                                      e.message);
							}
						}
					}
				};

				this.action_group.add_actions (actions, this);
				this.action_group.get_action (ACTION_NEW).is_important = true;
			}

		}

	}

}
