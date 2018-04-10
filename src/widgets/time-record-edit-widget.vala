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

		public class TimeRecordEditWidget : Box {

			public Grid grid { get; private set; }

			public ComboBox employee_combobox { get; private set; }

			public DateTimeEntry start_entry { get; private set; }
			public DateTimeEntry end_entry { get; private set; }

			public CheckButton open_end_check { get; private set; }

			private TimeRecord _time_record;
			public TimeRecord time_record {
				get {
					return _time_record;
				}
				set {
					_time_record = value;

					if (value != null) {
						var dt = new DateTime.now_local ();
						start_entry.set_date_time (value.start?? dt);
						end_entry.set_date_time (value.end?? dt);

						var tr_null = (value.end == null);
						open_end_check.active = tr_null;
						end_entry.sensitive = !tr_null;

						var employees = time_record.database.get_employees ();
						employee_combobox.model = employees;

						if (_time_record.employee != null) {
							TreeIter iter;

							if (employees.get_iter_with_id (out iter, _time_record.employee.id)) {
								employee_combobox.set_active_iter (iter);
							}
						}
					}
				}
			}


			public TimeRecordEditWidget (TimeRecord time_record) {
				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add (grid);

				var employee_label = new Label (_("_Employee:"));
				employee_label.use_underline = true;
				employee_label.xalign = 0.0f;
				grid.add (employee_label);

				employee_combobox = new ComboBox ();
				employee_combobox.hexpand = true;
				grid.attach_next_to (employee_combobox,
				                     employee_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var employee_cell_renderer = new CellRendererText ();
				employee_combobox.pack_start (employee_cell_renderer, true);
				employee_combobox.add_attribute (employee_cell_renderer,
				                                 "text", EmployeeList.Columns.NAME);

				var start_label = new Label (_("_Start:"));
				start_label.use_underline = true;
				start_label.xalign = 0.0f;
				grid.add (start_label);

				start_entry = new DateTimeEntry ();
				start_entry.hexpand = true;
				grid.attach_next_to (start_entry,
				                     start_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var end_label = new Label (_("_End:"));
				end_label.use_underline = true;
				end_label.xalign = 0.0f;
				grid.add (end_label);

				end_entry = new DateTimeEntry ();
				end_entry.hexpand = true;
				grid.attach_next_to (end_entry,
				                     end_label,
				                     PositionType.RIGHT,
				                     2, 1);

				open_end_check = new CheckButton.with_mnemonic (_("_Open end"));
				open_end_check.hexpand = true;
				open_end_check.toggled.connect ((t) => {
					end_entry.sensitive = !open_end_check.active;
				});

				grid.attach_next_to (open_end_check,
				                     end_label,
				                     PositionType.BOTTOM,
				                     3, 1);

				this.time_record = time_record;
			}

			public void save () {
				if (this._time_record != null) {
					TreeIter iter;
					Employee employee;
					if (this.employee_combobox.get_active_iter (out iter)) {
						this.employee_combobox.model.get (iter, EmployeeList.Columns.OBJECT, out employee);
						this._time_record.employee = employee;
					}

					this._time_record.start = this.start_entry.get_date_time ();
					this._time_record.end = (this.open_end_check.active)? null : this.end_entry.get_date_time ();
				}
			}

		}

	}

}
