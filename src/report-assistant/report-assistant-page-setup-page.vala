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

		public class ReportAssistantPageSetupPage : ReportAssistantPage {

			public CheckButton continuous_check { get; private set; }


			public ReportAssistantPageSetupPage (ReportAssistant assistant) {
				base (assistant);


				push_composite_child ();


				var label = new Label (_("You may change the page setup for the report below."));
				label.xalign = 0.0f;
				this.add (label);
				label.show ();

				var page_setup_button = new Button.from_stock (Stock.PAGE_SETUP);
				page_setup_button.expand = false;
				page_setup_button.clicked.connect ((b) => {
					var new_page_setup = print_run_page_setup_dialog (assistant, assistant.page_setup, assistant.print_settings);

					try {
						assistant.page_setup = new_page_setup;
						assistant.page_setup.to_file (assistant.parent_window.app.settings.page_setup);

						assistant.print_settings.to_file (assistant.parent_window.app.settings.print_settings);
					} catch (Error e) {
						assistant.parent_window.show_error_dialog (_("Failed to save page setup and print settings"),
						                                           e.message);
					}
				});
				this.add (page_setup_button);
				page_setup_button.show ();

				continuous_check = new CheckButton.with_label (_("Use continuous paper"));
				continuous_check.active = assistant.continuous;
				continuous_check.toggled.connect ((t) => {
					assistant.continuous = continuous_check.active;
				});
				this.add (continuous_check);
				continuous_check.show ();


				pop_composite_child ();
			}

		}

	}

}
