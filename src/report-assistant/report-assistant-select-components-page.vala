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

		public class ReportAssistantSelectComponentsPage : ReportAssistantPage {

			public Grid grid { get; private set; }

			public CheckButton payroll_check { get; private set; }
			public CheckButton payslip_check { get; private set; }


			public ReportAssistantSelectComponentsPage (ReportAssistant assistant) {
				base (assistant);


				push_composite_child ();


				var label = new Label (_("Select the components you want to be included to the report."));
				label.wrap = true;
				label.xalign = 0.0f;
				this.add (label);
				label.show ();

				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 6;
				this.add (grid);
				grid.show ();

				payroll_check = new CheckButton.with_mnemonic (_("Pay_roll"));
				payroll_check.active = true;
				grid.add (payroll_check);
				payroll_check.show ();

				payslip_check = new CheckButton.with_mnemonic (_("Pay_slip"));
				payslip_check.active = true;
				grid.attach_next_to (payslip_check,
				                     payroll_check,
				                     PositionType.BOTTOM,
				                     1, 1);
				payslip_check.show ();


				pop_composite_child ();
			}

		}

	}

}
