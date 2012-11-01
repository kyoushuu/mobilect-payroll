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


namespace Mobilect {

	namespace Payroll {

		public class ReportAssistantApplyPage : ReportAssistantPage {

			public ProgressBar progress_bar { get; private set; }


			public ReportAssistantApplyPage (ReportAssistant assistant) {
				base (assistant);


				push_composite_child ();


				var label = new Label (_("Creating the report..."));
				label.xalign = 0.0f;
				this.add (label);
				label.show ();

				progress_bar = new ProgressBar ();
				progress_bar.ellipsize = EllipsizeMode.END;
				progress_bar.show_text = true;
				progress_bar.text = _("Please wait...");
				this.pack_end (progress_bar, true, false);
				progress_bar.show ();


				pop_composite_child ();
			}

			public override void prepare () {
				assistant.commit ();
			}

		}

	}

}
