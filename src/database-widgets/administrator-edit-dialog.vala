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

		public class AdministratorEditDialog : Dialog {

			public Administrator administrator {
				get {
					return widget.administrator;
				}
				set {
					widget.administrator = value;
				}
			}

			public AdministratorEditWidget widget { get; private set; }


			public AdministratorEditDialog (string title, Window parent, Administrator administrator) {
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

				widget = new AdministratorEditWidget (administrator);
				widget.border_width = 5;
				widget.username_entry.changed.connect ((e) => {
														set_response_sensitive (ResponseType.ACCEPT,
														                        widget.username_entry.text_length > 0);
													});
				widget.username_entry.changed ();
				content_area.add (widget);

				widget.show ();

				pop_composite_child ();


				response.connect ((response_id) => {
														if (response_id == ResponseType.ACCEPT) {
															this.widget.save ();
														}
													});
			}
		}

	}

}
