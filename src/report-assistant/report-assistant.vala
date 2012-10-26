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
using Pango;


namespace Mobilect {

	namespace Payroll {

		public class ReportAssistant : Assistant {

			public enum Pages {
				WELCOME,
				BASIC_INFO,
				SELECT_EMPLOYEES,
				FOOTER_INFO,
				PAGE_SETUP,
				FINISH,
				NUM
			}


			public Window parent_window { get; private set; }

			public UIManager ui_manager { get; private set; }

			public PageSetup page_setup { get; set; }
			public PrintSettings print_settings { get; set; }
			public bool continuous { get; set; }


			public ReportAssistant (Window parent, PageSetup page_setup, PrintSettings print_settings) {
				Object (title: _("Report Assistant"),
				        transient_for: parent);

				this.parent_window = parent;
				this.page_setup = page_setup;
				this.print_settings = print_settings;
				this.prepare.connect ((a, p) => {
							(p as ReportAssistantPage).prepare ();
						});

				this.ui_manager = new UIManager ();
				try {
					this.ui_manager.add_ui_from_resource ("/com/mobilectpower/Payroll/mobilect-payroll-report-assistant-ui.xml");
				} catch (Error e) {
					error ("Failed to add UI to UI Manager: %s", e.message);
				}


				ReportAssistantPage page;


				page = new ReportAssistantWelcomePage (this);
				insert_page (page, Pages.WELCOME);
				set_page_type (page, AssistantPageType.INTRO);
				set_page_title (page, _("Welcome"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantBasicInfoPage (this);
				insert_page (page, Pages.BASIC_INFO);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Basic Information"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantSelectEmployeesPage (this);
				insert_page (page, Pages.SELECT_EMPLOYEES);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Select Employees"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantFooterInfoPage (this);
				insert_page (page, Pages.FOOTER_INFO);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Footer Information"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantPageSetupPage (this);
				insert_page (page, Pages.PAGE_SETUP);
				set_page_type (page, AssistantPageType.CONTENT);
				set_page_title (page, _("Page Setup"));
				set_page_complete (page, true);
				page.show ();

				page = new ReportAssistantFinishPage (this);
				insert_page (page, Pages.FINISH);
				set_page_type (page, AssistantPageType.SUMMARY);
				set_page_title (page, _("Finish"));
				set_page_complete (page, true);
				page.show ();
			}

		}

	}

}
