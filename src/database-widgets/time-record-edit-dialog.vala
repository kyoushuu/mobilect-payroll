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

		public class TimeRecordEditDialog : Dialog {

			public TimeRecord time_record {
				public get {
					return widget.time_record;
				}
				public set {
					widget.time_record = value;
				}
			}

			public TimeRecordEditWidget widget { public get; private set; }


			public TimeRecordEditDialog (string title, Window parent, TimeRecord time_record) {
				base (title, parent);

				var content_area = this.get_content_area ();


				push_composite_child ();

				widget = new TimeRecordEditWidget (time_record);
				widget.border_width = 5;
				widget.employee_combobox.changed.connect (changed);
				widget.start_spin.value_changed.connect (changed);
				widget.end_spin.value_changed.connect (changed);
				widget.open_end_check.toggled.connect (changed);
				changed ();
				content_area.add (widget);

				widget.show ();

				pop_composite_child ();


				response.connect ((response_id) => {
					if (response_id == ResponseType.ACCEPT) {
						this.widget.save ();
					}
				});
			}

			private void changed () {
				set_response_sensitive (ResponseType.ACCEPT,
				                        widget.employee_combobox.active != -1 &&
				                        (widget.open_end_check.active ||
				                         widget.start_spin.get_date_time ().compare (widget.end_spin.get_date_time ()) < 0));
			}

		}

	}

}
