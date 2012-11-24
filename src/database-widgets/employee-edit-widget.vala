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

			public Grid grid { public get; private set; }

			public ComboBox branch_combobox { public get; private set; }

			public Entry lastname_entry { public get; private set; }
			public Entry firstname_entry { public get; private set; }
			public Entry middlename_entry { public get; private set; }
			public Entry tin_entry { public get; private set; }
			private Label rate_label { public get; private set; }
			public SpinButton rate_spin { public get; private set; }
			public CheckButton regular_check { public get; private set; }

			private Employee _employee;
			public Employee employee {
				public get {
					return _employee;
				}
				public set {
					_employee = value;

					if (value != null) {
						lastname_entry.text = value.lastname?? "";
						firstname_entry.text = value.firstname?? "";
						middlename_entry.text = value.middlename?? "";
						tin_entry.text = value.tin?? "";
						regular_check.active = value.regular;

						if (value.regular) {
							rate_label.set_text_with_mnemonic (_("_Rate:"));
							rate_spin.value = value.rate;
						} else {
							rate_label.set_text_with_mnemonic (_("_Rate (per day):"));
							rate_spin.value = value.rate_per_day;
						}

						var branches = employee.database.branch_list;
						branch_combobox.model = branches;

						if (_employee.branch != null) {
							TreeIter iter;

							if (branches.get_iter_with_id (out iter, _employee.branch.id)) {
								branch_combobox.set_active_iter (iter);
							}
						}
					}
				}
			}


			public EmployeeEditWidget (Employee employee) {
				push_composite_child ();


				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_homogeneous = true;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add (grid);
				grid.show ();


				var lastname_label = new Label.with_mnemonic (_("_Last Name:"));
				lastname_label.xalign = 0.0f;
				grid.add (lastname_label);
				lastname_label.show ();

				lastname_entry = new Entry ();
				lastname_entry.hexpand = true;
				lastname_entry.activates_default = true;
				lastname_entry.secondary_icon_tooltip_text = _("Last name is empty");
				lastname_entry.changed.connect ((e) => {
	if (lastname_entry.text_length > 0) {
		lastname_entry.secondary_icon_stock = null;
	} else {
		lastname_entry.secondary_icon_stock = Stock.DIALOG_WARNING;
	}
});
				grid.attach_next_to (lastname_entry,
				                     lastname_label,
				                     PositionType.RIGHT,
				                     1, 1);
				lastname_label.mnemonic_widget = lastname_entry;
				lastname_entry.show ();


				var firstname_label = new Label.with_mnemonic (_("_First Name:"));
				firstname_label.xalign = 0.0f;
				grid.add (firstname_label);
				firstname_label.show ();

				firstname_entry = new Entry ();
				firstname_entry.hexpand = true;
				firstname_entry.activates_default = true;
				grid.attach_next_to (firstname_entry,
				                     firstname_label,
				                     PositionType.RIGHT,
				                     1, 1);
				firstname_label.mnemonic_widget = firstname_entry;
				firstname_entry.show ();


				var middlename_label = new Label.with_mnemonic (_("_Middle Name:"));
				middlename_label.xalign = 0.0f;
				grid.add (middlename_label);
				middlename_label.show ();

				middlename_entry = new Entry ();
				middlename_entry.hexpand = true;
				middlename_entry.activates_default = true;
				grid.attach_next_to (middlename_entry,
				                     middlename_label,
				                     PositionType.RIGHT,
				                     1, 1);
				middlename_label.mnemonic_widget = middlename_entry;
				middlename_entry.show ();


				var tin_label = new Label.with_mnemonic (_("_TIN Number:"));
				tin_label.xalign = 0.0f;
				grid.add (tin_label);
				tin_label.show ();

				tin_entry = new Entry ();
				tin_entry.hexpand = true;
				tin_entry.activates_default = true;
				grid.attach_next_to (tin_entry,
				                     tin_label,
				                     PositionType.RIGHT,
				                     1, 1);
				tin_label.mnemonic_widget = tin_entry;
				tin_entry.show ();


				rate_label = new Label.with_mnemonic (_("_Rate:"));
				rate_label.xalign = 0.0f;
				grid.add (rate_label);
				rate_label.show ();

				rate_spin = new SpinButton (new Adjustment (3500,
				                                            0, 1000000,
				                                            10, 100,
				                                            0),
				                            100, 0);
				grid.attach_next_to (rate_spin,
				                     rate_label,
				                     PositionType.RIGHT,
				                     1, 1);
				rate_label.mnemonic_widget = rate_spin;
				rate_spin.show ();


				var branch_label = new Label.with_mnemonic (_("_Branch:"));
				branch_label.xalign = 0.0f;
				grid.add (branch_label);
				branch_label.show ();

				branch_combobox = new ComboBox ();
				branch_combobox.hexpand = true;
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


				regular_check = new CheckButton.with_mnemonic (_("Re_gular"));
				regular_check.toggled.connect ((t) => {
					if (regular_check.active) {
						rate_label.set_text_with_mnemonic (_("_Rate:"));
						rate_spin.value = _employee.rate;
					} else {
						rate_label.set_text_with_mnemonic (_("_Rate (per day):"));
						rate_spin.value = _employee.rate_per_day;
					}
				});
				grid.attach_next_to (regular_check,
				                     branch_label,
				                     PositionType.BOTTOM,
				                     2, 1);
				regular_check.show ();


				pop_composite_child ();


				this.employee = employee;
			}

			public void save () {
				if (this._employee != null) {
					TreeIter iter;
					Branch branch;

					this._employee.lastname = this.lastname_entry.text;
					this._employee.firstname = this.firstname_entry.text;
					this._employee.middlename = this.middlename_entry.text;
					this._employee.tin = this.tin_entry.text;
					this._employee.regular = this.regular_check.active;

					if (this._employee.regular) {
						this._employee.rate = this.rate_spin.get_value_as_int ();
					} else {
						this._employee.rate_per_day = (double) this.rate_spin.get_value_as_int ();
					}

					if (this.branch_combobox.get_active_iter (out iter)) {
						this.branch_combobox.model.get (iter, BranchList.Columns.OBJECT, out branch);
						this._employee.branch = branch;
					}
				}
			}

		}

	}

}
