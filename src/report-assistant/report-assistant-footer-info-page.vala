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

		public class ReportAssistantFooterInfoPage : ReportAssistantPage {

			public Grid grid { get; private set; }

			public Entry preparer_entry { get; private set; }
			public Entry approver_entry { get; private set; }
			public Entry approver_position_entry { get; private set; }


			public ReportAssistantFooterInfoPage (ReportAssistant assistant) {
				base (assistant);


				push_composite_child ();


				var label = new Label (_("Set the information shown in the footer of the report below."));
				label.xalign = 0.0f;
				this.add (label);
				label.show ();

				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 6;
				this.add (grid);
				grid.show ();

				var preparer_label = new Label.with_mnemonic (_("P_reparer:"));
				preparer_label.xalign = 0.0f;
				grid.add (preparer_label);
				preparer_label.show ();

				preparer_entry = new Entry ();
				grid.attach_next_to (preparer_entry,
				                     preparer_label,
				                     PositionType.RIGHT,
				                     1, 1);
				preparer_entry.show ();

				var approver_label = new Label.with_mnemonic (_("_Approver:"));
				approver_label.xalign = 0.0f;
				grid.add (approver_label);
				approver_label.show ();

				approver_entry = new Entry ();
				grid.attach_next_to (approver_entry,
				                     approver_label,
				                     PositionType.RIGHT,
				                     1, 1);
				approver_entry.show ();

				approver_position_entry = new Entry ();
				grid.attach_next_to (approver_position_entry,
				                     approver_entry,
				                     PositionType.BOTTOM,
				                     1, 1);
				approver_position_entry.show ();


				var report_settings = assistant.parent_window.app.settings.report;
				preparer_entry.text = report_settings.get_string ("preparer");
				approver_entry.text = report_settings.get_string ("approver");
				approver_position_entry.text = report_settings.get_string ("approver-position");


				pop_composite_child ();
			}

		}

	}

}
