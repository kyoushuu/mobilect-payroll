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

		public class EmployeeEditWidget : Box {

			public Grid grid { get; private set; }

			public Entry lastname_entry { get; private set; }
			public Entry firstname_entry { get; private set; }
			public Entry middlename_entry { get; private set; }
			public Entry tin_entry { get; private set; }
			public SpinButton rate_spin { get; private set; }

			private Employee _employee;
			public Employee employee {
				get {
					return _employee;
				}
				set {
					_employee = value;

					if (value != null) {
						lastname_entry.text = value.lastname?? "";
						firstname_entry.text = value.firstname?? "";
						middlename_entry.text = value.middlename?? "";
						tin_entry.text = value.tin?? "";
						rate_spin.value = value.rate;
					}
				}
			}


			public EmployeeEditWidget (Employee employee) {
				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add (grid);

				var lastname_label = new Label (_("_Last Name:"));
				lastname_label.use_underline = true;
				lastname_label.xalign = 0.0f;
				grid.add (lastname_label);

				lastname_entry = new Entry ();
				lastname_entry.hexpand = true;
				lastname_entry.activates_default = true;
				grid.attach_next_to (lastname_entry,
				                     lastname_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var firstname_label = new Label (_("_First Name:"));
				firstname_label.use_underline = true;
				firstname_label.xalign = 0.0f;
				grid.add (firstname_label);

				firstname_entry = new Entry ();
				firstname_entry.hexpand = true;
				firstname_entry.activates_default = true;
				grid.attach_next_to (firstname_entry,
				                     firstname_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var middlename_label = new Label (_("_Middle Name:"));
				middlename_label.use_underline = true;
				middlename_label.xalign = 0.0f;
				grid.add (middlename_label);

				middlename_entry = new Entry ();
				middlename_entry.hexpand = true;
				middlename_entry.activates_default = true;
				grid.attach_next_to (middlename_entry,
				                     middlename_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var tin_label = new Label (_("_TIN Number:"));
				tin_label.use_underline = true;
				tin_label.xalign = 0.0f;
				grid.add (tin_label);

				tin_entry = new Entry ();
				tin_entry.hexpand = true;
				tin_entry.activates_default = true;
				grid.attach_next_to (tin_entry,
				                     tin_label,
				                     PositionType.RIGHT,
				                     2, 1);

				var rate_label = new Label (_("_Rate:"));
				rate_label.use_underline = true;
				rate_label.xalign = 0.0f;
				grid.add (rate_label);

				rate_spin = new SpinButton (new Adjustment (3500,
				                                            0, 1000000,
				                                            10, 100,
				                                            0),
				                            100, 0);
				grid.attach_next_to (rate_spin,
				                     rate_label,
				                     PositionType.RIGHT,
				                     2, 1);

				this.employee = employee;
			}

			public void save () {
				if (this._employee != null) {
					this._employee.lastname = this.lastname_entry.text;
					this._employee.firstname = this.firstname_entry.text;
					this._employee.middlename = this.middlename_entry.text;
					this._employee.tin = this.tin_entry.text;
					this._employee.rate = this.rate_spin.get_value_as_int ();
				}
			}

		}

	}

}
