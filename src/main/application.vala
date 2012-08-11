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
using Gdk;
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

			public Window window { get; private set; }
			public Database database { get; private set; }
			public Settings settings { get; private set; }


			public Application () {
				Object (application_id: "com.mobilectpower.payroll");

				database = new Database ();
				settings = new Settings ();
			}

			public override void startup () {
				base.startup ();

				if (database == null) {
					var e_dialog = new MessageDialog (window, DialogFlags.MODAL,
					                                  MessageType.ERROR, ButtonsType.OK,
					                                  _("Failed to load database."));
					e_dialog.secondary_text = _("Check error logs for more information about this error.");
					e_dialog.run ();
					e_dialog.destroy ();
				}
			}

			public override void activate () {
				if (database == null) {
					return;
				}

				if (window == null) {
					window = new Window (this);
				}

				window.present ();
			}

			internal string help_link_uri (string name, string? link_id) {
				return link_id != null? "help:%s/%s".printf (name, link_id) : "help:%s".printf (name);
			}

			public void show_help (string? name, string? link_id) {
				try {
					show_uri ((window as Widget).get_screen (),
					          help_link_uri (name?? PACKAGE, link_id),
					          CURRENT_TIME);
				} catch (Error e) {
					warning ("Failed to display the help: %s", e.message);
				}
			}

		}

	}

}
