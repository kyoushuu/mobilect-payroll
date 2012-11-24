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

		public class ReportAssistantBasicInfoPage : ReportAssistantPage {

			public Grid grid { get; private set; }

			public RadioButton regular_radio { get; private set; }
			public RadioButton overtime_radio { get; private set; }
			public RadioButton irregular_radio { get; private set; }
			public DateSpinButton start_spin { get; private set; }
			public DateSpinButton end_spin { get; private set; }
			public ComboBox branch_combobox { get; private set; }
			public EmployeeList list;


			public ReportAssistantBasicInfoPage (ReportAssistant assistant) {
				base (assistant);


				push_composite_child ();


				var label = new Label (_("Select the branch, type and date for the report below.\n\nFor semi-monthly reports, the start date should be the 1st or 15th day of the month, with the end date 16th or last day of the month, respectively."));
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

				var type_label = new Label (_("Type:"));
				type_label.xalign = 0.0f;
				grid.add (type_label);
				type_label.show ();

				regular_radio = new RadioButton.with_mnemonic (null, _("_Semi-Monthly"));
				regular_radio.toggled.connect (changed);
				grid.attach_next_to (regular_radio,
				                     type_label,
				                     PositionType.RIGHT,
				                     1, 1);
				regular_radio.show ();

				overtime_radio = new RadioButton.with_mnemonic_from_widget (regular_radio, _("Monthly _Overtime"));
				overtime_radio.toggled.connect (changed);
				grid.attach_next_to (overtime_radio,
				                     regular_radio,
				                     PositionType.BOTTOM,
				                     1, 1);
				overtime_radio.show ();

				irregular_radio = new RadioButton.with_mnemonic_from_widget (overtime_radio, _("Weekly _Overtime"));
				irregular_radio.toggled.connect (changed);
				grid.attach_next_to (irregular_radio,
				                     overtime_radio,
				                     PositionType.BOTTOM,
				                     1, 1);
				irregular_radio.show ();

				var period_label = new Label.with_mnemonic (_("_Period:"));
				period_label.xalign = 0.0f;
				grid.add (period_label);
				period_label.show ();

				start_spin = new DateSpinButton ();
				start_spin.value_changed.connect (changed);
				grid.attach_next_to (start_spin,
				                     period_label,
				                     PositionType.RIGHT,
				                     1, 1);
				period_label.mnemonic_widget = start_spin;
				start_spin.show ();

				end_spin = new DateSpinButton ();
				end_spin.value_changed.connect (changed);
				grid.attach_next_to (end_spin,
				                     start_spin,
				                     PositionType.BOTTOM,
				                     1, 1);
				end_spin.show ();

				var branch_label = new Label.with_mnemonic (_("_Branch:"));
				branch_label.xalign = 0.0f;
				grid.add (branch_label);
				branch_label.show ();

				branch_combobox = new ComboBox.with_model (assistant.parent_window.app.database.branch_list);
				branch_combobox.hexpand = true;
				branch_combobox.changed.connect (changed);
				grid.attach_next_to (branch_combobox,
				                     branch_label,
				                     PositionType.RIGHT,
				                     1, 1);
				branch_label.mnemonic_widget = branch_combobox;
				branch_combobox.show ();

				var branch_cell_renderer = new CellRendererText ();
				branch_combobox.pack_start (branch_cell_renderer, true);
				branch_combobox.add_attribute (branch_cell_renderer,
				                               "text", BranchList.Columns.NAME);


				pop_composite_child ();


				/* Set default period */
				Date start, end;
				get_current_period (out start, out end);
				start_spin.date = start;
				end_spin.date = end;

				/* Set default branch */
				TreeIter iter;
				Branch branch;

				if (branch_combobox.model.get_iter_first (out iter)) {
					branch_combobox.set_active_iter (iter);
					branch_combobox.model.get (iter, BranchList.Columns.OBJECT, out branch);
					list = assistant.parent_window.app.database.employee_list
						.get_subset_with_branch (branch)
						.get_subset_is_regular (true);
				}
			}

			public void changed () {
				TreeIter iter;
				Branch branch;

				if (assistant.get_current_page () < 0) {
					return;
				}

				if (branch_combobox.get_active_iter (out iter)) {
					branch_combobox.model.get (iter, BranchList.Columns.OBJECT, out branch);
					list = assistant.parent_window.app.database.employee_list
						.get_subset_with_branch (branch)
						.get_subset_is_regular (!irregular_radio.active);
				} else {
					assistant.set_page_complete (this, false);
					return;
				}

				if (regular_radio.active) {
					var start = start_spin.date;

					if (start.get_day () != 1 && start.get_day () != 16) {
						assistant.set_page_complete (this, false);
						return;
					}

					var period = (int) Math.round ((start.get_day () - 1) / 30.0);

					DateDay last_day;
					if (period == 0) {
						last_day = 15;
					} else {
						last_day = 31;
						while (!Date.valid_dmy (last_day,
						                        start.get_month (),
						                        start.get_year ())) {
							last_day--;
						}
					}

					var end = end_spin.date;
					var correct_end = Date ();
					correct_end.set_dmy (last_day, start.get_month (), start.get_year ());
					if (correct_end.compare (end) != 0) {
						assistant.set_page_complete (this, false);
						return;
					}
				}

				assistant.set_page_complete (this, true);
			}

		}

	}

}
