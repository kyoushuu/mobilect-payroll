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

		public class Dialog : Gtk.Dialog {

			public Button accept_button {
				public get {
					return get_widget_for_response (ResponseType.ACCEPT) as Button;
				}
			}

			public Button reject_button {
				public get {
					return get_widget_for_response (ResponseType.REJECT) as Button;
				}
			}

			public Button help_button {
				public get {
					return get_widget_for_response (ResponseType.HELP) as Button;
				}
			}

			public string action {
				public get {
					return accept_button.label;
				}

				public set {
					accept_button.label = value;
				}
			}

			public string help_link_id { public get; public set; }


			public Dialog (string title, Window parent) {
				Object (title: title,
				        transient_for: parent);

				var content_area = this.get_content_area ();
				var action_area = this.get_action_area ();

				this.add_buttons (Stock.CANCEL, ResponseType.REJECT,
				                  Stock.OK, ResponseType.ACCEPT,
				                  Stock.HELP, ResponseType.HELP);
				this.set_alternative_button_order (ResponseType.ACCEPT,
				                                   ResponseType.REJECT,
				                                   ResponseType.HELP);
				this.set_default_response (ResponseType.ACCEPT);

				(action_area as ButtonBox).set_child_secondary (help_button, true);
				this.response.connect ((d, r) => {
														if (r == ResponseType.HELP) {
															(this.transient_for as Window).help (null, this.help_link_id);
														}
													});

				this.border_width = 5;
				content_area.spacing = 2; /* 2 * 5 + 2 = 12 */
				(action_area as Container).border_width = 5;
			}

		}

	}

}
