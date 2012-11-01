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


using Config;


namespace Mobilect {

	namespace Payroll {

		public class Settings : Object {

			public GLib.Settings main { public get; private set; }
			public GLib.Settings view { public get; private set; }
			public GLib.Settings report { public get; private set; }

			public string page_setup { public get; private set; }
			public string print_settings { public get; private set; }


			public Settings () {
				main = new GLib.Settings ("com.mobilectpower.payroll");
				view = new GLib.Settings ("com.mobilectpower.payroll.view");
				report = new GLib.Settings ("com.mobilectpower.payroll.report");

				var user_config_dir = Environment.get_user_config_dir ();
				page_setup = Path.build_filename (user_config_dir, PACKAGE, "page-setup");
				print_settings = Path.build_filename (user_config_dir, PACKAGE, "print-settings");
			}

		}

	}

}
