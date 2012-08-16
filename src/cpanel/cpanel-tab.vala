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

		public abstract class CPanelTab : Box {

			public weak CPanel cpanel { get; internal set; }

			public Gtk.ActionGroup action_group { get; internal set; }


			public virtual signal void changed_to () {
				if (this.action_group != null) {
					this.action_group.sensitive = true;
					this.action_group.visible = true;
				}
			}

			public virtual signal void changed_from () {
				if (this.action_group != null) {
					this.action_group.sensitive = false;
					this.action_group.visible = false;
				}
			}


			public CPanelTab (CPanel cpanel, string? action_name = null, string? ui_resource_path = null) {
				this.cpanel = cpanel;
				this.orientation = Orientation.VERTICAL;

				if (action_name != null) {
					this.action_group = new Gtk.ActionGroup (action_name);
					cpanel.window.ui_manager.insert_action_group (this.action_group, -1);
				}

				if (ui_resource_path != null) {
					try {
						cpanel.window.ui_manager.add_ui_from_resource (ui_resource_path);
					} catch (Error e) {
						error ("Failed to add UI to UI Manager: %s", e.message);
					}
				}
			}

		}

	}

}
