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

		public class FindTimeRecordDialog : Dialog {

			public Grid grid { get; private set; }

			public DateSpinButton start_spin { get; private set; }
			public DateSpinButton end_spin { get; private set; }

			public CheckButton branch_check { get; private set; }
			public ComboBox branch_combobox { get; private set; }

			public CheckButton employee_check { get; private set; }
			public ComboBox employee_combobox { get; private set; }


			public FindTimeRecordDialog (Window parent) {
				base (_("Find"), parent);

				this.action = Stock.FIND;
				this.help_link_id = "time-records-search";

				var content_area = this.get_content_area ();


				push_composite_child ();


				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_homogeneous = true;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				grid.border_width = 5;
				content_area.add (grid);
				grid.show ();


				var start_date_label = new Label.with_mnemonic (_("_Start:"));
				start_date_label.xalign = 0.0f;
				grid.add (start_date_label);
				start_date_label.show ();

				start_spin = new DateSpinButton ();
				start_spin.hexpand = true;
				grid.attach_next_to (start_spin,
				                     start_date_label,
				                     PositionType.RIGHT,
				                     1, 1);
				start_date_label.mnemonic_widget = start_spin;
				start_spin.changed.connect (changed);
				start_spin.show ();


				var end_date_label = new Label.with_mnemonic (_("_End:"));
				end_date_label.xalign = 0.0f;
				grid.add (end_date_label);
				end_date_label.show ();

				end_spin = new DateSpinButton ();
				end_spin.hexpand = true;
				grid.attach_next_to (end_spin,
				                     end_date_label,
				                     PositionType.RIGHT,
				                     1, 1);
				end_date_label.mnemonic_widget = end_spin;
				end_spin.changed.connect (changed);
				end_spin.show ();


				branch_check = new CheckButton.with_mnemonic (_("_Branch:"));
				branch_check.active = false;
				branch_check.toggled.connect ((t) =>
				                              {
												  branch_combobox.sensitive = t.active;
												  employee_check.sensitive = t.active && branch_combobox.active >= 0;
												  employee_combobox.sensitive = employee_check.sensitive && employee_check.active;

												  changed ();
											  });
				grid.add (branch_check);
				branch_check.show ();

				branch_combobox = new ComboBox.with_model (parent.app.database.branch_list);
				branch_combobox.hexpand = true;
				branch_combobox.sensitive = false;
				branch_combobox.changed.connect ((w) =>
				                                 {
													 TreeIter iter;
													 if (branch_combobox.get_active_iter (out iter)) {
														 employee_combobox.model = parent.app.database.employee_list.
															 get_subset_with_branch (parent.app.database.branch_list.
															                         get_from_iter (iter));
														 employee_combobox.active = -1;
														 employee_check.sensitive = true;

														 changed ();
													 } else {
														 employee_check.sensitive = false;
														 employee_combobox.sensitive = false;
													 }
												 });
				grid.attach_next_to (branch_combobox,
				                     branch_check,
				                     PositionType.RIGHT,
				                     1, 1);
				branch_combobox.show ();

				var branch_cell_renderer = new CellRendererText ();
				branch_combobox.pack_start (branch_cell_renderer, true);
				branch_combobox.add_attribute (branch_cell_renderer,
				                               "text", BranchList.Columns.NAME);


				employee_check = new CheckButton.with_mnemonic (_("E_mployee:"));
				employee_check.sensitive = false;
				employee_check.toggled.connect ((t) =>
				                                {
													employee_combobox.sensitive = t.active;

													changed ();
												});
				grid.add (employee_check);
				employee_check.show ();

				employee_combobox = new ComboBox ();
				employee_combobox.hexpand = true;
				employee_combobox.sensitive = false;
				employee_combobox.changed.connect (changed);
				grid.attach_next_to (employee_combobox,
				                     employee_check,
				                     PositionType.RIGHT,
				                     1, 1);
				employee_combobox.show ();

				var employee_cell_renderer = new CellRendererText ();
				employee_combobox.pack_start (employee_cell_renderer, true);
				employee_combobox.add_attribute (employee_cell_renderer,
				                                 "text", EmployeeList.Columns.NAME);


				pop_composite_child ();


				changed ();
			}

			public Date get_start_date () {
				return start_spin.date;
			}

			public void set_start_dmy (int day, int month, int year) {
				start_spin.set_dmy (day, month, year);
			}

			public Date get_end_date () {
				return end_spin.date;
			}

			public void set_end_dmy (int day, int month, int year) {
				end_spin.set_dmy (day, month, year);
			}

			private void changed () {
				set_response_sensitive (ResponseType.ACCEPT,
				                        start_spin.date.compare (end_spin.date) <= 0 &&
				                        (!branch_check.active || branch_combobox.active >= 0) &&
				                        (!employee_check.sensitive || !employee_check.active || employee_combobox.active >= 0));
			}

		}

	}

}
