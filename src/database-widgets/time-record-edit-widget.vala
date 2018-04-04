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

			public Grid grid { public get; private set; }

			public ComboBox employee_combobox { public get; private set; }

			public DateTimeSpinButton start_spin { public get; private set; }
			public DateTimeSpinButton end_spin { public get; private set; }

			public CheckButton open_end_check { public get; private set; }
			public CheckButton straight_time_check { public get; private set; }
			public CheckButton include_break_check { public get; private set; }

			public Label total_time_value_label { public get; private set; }

			private TimeRecord _time_record;
			public TimeRecord time_record {
				public get {
					return _time_record;
				}
				public set {
					_time_record = value;

					if (value != null) {
						var dt = new DateTime.now_local ();
						dt = dt.add_full (0, 0, 0, 0,
						                  -dt.get_minute (),
						                  -dt.get_second ());
						start_spin.set_date_time (value.start?? dt);
						end_spin.set_date_time (value.end?? start_spin.get_date_time ());

						var tr_null = (value.start != null && value.end == null);
						open_end_check.active = tr_null;
						end_spin.sensitive = !tr_null;

						straight_time_check.active = value.straight_time;
						include_break_check.active = value.include_break;

						var employees = time_record.database.employee_list;

						var sort = new TreeModelSort.with_model (employees);
						sort.set_default_sort_func ((model, a, b) => {
							var employee1 = a.user_data as Employee;
							var employee2 = b.user_data as Employee;

							if (employee1.regular != employee2.regular) {
								if (employee1.regular) {
									return -1;
								} else {
									return 1;
								}
							}

							return strcmp (employee1.get_name (),
							               employee2.get_name ());
						});

						employee_combobox.model = sort;

						if (_time_record.employee != null) {
							TreeIter iter, sort_iter;

							if (employees.get_iter_with_id (out iter, _time_record.employee.id)) {
								if (sort.convert_child_iter_to_iter (out sort_iter, iter)) {
									employee_combobox.set_active_iter (sort_iter);
								}
							}
						}
					}
				}
			}


			public TimeRecordEditWidget (TimeRecord time_record) {
				push_composite_child ();


				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_homogeneous = true;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add (grid);
				grid.show ();


				var employee_label = new Label.with_mnemonic (_("_Employee:"));
				employee_label.xalign = 0.0f;
				grid.add (employee_label);
				employee_label.show ();

				employee_combobox = new ComboBox ();
				employee_combobox.hexpand = true;
				grid.attach_next_to (employee_combobox,
				                     employee_label,
				                     PositionType.RIGHT,
				                     1, 1);
				employee_label.mnemonic_widget = employee_combobox;
				employee_combobox.show ();

				var employee_cell_renderer = new CellRendererText ();
				employee_combobox.pack_start (employee_cell_renderer, true);
				employee_combobox.add_attribute (employee_cell_renderer,
				                                 "text", EmployeeList.Columns.NAME);


				var start_label = new Label.with_mnemonic (_("S_tart:"));
				start_label.xalign = 0.0f;
				grid.add (start_label);
				start_label.show ();

				start_spin = new DateTimeSpinButton ();
				start_spin.value_changed.connect (() => { end_spin.set_date_time (start_spin.get_date_time ()); });
				start_spin.hexpand = true;
				grid.attach_next_to (start_spin,
				                     start_label,
				                     PositionType.RIGHT,
				                     1, 1);
				start_label.mnemonic_widget = start_spin.date_spin;
				start_spin.show ();


				var end_label = new Label.with_mnemonic (_("E_nd:"));
				end_label.xalign = 0.0f;
				grid.add (end_label);
				end_label.show ();

				end_spin = new DateTimeSpinButton ();
				end_spin.hexpand = true;
				grid.attach_next_to (end_spin,
				                     end_label,
				                     PositionType.RIGHT,
				                     1, 1);
				end_label.mnemonic_widget = end_spin.date_spin;
				end_spin.show ();


				open_end_check = new CheckButton.with_mnemonic (_("_Open end"));
				open_end_check.hexpand = true;
				open_end_check.toggled.connect ((t) => {
					end_spin.sensitive = !open_end_check.active;
				});
				grid.attach_next_to (open_end_check,
				                     end_label,
				                     PositionType.BOTTOM,
				                     2, 1);
				open_end_check.show ();


				straight_time_check = new CheckButton.with_mnemonic (_("St_raight time only"));
				straight_time_check.hexpand = true;
				grid.attach_next_to (straight_time_check,
				                     open_end_check,
				                     PositionType.BOTTOM,
				                     2, 1);
				straight_time_check.show ();


				include_break_check = new CheckButton.with_mnemonic (_("Include lunch break (Sundays only)"));
				include_break_check.hexpand = true;
				grid.attach_next_to (include_break_check,
				                     straight_time_check,
				                     PositionType.BOTTOM,
				                     2, 1);
				include_break_check.show ();


				var total_time_label = new Label.with_mnemonic (_("Total time:"));
				total_time_label.xalign = 0.0f;
				grid.add (total_time_label);
				total_time_label.show ();

				total_time_value_label = new Label (_("empty"));
				total_time_value_label.xalign = 0.0f;
				start_spin.value_changed.connect (() => { update_total_time (); });
				end_spin.value_changed.connect (() => { update_total_time (); });
				grid.attach_next_to (total_time_value_label,
				                     total_time_label,
				                     PositionType.RIGHT,
				                     1, 1);
				total_time_value_label.show ();


				pop_composite_child ();


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

					this._time_record.start = this.start_spin.get_date_time ();
					this._time_record.end = (this.open_end_check.active)? null : this.end_spin.get_date_time ();
					this._time_record.straight_time = straight_time_check.active;
					this._time_record.include_break = include_break_check.active;
				}
			}

			public void update_total_time () {
				var diff = end_spin.get_date_time ().difference (start_spin.get_date_time ());

				if (diff > 0) {
					var diff_array = new string[0];

					if (diff >= TimeSpan.HOUR) {
						var hours = diff / TimeSpan.HOUR;
						diff_array += ngettext("%d hour", "%d hours", (int) hours)
							.printf ((int) hours);
						diff %= TimeSpan.HOUR;
					}

					if (diff >= TimeSpan.MINUTE) {
						var minutes = diff / TimeSpan.MINUTE;
						diff_array += ngettext("%d minute", "%d minutes", (int) minutes)
							.printf ((int) minutes);
						diff %= TimeSpan.MINUTE;
					}

					diff_array += null;
					total_time_value_label.label = string.joinv (" ", diff_array);
				} else {
					total_time_value_label.label = _("empty");
				}
			}

		}

	}

}
