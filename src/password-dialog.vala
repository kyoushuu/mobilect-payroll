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

				this.add_buttons (Stock.OK, ResponseType.ACCEPT,
				                  Stock.CANCEL, ResponseType.REJECT);
				this.set_default_response (ResponseType.ACCEPT);
				this.response.connect ((t, r) => {
					if (r == ResponseType.ACCEPT && widget.get_password () == null) {
						var e_dialog = new MessageDialog (parent,
						                                  DialogFlags.MODAL,
						                                  MessageType.ERROR,
						                                  ButtonsType.OK,
						                                  _("Passwords didn't match."));
						e_dialog.run ();
						e_dialog.destroy ();
					}
				});

				widget = new PasswordWidget ();
				this.get_content_area ().add (widget);

				this.show_all ();
				this.hide ();
			}

		}

	}

}
