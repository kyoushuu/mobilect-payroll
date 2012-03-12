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

		public class Application : Gtk.Application {

			private const string db_name = "mobilect-payroll";

			public Window window { get; private set; }
			public Database database { get; private set; }

			public Application () {
				Object (application_id: "com.mobilectpower.payroll");

				try {
					database = new Database ();
				} catch (Error e) {
					stdout.printf ("Error: %d %s\n", e.code, e.message);
				}
			}

			public override void activate () {
				if (window == null)
					window = new Window (this);

				window.present ();
			}

		}

	}

}
