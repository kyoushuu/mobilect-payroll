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

		public class PasswordDialog : Dialog {

			public PasswordWidget widget { get; private set; }


			public PasswordDialog (string title, Window parent) {
				Object (title: title,
				        transient_for: parent);

				this.add_buttons (Stock.CANCEL, ResponseType.REJECT,
				                  Stock.SAVE, ResponseType.ACCEPT);
				this.set_default_response (ResponseType.ACCEPT);


				var content_area = this.get_content_area ();
				var action_area = this.get_action_area ();

				this.border_width = 5;
				content_area.spacing = 2; /* 2 * 5 + 2 = 12 */
				(action_area as Container).border_width = 5;


				push_composite_child ();

				widget = new PasswordWidget ();
				widget.border_width = 5;
				widget.password_entry.changed.connect (changed);
				widget.verify_entry.changed.connect (changed);
				changed ();
				content_area.add (widget);

				widget.show ();

				pop_composite_child ();
			}

			private void changed () {
				set_response_sensitive (ResponseType.ACCEPT,
				                        widget.password_entry.text_length > 0 &&
				                        widget.password_entry.text == widget.verify_entry.text);
			}

		}

	}

}
