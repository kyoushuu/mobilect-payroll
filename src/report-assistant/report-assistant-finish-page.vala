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

		public class ReportAssistantFinishPage : ReportAssistantPage {

			public ReportAssistantFinishPage (ReportAssistant assistant) {
				base (assistant);


				push_composite_child ();


				var label = new Label (_("The report has been successfully created.\n\nClick the button below to select another action."));
				label.xalign = 0.0f;
				this.add (label);
				label.show ();

				var button = new Button.with_label (_("Select another action"));
				button.clicked.connect (() => {
					assistant.set_current_page (ReportAssistant.Pages.CONFIRM);
				});
				this.add (button);
				button.show ();

				pop_composite_child ();
			}

		}

	}

}
