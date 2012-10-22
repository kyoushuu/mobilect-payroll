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
using Config;


namespace Mobilect {

	namespace Payroll {

		public errordomain ApplicationError {
			USERNAME_NOT_FOUND,
			WRONG_PASSWORD,
			ALREADY_LOGGED_IN,
			NOT_LOGGED_IN
		}

		public class Application : Gtk.Application {

			private const string db_name = "mobilect-payroll";

			public Database database { get; private set; }
			public Settings settings { get; private set; }


			public Application () {
				Object (application_id: "com.mobilectpower.payroll");

				settings = new Settings ();
			}

			public override void startup () {
				base.startup ();

				try {
					database = new Database (this);
				} catch (Error e) {
					var e_dialog = new MessageDialog (null, DialogFlags.MODAL,
					                                  MessageType.ERROR, ButtonsType.OK,
					                                  _("Failed to load database."));
					e_dialog.secondary_text = e.message;
					e_dialog.run ();
					e_dialog.destroy ();
				}

				Log.set_handler ("Mobilect-Payroll",
				                 LogLevelFlags.LEVEL_WARNING |
				                 LogLevelFlags.LEVEL_MESSAGE,
				                 (d, l, m) => {
													 var text = m;
													 MessageType type = MessageType.INFO;
													 if (l == LogLevelFlags.LEVEL_WARNING) {
														 text = _("Warning");
														 type = MessageType.WARNING;
													 }

													 var dialog = new MessageDialog (null, DialogFlags.DESTROY_WITH_PARENT,
													                                 type, ButtonsType.OK,
													                                 text);
													 dialog.title = _("Mobilect Payroll");

													 if (l != LogLevelFlags.LEVEL_MESSAGE) {
														 dialog.secondary_text = m;
													 }

													 dialog.run ();
													 dialog.destroy ();
												 });
			}

			public override void activate () {
				if (database == null) {
					return;
				}

				var window = new Window (this);
				window.present ();
			}

		}

	}

}
