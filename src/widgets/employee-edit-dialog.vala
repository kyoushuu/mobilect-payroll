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

		public class EmployeeEditDialog : Dialog {

			public Employee employee {
				get {
					return widget.employee;
				}
				set {
					widget.employee = value;
				}
			}

			public EmployeeEditWidget widget { get; private set; }

			public EmployeeEditDialog (string title, Window parent, Employee employee) {
				Object (title: title,
				        transient_for: parent);

				this.add_buttons (Stock.OK, ResponseType.ACCEPT,
				                  Stock.CANCEL, ResponseType.REJECT);
				this.set_default_response (ResponseType.ACCEPT);
				this.response.connect ((t, r) => {
					if (r == ResponseType.ACCEPT) {
						this.widget.save ();
					}
				});

				widget = new EmployeeEditWidget (employee);
				this.get_content_area ().add (widget);

				this.show_all ();
				this.hide ();
			}

		}

	}

}
