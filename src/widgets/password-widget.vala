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

		public class PasswordWidget : Box {

			public Grid grid { get; private set; }

			public Entry password_entry { get; private set; }
			public Entry verify_entry { get; private set; }


			public PasswordWidget () {
				push_composite_child ();


				grid = new Grid ();
				grid.orientation = Orientation.VERTICAL;
				grid.row_homogeneous = true;
				grid.row_spacing = 3;
				grid.column_spacing = 12;
				this.add (grid);
				grid.show ();


				var password_label = new Label.with_mnemonic (_("_Password:"));
				password_label.xalign = 0.0f;
				grid.add (password_label);
				password_label.show ();

				password_entry = new Entry ();
				password_entry.visibility = false;
				password_entry.hexpand = true;
				password_entry.activates_default = true;
				password_entry.secondary_icon_tooltip_text = _("Password is empty");
				password_entry.changed.connect (changed);
				grid.attach_next_to (password_entry,
				                     password_label,
				                     PositionType.RIGHT,
				                     1, 1);
				password_entry.show ();


				var verify_label = new Label.with_mnemonic (_("_Verify:"));
				verify_label.xalign = 0.0f;
				grid.add (verify_label);
				verify_label.show ();

				verify_entry = new Entry ();
				verify_entry.visibility = false;
				verify_entry.hexpand = true;
				verify_entry.activates_default = true;
				verify_entry.secondary_icon_tooltip_text = _("Passwords didn't match");
				verify_entry.changed.connect (changed);
				grid.attach_next_to (verify_entry,
				                     verify_label,
				                     PositionType.RIGHT,
				                     1, 1);
				verify_entry.show ();


				pop_composite_child ();
			}

			public string? get_password () {
				if (password_entry.text != verify_entry.text) {
					return null;
				} else {
					return password_entry.text;
				}
			}

			private void changed () {
				if (password_entry.text_length > 0) {
					password_entry.secondary_icon_stock = null;
				} else {
					password_entry.secondary_icon_stock = Stock.DIALOG_WARNING;
				}
				if (password_entry.text == verify_entry.text) {
					verify_entry.secondary_icon_stock = null;
				} else {
					verify_entry.secondary_icon_stock = Stock.DIALOG_WARNING;
				}
			}

		}

	}

}
